/*-------------------------------------------------------------------------
 *
 * procedures.c
 *   Built-in Procedures for Babel 
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/tupdesc.h"
#include "access/printtup.h"
#include "access/relation.h"
#include "access/xact.h"
#include "catalog/pg_type.h"
#include "commands/prepare.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "pltsql_instr.h"
#include "parser/parser.h"
#include "parser/parse_target.h"
#include "tcop/pquery.h"
#include "tcop/tcopprot.h"

#include "multidb.h"

PG_FUNCTION_INFO_V1(sp_unprepare);
PG_FUNCTION_INFO_V1(sp_prepare);
PG_FUNCTION_INFO_V1(sp_babelfish_configure);
PG_FUNCTION_INFO_V1(sp_describe_undeclared_parameters_internal);

extern void delete_cached_batch(int handle);
extern InlineCodeBlockArgs *create_args(int numargs);
extern void read_param_def(InlineCodeBlockArgs * args, const char *paramdefstr);
extern int execute_batch(PLtsql_execstate *estate, char *batch, InlineCodeBlockArgs *args, List *params);
extern PLtsql_execstate *get_current_tsql_estate(void);

Datum
sp_unprepare(PG_FUNCTION_ARGS)
{
    int32_t handle;
	TSQLInstrumentation(INSTR_TSQL_SP_UNPREPARE);
    if (PG_ARGISNULL(0))
        ereport(ERROR,
                (errcode(ERRCODE_UNDEFINED_OBJECT),
                 errmsg("expect handle as integer")));

    handle = PG_GETARG_INT32(0);

	delete_cached_batch(handle);

    PG_RETURN_VOID();
}

Datum
sp_prepare(PG_FUNCTION_ARGS)
{
	char *params = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));
  	char *batch = PG_ARGISNULL(2) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(2));
  	/*int  options = PG_GETARG_INT32(3); */
  	InlineCodeBlockArgs *args;
 	HeapTuple	tuple;
  	HeapTupleHeader result;
	TupleDesc tupdesc;
	bool isnull = false;
	Datum values[1];
	const char *old_dialect;

	if (!batch)
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
			errmsg("query argument of sp_prepare is null")));

	old_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);
	set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
					  (superuser() ? PGC_SUSET : PGC_USERSET),
					  PGC_S_SESSION,
					  GUC_ACTION_SAVE,
					  true,
					  0,
					  false);

	args = create_args(0);
	if (params)
		read_param_def(args, params);

	args->options = (BATCH_OPTION_CACHE_PLAN | 
					BATCH_OPTION_PREPARE_PLAN |
					BATCH_OPTION_SEND_METADATA |
					BATCH_OPTION_NO_EXEC);

	PG_TRY();
	{
		PLtsql_execstate *estate = get_current_tsql_estate();
		execute_batch(estate, batch, args, NULL);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", old_dialect,
						  (superuser() ? PGC_SUSET : PGC_USERSET),
						  PGC_S_SESSION,
						  GUC_ACTION_SAVE,
						  true,
						  0,
						  false);
		PG_RE_THROW();
	}
	PG_END_TRY();

	set_config_option("babelfishpg_tsql.sql_dialect", old_dialect,
					  (superuser() ? PGC_SUSET : PGC_USERSET),
					  PGC_S_SESSION,
					  GUC_ACTION_SAVE,
					  true,
					  0,
					  false);

	values[0] = Int32GetDatum(args->handle);

	/* 5. Return back handle */
	tupdesc = CreateTemplateTupleDesc(1);
  	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "prep_handle", INT4OID, -1, 0);
  	tupdesc = BlessTupleDesc(tupdesc);
  	tuple = heap_form_tuple(tupdesc, values, &isnull);

  	result = (HeapTupleHeader) palloc(tuple->t_len);
  	memcpy(result, tuple->t_data, tuple->t_len);

  	heap_freetuple(tuple);
  	ReleaseTupleDesc(tupdesc);

  	PG_RETURN_HEAPTUPLEHEADER(result);
}

Datum
sp_babelfish_configure(PG_FUNCTION_ARGS)
{
	int rc;
	int nargs;
	MemoryContext savedPortalCxt;

	/* SPI call input */
	const char* query = "SELECT name, setting, short_desc from pg_settings where name like 'babelfish%%escape_hatch%%' AND name like $1";
	Datum arg;
	Oid argoid = TEXTOID;
	char nulls = 0;

	SPIPlanPtr plan;
	Portal portal;
	DestReceiver *receiver;

	nargs = PG_NARGS();
	if (nargs == 0)
	{
		arg = PointerGetDatum(cstring_to_text("%"));
	}
	else if (nargs == 1)
	{
		const char* common_prefix = "babelfishpg_tsql.";

		char *arg0 = PG_ARGISNULL(0) ? "%" : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		if (strncmp(arg0, common_prefix, strlen(common_prefix)) == 0)
			arg = PointerGetDatum(cstring_to_text(arg0));
		else
		{
			char buf[1024];
			snprintf(buf, 1024, "%s%s", common_prefix, arg0);
			arg = PointerGetDatum(cstring_to_text(buf));
		}
	}
	else
	{
		elog(ERROR, "unexpected number of arguments: %d", nargs);
	}

	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	if ((plan = SPI_prepare(query, 1, &argoid)) == NULL)
		elog(ERROR, "SPI_prepare(\"%s\") failed", query);

	if ((portal = SPI_cursor_open(NULL, plan, &arg, &nulls, true)) == NULL)
		elog(ERROR, "SPI_cursor_open(\"%s\") failed", query);

	/*
	 * According to specifictation, sp_babelfish_configure returns a result-set.
	 * If there is no destination, it will send the result-set to client, which is not allowed behavior of PG procedures.
	 * To implement this behavior, we added a code to push the result.
	 */
	receiver = CreateDestReceiver(DestRemote);
	SetRemoteDestReceiverParams(receiver, portal);

	// fetch the result and return the result-set
	PortalRun(portal, FETCH_ALL, true, true, receiver, receiver, NULL);

	receiver->rDestroy(receiver);

	SPI_cursor_close(portal);

	if ((rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

  PG_RETURN_VOID();
}

/*
 * Structure used to store state in the SRF (Set-Returning-Function)
 * sp_describe_undeclared_parameters_internal
 */
typedef struct UndeclaredParams
{
	/* Names of the undeclared parameters */
	char			**paramnames;

	/* Indexes of the undeclared parameters in the targetattnums array */
	int				*paramindexes;

	/*
	 * The relevant attnums in the target table.
	 * For 'INSERT INTO t1 ...' it is all the attnums in the target table t1;
	 * for 'INSERT INTO t1 (a, c) ...' it is the attnums of columns a and c in
	 * the target table t1.
	 */
	int 			*targetattnums;

	/* Name of the target table */
	char 			*tablename;
} UndeclaredParams;

/*
 * Internal function used by procedure sys.sp_describe_undeclared_parameters
 * Currently only support the use case of 'INSERT ... VALUES (@P1, @P2, ...)'.
 */
Datum
sp_describe_undeclared_parameters_internal(PG_FUNCTION_ARGS)
{
	/* SRF related things to keep enough state between calls */
	FuncCallContext *funcctx;
	int call_cntr;
	int max_calls;
	TupleDesc tupdesc;
	AttInMetadata *attinmeta;

	ANTLR_result result;
	List *raw_parsetree_list;
	ListCell *list_item;
  	InlineCodeBlockArgs *args;
	UndeclaredParams *undeclaredparams;

	if (SRF_IS_FIRSTCALL())
	{
		/*
		 * In the first call of the SRF, we do all the processing, and store the
		 * result and state information in a UndeclaredParams struct in
		 * funcctx->user_fctx
		 */
		MemoryContext oldcontext;
		char *batch;
		char *parsedbatch;
		char *params;
		int sql_dialect_value_old;

		SelectStmt *select_stmt;
		List *values_list;
		ListCell *lc;
		int numresults = 0;
		ListCell *lc_attnum;
		int num_target_attnums = 0;
		RawStmt    *parsetree;
		InsertStmt *insert_stmt;
		RangeVar *relation;
		Oid relid;
		Relation r;
		List *target_attnums = NIL;
		ParseState *pstate;

		funcctx = SRF_FIRSTCALL_INIT();
		oldcontext = MemoryContextSwitchTo(funcctx->multi_call_memory_ctx);

		get_call_result_type(fcinfo, NULL, &tupdesc);
		attinmeta = TupleDescGetAttInMetadata(tupdesc);
		funcctx->attinmeta = attinmeta;

		undeclaredparams = (UndeclaredParams *) palloc0(sizeof(UndeclaredParams));
		funcctx->user_fctx = (void *) undeclaredparams;

		batch = PG_ARGISNULL(0) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(0));
		params = PG_ARGISNULL(1) ? NULL : TextDatumGetCString(PG_GETARG_TEXT_PP(1));

		/* First, pass the batch to the ANTLR parser */
		result = antlr_parser_cpp(batch);
		if (!result.success)
			report_antlr_error(result);
		/*
		 * For the currently supported use case, the parse result should contain
		 * two statements, INIT and EXECSQL. The EXECSQL statement should be an
		 * INSERT statement with VALUES clause.
		 */
		if (!pltsql_parse_result ||
			list_length(pltsql_parse_result->body) != 2 ||
			((PLtsql_stmt *)lsecond(pltsql_parse_result->body))->cmd_type != PLTSQL_STMT_EXECSQL)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}
		parsedbatch = ((PLtsql_stmt_execsql *)lsecond(pltsql_parse_result->body))->sqlstmt->query;

		args = create_args(0);
		if (params)
			read_param_def(args, params);

		/* Next, pass the ANTLR-parsed batch to the backend parser */
		sql_dialect_value_old = sql_dialect;
		sql_dialect = SQL_DIALECT_TSQL;
		raw_parsetree_list = pg_parse_query(parsedbatch);
		if (list_length(raw_parsetree_list) != 1)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}
		list_item = list_head(raw_parsetree_list);
		parsetree = lfirst_node(RawStmt, list_item);
		if (nodeTag(parsetree->stmt) != T_InsertStmt)
		{
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
		}

		/*
		 * Analyze the parsed InsertStmt to suggest types for undeclared
		 * parameters
		 */
		rewrite_object_refs(parsetree->stmt);
		sql_dialect = sql_dialect_value_old;
		insert_stmt = (InsertStmt *)parsetree->stmt;
		relation = insert_stmt->relation;
		relid = RangeVarGetRelid(relation, NoLock, false);
		r = relation_open(relid, AccessShareLock);
		pstate = (ParseState *) palloc(sizeof(ParseState));
		pstate->p_target_relation = r;
		checkInsertTargets(pstate, insert_stmt->cols, &target_attnums);

		undeclaredparams->tablename = (char *) palloc(sizeof(char) * 64);
		strncpy(undeclaredparams->tablename, relation->relname, strlen(relation->relname));
		undeclaredparams->targetattnums = (int *) palloc(sizeof(int) * list_length(target_attnums));
		foreach(lc_attnum, target_attnums)
		{
			undeclaredparams->targetattnums[num_target_attnums] = lfirst_int(lc_attnum);
			num_target_attnums += 1;
		}

		relation_close(r, AccessShareLock);
		pfree(pstate);

		select_stmt = (SelectStmt *)insert_stmt->selectStmt;
		values_list = select_stmt->valuesLists;
		foreach(lc, values_list)
		{
			List *sublist = lfirst(lc);
			ListCell *sublc;
			int numvalues = 0;
			int numtotalvalues = list_length(sublist);
			undeclaredparams->paramnames = (char **) palloc(sizeof(char *) * numtotalvalues);
			undeclaredparams->paramindexes = (int *) palloc(sizeof(int) * numtotalvalues);
			foreach(sublc, sublist)
			{
				ColumnRef *columnref = lfirst(sublc);
				ListCell *fieldcell;
				if (nodeTag(columnref) != T_ColumnRef)
				{
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Unsupported use case in sp_describe_undeclared_parameters")));
				}
				foreach(fieldcell, columnref->fields)
				{
					Value *field = lfirst(fieldcell);
					/* Make sure it's a parameter reference */
					if (field->val.str && field->val.str[0] == '@')
					{
						int i;
						bool undeclared = true;
						/* Make sure it is not declared in @params */
						for (i = 0; i < args->numargs; ++i)
						{
							if (args->argnames && args->argnames[i] &&
								(strcmp(args->argnames[i], field->val.str) == 0))
							{
								undeclared = false;
								break;
							}
						}
						if (undeclared)
						{
							undeclaredparams->paramnames[numresults] = (char *) palloc(64 * sizeof(char));
							strncpy(undeclaredparams->paramnames[numresults], field->val.str, strlen(field->val.str));
							undeclaredparams->paramindexes[numresults] = numvalues;
							numresults += 1;
						}
					}
				}
				numvalues += 1;
			}
		}

		funcctx->max_calls = numresults;
		MemoryContextSwitchTo(oldcontext);
	}

	funcctx = SRF_PERCALL_SETUP();
	call_cntr = funcctx->call_cntr;
	max_calls = funcctx->max_calls;
	attinmeta = funcctx->attinmeta;
	undeclaredparams = funcctx->user_fctx;

	if (call_cntr < max_calls)
	{
		char **values;
		HeapTuple tuple;
		Datum result;
		int numresultcols = 24;
		bool isnull;
		char *data_type;
		char *udt_name;
		/*
		 * Use the same query as sp_describe_first_result_set_internal to get
		 * the relevant column information
		 */
		char *tempq = "select t2.length, t1.numeric_precision, t1.numeric_scale, t1.data_type, t1.udt_name "
					  " FROM information_schema.columns t1, sys.spt_datatype_info_table t2 "
					  " WHERE table_name = \'%s\' "
					  	" AND t1.ordinal_position = %d "
 						" AND (t1.data_type = t2.pg_type_name "
							" OR ((SELECT coalesce(t1.domain_name, \'\') != \'tinyint\') "
								" AND (SELECT coalesce(t1.domain_name, \'\') != \'nchar\') "
								" AND t2.pg_type_name = t1.udt_name) "
							" OR (t1.domain_schema = \'sys\' AND t2.type_name = t1.domain_name))";
		char *query = psprintf(tempq, undeclaredparams->tablename,
				undeclaredparams->targetattnums[undeclaredparams->paramindexes[call_cntr]]);
		SPI_execute(query, true, 1);
		if (SPI_processed == 0)
			SRF_RETURN_DONE(funcctx);

		values = (char **) palloc(numresultcols * sizeof(char *));

		values[0] = psprintf("%d", call_cntr + 1);
		values[1] = undeclaredparams->paramnames[call_cntr];
		values[2] = "0";
		values[3] = "";
		values[4] = psprintf("%d",
				 DatumGetInt32(SPI_getbinval(SPI_tuptable->vals[0],
											SPI_tuptable->tupdesc,
											1, &isnull)));
		values[5] = psprintf("%d",
				 DatumGetInt32(SPI_getbinval(SPI_tuptable->vals[0],
											SPI_tuptable->tupdesc,
											2, &isnull)));
		values[6] = psprintf("%d",
				 DatumGetInt32(SPI_getbinval(SPI_tuptable->vals[0],
											SPI_tuptable->tupdesc,
											3, &isnull)));
		values[7] = NULL;
		values[8] = "";
		values[9] = "";
		values[10] = "";
		values[11] = "";
		values[12] = NULL;
		values[13] = "";
		values[14] = "";
		values[15] = "";
		data_type = SPI_getvalue(SPI_tuptable->vals[0],
								 SPI_tuptable->tupdesc, 4);
		if (strcmp(data_type, "xml") == 0)
			values[16] = "1";
		else
			values[16] = "0";
		udt_name = DatumGetCString(SPI_getbinval(SPI_tuptable->vals[0],
												 SPI_tuptable->tupdesc,
												 5, &isnull));
		if (strcmp(udt_name, "citext") == 0)
			values[17] = "1";
		else
			values[17] = "0";
		values[18] = "0";
		values[19] = "0";
		values[20] = "0";
		values[21] = "";
		values[22] = "0";
		values[23] = "0";

		tuple = BuildTupleFromCStrings(attinmeta, values);
		result = HeapTupleGetDatum(tuple);
		SPI_freetuptable(SPI_tuptable);
		SRF_RETURN_NEXT(funcctx, result);
	}
	else
	{
		SRF_RETURN_DONE(funcctx);
	}
}
