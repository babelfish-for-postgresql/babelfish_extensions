/*-------------------------------------------------------------------------
 *
 * pl_insert_exec.c
 *	  INSERT EXECUTE implementation for Babelfish PL/tsql
 *
 * This file contains all logic for the INSERT INTO <target> EXEC <proc>
 * statement redesign. It implements:
 *   - InsertExecContext: global state tracking for an active INSERT EXEC
 *   - DestReceiver (DR_insertexec): captures procedure output into a
 *     session-local temp table
 *   - Temp table lifecycle: creation, schema inference, flush, and drop
 *   - Context management accessors used across pl_exec.c, hooks.c, and
 *     the TDS layer
 *
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

/* Forward declaration for exec_set_rowcount - defined in pl_exec.c */
extern void exec_set_rowcount(uint64 rowno);

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
	char	   *lower_table_name;
	RangeVar   *rv;

	initStringInfo(&col_list);

	lower_table_name = downcase_identifier(table_name, strlen(table_name), false, false);

	/* Resolve the relation OID using RangeVar - works for both regular and temp tables */
	rv = makeRangeVar(physical_schema ? pstrdup(physical_schema) : NULL,
					  pstrdup(lower_table_name), -1);
	relid = RangeVarGetRelid(rv, AccessShareLock, false);

	pfree(lower_table_name);

	if (!OidIsValid(relid))
		elog(ERROR, "could not find relation for INSERT EXEC target table: %s",
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

	table_close(rel, AccessShareLock);

	/* Error if no insertable columns found */
	if (first_col)
	{
		pfree(col_list.data);
		elog(ERROR, "no insertable columns found for INSERT EXEC target table: %s",
			table_name);
	}

	return col_list.data;
}


/*
 * Create a temp table for INSERT EXEC buffering.
 *
 * Creates a PostgreSQL temp table with schema matching
 * the target table. Uses ChooseRelationName to generate a unique name.
 * For regular tables, queries pg_attribute to get column definitions
 * (avoids needing SELECT permission for ownership chaining).
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
		elog(ERROR, "INSERT-EXEC: pg_temp namespace not found");

	temp_table_name = ChooseRelationName("__insert_exec_buf", NULL, NULL,
										 temp_nsp_oid, false);

	if (temp_table_name == NULL)
		elog(ERROR, "INSERT-EXEC: failed to generate temp table name for buffering");

	/*
	 * Parse schema and table name from target_table.
	 * For temp tables (starting with #) and table variables (@),
	 * no schema resolution is needed.
	 */
	if (!(target_table[0] == '#' || target_table[0] == '@'))
	{
		const char *sname = (schema_name_in != NULL) ? schema_name_in : "dbo";
		physical_schema = get_physical_schema_name(get_cur_db_name(), sname);
		if (physical_schema == NULL)
			elog(ERROR, "INSERT-EXEC: Failed to resolve schema for target table: %s",
				target_table);
	}

	/*
	 * Determine the column list to SELECT.
	 *
	 * If the user specified columns, use them directly.
	 * Otherwise, query the relation to get all non-IDENTITY,
	 * non-computed column names.
	 */
	if (column_list != NULL)
	{
		select_cols = column_list;
	}
	else
	{
		cols_to_free = get_insertable_column_list(target_table, physical_schema);
		select_cols = cols_to_free;
	}

	/*
	 * Build a fully qualified reference for the source table.
	 * For temp tables and table variables, use the name directly.
	 */
	if (physical_schema != NULL)
		qualified_target = psprintf("%s.%s",
									quote_identifier(physical_schema),
									quote_identifier(target_table));
	else
		qualified_target = pstrdup(quote_identifier(target_table));

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
		elog(ERROR, "failed to create INSERT EXEC temp table: %s",
			 SPI_result_code_string(rc));

	pfree(create_stmt.data);

	/* Get the OID of the created temp table */
	temp_table_oid = RelnameGetRelid(temp_table_name);
	if (!OidIsValid(temp_table_oid))
		elog(ERROR, "could not find INSERT EXEC temp table %s", temp_table_name);

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
							 const char *target_table,
							 const char *column_list)
{
	char			*temp_table_name;
	StringInfoData	flush_query;
	int				rc;
	Oid				temp_oid = insert_exec_ctx.temp_table_oid;

	if (!OidIsValid(temp_oid) || target_table == NULL)
	{
		return;
	}

	/*
	 * Verify target table schema hasn't changed since INSERT EXEC started.
	 */
	if (insert_exec_ctx.is_target_relation_modified)
	{
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("INSERT EXEC failed because the stored procedure altered the schema of the target table.")));
	}

	/* Get the temp table name from its OID */
	temp_table_name = get_rel_name(temp_oid);
	if (temp_table_name == NULL)
	{
		elog(ERROR, "INSERT-EXEC: Could not find temp table with OID %u", temp_oid);
	}

	initStringInfo(&flush_query);

	if (column_list != NULL)
	{
		/*
		 * User specified columns - use them directly.
		 * The temp table was created with columns in the same order as the
		 * user's column list, so SELECT * gives values in the correct order.
		 */
		appendStringInfo(&flush_query,
			"INSERT INTO %s (%s) SELECT * FROM %s",
			quote_identifier(target_table),
			column_list,
			quote_identifier(temp_table_name));
	}
	else
	{
		appendStringInfo(&flush_query,
			"INSERT INTO %s SELECT * FROM %s",
			quote_identifier(target_table),
			quote_identifier(temp_table_name));
	}

	/*
	 * We route through exec_stmt_execsql to reuse the standard SQL execution
	 * path which handles triggers, rowcount, and FOUND properly.
	 */
	PG_TRY();
	{
		/* Execute the flush INSERT using SPI */
		rc = SPI_execute(flush_query.data, false, 0);

		/*
   		 * SPI_execute returns SPI_OK_INSERT_RETURNING (not SPI_OK_INSERT) when
   		 * the target table has IDENTITY INSERT ON. Accept both.
   		 */
		if (rc != SPI_OK_INSERT && rc != SPI_OK_INSERT_RETURNING)
			elog(ERROR, "INSERT-EXEC: Failed to flush temp table to target");

		/* Update rowcount for T-SQL compatibility */
		estate->eval_processed = SPI_processed;
		exec_set_rowcount(SPI_processed);
	}
	PG_CATCH();
	{

		pfree(flush_query.data);
		PG_RE_THROW();
	}
	PG_END_TRY();

	pfree(flush_query.data);
}
