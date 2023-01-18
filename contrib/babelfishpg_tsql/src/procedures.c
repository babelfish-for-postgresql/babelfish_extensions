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
#include "utils/rel.h"
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
PG_FUNCTION_INFO_V1(xp_qv_internal);
PG_FUNCTION_INFO_V1(create_xp_qv_in_master_dbo_internal);

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

	/* The relevant colume names in the target table. */
	char			**targetcolnames;

	/* Name of the target table */
	char 			*tablename;

	/* The Oid of the table's schema */
	Oid 			schemaoid;
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
		int num_target_attnums = 0;
		RawStmt    *parsetree;
		InsertStmt *insert_stmt;
		RangeVar *relation;
		Oid relid;
		Relation r;
		List *target_attnums = NIL;
		ParseState *pstate;
		int relname_len;
		List *cols;
		int target_attnum_i;
		int target_attnums_len;

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
		cols = checkInsertTargets(pstate, insert_stmt->cols, &target_attnums);

		undeclaredparams->tablename = (char *) palloc(NAMEDATALEN);
		relname_len = strlen(relation->relname);
		strncpy(undeclaredparams->tablename, relation->relname, NAMEDATALEN);
		undeclaredparams->tablename[relname_len] = '\0';
		undeclaredparams->schemaoid = RelationGetNamespace(r);
		undeclaredparams->targetattnums = (int *) palloc(sizeof(int) * list_length(target_attnums));
		undeclaredparams->targetcolnames = (char **) palloc(sizeof(char *) * list_length(target_attnums));

		/* Record attnums and column names of the target table */
		target_attnum_i = 0;
		target_attnums_len = list_length(target_attnums);
		while (target_attnum_i < target_attnums_len)
		{
			ListCell *lc;
			ResTarget *col;
			int colname_len;

			lc = list_nth_cell(target_attnums, target_attnum_i);
			undeclaredparams->targetattnums[num_target_attnums] = lfirst_int(lc);

			col = (ResTarget *)list_nth(cols, target_attnum_i);
			colname_len = strlen(col->name);
			undeclaredparams->targetcolnames[num_target_attnums] = (char *) palloc(NAMEDATALEN);
			strncpy(undeclaredparams->targetcolnames[num_target_attnums], col->name, NAMEDATALEN);
			undeclaredparams->targetcolnames[num_target_attnums][colname_len] = '\0';

			target_attnum_i += 1;
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
							int paramname_len = strlen(field->val.str);
							undeclaredparams->paramnames[numresults] = (char *) palloc(NAMEDATALEN);
							strncpy(undeclaredparams->paramnames[numresults], field->val.str, NAMEDATALEN);
							undeclaredparams->paramnames[numresults][paramname_len] = '\0';
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
		int col;
		int numresultcols = 24;
		char *tempq = 
" SELECT "
	"CAST( 0 AS INT ) " /* AS "parameter_ordinal"  -- Need to get correct ordinal number in code. */
	", CAST( NULL AS sysname ) " /* AS "name"  -- Need to get correct parameter name in code. */
	", CASE "
		"WHEN T2.name = \'bigint\' THEN 127 "
		"WHEN T2.name = \'binary\' THEN 173 "
		"WHEN T2.name = \'bit\' THEN 104 "
		"WHEN T2.name = \'char\' THEN 175 "
		"WHEN T2.name = \'date\' THEN 40 "
		"WHEN T2.name = \'datetime\' THEN 61 "
		"WHEN T2.name = \'datetime2\' THEN 42 "
		"WHEN T2.name = \'datetimeoffset\' THEN 43 "
		"WHEN T2.name = \'decimal\' THEN 106 "
		"WHEN T2.name = \'float\' THEN 62 "
		"WHEN T2.name = \'image\' THEN 34 "
		"WHEN T2.name = \'int\' THEN 56 "
		"WHEN T2.name = \'money\' THEN 60 "
		"WHEN T2.name = \'nchar\' THEN 239 "
		"WHEN T2.name = \'ntext\' THEN 99 "
		"WHEN T2.name = \'numeric\' THEN 108 "
		"WHEN T2.name = \'nvarchar\' THEN 231 "
		"WHEN T2.name = \'real\' THEN 59 "
		"WHEN T2.name = \'smalldatetime\' THEN 58 "
		"WHEN T2.name = \'smallint\' THEN 52 "
		"WHEN T2.name = \'smallmoney\' THEN 122 "
		"WHEN T2.name = \'text\' THEN 35 "
		"WHEN T2.name = \'time\' THEN 41 "
		"WHEN T2.name = \'tinyint\' THEN 48 "
		"WHEN T2.name = \'uniqueidentifier\' THEN 36 "
		"WHEN T2.name = \'varbinary\' THEN 165 "
		"WHEN T2.name = \'varchar\' THEN 167 "
		"WHEN T2.name =  \'xml\' THEN 241 "
		"ELSE C.system_type_id "
	"END " /* AS "suggested_system_type_id" */
	", CASE "
		"WHEN T2.name = \'decimal\' THEN \'decimal(\' + CAST( C.precision AS sys.VARCHAR(10) ) + \',\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name = \'numeric\' THEN \'numeric(\' + CAST( C.precision AS sys.VARCHAR(10) ) + \',\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name = \'char\' THEN \'char(\' + CAST( C.max_length AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name = \'nchar\' THEN \'nchar(\' + CAST( C.max_length/2 AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name = \'binary\' THEN \'binary(\' + CAST( C.max_length AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name = \'datetime2\' THEN \'datetime2(\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name = \'datetimeoffset\' THEN \'datetimeoffset(\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name = \'time\' THEN \'time(\' + CAST( C.scale AS sys.VARCHAR(10) ) + \')\' "
		"WHEN T2.name = \'varchar\' THEN "
			"CASE WHEN C.max_length = -1 THEN \'varchar(max)\' "
				"ELSE \'varchar(\' + CAST( C.max_length AS sys.VARCHAR(10) ) + \')\' "
			"END "
		"WHEN T2.name = \'nvarchar\' THEN "
			"CASE WHEN C.max_length = -1 THEN \'nvarchar(max)\' "
			"ELSE \'nvarchar(\' + CAST( C.max_length/2 AS sys.VARCHAR(10) ) + \')\' "
			"END "
		"WHEN T2.name = \'varbinary\' THEN "
		"CASE WHEN C.max_length = -1 THEN \'varbinary(max)\' "
			"ELSE \'varbinary(\' + CAST( C.max_length AS sys.VARCHAR(10) ) + \')\' "
			"END "
		"ELSE T2.name "
	"END " /* AS "suggested_system_type_name" */
	", CASE "
		"WHEN T2.name IN (\'image\', \'ntext\',\'text\') THEN -1 "
		"ELSE C.max_length "
	"END  " /* AS "suggested_max_length" */
	", C.precision " /* AS "suggested_precision" */
	", C.scale " /* AS "suggested_scale" */
	", CASE WHEN T.user_type_id = T.system_type_id THEN CAST( NULL AS INT ) ELSE T.user_type_id END " /* AS "suggested_user_type_id" */
	", CASE WHEN T.user_type_id = T.system_type_id THEN CAST( NULL AS sysname) ELSE DB_NAME() END " /* AS "suggested_user_type_database" */
	", CASE WHEN T.user_type_id = T.system_type_id THEN CAST( NULL AS sysname) ELSE SCHEMA_NAME( T.schema_id ) END " /* AS "suggested_user_type_schema" */
	", CASE WHEN T.user_type_id = T.system_type_id THEN CAST( NULL AS sysname) ELSE T.name END " /* AS "suggested_user_type_name" */
	", CAST( NULL AS NVARCHAR(4000) ) " /* AS "suggested_assembly_qualified_type_name" */
	", CASE "
		"WHEN C.xml_collection_id = 0 THEN CAST( NULL AS INT ) "
		"ELSE C.xml_collection_id "
	"END " /* AS "suggested_xml_collection_id" */
	", CAST( NULL AS sysname ) " /* AS "suggested_xml_collection_database" */
	", CAST( NULL AS sysname ) " /* AS "suggested_xml_collection_schema" */
	", CAST( NULL AS sysname ) " /* AS "suggested_xml_collection_name" */
	", C.is_xml_document " /* AS "suggested_is_xml_document" */
	", CAST( 0 AS BIT ) " /* AS "suggested_is_case_sensitive" */
	", CAST( 0 AS BIT ) " /* AS "suggested_is_fixed_length_clr_type" */
	", CAST( 1 AS BIT ) " /* AS "suggested_is_input" */
	", CAST( 0 AS BIT ) " /* AS "suggested_is_output" */
	", CAST( NULL AS sysname ) " /* AS "formal_parameter_name" */
	", CASE "
		"WHEN T2.name IN (\'tinyint\', \'smallint\', \'int\', \'bigint\') THEN 38 "
		"WHEN T2.name IN (\'float\', \'real\') THEN 109 "
		"WHEN T2.name IN (\'smallmoney\', \'money\') THEN 110 "
		"WHEN T2.name IN (\'smalldatetime\', \'datetime\') THEN 111 "
		"WHEN T2.name = \'binary\' THEN 173 "
		"WHEN T2.name = \'bit\' THEN 104 "
		"WHEN T2.name = \'char\' THEN 175 "
		"WHEN T2.name = \'date\' THEN 40 "
		"WHEN T2.name = \'datetime2\' THEN 42 "
		"WHEN T2.name = \'datetimeoffset\' THEN 43 "
		"WHEN T2.name = \'decimal\' THEN 106 "
		"WHEN T2.name = \'image\' THEN 34 "
		"WHEN T2.name = \'nchar\' THEN 239 "
		"WHEN T2.name = \'ntext\' THEN 99 "
		"WHEN T2.name = \'numeric\' THEN 108 "
		"WHEN T2.name = \'nvarchar\' THEN 231 "
		"WHEN T2.name = \'text\' THEN 35 "
		"WHEN T2.name = \'time\' THEN 41 "
		"WHEN T2.name = \'uniqueidentifier\' THEN 36 "
		"WHEN T2.name = \'varbinary\' THEN 165 "
		"WHEN T2.name = \'varchar\' THEN 167 "
		"WHEN T2.name =  \'xml\' THEN 241 "
		"ELSE C.system_type_id "
	"END " /* AS "suggested_tds_type_id" */
	", CASE "
		"WHEN T2.name = \'nvarchar\' AND C.max_length = -1 THEN 65535 "
		"WHEN T2.name = \'varbinary\' AND C.max_length = -1 THEN 65535 "
		"WHEN T2.name = \'varchar\' AND C.max_length = -1 THEN 65535 "
		"WHEN T2.name IN (\'decimal\', \'numeric\') THEN 17 "
		"WHEN T2.name = \'xml\' THEN 8100 "
		"WHEN T2.name in (\'image\', \'text\') THEN 2147483647"
		"WHEN T2.name = \'ntext\' THEN 2147483646"
		"ELSE CAST( C.max_length AS INT ) "
	"END " /* AS "suggested_tds_length" */
"FROM sys.objects O, sys.columns C, sys.types T, sys.types T2 "
"WHERE O.object_id = C.object_id "
"AND C.user_type_id = T.user_type_id "
"AND C.name = \'%s\' " /* -- INPUT column name */
"AND T.system_type_id = T2.user_type_id " /*  -- To get system dt name. */
"AND O.name = \'%s\'  " /*  -- INPUT table name */
"AND O.schema_id = %d " /*  -- INPUT schema Oid */
"AND O.type = \'U\'"; /* -- User tables only for the time being */
		char *query = psprintf(tempq,
				undeclaredparams->targetcolnames[undeclaredparams->paramindexes[call_cntr]],
				undeclaredparams->tablename,
				undeclaredparams->schemaoid);

		int rc = SPI_execute(query, true, 1);
		if (rc != SPI_OK_SELECT)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("SPI_execute failed: %s", SPI_result_code_string(rc))));
		if (SPI_processed == 0)
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("SPI_execute returned no rows: %s", query)));

		values = (char **) palloc(numresultcols * sizeof(char *));

		values[0] = psprintf("%d", call_cntr + 1);
		values[1] = undeclaredparams->paramnames[call_cntr];
		for (col = 2; col < numresultcols; col++)
		{
			values[col] = SPI_getvalue(SPI_tuptable->vals[0],
									   SPI_tuptable->tupdesc, col+1);
		}

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

/*
 * Internal function used by procedure xp_qv.
 * The xp_qv procedure is called by SSMS. Only the minimum implementation is required.
 */
Datum 
xp_qv_internal(PG_FUNCTION_ARGS)
{	
	PG_RETURN_INT32(0);
}

/*
 * Internal function to create the xp_qv procedure in master.dbo schema.
 * Some applications invoke this referencing master.dbo.xp_qv
 */
Datum 
create_xp_qv_in_master_dbo_internal(PG_FUNCTION_ARGS)
{	
	char *query = NULL;
	int rc = -1;

	char *tempq = "CREATE OR REPLACE PROCEDURE %s.xp_qv(IN SYS.NVARCHAR(256), IN SYS.NVARCHAR(256))"
				  "AS \'babelfishpg_tsql\', \'xp_qv_internal\' LANGUAGE C";

	const char  *dbo_scm = get_dbo_schema_name("master");
	if (dbo_scm == NULL) 
		elog(ERROR, "Failed to retrieve dbo schema name");

	query = psprintf(tempq, dbo_scm);

	PG_TRY();
	{
		if ((rc = SPI_connect()) != SPI_OK_CONNECT)
			elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));

		if ((rc = SPI_execute(query, false, 1)) < 0)
			elog(ERROR, "SPI_execute failed: %s", SPI_result_code_string(rc));

		if ((rc = SPI_finish()) != SPI_OK_FINISH)
			elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));
	}
	PG_CATCH();
	{
		SPI_finish();
		PG_RE_THROW();
	}
	PG_END_TRY();

	PG_RETURN_INT32(0);
}
