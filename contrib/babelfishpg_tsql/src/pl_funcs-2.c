#include "postgres.h"
#include <stdlib.h>

#include "nodes/parsenodes.h"
#include "parser/parser.h"
#include "parser/scansup.h"
#include "libpq/pqformat.h"
#include "utils/memutils.h"
#include "pltsql.h"
#include "pltsql-2.h"
#include "pltsql_instr.h"
#include "utils/builtins.h"
#include "utils/numeric.h"
#include "utils/syscache.h"

static int cmpfunc(const void *a, const void *b)
{
  return ( *(int*)a - *(int*)b );
}

PG_FUNCTION_INFO_V1(updated);
Datum
updated(PG_FUNCTION_ARGS){
	char	   *column = text_to_cstring(PG_GETARG_TEXT_PP(0));
	char       *real_column;
	List       *curr_columns_list;
	ListCell   *l;

	if (pltsql_trigger_depth-1<list_length(columns_updated_list))
		curr_columns_list = (List *)list_nth(columns_updated_list, pltsql_trigger_depth - 1);
	else curr_columns_list = NIL;
	foreach(l, curr_columns_list){
			real_column = ((UpdatedColumn *)lfirst(l))->column_name;
			if (pg_strcasecmp(real_column, column) == 0){
				PG_RETURN_BOOL(true);
			}
		}
	PG_RETURN_BOOL(false);
}

PG_FUNCTION_INFO_V1(columnsupdated);
Datum
columnsupdated(PG_FUNCTION_ARGS)
{
	StringInfoData buf;
	ListCell *l;
	UpdatedColumn *column;
	List* curr_columns_list;
	int *columnIndex;
	int i;
	int length, bufSize, curByteIndex, total_columns = 0;
	int8 curBuf;
	int j;
	if (columns_updated_list == NULL)
	{
		PG_RETURN_NULL();
	}
	if (pltsql_trigger_depth-1<list_length(columns_updated_list))
		curr_columns_list = (List *)list_nth(columns_updated_list, pltsql_trigger_depth - 1);
	else curr_columns_list = NIL;
	length = list_length(curr_columns_list);
	curBuf = 0;
	pq_begintypsend(&buf);
	if (length > 0){
		columnIndex =  (int *) palloc(sizeof(int) * length);
		i = 0;
		foreach(l, curr_columns_list){
			column = (UpdatedColumn *)lfirst(l);
			columnIndex[i] = column->x_attnum;
			total_columns = column->total_columns;
			++i;
		}
		qsort(columnIndex, length, sizeof(int), cmpfunc);
		bufSize = total_columns/8 + 1;
		curByteIndex = 0;
		for (i = 0; i < length; ++i){
			if ( columnIndex[i]/8 > curByteIndex){
				for(j = curByteIndex; j<columnIndex[i]/8; ++j){
					pq_writeint8(&buf, curBuf);
					curBuf = 0;
				}
				curByteIndex = columnIndex[i]/8;
			}
			curBuf = curBuf | (1<<(columnIndex[i]%8-1));
		}
		while(curByteIndex++<bufSize){
			pq_writeint8(&buf, curBuf);//the last one
			curBuf = 0;
		}
	}
	PG_RETURN_BYTEA_P(pq_endtypsend(&buf));
}

PG_FUNCTION_INFO_V1(rowcount);

Datum
rowcount(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(rowcount_var);
}

PG_FUNCTION_INFO_V1(fetch_status);

Datum
fetch_status(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(fetch_status_var);
}

PG_FUNCTION_INFO_V1(get_last_identity);

Datum
get_last_identity(PG_FUNCTION_ARGS)
{
	PG_TRY();
	{
		PG_RETURN_INT64(last_identity_value());
	}
	PG_CATCH();
	{
		FlushErrorState();
		PG_RETURN_NULL();
	}
	PG_END_TRY();
}

PG_FUNCTION_INFO_V1(get_scope_identity);

Datum
get_scope_identity(PG_FUNCTION_ARGS)
{
    PG_TRY();
    {
        PG_RETURN_INT64(last_scope_identity_value());
    }
    PG_CATCH();
    {
        FlushErrorState();
        PG_RETURN_NULL();
    }
    PG_END_TRY();
}

/*
 * pltsqlMakeRangeVarFromName - convert pltsql identifiers to RangeVar
 */
RangeVar *
pltsqlMakeRangeVarFromName(const char *ident)
{
	const char *str = "SELECT * FROM ";
	StringInfoData query;
	List *parsetree;
	SelectStmt *sel_stmt;
	Node *n;

	/* Create a fake SELECT statement to get the identifier names */
	initStringInfo(&query);
	appendStringInfoString(&query, str);
	appendStringInfoString(&query, ident);

	/*
	 * Check the dialect is in tsql mode. This should be a given but need to
	 * confirm since it affects the parser.
	 */
	Assert(sql_dialect == SQL_DIALECT_TSQL);
	parsetree = raw_parser(query.data, RAW_PARSE_DEFAULT);

	sel_stmt = (SelectStmt *) (((RawStmt *) linitial(parsetree))->stmt);
	n = linitial(sel_stmt->fromClause);
	Assert(IsA(n, RangeVar));

	return (RangeVar *) n;
}

/* ----------
 * pltsql_convert_ident
 *
 * Convert a possibly-qualified identifier to internal form: handle
 * double quotes, translate to lower case where not inside quotes,
 * truncate to NAMEDATALEN.
 *
 * There may be several identifiers separated by dots and optional
 * whitespace.	Each one is converted to a separate palloc'd string.
 * The caller passes the expected number of identifiers, as well as
 * a char* array to hold them.	It is an error if we find the wrong
 * number of identifiers (cf grammar processing of fori_varname).
 *
 * NOTE: the input string has already been accepted by the flex lexer,
 * so we don't need a heckuva lot of error checking here.
 * ----------
 */
void
pltsql_convert_ident(const char *s, char **output, int numidents)
{
	const char *sstart = s;
	int			identctr = 0;

	/* Outer loop over identifiers */
	while (*s)
	{
		char	   *curident;
		char	   *cp;

		/* Process current identifier */

		if (*s == '"')
		{
			/* Quoted identifier: copy, collapsing out doubled quotes */

			curident = palloc(strlen(s) + 1);	/* surely enough room */
			cp = curident;
			s++;
			while (*s)
			{
				if (*s == '"')
				{
					if (s[1] != '"')
						break;
					s++;
				}
				*cp++ = *s++;
			}
			if (*s != '"')		/* should not happen if lexer checked */
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("unterminated \" in name: %s", sstart)));
			s++;
			*cp = '\0';
			/* Truncate to NAMEDATALEN */
			truncate_identifier(curident, cp - curident, false);
		}
		else if (*s == '[')
		{
			/* Bracket-quoted identifier: extends till close bracket */
			/* FIXME: how do you escape a close-bracket? */
			const char *close = strchr(s+1, ']');
			size_t		identlen;

			if (close == NULL)
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("unterminated [ in name: %s", sstart)));
			
			identlen = (close - s) - 1;

			curident = palloc(identlen + 1);
			memcpy(curident, s+1, identlen);
			curident[identlen] = '\0';

			/* Truncate to NAMEDATALEN */
			truncate_identifier(curident, identlen, false);

			s = close + 1;
		}
		else
		{
			/* Normal identifier: extends till dot or whitespace */
			const char *thisstart = s;

			while (*s && *s != '.' && !scanner_isspace(*s))
				s++;
			/* Downcase and truncate to NAMEDATALEN */
			curident = downcase_truncate_identifier(thisstart, s - thisstart,
													false);
		}

		/* Pass ident to caller */
		if (identctr < numidents)
			output[identctr++] = curident;
		else
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("qualified identifier cannot be used here: %s",
							sstart)));

		/* If not done, skip whitespace, dot, whitespace */
		if (*s)
		{
			while (*s && scanner_isspace(*s))
				s++;
			if (*s++ != '.')
				elog(ERROR, "expected dot between identifiers: %s", sstart);
			while (*s && scanner_isspace(*s))
				s++;
			if (*s == '\0')
				elog(ERROR, "expected another identifier: %s", sstart);
		}
	}

	if (identctr != numidents)
		elog(ERROR, "improperly qualified identifier: %s",
			 sstart);
}

static char
*replace_with_underscore(const char *s)
{
	int	i, n = strlen(s);
	char	*s_copy = palloc(n + 1);

	s_copy[0] = '\0';
	strncat(s_copy, s, n);

	for (i = 0; i < n; i++)
	{
		if (s_copy[i] == '.')
			s_copy[i] = '_';
	}

	return s_copy;
}

void
pre_function_call_hook_impl(const char *funcName)
{
	if ((pltsql_instr_plugin_ptr &&
				(*pltsql_instr_plugin_ptr) &&
				(*pltsql_instr_plugin_ptr)->pltsql_instr_increment_func_metric))
	{
	        char	*prefix = "instr_tsql_";
	        char	*funcname_edited = replace_with_underscore(funcName);
	        StringInfoData metricName;
	        initStringInfo(&metricName);

	        appendStringInfoString(&metricName, prefix);
	        appendStringInfoString(&metricName, funcname_edited);

		if (!(*pltsql_instr_plugin_ptr)->pltsql_instr_increment_func_metric(metricName.data))
		{
			/* check with "unsupported" in prefix */
			prefix = "instr_unsupported_tsql_";

			resetStringInfo(&metricName);
			appendStringInfoString(&metricName, prefix);
			appendStringInfoString(&metricName, funcname_edited);
			(*pltsql_instr_plugin_ptr)->pltsql_instr_increment_func_metric(metricName.data);
		}

              if(funcname_edited != NULL)
                      pfree(funcname_edited);
              if(metricName.data != NULL)
                      pfree(metricName.data);
	}
}

int32
coalesce_typmod_hook_impl(const CoalesceExpr *cexpr)
{
	/*
	 * For T-SQL ISNULL, the typmod depends only on the first argument of
	 * the function unlike PG COALESCE, which checks whether all the data
	 * types and their typmods are in agreement.
	 */

	Oid nspoid, pg_catalog_numericoid, sys_decimaloid;

	nspoid = get_namespace_oid("pg_catalog", false);
	pg_catalog_numericoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("numeric"), ObjectIdGetDatum(nspoid));

	nspoid = get_namespace_oid("sys", false);
	sys_decimaloid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid, CStringGetDatum("decimal"), ObjectIdGetDatum(nspoid));

	/*
	 * If data type is numeric/decimal, resolve_numeric_typmod_from_exp
	 * will figure out the precision and scale.
	 */
	if (cexpr->coalescetype == pg_catalog_numericoid || cexpr->coalescetype == sys_decimaloid)
		return -1;

	if (exprType((Node *) linitial(cexpr->args)) != cexpr->coalescetype)
		return -1;

	return exprTypmod((Node *) linitial(cexpr->args));
}

/***********************************************************************************
 *                            FREE FUNCTIONS
 **********************************************************************************/

static void
free_stmt2(PLtsql_stmt *stmt)
{
	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_GOTO:
		{
			PLtsql_stmt_goto *go = (PLtsql_stmt_goto *) stmt;

			free_expr(go->cond);

			break;
		}

		case PLTSQL_STMT_PRINT:
		{
			PLtsql_stmt_print *print = (PLtsql_stmt_print *) stmt;
			ListCell *l;

			foreach(l, print->exprs)
				free_expr((PLtsql_expr *) lfirst(l));
			break;
		}

	    case PLTSQL_STMT_INIT:
		{
			PLtsql_stmt_init *init = (PLtsql_stmt_init *) stmt;
			ListCell *l;

			foreach(l, init->inits)
				free_stmt((PLtsql_stmt *) lfirst(l));
			break;
		}

	    case PLTSQL_STMT_QUERY_SET:
		{
			PLtsql_stmt_query_set *select = (PLtsql_stmt_query_set *) stmt;

			free_expr(select->sqlstmt);

			break;
		}

        case PLTSQL_STMT_TRY_CATCH:
        {
            PLtsql_stmt_try_catch *try_catch = (PLtsql_stmt_try_catch *) stmt;
            free_stmt((PLtsql_stmt *) try_catch->body);
            free_stmt((PLtsql_stmt *) try_catch->handler);
            break;
        }

	    case PLTSQL_STMT_PUSH_RESULT:
		{
			PLtsql_stmt_push_result *push = (PLtsql_stmt_push_result *) stmt;
			free_expr(push->query);
			break;
		}

	    case PLTSQL_STMT_EXEC:
		{
			PLtsql_stmt_exec *exec = (PLtsql_stmt_exec *) stmt;
			free_expr(exec->expr);
			break;
		}
		case PLTSQL_STMT_EXEC_BATCH:
		{
			PLtsql_stmt_exec_batch *exec = (PLtsql_stmt_exec_batch *) stmt;

			free_expr(exec->expr);

			break;
		}
		case PLTSQL_STMT_EXEC_SP:
		{
			PLtsql_stmt_exec_sp *exec = (PLtsql_stmt_exec_sp *) stmt;
			ListCell *l;

			if (exec->handle)
				free_expr(exec->handle);
			if (exec->query)
				free_expr(exec->query);
			if (exec->param_def)
				free_expr(exec->param_def);
			foreach(l, exec->params)
				free_expr((PLtsql_expr *) ((tsql_exec_param *) lfirst(l))->expr);
			if (exec->opt1)
				free_expr(exec->opt1);
			if (exec->opt2)
				free_expr(exec->opt2);
			if (exec->opt3)
				free_expr(exec->opt3);
			break;
		}
		case PLTSQL_STMT_DECL_TABLE:
		{
			/* Nothing to free */
			break;
		}
		case PLTSQL_STMT_RETURN_TABLE:
		{
			free_return_query((PLtsql_stmt_return_query *) stmt);
			break;
		}
		case PLTSQL_STMT_DEALLOCATE:
		{
			/* Nothing to free */
			break;
		}
		case PLTSQL_STMT_DECL_CURSOR:
		{
			PLtsql_stmt_decl_cursor *decl = (PLtsql_stmt_decl_cursor *) stmt;
			free_expr(decl->cursor_explicit_expr);
			break;
		}
	    case PLTSQL_STMT_LABEL:
		case PLTSQL_STMT_USEDB:
        case PLTSQL_STMT_INSERT_BULK:
		case PLTSQL_STMT_GRANTDB:
		case PLTSQL_STMT_SET_EXPLAIN_MODE:
		{
			/* Nothing to free */
			break;
		}
		case PLTSQL_STMT_RAISERROR:
		{
			PLtsql_stmt_raiserror *raiserror = (PLtsql_stmt_raiserror *) stmt;
			ListCell *l;

			foreach(l, raiserror->params)
				free_expr((PLtsql_expr *) lfirst(l));
			break;
		}
		case PLTSQL_STMT_THROW:
		{
			PLtsql_stmt_throw *throw = (PLtsql_stmt_throw *) stmt;
			ListCell *l;

			foreach(l, throw->params)
				free_expr((PLtsql_expr *) lfirst(l));
			break;
		}
        case PLTSQL_STMT_SAVE_CTX:
        case PLTSQL_STMT_RESTORE_CTX_FULL:
        case PLTSQL_STMT_RESTORE_CTX_PARTIAL:
        {
            break;
        }
	    default:
			elog(ERROR, "unrecognized cmd_type: %d", stmt->cmd_type);
			break;
	}
}

/***********************************************************************************
 *                            DUMP FUNCTIONS
 **********************************************************************************/

void dump_stmt2(PLtsql_stmt *stmt);

void dump_stmt_print(PLtsql_stmt_print *stmt_print);
void dump_stmt_init(PLtsql_stmt_init *stmt_init);
void dump_stmt_push_result(PLtsql_stmt_push_result *stmt_push_result);
void dump_stmt_exec(PLtsql_stmt_exec *stmt_exec);
void dump_stmt_goto(PLtsql_stmt_goto *stmt_goto);
void dump_stmt_label(PLtsql_stmt_label *stmt_label);
void dump_stmt_raiserror(PLtsql_stmt_raiserror *stmt_raiserror);
void dump_stmt_throw(PLtsql_stmt_throw *stmt_throw);
void dump_stmt_usedb(PLtsql_stmt_usedb *stmt_usedb);
void dump_stmt_grantdb(PLtsql_stmt_grantdb *stmt_grantdb);
void dump_stmt_insert_bulk(PLtsql_stmt_insert_bulk *stmt_insert_bulk);
void dump_stmt_try_catch(PLtsql_stmt_try_catch *stmt_try_catch);
void dump_stmt_query_set(PLtsql_stmt_query_set *query_set);
void dump_stmt_exec_batch(PLtsql_stmt_exec_batch *exec_batch);
void get_grantees_names(List *grantees, StringInfo grantees_names);

void
dump_stmt_print(PLtsql_stmt_print *stmt_print)
{
    ListCell *l;

    printf("PRINT ");
    foreach(l, stmt_print->exprs)
    {
        dump_expr((PLtsql_expr *) lfirst(l));
        printf(" ,");
    }
    printf("\n");
}

void
dump_stmt_init(PLtsql_stmt_init *stmt_init)
{
    ListCell *l;
    printf("DECLARE ");
    foreach(l, stmt_init->inits)
    {
        if (l)
            dump_assign((PLtsql_stmt_assign *)lfirst(l));

        printf(" ,");  /* could not print some variables */
    }
    printf("\n");
}

void
dump_stmt_push_result(PLtsql_stmt_push_result *stmt_push_result)
{
    printf("PUSH RESULT: ");
    dump_expr(stmt_push_result->query);
    printf("\n");
}

void
dump_stmt_exec(PLtsql_stmt_exec *stmt_exec)
{
    printf("EXEC ");
    dump_expr(stmt_exec->expr);
    printf("\n");
}

void
dump_stmt_goto(PLtsql_stmt_goto *stmt_goto)
{
    printf("GOTO %s\n", stmt_goto->target_label);
}

void
dump_stmt_label(PLtsql_stmt_label *stmt_label)
{
    printf("%s:\n", stmt_label->label);
}

void
dump_stmt_raiserror(PLtsql_stmt_raiserror *stmt_raiserror)
{
	ListCell *l;

	printf("RAISERROR ");
	foreach(l, stmt_raiserror->params)
	{
		dump_expr((PLtsql_expr *) lfirst(l));
		printf(" ,");
	}
	printf("\n");
}

void
dump_stmt_throw(PLtsql_stmt_throw *stmt_throw)
{
	ListCell *l;

	if (stmt_throw->params == NIL)
		printf("THROW\n");
	else
	{
		printf("THROW ");
		foreach(l, stmt_throw->params)
		{
			dump_expr((PLtsql_expr *) lfirst(l));
			printf(" ,");
		}
		printf("\n");
	}
}

void
dump_stmt_usedb(PLtsql_stmt_usedb *stmt_usedb)
{
	printf("USE %s\n", stmt_usedb->db_name);
}

void get_grantees_names(List *grantees, StringInfo grantees_names)
{	
	for(int i = 0; i < list_length(grantees); i++)
	{
		char *grantee_name = (char *) list_nth(grantees, i);
		if(i < list_length(grantees) - 1)
			appendStringInfo(grantees_names, "%s, ", grantee_name);
		else
			appendStringInfo(grantees_names, "%s", grantee_name);
	}
}

void
dump_stmt_grantdb(PLtsql_stmt_grantdb *stmt_grantdb)
{	
	StringInfoData grantees_names;
	initStringInfo(&grantees_names);
	get_grantees_names(stmt_grantdb->grantees, &grantees_names);
	if(stmt_grantdb->is_grant)
		printf("GRANT CONNECT TO %s\n", grantees_names.data);
	else
		printf("REVOKE CONNECT FROM %s\n", grantees_names.data);
	resetStringInfo(&grantees_names);
}

void
dump_stmt_insert_bulk(PLtsql_stmt_insert_bulk *stmt_insert_bulk)
{
    printf("INSERT BULK %s\n", stmt_insert_bulk->table_name);
}

void
dump_stmt_try_catch(PLtsql_stmt_try_catch *stmt_try_catch)
{
    printf("TRY BEGIN\n");
    dump_indent +=2;
	dump_stmt(stmt_try_catch->body);
    dump_indent -=2;
    dump_ind();
    printf("TRY END\n");
    dump_ind();
    printf("CATCH BEGIN\n");
    dump_indent +=2;
	dump_stmt(stmt_try_catch->handler);
    dump_indent -=2;
    dump_ind();
    printf("CATCH END\n");
}

void
dump_stmt_query_set(PLtsql_stmt_query_set *query_set)
{
	printf("QUERY_SET\n");
	dump_expr(query_set->sqlstmt);
	dump_indent += 2;
	dump_ind();
	printf("    INTO target = %d %s\n", query_set->target->dno, query_set->target->refname);
	dump_indent -= 2;
}

void
dump_stmt_exec_batch(PLtsql_stmt_exec_batch *exec_batch)
{
	printf("EXEC (");
	dump_expr(exec_batch->expr);
	printf(")");
}

static void
dump_stmt2(PLtsql_stmt *stmt)
{
    switch (stmt->cmd_type)
    {
        case PLTSQL_STMT_GOTO:
        {
            dump_stmt_goto((PLtsql_stmt_goto *) stmt);
            break;
        }
        case PLTSQL_STMT_PRINT:
        {
            dump_stmt_print((PLtsql_stmt_print *) stmt);
            break;
        }
        case PLTSQL_STMT_INIT:
        {
            dump_stmt_init((PLtsql_stmt_init *) stmt);
            break;
        }
	    case PLTSQL_STMT_QUERY_SET:
		{
			dump_stmt_query_set((PLtsql_stmt_query_set *) stmt);
			break;
		}
        case PLTSQL_STMT_TRY_CATCH:
        {
            dump_stmt_try_catch((PLtsql_stmt_try_catch *) stmt);
            break;
        }
        case PLTSQL_STMT_PUSH_RESULT:
        {
            dump_stmt_push_result((PLtsql_stmt_push_result *) stmt);
            break;
        }
        case PLTSQL_STMT_EXEC:
        {
            dump_stmt_exec((PLtsql_stmt_exec *) stmt);
            break;
        }
		case PLTSQL_STMT_EXEC_BATCH:
		{
			dump_stmt_exec_batch((PLtsql_stmt_exec_batch *) stmt);
			break;
		}
		case PLTSQL_STMT_DECL_TABLE:
		{
			printf("DECLARE TABLE");
			break;
		}
		case PLTSQL_STMT_RETURN_TABLE:
		{
			dump_return_query((PLtsql_stmt_return_query *) stmt);
			break;
		}
		case PLTSQL_STMT_DEALLOCATE:
		{
			printf("DEALLOCATE");
			break;
		}
        case PLTSQL_STMT_LABEL:
        {
            dump_stmt_label((PLtsql_stmt_label *) stmt);
            break;
        }
		case PLTSQL_STMT_RAISERROR:
		{
			dump_stmt_raiserror((PLtsql_stmt_raiserror *) stmt);
			break;
		}
		case PLTSQL_STMT_THROW:
		{
			dump_stmt_throw((PLtsql_stmt_throw *) stmt);
			break;
		}
		case PLTSQL_STMT_USEDB:
		{
			dump_stmt_usedb((PLtsql_stmt_usedb *) stmt);
			break;
		}
		case PLTSQL_STMT_GRANTDB:
		{
			dump_stmt_grantdb((PLtsql_stmt_grantdb *) stmt);
			break;
		}
        case PLTSQL_STMT_INSERT_BULK:
        {
            dump_stmt_insert_bulk((PLtsql_stmt_insert_bulk *) stmt);
            break;
        }
        default:
            elog(ERROR, "unrecognized cmd_type: %d", stmt->cmd_type);
            break;
    }
}
