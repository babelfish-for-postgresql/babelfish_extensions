/*-------------------------------------------------------------------------
 *
 * extendedproperty.c
 *	  support extended property
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/genam.h"
#include "access/skey.h"
#include "access/table.h"
#include "access/xact.h"
#include "catalog/indexing.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "tsearch/ts_locale.h"
#include "utils/builtins.h"
#include "utils/catcache.h"
#include "utils/datum.h"
#include "utils/formatting.h"
#include "utils/syscache.h"
#include "utils/fmgroids.h"
#include "utils/rel.h"

#include "catalog.h"
#include "extendedproperty.h"
#include "multidb.h"
#include "pltsql.h"
#include "session.h"

typedef enum ExtendedPropertyProc
{
	SP_ADDEXTENDEDPROPERTY = 0,
	SP_UPDATEEXTENDEDPROPERTY,
	SP_DROPEXTENDEDPROPERTY
} ExtendedPropertyProc;

const char *const ExtendedPropertyTypeNames[] = {
    "DATABASE",
    "SCHEMA",
    "TABLE",
    "VIEW",
    "SEQUENCE",
    "PROCEDURE",
    "FUNCTION",
    "TYPE",
    "TABLE COLUMN"
};

StaticAssertDecl(lengthof(ExtendedPropertyTypeNames) == EXTENDED_PROPERTY_MAX,
				 "array length mismatch");

PG_FUNCTION_INFO_V1(sp_addextendedproperty);
PG_FUNCTION_INFO_V1(sp_updateextendedproperty);
PG_FUNCTION_INFO_V1(sp_dropextendedproperty);
PG_FUNCTION_INFO_V1(fn_listextendedproperty);

static void init_scan_key(ScanKeyData *scanKey,
						  int *nkeys,
						  int16 db_id,
						  const char *type,
						  const char *schema_name,
						  const char *major_name,
						  const char *minor_name,
						  const char *name);
static void sp_execextended_property(PG_FUNCTION_ARGS, ExtendedPropertyProc proc);
static bool get_extended_property_from_tuple(Relation relation, HeapTuple tuple,
											 Datum *values, bool *nulls, int len);
static char* get_value_by_name_from_array(ArrayType *array, const char *name);

static void
init_scan_key(ScanKeyData *scanKey,
			  int *nkeys,
			  int16 db_id,
			  const char *type,
			  const char *schema_name,
			  const char *major_name,
			  const char *minor_name,
			  const char *name)
{
	*nkeys = 0;
	ScanKeyInit(&scanKey[*nkeys],
				Anum_bbf_extended_properties_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(db_id));
	(*nkeys)++;

	if (type)
	{
		ScanKeyInit(&scanKey[*nkeys],
					Anum_bbf_extended_properties_type,
					BTEqualStrategyNumber, F_TEXTEQ,
					CStringGetTextDatum(type));
		(*nkeys)++;
	}

	if (schema_name)
	{
		ScanKeyInit(&scanKey[*nkeys],
					Anum_bbf_extended_properties_schema_name,
					BTEqualStrategyNumber, F_NAMEEQ,
					CStringGetDatum(schema_name));
		(*nkeys)++;
	}

	if (major_name)
	{
		ScanKeyInit(&scanKey[*nkeys],
					Anum_bbf_extended_properties_major_name,
					BTEqualStrategyNumber, F_NAMEEQ,
					CStringGetDatum(major_name));
		(*nkeys)++;
	}

	if (minor_name)
	{
		ScanKeyInit(&scanKey[*nkeys],
					Anum_bbf_extended_properties_minor_name,
					BTEqualStrategyNumber, F_NAMEEQ,
					CStringGetDatum(minor_name));
		(*nkeys)++;
	}

	if (name)
	{
		ScanKeyInit(&scanKey[*nkeys],
					Anum_bbf_extended_properties_name,
					BTEqualStrategyNumber, F_TEXTEQ,
					CStringGetTextDatum(name));
		(*nkeys)++;
	}
}

void
delete_extended_property(int16 db_id,
						 const char *type,
						 const char *schema_name,
						 const char *major_name,
						 const char *minor_name)
{
	Relation	rel;
	int			nkeys = 0;
	ScanKeyData scanKey[5];
	SysScanDesc scan;
	HeapTuple	tuple;

	rel = table_open(get_bbf_extended_properties_oid(), RowExclusiveLock);

	init_scan_key(scanKey, &nkeys, db_id, type, schema_name, major_name,
				  minor_name, NULL);

	scan = systable_beginscan(rel, get_bbf_extended_properties_idx_oid(), true,
							  NULL, nkeys, scanKey);

	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
		CatalogTupleDelete(rel, &tuple->t_self);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	CommandCounterIncrement();
}

void
update_extended_property(int16 db_id,
						 const char *type,
						 const char *schema_name,
						 const char *major_name,
						 const char *minor_name,
						 int attnum,
						 const char *new_value)
{
	Relation	rel;
	int			nkeys = 0;
	ScanKeyData scanKey[5];
	SysScanDesc scan;
	HeapTuple	tuple, new_tuple;
	Datum		values[BBF_EXTENDED_PROPERTIES_NUM_COLS];
	bool		nulls[BBF_EXTENDED_PROPERTIES_NUM_COLS];
	bool		replaces[BBF_EXTENDED_PROPERTIES_NUM_COLS];
	NameData 	new_value_namedata;

	rel = table_open(get_bbf_extended_properties_oid(), RowExclusiveLock);

	init_scan_key(scanKey, &nkeys, db_id, type, schema_name, major_name,
				  minor_name, NULL);

	scan = systable_beginscan(rel, get_bbf_extended_properties_idx_oid(), true,
							  NULL, nkeys, scanKey);

	MemSet(values, 0, sizeof(values));
	MemSet(nulls, false, sizeof(nulls));
	MemSet(replaces, false, sizeof(replaces));

	namestrcpy(&new_value_namedata, new_value);

	values[attnum - 1] = NameGetDatum(&new_value_namedata);
	replaces[attnum - 1] = true;

	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
		new_tuple = heap_modify_tuple(tuple, RelationGetDescr(rel),
									  values, nulls, replaces);

		CatalogTupleUpdate(rel, &new_tuple->t_self, new_tuple);

		heap_freetuple(new_tuple);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	CommandCounterIncrement();
}

Datum
sp_addextendedproperty(PG_FUNCTION_ARGS)
{
	sp_execextended_property(fcinfo, SP_ADDEXTENDEDPROPERTY);

	PG_RETURN_VOID();
}

Datum
sp_updateextendedproperty(PG_FUNCTION_ARGS)
{
	sp_execextended_property(fcinfo, SP_UPDATEEXTENDEDPROPERTY);

	PG_RETURN_VOID();
}

Datum
sp_dropextendedproperty(PG_FUNCTION_ARGS)
{
	sp_execextended_property(fcinfo, SP_DROPEXTENDEDPROPERTY);

	PG_RETURN_VOID();
}

/*
 * Main routine of sp_xxxextendedproperty.
 * Now we support some types of extended property, such as database, schema,
 * table, view, sequence, procedure, function, type, table column. We store type
 * of extended property as well, like TABLE or TABLE COLUMN. Note that we store
 * level1type with level2type. We will store PROCEDURE PARAMTER if we support
 * extended property of procedure paramter.
 * If we support more extended property, we should adapt sp_rename and
 * bbf_ExecDropStmt as well.
 */
static void
sp_execextended_property(PG_FUNCTION_ARGS, ExtendedPropertyProc proc)
{
	char		*name = NULL, *orig_name = NULL,
				*level0type = NULL, *level0name = NULL,
				*level1type = NULL, *level1name = NULL,
				*level2type = NULL, *level2name = NULL;
	bytea		*value = NULL;
	int16		db_id;
	const char	*type;
	char 		*schema_name, *major_name, *minor_name, *var_object_name;
	Oid			schema_id, owner_id;
	Oid			db_owner, cur_user_id;
	bool		is_dbo = false;
	Relation	rel;
	HeapTuple	tuple;
	int			nkeys = 0;
	ScanKeyData scanKey[6];
	SysScanDesc scan;
	uint8		param_valid = 0;
	char		*procedure_name;
	char		*db_name = get_cur_db_name();

	if (proc == SP_ADDEXTENDEDPROPERTY || proc == SP_UPDATEEXTENDEDPROPERTY)
	{
		orig_name = TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		value = PG_ARGISNULL(1) ? NULL : PG_GETARG_BYTEA_PP(1);
		level0type = PG_ARGISNULL(2) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(2));
		level0name = PG_ARGISNULL(3) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(3));
		level1type = PG_ARGISNULL(4) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(4));
		level1name = PG_ARGISNULL(5) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(5));
		level2type = PG_ARGISNULL(6) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(6));
		level2name = PG_ARGISNULL(7) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(7));
	}
	else if (proc == SP_DROPEXTENDEDPROPERTY)
	{
		orig_name = TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		level0type = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));
		level0name = PG_ARGISNULL(2) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(2));
		level1type = PG_ARGISNULL(3) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(3));
		level1name = PG_ARGISNULL(4) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(4));
		level2type = PG_ARGISNULL(5) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(5));
		level2name = PG_ARGISNULL(6) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(6));
	}

	db_owner = get_role_oid(get_db_owner_name(db_name), false);
	cur_user_id = GetUserId();
	if (is_member_of_role(cur_user_id, db_owner))
	{
		is_dbo = true;
	}

	db_id = get_cur_db_id();
	type = NULL;
	schema_name = "";
	major_name = "";
	minor_name = "";
	name = NULL;
	var_object_name = "";

	if (orig_name)
	{
		remove_trailing_spaces(orig_name);
		name = lowerstr(orig_name);
	}
	if (level0type)
	{
		remove_trailing_spaces(level0type);
		level0type = lowerstr(level0type);
	}
	if (level0name)
	{
		remove_trailing_spaces(level0name);
		level0name = lowerstr(level0name);
	}
	if (level1type)
	{
		remove_trailing_spaces(level1type);
		level1type = lowerstr(level1type);
	}
	if (level1name)
	{
		remove_trailing_spaces(level1name);
		level1name = lowerstr(level1name);
	}
	if (level2type)
	{
		remove_trailing_spaces(level2type);
		level2type = lowerstr(level2type);
	}
	if (level2name)
	{
		remove_trailing_spaces(level2name);
		level2name = lowerstr(level2name);
	}

	switch (proc)
	{
		case 0:
			procedure_name = "sp_addextendedproperty";
			break;
		case 1:
			procedure_name = "sp_updateextendedproperty";
			break;
		case 2:
			procedure_name = "sp_dropextendedproperty";
			break;
		default:
			Assert(false);
			procedure_name = "";
			break;
	}

	/*
	 * If param is not null, its length must not 0.
	 * orig_name must be not null and not empty.
	 */
	if ((!orig_name || strlen(orig_name) == 0) ||
		(level0type && strlen(level0type) == 0) ||
		(level0name && strlen(level0name) == 0) ||
		(level1type && strlen(level1type) == 0) ||
		(level1name && strlen(level1name) == 0) ||
		(level2type && strlen(level2type) == 0) ||
		(level2name && strlen(level2name) == 0))
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("An invalid parameter or option was specified for procedure '%s'.", procedure_name)));
	}

	/*
	 * Params are valid only when they are paired.
	 * We use bit map to store valid param and the valid bit maps are 000000,
	 * 110000, 111100, 111111.
	 */
	if (level0type)
		param_valid |= (1 << 5);
	if (level0name)
		param_valid |= (1 << 4);
	if (level1type)
		param_valid |= (1 << 3);
	if (level1name)
		param_valid |= (1 << 2);
	if (level2type)
		param_valid |= (1 << 1);
	if (level2name)
		param_valid |= (1 << 0);
	if (param_valid != 0 && param_valid != 48 && param_valid != 60 && param_valid != 63)
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("An invalid parameter or option was specified for procedure '%s'.", procedure_name)));
	}

	/* database */
	if (!level0type)
	{
		if (!is_dbo)
		{
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("Cannot find the object \"object specified\" because it does not exist or you do not have permissions.")));
		}

		type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_DATABASE];
		var_object_name = "object specified";
	}
	else
	{
		/* schema or object in schema */
		if (strcmp(level0type, "schema") == 0)
		{
			Form_pg_namespace	nspform;

			var_object_name = level0name;

			schema_name = get_physical_schema_name(db_name, level0name);
			tuple = SearchSysCache1(NAMESPACENAME, CStringGetDatum(schema_name));

			if (!HeapTupleIsValid(tuple))
			{
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("Object is invalid. Extended properties are not permitted on '%s', or the object does not exist.", var_object_name)));
			}

			nspform = (Form_pg_namespace) GETSTRUCT(tuple);
			schema_id = nspform->oid;
			owner_id = nspform->nspowner;
			ReleaseSysCache(tuple);

			/* schema */
			if (!level1type)
			{
				if (!is_dbo && !is_member_of_role(cur_user_id, owner_id))
				{
					ereport(ERROR,
							(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							 errmsg("Cannot find the object \"%s\" because it does not exist or you do not have permissions.", var_object_name)));
				}

				type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SCHEMA];
			}
			/* object in schema */
			else
			{
				Oid reloid = InvalidOid;

				if (strcmp(level1type, "table") != 0 &&
					strcmp(level1type, "view") != 0 &&
					strcmp(level1type, "sequence") != 0 &&
					strcmp(level1type, "procedure") != 0 &&
					strcmp(level1type, "function") != 0 &&
					strcmp(level1type, "type") != 0)
				{
					ereport(ERROR,
							(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							 errmsg("Extended properties for object type %s are not currently supported in Babelfish.", level1type)));
				}

				var_object_name = psprintf("%s.%s", level0name, level1name);
				major_name = level1name;
				truncate_tsql_identifier(major_name);

				if (strcmp(level1type, "table") == 0 ||
					strcmp(level1type, "view") == 0 ||
					strcmp(level1type, "sequence") == 0)
				{
					Form_pg_class	classform;
					char			relkind;

					tuple = SearchSysCache2(RELNAMENSP,
											CStringGetDatum(major_name),
											ObjectIdGetDatum(schema_id));
					if (!HeapTupleIsValid(tuple))
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Object is invalid. Extended properties are not permitted on '%s', or the object does not exist.", var_object_name)));
					}

					classform = (Form_pg_class) GETSTRUCT(tuple);
					reloid = classform->oid;
					relkind = classform->relkind;
					owner_id = classform->relowner;
					ReleaseSysCache(tuple);

					if ((strcmp(level1type, "table") == 0 && (relkind != RELKIND_RELATION && relkind != RELPERSISTENCE_PERMANENT)) ||
						(strcmp(level1type, "view") == 0 && (relkind != RELKIND_VIEW && relkind != RELKIND_MATVIEW)) ||
						(strcmp(level1type, "sequence") == 0 && relkind != RELKIND_SEQUENCE))
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Object is invalid. Extended properties are not permitted on '%s', or the object does not exist.", var_object_name)));
					}

					if (!is_dbo && !is_member_of_role(cur_user_id, owner_id))
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Cannot find the object \"%s\" because it does not exist or you do not have permissions.", var_object_name)));
					}
				}
				else if (strcmp(level1type, "procedure") == 0 ||
						 strcmp(level1type, "function") == 0)
				{
					CatCList   		*catlist;
					Form_pg_proc	procform;
					bool			find = false;

					catlist = SearchSysCacheList1(PROCNAMEARGSNSP,
												  CStringGetDatum(major_name));
					for (int i = 0; i < catlist->n_members; i++)
					{
						tuple = &catlist->members[i]->tuple;
						procform = (Form_pg_proc) GETSTRUCT(tuple);
						if (procform->pronamespace == schema_id)
						{
							owner_id = procform->proowner;
							find = true;
							break;
						}
					}
					ReleaseSysCacheList(catlist);

					if (!find)
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Object is invalid. Extended properties are not permitted on '%s', or the object does not exist.", var_object_name)));
					}

					if (!is_dbo && !is_member_of_role(cur_user_id, owner_id))
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Cannot find the object \"%s\" because it does not exist or you do not have permissions.", var_object_name)));
					}
				}
				else if (strcmp(level1type, "type") == 0)
				{
					Form_pg_type	typeform;

					tuple = SearchSysCache2(TYPENAMENSP,
											CStringGetDatum(major_name),
											ObjectIdGetDatum(schema_id));
					if (!HeapTupleIsValid(tuple))
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Object is invalid. Extended properties are not permitted on '%s', or the object does not exist.", var_object_name)));
					}

					typeform = (Form_pg_type) GETSTRUCT(tuple);
					owner_id = typeform->typowner;
					ReleaseSysCache(tuple);

					if (!is_dbo && !is_member_of_role(cur_user_id, owner_id))
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Cannot find the object \"%s\" because it does not exist or you do not have permissions.", var_object_name)));
					}
				}

				if (!level2type)
				{
					type = asc_toupper(level1type, strlen(level1type));
				}
				else
				{
					char *temp;

					if (strcmp(level1type, "table") != 0 &&
						strcmp(level2type, "column") != 0)
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Extended properties for object type %s are not currently supported in Babelfish.", level2type)));
					}

					var_object_name = psprintf("%s.%s.%s", level0name, level1name, level2name);
					minor_name = level2name;
					truncate_tsql_identifier(minor_name);

					tuple = SearchSysCacheAttName(reloid, minor_name);
					if (!HeapTupleIsValid(tuple))
					{
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
								 errmsg("Object is invalid. Extended properties are not permitted on '%s', or the object does not exist.", var_object_name)));
					}
					ReleaseSysCache(tuple);

					temp = psprintf("%s %s", level1type, level2type);
					type = asc_toupper(temp, strlen(temp));
					pfree(temp);
				}
			}
		}
	}

	/* insert/update/drop extended property */
	rel = table_open(get_bbf_extended_properties_oid(), RowExclusiveLock);

	init_scan_key(scanKey, &nkeys, db_id, type, schema_name, major_name,
				  minor_name, name);

	scan = systable_beginscan(rel, get_bbf_extended_properties_idx_oid(), true,
							  NULL, 6, scanKey);
	if (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
		if (proc == SP_ADDEXTENDEDPROPERTY)
		{
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("Property cannot be added. Property '%s' already exists for '%s'.", name, var_object_name)));
		}
	}
	else
	{
		if (proc == SP_UPDATEEXTENDEDPROPERTY || proc == SP_DROPEXTENDEDPROPERTY)
		{
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("Property cannot be updated or deleted. Property '%s' does not exist for '%s'.", name, var_object_name)));
		}
	}

	if (proc == SP_ADDEXTENDEDPROPERTY)
	{
		Datum		values[BBF_EXTENDED_PROPERTIES_NUM_COLS];
		bool		nulls[BBF_EXTENDED_PROPERTIES_NUM_COLS];
		NameData    schema_name_namedata;
		NameData    major_name_namedata;
		NameData    minor_name_namedata;

		MemSet(values, 0, sizeof(values));
		MemSet(nulls, false, sizeof(nulls));
		namestrcpy(&schema_name_namedata, schema_name);
		namestrcpy(&major_name_namedata, major_name);
		namestrcpy(&minor_name_namedata, minor_name);

		values[0] = Int16GetDatum(db_id);
		values[1] = NameGetDatum(&schema_name_namedata);
		values[2] = NameGetDatum(&major_name_namedata);
		values[3] = NameGetDatum(&minor_name_namedata);
		values[4] = CStringGetTextDatum(type);
		values[5] = CStringGetTextDatum(name);
		values[6] = CStringGetTextDatum(orig_name);
		if (value)
			values[7] = CStringGetDatum(value);
		else
			nulls[7] = true;

		tuple = heap_form_tuple(RelationGetDescr(rel), values, nulls);
		CatalogTupleInsert(rel, tuple);
		heap_freetuple(tuple);
	}
	else if (proc == SP_UPDATEEXTENDEDPROPERTY)
	{
		Datum		values[BBF_EXTENDED_PROPERTIES_NUM_COLS];
		bool		nulls[BBF_EXTENDED_PROPERTIES_NUM_COLS];
		bool		replaces[BBF_EXTENDED_PROPERTIES_NUM_COLS];
		HeapTuple	new_tuple;

		MemSet(values, 0, sizeof(values));
		MemSet(nulls, false, sizeof(nulls));
		MemSet(replaces, false, sizeof(replaces));

		if (value)
			values[Anum_bbf_extended_properties_value - 1] = CStringGetDatum(value);
		else
			nulls[Anum_bbf_extended_properties_value - 1] = true;
		replaces[Anum_bbf_extended_properties_value - 1] = true;

		new_tuple = heap_modify_tuple(tuple, RelationGetDescr(rel),
									  values, nulls, replaces);
		CatalogTupleUpdate(rel, &new_tuple->t_self, new_tuple);
		heap_freetuple(new_tuple);
	}
	else if (proc == SP_DROPEXTENDEDPROPERTY)
	{
		CatalogTupleDelete(rel, &tuple->t_self);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	CommandCounterIncrement();
}

Datum
fn_listextendedproperty(PG_FUNCTION_ARGS)
{
	ReturnSetInfo	*rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc		tupdesc;
	Tuplestorestate	*tupstore;
	MemoryContext	per_query_ctx;
	MemoryContext	oldcontext;
	char			*name,
					*level0type, *level0name,
					*level1type, *level1name,
					*level2type, *level2name;
	int16			db_id;
	const char		*type;
	char			*schema_name, *major_name, *minor_name;
	Relation		rel;
	HeapTuple		tuple;
	ScanKeyData		scanKey[6];
	int				nkeys;
	SysScanDesc		scan;
	uint8			param_valid = 0;
	Oid				nspoid, sysname_oid, sql_variant_oid, colloid;

	name = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
	level0type = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));
	level0name = PG_ARGISNULL(2) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(2));
	level1type = PG_ARGISNULL(3) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(3));
	level1name = PG_ARGISNULL(4) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(4));
	level2type = PG_ARGISNULL(5) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(5));
	level2name = PG_ARGISNULL(6) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(6));

	db_id = get_cur_db_id();
	type = NULL;
	schema_name = "";
	major_name = "";
	minor_name = "";

	if (name)
	{
		remove_trailing_spaces(name);
		name = lowerstr(name);
	}
	if (level0type)
	{
		remove_trailing_spaces(level0type);
		level0type = lowerstr(level0type);
	}
	if (level0name)
	{
		remove_trailing_spaces(level0name);
		level0name = lowerstr(level0name);
	}
	if (level1type)
	{
		remove_trailing_spaces(level1type);
		level1type = lowerstr(level1type);
	}
	if (level1name)
	{
		remove_trailing_spaces(level1name);
		level1name = lowerstr(level1name);
	}
	if (level2type)
	{
		remove_trailing_spaces(level2type);
		level2type = lowerstr(level2type);
	}
	if (level2name)
	{
		remove_trailing_spaces(level2name);
		level2name = lowerstr(level2name);
	}

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));

	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	nspoid = get_namespace_oid("sys", false);
	sysname_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
								  CStringGetDatum("sysname"),
								  ObjectIdGetDatum(nspoid));
	sql_variant_oid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
									  CStringGetDatum("sql_variant"),
									  ObjectIdGetDatum(nspoid));
	colloid = tsql_get_server_collation_oid_internal(false);

	/* need to build tuplestore in query context */
	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	/* Build tupdesc for result tuples. */
	tupdesc = CreateTemplateTupleDesc(4);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "objtype", sysname_oid, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 2, "objname", sysname_oid, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 3, "name", sysname_oid, 128, 0);
	TupleDescInitEntry(tupdesc, (AttrNumber) 4, "value", sql_variant_oid, -1, 0);
	tupdesc = BlessTupleDesc(tupdesc);

	/* And set the correct collations to the required fields. */
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 1, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 2, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 3, colloid);
	TupleDescInitEntryCollation(tupdesc, (AttrNumber) 4, colloid);

	tupstore = tuplestore_begin_heap(true, false, work_mem);
	/* generate junk in short-term context */
	MemoryContextSwitchTo(oldcontext);

	/* If param is not null, its length must not 0. */
	if ((name && strlen(name) == 0) ||
		(level0type && strlen(level0type) == 0) ||
		(level0name && strlen(level0name) == 0) ||
		(level1type && strlen(level1type) == 0) ||
		(level1name && strlen(level1name) == 0) ||
		(level2type && strlen(level2type) == 0) ||
		(level2name && strlen(level2name) == 0))
		goto end;
	/*
	 * Params are valid only when they are continuous.
	 * We use bit map to store valid param and the valid bit maps are 100000,
	 * 110000, 111000, 111100, 111110, 111111.
	 */
	if (level0type && strlen(level0type) != 0)
		param_valid |= (1 << 5);
	if (level0name && strlen(level0name) != 0)
		param_valid |= (1 << 4);
	if (level1type && strlen(level1type) != 0)
		param_valid |= (1 << 3);
	if (level1name && strlen(level1name) != 0)
		param_valid |= (1 << 2);
	if (level2type && strlen(level2type) != 0)
		param_valid |= (1 << 1);
	if (level2name && strlen(level2name) != 0)
		param_valid |= (1 << 0);
	param_valid ^= 63;
	if (((param_valid + 1) & param_valid) != 0)
		goto end;

	/* database */
	if (!level0type)
	{
		type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_DATABASE];
	}
	else
	{
		/* schema or object in schema */
		if (strcmp(level0type, "schema") == 0)
		{
			schema_name = get_physical_schema_name(get_cur_db_name(), level0name);

			/* schema */
			if (!level1type)
			{
				type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SCHEMA];
			}
			/* object in schema */
			else
			{
				major_name = level1name;
				truncate_tsql_identifier(major_name);

				if (!level2type)
					type = asc_toupper(level1type, strlen(level1type));
				else
				{
					char	*temp;

					temp = psprintf("%s %s", level1type, level2type);
					type = asc_toupper(temp, strlen(temp));
					pfree(temp);

					minor_name = level2name;
					truncate_tsql_identifier(minor_name);
				}
			}
		}
	}
	rel = table_open(get_bbf_extended_properties_oid(), AccessShareLock);

	init_scan_key(scanKey, &nkeys, db_id, type, schema_name, major_name,
				  minor_name, name);

	scan = systable_beginscan(rel, get_bbf_extended_properties_idx_oid(), true,
							  NULL, nkeys, scanKey);
	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
		Datum	values[4];
		bool	nulls[4];

		if (get_extended_property_from_tuple(rel, tuple, values, nulls, 4))	
			tuplestore_putvalues(tupstore, tupdesc, values, nulls);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	/* clean up and return the tuplestore */
	tuplestore_donestoring(tupstore);

end:
	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	PG_RETURN_NULL();
}

extern const char *ATTOPTION_BBF_ORIGINAL_TABLE_NAME;
extern const char *ATTOPTION_BBF_ORIGINAL_NAME;

static char*
get_value_by_name_from_array(ArrayType *array, const char *name)
{
	int			i;

	for (i = 1; i <= ARR_DIMS(array)[0]; i++)
	{
		Datum		d;
		bool		isnull;
		char	   *s;
		char	   *p;

		d = array_ref(array, 1, &i,
					  -1 /* varlenarray */ ,
					  -1 /* TEXT's typlen */ ,
					  false /* TEXT's typbyval */ ,
					  TYPALIGN_INT /* TEXT's typalign */ ,
					  &isnull);
		if (isnull)
			continue;

		s = TextDatumGetCString(d);
		p = strchr(s, '=');
		if (p)
			*p++ = '\0';

		if (strcmp(s, name) == 0)
			return p;
	}
	return NULL;
}

/*
 * Extract columns from extended property tuple and filter rows that
 * current user does not has read-only privilege.
 *
 * Privileges are usage privilege on schema/type, select privilege on
 * table/view/sequence/table column, execute privilege on procedure/function.
 *
 * We only check privilege of low level type. If type is TABLE COLUMN, we only
 * check privilege of table column, skip privilege of schema or table.
 */
static bool
get_extended_property_from_tuple(Relation relation, HeapTuple tuple,
								 Datum *values, bool *nulls, int len)
{
	Form_bbf_extended_properties bep;
	char		*schema_name, *major_name, *minor_name, *type;
	char		*original_major_name = NULL, *original_minor_name = NULL;
	Oid			cur_user_id;
	Oid			schema_id, reloid = InvalidOid, procoid, typeoid;
	HeapTuple	heaptuple;
	int16		attnum;
	Datum		datum;
	bool		isnull;

	type = "";
	schema_name = "";
	major_name = "";
	minor_name = "";

	/* check if have read-only permission */
	cur_user_id = GetUserId();

	bep = (Form_bbf_extended_properties) GETSTRUCT(tuple);

	/*
	 * we must use heap_getattr instead of GETSTRUCT, because type of Varchar
	 * doesn't have fix length.
	 */
	datum = heap_getattr(tuple, Anum_bbf_extended_properties_type,
						 RelationGetDescr(relation), &isnull);
	type = TextDatumGetCString(datum);
	schema_name = NameStr(bep->schema_name);

	if (strcmp(schema_name, "") != 0)
	{
		heaptuple = SearchSysCache1(NAMESPACENAME,
									CStringGetDatum(schema_name));

		if (!HeapTupleIsValid(heaptuple))
			return false;

		schema_id = ((Form_pg_namespace) GETSTRUCT(heaptuple))->oid;
		ReleaseSysCache(heaptuple);

		if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SCHEMA]) == 0 &&
			pg_namespace_aclcheck(schema_id, cur_user_id, ACL_USAGE | ACL_CREATE) != ACLCHECK_OK)
			return false;

		major_name = NameStr(bep->major_name);
		if (strcmp(major_name, "") != 0)
		{
			/*
			 * We use strncmp rather than strcmp because we need to get relation
			 * oid before we get to lower layer. For example, the type is
			 * "TABLE COLUMN", we need to get table oid here.
			 */
			if (strncmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TABLE], 5) == 0 ||
				strncmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_VIEW], 4) == 0 ||
				strncmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SEQUENCE], 8) == 0)
			{
				Form_pg_class	classform;
				ArrayType		*reloptions;

				heaptuple = SearchSysCache2(RELNAMENSP,
											CStringGetDatum(major_name),
											ObjectIdGetDatum(schema_id));
				if (!HeapTupleIsValid(heaptuple))
					return false;

				classform = (Form_pg_class) GETSTRUCT(heaptuple);
				reloid = classform->oid;
				datum = SysCacheGetAttr(RELOID, heaptuple,
										Anum_pg_class_reloptions, &isnull);
				if (!isnull)
				{
					reloptions = DatumGetArrayTypeP(datum);
					original_major_name = get_value_by_name_from_array(reloptions, ATTOPTION_BBF_ORIGINAL_TABLE_NAME);
				}
				ReleaseSysCache(heaptuple);

				if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TABLE]) == 0 ||
					strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_VIEW]) == 0 ||
					strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SEQUENCE]) == 0)
				{
					if (pg_class_aclcheck(reloid, cur_user_id, ACL_SELECT | ACL_INSERT | ACL_UPDATE | ACL_DELETE | ACL_REFERENCES | ACL_TRIGGER) != ACLCHECK_OK)
						return false;
				}
			}
			else if (strncmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_PROCEDURE], 9) == 0 ||
					 strncmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_FUNCTION], 8) == 0)
			{
				CatCList   		*catlist;
				Form_pg_proc	procform;
				bool			find = false;

				catlist = SearchSysCacheList1(PROCNAMEARGSNSP,
											  CStringGetDatum(major_name));
				for (int i = 0; i < catlist->n_members; i++)
				{
					heaptuple = &catlist->members[i]->tuple;
					procform = (Form_pg_proc) GETSTRUCT(heaptuple);
					if (procform->pronamespace == schema_id)
					{
						procoid = procform->oid;
						find = true;
						break;
					}
				}
				ReleaseSysCacheList(catlist);

				if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_PROCEDURE]) == 0 ||
					strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_FUNCTION]) == 0)
				{
					if (!find ||
						pg_proc_aclcheck(procoid, cur_user_id, ACL_EXECUTE) != ACLCHECK_OK)
						return false;
				}
			}
			else if (strncmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TYPE], 4) == 0)
			{
				Form_pg_type	typeform;

				heaptuple = SearchSysCache2(TYPENAMENSP,
											CStringGetDatum(major_name),
											ObjectIdGetDatum(schema_id));
				if (!HeapTupleIsValid(heaptuple))
					return false;

				typeform = (Form_pg_type) GETSTRUCT(heaptuple);
				typeoid = typeform->oid;
				ReleaseSysCache(heaptuple);

				if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TYPE]) == 0)
				{
					if (pg_type_aclcheck(typeoid, cur_user_id, ACL_USAGE) != ACLCHECK_OK)
						return false;
				}
			}

			minor_name = NameStr(bep->minor_name);
			if (strcmp(minor_name, "") != 0)
			{
				if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TABLE_COLUMN]) == 0)
				{
					Form_pg_attribute	attform;
					ArrayType			*attoptions;

					heaptuple = SearchSysCacheAttName(reloid, minor_name);
					if (!HeapTupleIsValid(heaptuple))
						return false;

					attform = (Form_pg_attribute) GETSTRUCT(heaptuple);
					attnum = attform->attnum;
					datum = SysCacheGetAttr(ATTNAME, heaptuple,
											Anum_pg_attribute_attoptions,
											&isnull);
					if (!isnull)
					{
						attoptions = DatumGetArrayTypeP(datum);
						original_minor_name = get_value_by_name_from_array(attoptions, ATTOPTION_BBF_ORIGINAL_NAME);
					}
					ReleaseSysCache(heaptuple);

					if (pg_class_aclcheck(reloid, cur_user_id, ACL_SELECT | ACL_INSERT | ACL_UPDATE | ACL_DELETE | ACL_REFERENCES | ACL_TRIGGER) != ACLCHECK_OK &&
						pg_attribute_aclcheck(reloid, attnum, cur_user_id, ACL_SELECT | ACL_INSERT | ACL_UPDATE | ACL_REFERENCES) != ACLCHECK_OK)
						return false;
				}
			}
		}
	}

	MemSet(values, 0, len);
	MemSet(nulls, 0, len);

	if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_DATABASE]) == 0)
	{
		nulls[0] = true;
		nulls[1] = true;
	}
	else if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SCHEMA]) == 0)
	{
		values[0] = CStringGetTextDatum(ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SCHEMA]);
		values[1] = CStringGetTextDatum(get_logical_schema_name(schema_name, true));
	}
	else if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TABLE]) == 0 ||
			 strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_VIEW]) == 0 ||
			 strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SEQUENCE]) == 0 ||
			 strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_PROCEDURE]) == 0 ||
			 strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_FUNCTION]) == 0 ||
			 strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TYPE]) == 0)
	{
		values[0] = CStringGetTextDatum(type);
		values[1] = CStringGetTextDatum(original_major_name ? original_major_name : major_name);
	}
	else if (strcmp(type, ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TABLE_COLUMN]) == 0)
	{
		values[0] = CStringGetTextDatum("COLUMN");
		values[1] = CStringGetTextDatum(original_minor_name ? original_minor_name : minor_name);
	}

	datum = heap_getattr(tuple, Anum_bbf_extended_properties_orig_name,
						 RelationGetDescr(relation), &isnull);
	values[2] = datumCopy(datum, false, -1);
	datum = heap_getattr(tuple, Anum_bbf_extended_properties_value,
						 RelationGetDescr(relation), &isnull);
	values[3] = datumCopy(datum, false, -1);

	return true;
}
