#include "postgres.h"

#include "access/genam.h"
#include "access/htup.h"
#include "access/htup_details.h"
#include "catalog/indexing.h"
#include "access/skey.h"
#include "access/table.h"
#include "access/xact.h"
#include "catalog/namespace.h"
#include "parser/parser.h"
#include "nodes/parsenodes.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/rel.h"

#include "catalog.h"
#include "guc.h"
#include "hooks.h"
#include "schemacmds.h"
#include "session.h"

static bool has_ext_info(const char *schemaname);

void
add_ns_ext_info(CreateSchemaStmt *stmt, const char *queryString, const char *orig_name)
{
	Relation	rel;
	Datum	   *new_record;
	bool	   *new_record_nulls;
	HeapTuple	tuple;
	int16		db_id = get_cur_db_id();
	NameData    schemaname_namedata;

	/*
	 * orig_name will be provided only when queryString is not valid. e.g
	 * CREATE LOGICLA DATABASE
	 */
	if (!orig_name)
	{
		if (stmt->location != -1 && queryString)
			orig_name = extract_identifier(queryString + stmt->location, NULL);
		else
			orig_name = "";
	}

	if (get_namespace_oid(stmt->schemaname, false) == InvalidOid)
		return;

	rel = table_open(namespace_ext_oid, RowExclusiveLock);

	new_record = palloc0(sizeof(Datum) * namespace_ext_num_cols);
	new_record_nulls = palloc0(sizeof(bool) * namespace_ext_num_cols);
	namestrcpy(&schemaname_namedata, stmt->schemaname);

	new_record[0] = NameGetDatum(&schemaname_namedata);
	new_record[1] = Int16GetDatum(db_id);
	new_record[2] = CStringGetTextDatum(orig_name);
	new_record[3] = CStringGetTextDatum("{}");	/* place holder */

	tuple = heap_form_tuple(RelationGetDescr(rel),
							new_record, new_record_nulls);
	CatalogTupleInsert(rel, tuple);
	table_close(rel, RowExclusiveLock);

	/* Advance cmd counter to make the new meta visible */
	CommandCounterIncrement();
}

void
del_ns_ext_info(const char *schemaname, bool missing_ok)
{
	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData scanKey;
	SysScanDesc scan;

	if (get_namespace_oid(schemaname, missing_ok) == InvalidOid)
		return;

	rel = table_open(namespace_ext_oid, RowExclusiveLock);
	ScanKeyInit(&scanKey,
				Anum_namespace_ext_namespace,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(schemaname));

	scan = systable_beginscan(rel, namespace_ext_idx_oid_oid, true,
							  NULL, 1, &scanKey);

	tuple = systable_getnext(scan);
	if (!HeapTupleIsValid(tuple))
	{
		systable_endscan(scan);
		table_close(rel, RowExclusiveLock);
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Could not drop schema created under PostgreSQL dialect: \"%s\"", schemaname)));
		return;
	}

	CatalogTupleDelete(rel, &tuple->t_self);
	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	CommandCounterIncrement();
}

void
check_extra_schema_restrictions(Node *stmt)
{
	if (sql_dialect == SQL_DIALECT_PG)
	{
		switch (nodeTag(stmt))
		{
			case T_DropStmt:
				{
					DropStmt   *drop_stmt = (DropStmt *) stmt;

					if (drop_stmt->removeType == OBJECT_SCHEMA)
					{
						const char *schemaname = strVal(lfirst(list_head(drop_stmt->objects)));

						if (has_ext_info(schemaname))
							ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									 errmsg("Could not drop schema created under T-SQL dialect: \"%s\"", schemaname)));
					}
					break;
				}
			case T_RenameStmt:
				{
					RenameStmt *rename_stmt = (RenameStmt *) stmt;

					if (rename_stmt->renameType == OBJECT_SCHEMA)
					{
						const char *schemaname = rename_stmt->subname;

						if (has_ext_info(schemaname))
							ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									 errmsg("Could not rename schema created under T-SQL dialect: \"%s\"", schemaname)));
					}
					break;
				}
			default:
				break;
		}
	}
}

static bool
has_ext_info(const char *schemaname)
{
	Relation	rel;
	HeapTuple	tuple;
	ScanKeyData scanKey;
	SysScanDesc scan;
	bool		found = true;

	rel = table_open(namespace_ext_oid, AccessShareLock);
	ScanKeyInit(&scanKey,
				Anum_namespace_ext_namespace,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(schemaname));

	scan = systable_beginscan(rel, namespace_ext_idx_oid_oid, true,
							  NULL, 1, &scanKey);

	tuple = systable_getnext(scan);
	if (!HeapTupleIsValid(tuple))
		found = false;

	systable_endscan(scan);
	table_close(rel, AccessShareLock);

	return found;
}
