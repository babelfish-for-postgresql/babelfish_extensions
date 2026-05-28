/*-------------------------------------------------------------------------
 * pl_insert_exec.c
 *	INSERT EXECUTE implementation for Babelfish PL/tsql
 *	It implements:
 *		- Temp table lifecycle: creation, flush, and drop
 *-------------------------------------------------------------------------
 */

/* Include pltsql.h first to define types used by pltsql-2.h */
#include "pltsql.h"
#include "pltsql-2.h"

#include "access/table.h"
#include "access/xact.h"
#include "catalog/namespace.h"
#include "catalog/pg_attribute.h"
#include "commands/defrem.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "parser/scansup.h"

#include "catalog.h"
#include "multidb.h"
#include "session.h"

#include "utils/builtins.h"
#include "utils/lsyscache.h"

extern int execute_batch(PLtsql_execstate *estate, char *batch, InlineCodeBlockArgs *args, List *params);

/*
 * Global INSERT EXEC context - defined in pltsql.h, declared here.
 */
InsertExecContext insert_exec_ctx;

/*
 * Get a comma-separated list of non-IDENTITY, non-computed column names
 * for a table by opening the relation and iterating over its tuple descriptor.
 */
static char *
get_insertable_column_list(const char *table_name, const char *physical_schema)
{
	StringInfoData col_list;
	Oid			relid;
	Relation	rel;
	TupleDesc	tupdesc;
	int			i;
	bool		first_col = true;
	char		*lower_table_name;
	RangeVar	*rv;

	initStringInfo(&col_list);

	lower_table_name = downcase_identifier(table_name, strlen(table_name), false, false);

	/* Resolve the relation OID using RangeVar - works for both regular and temp tables */
	rv = makeRangeVar(physical_schema ? pstrdup(physical_schema) : NULL,
					  pstrdup(lower_table_name), -1);
	relid = RangeVarGetRelid(rv, NoLock, true);

	pfree(lower_table_name);

	if (!OidIsValid(relid))
		elog(ERROR, "INSERT EXEC failed due to missing relation for target table \"%s\"",
			table_name);

	/* Open the relation */
	rel = table_open(relid, AccessShareLock);
	tupdesc = RelationGetDescr(rel);

	/* Iterate over columns and build the list */
	for (i = 0; i < tupdesc->natts; i++)
	{
		Form_pg_attribute attr = TupleDescAttr(tupdesc, i);

		/* Skip dropped columns */
		if (attr->attisdropped)
			continue;

		/* Skip identity columns */
		if (attr->attidentity != '\0')
			continue;

		/* Skip generated/computed columns */
		if (attr->attgenerated != '\0')
			continue;

		/* Add column name to the list */
		if (!first_col)
			appendStringInfoString(&col_list, ", ");
		appendStringInfoString(&col_list, quote_identifier(NameStr(attr->attname)));
		first_col = false;
	}

	/* release the lock acquired by RangeVarGetRelid */
	table_close(rel, AccessShareLock);

	/* Error if no insertable columns found */
	if (first_col)
	{
		pfree(col_list.data);
		elog(ERROR, "INSERT EXEC failed due to no insertable columns in target table \"%s\"",
			table_name);
	}

	return col_list.data;
}


/*
 * Create a temp table for INSERT EXEC buffering.
 *
 * Creates a PostgreSQL temp table with schema matching the target table.
 * Uses ChooseRelationName to generate a unique name and ON COMMIT DROP
 * for automatic cleanup. Column types are inferred from the target table
 * via SELECT ... WITH NO DATA. The caller must have SELECT permission on
 * the target table for this to succeed.
 */
Oid
create_insert_exec_temp_table(const char *target_table, const char *column_list, const char *schema_name_in)
{
	StringInfoData create_stmt;
	int			rc;
	Oid			temp_table_oid;
	char		*temp_table_name;
	char		*physical_schema = NULL;
	Oid			temp_nsp_oid;
	const char	*select_cols;
	char		*cols_to_free = NULL;
	char		*qualified_target;

	/*
	 * Generate a unique temp table name using ChooseRelationName.
	 */
	temp_nsp_oid = LookupNamespaceNoError("pg_temp");
	if (!OidIsValid(temp_nsp_oid))
		elog(ERROR, "INSERT EXEC failed due to missing pg_temp namespace");

	temp_table_name = ChooseRelationName("__insert_exec_buf", NULL, NULL,
										 temp_nsp_oid, false);

	/*
	 * Resolve the physical schema for the target table reference.
	 *
	 * Three cases per T-SQL semantics:
	 *	1. Temp table (#) — always in pg_temp
	 *	2. Schema explicitly specified — resolve to physical schema name
	 *	3. No schema specified — leave NULL, let search_path handle resolution
	 */
	if (target_table[0] == '#')
		physical_schema = pstrdup("pg_temp");
	else if (schema_name_in != NULL)
	{
		/* User specified schema — resolve to physical name */
		physical_schema = get_physical_schema_name(get_cur_db_name(), schema_name_in);
		if (physical_schema == NULL)
			elog(ERROR, "INSERT EXEC failed due to unresolvable schema for target table \"%s\"",
				target_table);
	}
	/* 
	 * else: no schema specified, not a temp table — physical_schema stays NULL,
	 * search_path will resolve the target correctly
	 */

	/*
	 * Determine the column list to SELECT.
	 *
	 * If the user specified columns, use them directly.
	 * Otherwise, query the relation to get all non-IDENTITY,
	 * non-computed column names.
	 */
	if (column_list != NULL)
		select_cols = column_list;
	else
		select_cols = cols_to_free = get_insertable_column_list(target_table, physical_schema);


	/*
	 * Build a fully qualified reference for the source table.
	 */
	qualified_target = quote_qualified_identifier(physical_schema, target_table);

	/*
	 * Create the temp buffer table by selecting the desired columns
	 * with no rows. PostgreSQL infers column types from the SELECT.
	 * ON COMMIT DROP ensures automatic cleanup at transaction end.
	 */
	initStringInfo(&create_stmt);
	appendStringInfo(&create_stmt,
		"CREATE TEMP TABLE %s ON COMMIT DROP AS SELECT %s FROM %s WITH NO DATA",
		quote_identifier(temp_table_name), select_cols, qualified_target);

	if (cols_to_free)
		pfree(cols_to_free);
	pfree(qualified_target);

	/* Clean up parsed names */
	if (physical_schema)
		pfree(physical_schema);

	rc = SPI_execute(create_stmt.data, false, 0);
	if (rc != SPI_OK_UTILITY)
		elog(ERROR, "INSERT EXEC failed due to temp table creation error: %s",
			 SPI_result_code_string(rc));

	pfree(create_stmt.data);

	/* Get the OID of the created temp table */
	temp_table_oid = RelnameGetRelid(temp_table_name);
	if (!OidIsValid(temp_table_oid))
		elog(ERROR, "INSERT EXEC failed due to missing temp table \"%s\"", temp_table_name);

	return temp_table_oid;
}

/*
 * Flush data from temp table to target table.
 *
 * Executes INSERT INTO target SELECT * FROM temp_table.
 * Uses SPI_execute for the flush INSERT.
 * The flush is called while still inside the procedure's execution context.
 */
void
flush_insert_exec_temp_table(PLtsql_execstate *estate,
							 const char *column_list_str)
{
	char			*temp_name;
	char			*relname;
	char			*nspname;
	Relation		temp_rel;
	StringInfoData	flush_query;
	Oid				temp_oid = insert_exec_ctx.temp_table_oid;

	if (!OidIsValid(temp_oid) || !OidIsValid(insert_exec_ctx.target_rel_oid))
		return;

	relname = get_rel_name(insert_exec_ctx.target_rel_oid);
	nspname = get_namespace_name(get_rel_namespace(insert_exec_ctx.target_rel_oid));

	/*
	 * TODO: Reset insert_exec_ctx here before erroring to prevent stale state
	 * from affecting subsequent INSERT EXEC operations in the same session.
	 * Cleanup will be added in the wiring PR alongside reset_insert_exec_context().
	 *
	 * Verify target table schema hasn't changed since INSERT EXEC started.
	 */
	if (insert_exec_ctx.is_target_relation_modified)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("INSERT EXEC failed because the stored procedure altered the schema of the target table")));

	/* Get the temp table name from its OID */
	temp_rel = table_open(temp_oid, NoLock);
	temp_name = quote_qualified_identifier(get_namespace_name(RelationGetNamespace(temp_rel)),
										  RelationGetRelationName(temp_rel));
	table_close(temp_rel, NoLock);

	initStringInfo(&flush_query);

	appendStringInfo(&flush_query,
		"INSERT INTO %s%s SELECT * FROM %s",
		quote_qualified_identifier(nspname, relname),
		column_list_str ? column_list_str : "",
		temp_name);

	/* Route through execute_batch to handle triggers and errors properly. */
	execute_batch(estate, flush_query.data, NULL, NULL);
	pfree(flush_query.data);
}
