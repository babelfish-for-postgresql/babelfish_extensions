/*-------------------------------------------------------------------------
 *
 * tablecmds.c
 *	  Babel functions for creating and altering table structures and settings
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/genam.h"
#include "access/heapam.h"
#include "access/htup_details.h"
#include "access/xact.h"
#include "nodes/pg_list.h"
#include "catalog/pg_attrdef.h"
#include "catalog/heap.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/objectaccess.h"
#include "catalog/pg_depend.h"
#include "catalog/pg_trigger.h"
#include "catalog/pg_type.h"
#include "commands/tablecmds.h"
#include "nodes/nodeFuncs.h"
#include "parser/parser.h"
#include "parser/parse_expr.h"
#include "parser/parse_type.h"
#include "parser/parse_collate.h"
#include "parser/scansup.h"
#include "utils/fmgroids.h"
#include "utils/syscache.h"
#include "utils/lsyscache.h"
#include "utils/builtins.h"
#include "catalog/pg_trigger_d.h"

#include "../src/multidb.h"
#include "../src/session.h"

#include "catalog.h"
#include "extendedproperty.h"
#include "hooks.h"

const char *ATTOPTION_BBF_ORIGINAL_NAME = "bbf_original_name";
const char *ATTOPTION_BBF_ORIGINAL_TABLE_NAME = "bbf_original_rel_name";
const char *ATTOPTION_BBF_TABLE_CREATE_DATE = "bbf_rel_create_date";

typedef struct ComputedColumnContextData
{
	Relation	rel;
	ParseState *pstate;
	List	   *gen_column_list;
} ComputedColumnContextData;

typedef ComputedColumnContextData *ComputedColumnContext;

void		assign_object_access_hook_drop_relation(void);
void		uninstall_object_access_hook_drop_relation(void);
static void lookup_and_drop_triggers(ObjectAccessType access, Oid classId,
									 Oid relOid, int subId, void *arg);
void		assign_tablecmds_hook(void);
static void pltsql_PreDropColumnHook(Relation rel, AttrNumber attnum);
static void pltsql_PreAddConstraintsHook(Relation rel, ParseState *pstate, List *newColDefaults);
static bool checkAllowedTsqlAttoptions(Node *options);

/* Hook to tablecmds.c in the engine */
static object_access_hook_type prev_object_access_hook = NULL;
static InvokePreDropColumnHook_type prev_InvokePreDropColumnHook = NULL;
static InvokePreAddConstraintsHook_type prev_InvokePreAddConstraintsHook = NULL;

void		pre_check_trigger_schema(List *object, bool missing_ok);

void
pre_check_trigger_schema(List *object, bool missing_ok)
{
	const char *depname;
	Oid			trigger_rel_oid = InvalidOid;
	const char *tsql_trigger_logical_schema = NULL;

	/* Extract name of dependent object. */
	depname = strVal(llast(object));
	if (list_length(object) > 1)
	{
		tsql_trigger_logical_schema = ((String *) linitial(object))->sval;
	}

	trigger_rel_oid = get_tsql_trigger_oid(object, depname, true);

	if (!missing_ok && !OidIsValid(trigger_rel_oid))
	{
		if (list_length(object) == 1)
		{
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("trigger \"%s\" does not exist",
							depname)));
		}
		else
		{
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					 errmsg("trigger \"%s.%s\" does not exist",
							tsql_trigger_logical_schema, depname)));
		}
	}
}

static void
lookup_and_drop_triggers(ObjectAccessType access, Oid classId,
						 Oid relOid, int subId, void *arg)
{
	Relation	tgrel;
	ScanKeyData key;
	SysScanDesc tgscan;
	HeapTuple	tuple;
	DropBehavior behavior = DROP_CASCADE;
	ObjectAddress trigAddress;

	/* Call previous hook if exists */
	if (prev_object_access_hook)
		(*prev_object_access_hook) (access, classId, relOid, subId, arg);

	/*
	 * babelfishpg_tsql extension is loaded does not mean dialect is
	 * necessarily tsql
	 */
	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/* We only want to execute this function for the DROP TABLE case */
	if (classId != RelationRelationId || access != OAT_DROP)
		return;

	/*
	 * If the relation is a table, we must look for triggers and drop them
	 * when in the tsql dialect because the user does not create a function
	 * for the trigger - we create it internally, and so the table cannot be
	 * dropped if there is a tsql trigger on it because of the dependency of
	 * the function.
	 */
	tgrel = table_open(TriggerRelationId, AccessShareLock);

	ScanKeyInit(&key,
				Anum_pg_trigger_tgrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				relOid);

	tgscan = systable_beginscan(tgrel, TriggerRelidNameIndexId, false,
								NULL, 1, &key);

	while (HeapTupleIsValid(tuple = systable_getnext(tgscan)))
	{
		Form_pg_trigger pg_trigger = (Form_pg_trigger) GETSTRUCT(tuple);

		if (pg_trigger->tgrelid == relOid && !pg_trigger->tgisinternal)
		{
			trigAddress.classId = TriggerRelationId;
			trigAddress.objectId = pg_trigger->oid;
			trigAddress.objectSubId = 0;
			performDeletion(&trigAddress, behavior, PERFORM_DELETION_INTERNAL);
		}
	}

	systable_endscan(tgscan);
	table_close(tgrel, AccessShareLock);
}

void
assign_object_access_hook_drop_relation()
{
	if (object_access_hook)
	{
		prev_object_access_hook = object_access_hook;
	}
	object_access_hook = lookup_and_drop_triggers;
}

void
uninstall_object_access_hook_drop_relation()
{
	if (prev_object_access_hook)
		object_access_hook = prev_object_access_hook;
}

void
assign_tablecmds_hook(void)
{
	if (InvokePreDropColumnHook)
		prev_InvokePreDropColumnHook = InvokePreDropColumnHook;
	InvokePreDropColumnHook = &pltsql_PreDropColumnHook;

	if (InvokePreAddConstraintsHook)
		prev_InvokePreAddConstraintsHook = InvokePreAddConstraintsHook;
	InvokePreAddConstraintsHook = &pltsql_PreAddConstraintsHook;

	check_extended_attoptions_hook = &checkAllowedTsqlAttoptions;
}

static void
pltsql_PreDropColumnHook(Relation rel, AttrNumber attnum)
{
	Relation	depRel;
	ScanKeyData key[3];
	SysScanDesc scan;
	HeapTuple	depTup, tuple;
	char		*schema_name = NULL,
				*minor_name = NULL;

	/* Call previous hook if exists */
	if (prev_InvokePreDropColumnHook)
		(*prev_InvokePreDropColumnHook) (rel, attnum);

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/*
	 * TSQL: Find everything that depends on the column.  If we can find a
	 * computed column dependent on this column, will throw an error.
	 */
	depRel = table_open(DependRelationId, RowExclusiveLock);

	ScanKeyInit(&key[0],
				Anum_pg_depend_refclassid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(RelationRelationId));
	ScanKeyInit(&key[1],
				Anum_pg_depend_refobjid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(RelationGetRelid(rel)));
	ScanKeyInit(&key[2],
				Anum_pg_depend_refobjsubid,
				BTEqualStrategyNumber, F_INT4EQ,
				Int32GetDatum((int32) attnum));

	scan = systable_beginscan(depRel, DependReferenceIndexId, true,
							  NULL, 3, key);

	while (HeapTupleIsValid(depTup = systable_getnext(scan)))
	{
		Form_pg_depend foundDep = (Form_pg_depend) GETSTRUCT(depTup);
		ObjectAddress foundObject;

		foundObject.classId = foundDep->classid;
		foundObject.objectId = foundDep->objid;
		foundObject.objectSubId = foundDep->objsubid;

		/*
		 * Below logic has been taken from backend's ATExecAlterColumnType
		 * function
		 */
		if (foundObject.classId == AttrDefaultRelationId)
		{
			ObjectAddress col = GetAttrDefaultColumnAddress(foundObject.objectId);

			if (col.objectId != RelationGetRelid(rel) || col.objectSubId != attnum)
			{
				Form_pg_attribute att = TupleDescAttr(rel->rd_att, attnum - 1);

				/*
				 * This must be a reference from the expression of a generated
				 * column elsewhere in the same table. Dropping the type of a
				 * column that is used by a generated column is not allowed by
				 * SQL standard.
				 */
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("cannot drop a column used by a generated column"),
						 errdetail("Column \"%s\" is used by generated column \"%s\".",
								   NameStr(att->attname),
								   get_attname(col.objectId, col.objectSubId, false))));
			}
		}
	}

	systable_endscan(scan);

	table_close(depRel, RowExclusiveLock);

	/* Delete extended property as well */

	/* Get minor_name */
	tuple = SearchSysCacheAttNum(RelationGetRelid(rel), attnum);
	if (!HeapTupleIsValid(tuple))
		return;
	minor_name = pstrdup(NameStr(((Form_pg_attribute) GETSTRUCT(tuple))->attname));
	ReleaseSysCache(tuple);

	/* Get schema_name */
	schema_name = get_namespace_name(RelationGetNamespace(rel));

	if (schema_name && minor_name)
	{
		const char *type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TABLE_COLUMN];
		delete_extended_property(get_cur_db_id(), type, schema_name,
								 RelationGetRelationName(rel), minor_name);
	}
}

static bool
check_nested_computed_column(Node *node, void *context)
{
	if (node == NULL)
		return false;
	else if (IsA(node, ColumnRef))
	{
		ColumnRef  *cref = (ColumnRef *) node;
		ParseState *pstate = ((ComputedColumnContext) context)->pstate;

		switch (list_length(cref->fields))
		{
			case 1:
				{
					Node	   *field1 = (Node *) linitial(cref->fields);
					List	   *colList;
					char	   *col1name;
					ListCell   *lc;
					Relation	rel;

					colList = ((ComputedColumnContext) context)->gen_column_list;
					rel = ((ComputedColumnContext) context)->rel;

					Assert(IsA(field1, String));
					col1name = strVal(field1);

					foreach(lc, colList)
					{
						char	   *col2name = (char *) lfirst(lc);

						if (strcmp(col1name, col2name) == 0)
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("computed column \"%s\" in table \"%s\" is not allowed to "
											"be used in another computed-column definition",
											col2name, RelationGetRelationName(rel)),
									 parser_errposition(pstate, cref->location)));

					}

					break;
				}
			default:

				/*
				 * In CREATE/ALTER TABLE command, the name of the column
				 * should have only one field.
				 */
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("improper column name in CREATE/ALTER TABLE(too many dotted names): %s",
								NameListToString(cref->fields)),
						 parser_errposition(pstate, cref->location)));
		}
	}

	return raw_expression_tree_walker(node, check_nested_computed_column,
									  (void *) context);
}

static void
pltsql_PreAddConstraintsHook(Relation rel, ParseState *pstate, List *newColDefaults)
{
	ListCell   *cell;
	Relation	attrelation = NULL;
	ComputedColumnContext context;

	/* Call previous hook if exists */
	if (prev_InvokePreAddConstraintsHook)
		(*prev_InvokePreAddConstraintsHook) (rel, pstate, newColDefaults);

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/*
	 * TSQL: Support for computed columns
	 *
	 * For a computed column, datatype is not provided by the user.  Hence,
	 * we've to evaluate the computed column expression in order to determine
	 * the datatype.  By now, we should've already made an entry for the
	 * relatio in the catalog, which means we can execute transformExpr on the
	 * computed column expression. Once we determine the datatype of the
	 * column, we'll update the corresponding entry in the catalog.
	 */
	context = palloc0(sizeof(ComputedColumnContextData));
	context->pstate = pstate;
	context->rel = rel;
	context->gen_column_list = NIL;

	/*
	 * Collect the names of all computed columns first.  We need this in order
	 * to detect nested computed columns later.
	 */
	foreach(cell, newColDefaults)
	{
		RawColumnDefault *colDef = (RawColumnDefault *) lfirst(cell);
		Form_pg_attribute atp = TupleDescAttr(rel->rd_att, colDef->attnum - 1);

		if (!atp->attgenerated)
			continue;

		context->gen_column_list = lappend(context->gen_column_list,
										   NameStr(atp->attname));

	}

	foreach(cell, newColDefaults)
	{
		RawColumnDefault *colDef = (RawColumnDefault *) lfirst(cell);
		Form_pg_attribute atp = TupleDescAttr(rel->rd_att, colDef->attnum - 1);
		Node	   *expr;
		Oid			targettype;
		int32		targettypmod;
		HeapTuple	heapTup;
		Type		targetType;
		Form_pg_attribute attTup;
		Form_pg_type tform;

		/* skip if not a computed column */
		if (!atp->attgenerated)
			continue;

		/*
		 * Since we're using a dummy datatype for a computed column, we need
		 * to check for a nested computed column usage in the expression
		 * before evaluating the expression through transformExpr. N.B. When
		 * we add a new column through ALTER command, it's possible that the
		 * expression includes another computed column in the table.  We'll
		 * not be able to detetct that case here.  That'll be handled later in
		 * check_nested_generated that works on the executable expression.
		 */
		Assert(context->gen_column_list != NULL);
		check_nested_computed_column(colDef->raw_default, context);

		/*
		 * transform raw parsetree to executable expression.
		 */
		expr = transformExpr(pstate, colDef->raw_default, EXPR_KIND_GENERATED_COLUMN);

		/* extract the type and other relevant information */
		targettype = exprType(expr);
		targettypmod = exprTypmod(expr);

		/* now update the attribute catalog entry with the correct type */
		if (!RelationIsValid(attrelation))
			attrelation = table_open(AttributeRelationId, RowExclusiveLock);

		/* Look up the target column */
		heapTup = SearchSysCacheCopyAttNum(RelationGetRelid(rel), colDef->attnum);
		if (!HeapTupleIsValid(heapTup)) /* shouldn't happen */
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_COLUMN),
					 errmsg("column number %d of relation \"%s\" does not exist",
							colDef->attnum, RelationGetRelationName(rel))));

		attTup = (Form_pg_attribute) GETSTRUCT(heapTup);

		targetType = typeidType(targettype);
		tform = (Form_pg_type) GETSTRUCT(targetType);

		attTup->atttypid = targettype;
		attTup->atttypmod = targettypmod;

		/*
		 * The target column should already be having a collation associated
		 * with it due to explicit COLLATE clause If suppose collation is not
		 * valid or there is no explicit COLLATE clause, we try to find column
		 * collation from finished expession.
		 */
		if (!OidIsValid(attTup->attcollation) || !colDef->hasCollClause)
		{
			Oid			targetcollid;

			/* take care of collations in the finished expression */
			assign_expr_collations(pstate, expr);
			targetcollid = exprCollation(expr);

			if (OidIsValid(targetcollid))
				attTup->attcollation = targetcollid;
			else
				attTup->attcollation = tform->typcollation;
		}

		attTup->attndims = tform->typndims;
		attTup->attlen = tform->typlen;
		attTup->attbyval = tform->typbyval;
		attTup->attalign = tform->typalign;
		attTup->attstorage = tform->typstorage;

		/*
		 * Instead of invalidating and refetching the relcache entry, just
		 * update the entry that we've fetched previously.  This works because
		 * no one else can see our in-progress changes.  Also note that we
		 * only updated the fixed part of Form_pg_attribute.
		 */
		memcpy(atp, attTup, ATTRIBUTE_FIXED_PART_SIZE);

		CatalogTupleUpdate(attrelation, &heapTup->t_self, heapTup);
		ReleaseSysCache((HeapTuple) targetType);

		/* Cleanup */
		heap_freetuple(heapTup);
	}

	if (RelationIsValid(attrelation))
	{
		table_close(attrelation, RowExclusiveLock);

		/* Make the updated catalog row versions visible */
		CommandCounterIncrement();
	}

	list_free(context->gen_column_list);
	pfree(context);
}

static bool
checkAllowedTsqlAttoptions(Node *options)
{
	if (castNode(List, options) == NIL)
		return true;

	if (strcmp(((DefElem *) linitial(castNode(List, options)))->defname,
			   ATTOPTION_BBF_ORIGINAL_NAME) == 0)
		return true;

	if (strcmp(((DefElem *) linitial(castNode(List, options)))->defname,
			   ATTOPTION_BBF_ORIGINAL_TABLE_NAME) == 0)
		return true;

	if (strcmp(((DefElem *) linitial(castNode(List, options)))->defname,
			   ATTOPTION_BBF_TABLE_CREATE_DATE) == 0)
		return true;

	return false;
}
