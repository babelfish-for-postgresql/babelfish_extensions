#include "access/xact.h"
#include "pltsql.h"
#include "pltsql-2.h"
#include "iterative_exec.h"
#include "dynastack.h"

/***************************************************************************************
 *                         Execution Actions
 **************************************************************************************/

static int exec_stmt_init_vars(PLtsql_execstate *estate, PLtsql_stmt_init_vars *stmt);
static int exec_stmt_goto(PLtsql_execstate *estate, PLtsql_stmt_goto *stmt);
static int exec_stmt_restore_ctx_full(PLtsql_execstate *estate, PLtsql_stmt_restore_ctx_full *stmt);
static int exec_stmt_restore_ctx_partial(PLtsql_execstate *estate, PLtsql_stmt_restore_ctx_partial *stmt);
static int exec_stmt_raiserror(PLtsql_execstate *estate, PLtsql_stmt_raiserror *stmt);
static int exec_stmt_throw(PLtsql_execstate *estate, PLtsql_stmt_throw *stmt);
static void restore_ctx_full(PLtsql_execstate *estate);
static ErrorData * restore_ctx_partial1(PLtsql_execstate *estate);
static void restore_ctx_partial2(PLtsql_execstate *estate);
static void set_exec_error_data(char *procedure, int number, int severity, int state, bool rethrow);
static void reset_exec_error_data(PLtsql_execstate *estate);
static void assert_equal_estate_err(PLtsql_estate_err *err1, PLtsql_estate_err *err2);
static void read_raiserror_params(PLtsql_execstate *estate, List *params, int paramno,
								  char **msg, int *msg_id, int *severity, int *state);
static void read_throw_params(PLtsql_execstate *estate, List *params, 
							  char **msg, int *err_no, int *state);
static char *get_proc_name(PLtsql_execstate *estate);
static bool is_seterror_on(PLtsql_stmt *stmt);

extern PLtsql_estate_err *pltsql_clone_estate_err(PLtsql_estate_err *err);
extern void prepare_format_string(StringInfo buf, char *msg_string, int nargs, 
								  Datum *args, Oid *argtypes, bool *argisnull);

static int exec_stmt_init_vars(PLtsql_execstate *estate, PLtsql_stmt_init_vars *stmt)
{
    int i;

    /*
     * First initialize all variables declared in this block
     */
    estate->err_text = gettext_noop("during statement block local variable initialization");

    for (i = 0; i < stmt->n_initvars; i++)
    {
        int n = stmt->initvarnos[i];
        PLtsql_datum *datum = estate->datums[n];

        /*
         * The set of dtypes handled here must match pltsql_add_initdatums().
         *
         * Note that we currently don't support promise datums within blocks,
         * only at a function's outermost scope, so we needn't handle those
         * here.
         */
        switch (datum->dtype)
        {
            case PLTSQL_DTYPE_VAR:
                {
                    PLtsql_var *var = (PLtsql_var *) datum;

                    /*
                     * Free any old value, in case re-entering block, and
                     * initialize to NULL
                     */
                    assign_simple_var(estate, var, (Datum) 0, true, false);

                    if (var->default_val == NULL)
                    {
                        /*
                         * If needed, give the datatype a chance to reject
                         * NULLs, by assigning a NULL to the variable.  We
                         * claim the value is of type UNKNOWN, not the var's
                         * datatype, else coercion will be skipped.
                         */
                        if (var->datatype->typtype == TYPTYPE_DOMAIN)
                            exec_assign_value(estate,
                                              (PLtsql_datum *) var,
                                              (Datum) 0,
                                              true,
                                              UNKNOWNOID,
                                              -1);

                        /* parser should have rejected NOT NULL */
                        Assert(!var->notnull);
                    }
                    else
                    {
                        exec_assign_expr(estate, (PLtsql_datum *) var,
                                         var->default_val);
                    }
                }
                break;

            case PLTSQL_DTYPE_REC:
                {
                    PLtsql_rec *rec = (PLtsql_rec *) datum;

                    /*
                     * Deletion of any existing object will be handled during
                     * the assignments below, and in some cases it's more
                     * efficient for us not to get rid of it beforehand.
                     */
                    if (rec->default_val == NULL)
                    {
                        /*
                         * If needed, give the datatype a chance to reject
                         * NULLs, by assigning a NULL to the variable.
                         */
                        exec_move_row(estate, (PLtsql_variable *) rec,
                                      NULL, NULL);

                        /* parser should have rejected NOT NULL */
                        Assert(!rec->notnull);
                    }
                    else
                    {
                        exec_assign_expr(estate, (PLtsql_datum *) rec,
                                         rec->default_val);
                    }
                }
                break;

            default:
                elog(ERROR, "unrecognized dtype: %d", datum->dtype);
        }
    }

    estate->err_text = NULL;
    return PLTSQL_RC_OK;
}

static int exec_stmt_goto(PLtsql_execstate *estate, PLtsql_stmt_goto *stmt)
{
    if (stmt->cond)
    {
		/* conditional jump */
    	bool  isnull = false;
        bool value = exec_eval_boolean(estate, stmt->cond, &isnull);

        exec_eval_cleanup(estate);

		/* jump if condition is NULL or false */
		if (isnull || (value == false))
        	estate->pc = (stmt->target_pc - 1);
    }
	else /* unconditional jump */
        estate->pc = (stmt->target_pc - 1);

    return PLTSQL_RC_OK;
}

static int exec_stmt_raiserror(PLtsql_execstate *estate, PLtsql_stmt_raiserror *stmt)
{
	int		elevel;
	char	*msg = NULL;
	char	*proc_name = NULL;
	int		msg_id = 50000;
	int		severity = -1;
	int		state = -1;

	/* Read parameters of RAISERROR statements */
	read_raiserror_params(estate, stmt->params, stmt->paramno, &msg, &msg_id, &severity, &state);
	msg = pstrdup(msg);

	exec_eval_cleanup(estate);

	if (severity < 0 || severity > 24)
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("severity argument of RAISERROR should be in the range of 0 - 24")));

	if (stmt->seterror) 
		exec_set_error(estate, msg_id, 0, false /* error_mapping_failed */);

	/* Simply print out the error message if severity <= 10 */
	if (severity <= 10)
		elevel = INFO;
	/* Severity > 18 need sysadmin role using WITH LOG option */
	else if (severity > 18 && !stmt->log)
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("error severity levels greater than 18 require WITH LOG option.")));
	/* Otherwise, report error */
	else
	{
		elevel = ERROR;
		proc_name = get_proc_name(estate);
		/* Update error data info in exec_state_call_stack */
		set_exec_error_data(proc_name, msg_id, severity, state, false /* rethrow */);
	}
	ereport(elevel, (errcode(ERRCODE_PLTSQL_RAISERROR), 
			errmsg_internal("%s", msg)));

	if (elevel == INFO && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_info)
		((*pltsql_protocol_plugin_ptr)->send_info) (0,
													1,
													0,
													msg,
													0);

	return PLTSQL_RC_OK;
}

static int exec_stmt_throw(PLtsql_execstate *estate, PLtsql_stmt_throw *stmt)
{
	char	*msg = NULL;
	char	*proc_name = NULL;
	int		err_no = -1;
	int		state = -1;

	/* THROW without params is to re-throw */
	if (stmt->params == NIL)
	{
		/* Check if we are inside a CATCH block */
		if (estate->cur_error == NULL || estate->cur_error->error == NULL)
			ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
					errmsg("THROW without parameters should be executed inside a CATCH block")));

		/* Update error data info in exec_state_call_stack */
		set_exec_error_data(estate->cur_error->procedure,
							estate->cur_error->number,
							estate->cur_error->severity,
							estate->cur_error->state,
							true /* rethrow */);
		ReThrowError(estate->cur_error->error);
	}
	else
	{
		/* Read parameters of THROW statement */
		read_throw_params(estate, stmt->params, &msg, &err_no, &state);
		msg = pstrdup(msg);
		proc_name = get_proc_name(estate);

		exec_eval_cleanup(estate);

		/* Update error data info in exec_state_call_stack */
		set_exec_error_data(proc_name, err_no, 16, state, false /* rethrow */);
		ereport(ERROR, (errcode(ERRCODE_PLTSQL_THROW), 
				errmsg_internal("%s", msg)));
	}

	return PLTSQL_RC_OK;
}

static int exec_stmt_restore_ctx_full(PLtsql_execstate *estate, PLtsql_stmt_restore_ctx_full *stmt)
{
    estate->err_text = gettext_noop("during statement block exit");
    /* restore error context */
    restore_ctx_full(estate);
    return PLTSQL_RC_OK;
}

static int exec_stmt_restore_ctx_partial(PLtsql_execstate *estate, PLtsql_stmt_restore_ctx_partial *stmt)
{
    restore_ctx_partial2(estate);
    estate->err_text = NULL;
    return PLTSQL_RC_OK;
}

static void restore_ctx_full(PLtsql_execstate *estate)
{
    int i;
    PLtsql_errctx *cur_err_ctx = *(PLtsql_errctx **) vec_at(estate->err_ctx_stack,
                                                              estate->cur_err_ctx_idx);

    MemoryContextSwitchTo(cur_err_ctx->oldcontext);

    /* Assert that the stmt_mcontext stack is unchanged */
    Assert(cur_err_ctx->stmt_mcontext == estate->stmt_mcontext);

    /* PG_TRY_END */
    PG_exception_stack = cur_err_ctx->save_exception_stack;
    error_context_stack = cur_err_ctx->save_context_stack;

	assert_equal_estate_err(cur_err_ctx->save_cur_error, estate->cur_error);
	estate->err_text = NULL;

    vec_pop_back(estate->err_ctx_stack);

    /* find next active error context index */
    for ( i = (int) (estate->cur_err_ctx_idx) - 1; i >=0 ; i--)
    {
        PLtsql_errctx *context = *(PLtsql_errctx **) vec_at(estate->err_ctx_stack, i);
        if (!context->partial_restored) 
        {
            /* cur_err_ctx_idx is pointing to this error context */
            estate->cur_err_ctx_idx = i;
            break;
        }
    }
}

static ErrorData *restore_ctx_partial1(PLtsql_execstate *estate)
{
	ErrorData *edata;
    PLtsql_errctx *cur_err_ctx = *(PLtsql_errctx **) vec_at(estate->err_ctx_stack,
                                                              estate->cur_err_ctx_idx);

    PG_exception_stack = cur_err_ctx->save_exception_stack;
    error_context_stack = cur_err_ctx->save_context_stack;

    estate->err_text = gettext_noop("during exception cleanup");

    /* Save error info in our stmt_mcontext */
    MemoryContextSwitchTo(cur_err_ctx->stmt_mcontext);
	edata = CopyErrorData();
	FlushErrorState();

    MemoryContextSwitchTo(cur_err_ctx->oldcontext);

    /*
     * Set up the stmt_mcontext stack as though we had restored our
     * previous state and then done push_stmt_mcontext().  The push is
     * needed so that statements in the exception handler won't
     * clobber the error data that's in our stmt_mcontext.
     */
    estate->stmt_mcontext_parent = cur_err_ctx->stmt_mcontext;
    estate->stmt_mcontext = NULL;

    /*
     * Now we can delete any nested stmt_mcontexts that might have
     * been created as children of ours.  (Note: we do not immediately
     * release any statement-lifespan data that might have been left
     * behind in stmt_mcontext itself.  We could attempt that by doing
     * a MemoryContextReset on it before collecting the error data
     * above, but it seems too risky to do any significant amount of
     * work before collecting the error.)
     */
    MemoryContextDeleteChildren(cur_err_ctx->stmt_mcontext);

    /*
     * Must clean up the econtext too.  However, any tuple table made
     * in the subxact will have been thrown away by SPI during subxact
     * abort, so we don't need to (and mustn't try to) free the
     * eval_tuptable.
     */
    estate->eval_tuptable = NULL;
    exec_eval_cleanup(estate);

    cur_err_ctx->partial_restored = true;  /* update status */
	return edata;
}

static void restore_ctx_partial2(PLtsql_execstate *estate)
{
    /* partial1 cleaned all dangling errors, so vec_back is current error context */
    PLtsql_errctx *cur_err_ctx = *(PLtsql_errctx **) vec_back(estate->err_ctx_stack);

    /*
     * Restore previous state of cur_error, whether or not we executed
     * a handler.  This is needed in case an error got thrown from
     * some inner block's exception handler.
     */
	*estate->cur_error = *cur_err_ctx->save_cur_error;

    /* Restore stmt_mcontext stack and release the error data */
    pop_stmt_mcontext(estate);
    MemoryContextReset(cur_err_ctx->stmt_mcontext);

    /* end of current error handling */
    vec_pop_back(estate->err_ctx_stack);
	if (cur_err_ctx->save_cur_error)
	{
		if (cur_err_ctx->save_cur_error->procedure)
			pfree(cur_err_ctx->save_cur_error->procedure);
		pfree(cur_err_ctx->save_cur_error);
	}
    pfree(cur_err_ctx);
}

/***************************************************************************************
 *                              STATISTICS & TRACING 
 **************************************************************************************/

typedef struct
{
    DynaVec *counts;
    DynaVec *durations;
    uint64_t total_duration;
    uint64_t code_size;
} ExecStat;

static inline bool trace_exec_enabled(uint64_t trace_mode);
static inline bool trace_exec_codes_enabled(uint64_t trace_mode);
static inline bool trace_exec_counts_enabled(uint64_t trace_mode);
static inline bool trace_exec_time_enabled(uint64_t trace_mode);

/* measuring helpers */
static inline void pre_exec_measure(uint64_t trace_mode, ExecStat *stat, struct timeval *stmt_begin, int pc);
static inline void post_exec_measure(uint64_t trace_mode, ExecStat *stat, struct timeval *stmt_end, int pc);
static inline void initialize_trace(uint64_t trace_mode, ExecStat **stat, struct timeval *proc_begin, size_t size);
static inline void finalize_trace(uint64_t trace_mode, ExecCodes *exec_codes, ExecStat *stat, struct timeval *proc_begin);
         
ExecStat *create_stat(size_t code_size, uint64_t trace_mode);
void      destroy_stat(ExecStat *stat);

#define TRACE_LOCAL_BUF_SIZE 256
static void get_code_desc(PLtsql_stmt *stmt, const char *namespace, const char * name, StringInfo buf);
static void get_stat_desc(ExecStat *stat, size_t index, StringInfo buf);
static void get_stat_trace(ExecCodes *exec_code, ExecStat *stat, StringInfo buf);

/* describe execution details */
static void desc_stmt_goto(PLtsql_stmt_goto *stmt, char *buf);
static void desc_stmt_save_ctx(PLtsql_stmt_save_ctx *stmt, char *buf);

static inline bool trace_exec_enabled(uint64_t trace_mode)
{
    return trace_mode > 0;
}

static inline bool trace_exec_codes_enabled(uint64_t trace_mode)
{
    return trace_mode & TRACE_EXEC_CODES;
}

static inline bool trace_exec_counts_enabled(uint64_t trace_mode)
{
    return (trace_mode & TRACE_EXEC_COUNTS) == TRACE_EXEC_COUNTS;
}

static inline bool trace_exec_time_enabled(uint64_t trace_mode)
{
    return (trace_mode & TRACE_EXEC_TIME) == TRACE_EXEC_TIME;
}

static inline void 
pre_exec_measure(uint64_t trace_mode, ExecStat *stat, struct timeval *stmt_begin, int pc)
{
	if (trace_exec_counts_enabled(trace_mode))
	{
		size_t *cur_cnt = (size_t *) vec_at(stat->counts, pc);
		++(*cur_cnt);
	}
	if (trace_exec_time_enabled(trace_mode))
		gettimeofday(stmt_begin, NULL);
}

static inline void 
post_exec_measure(uint64_t trace_mode, ExecStat *stat, struct timeval *stmt_begin, int pc)
{
	if (trace_exec_time_enabled(trace_mode))
	{
		struct timeval stmt_end;
		long seconds, microseconds;
		size_t *cur_duration = (size_t *) vec_at(stat->durations, pc);
		gettimeofday(&stmt_end, NULL);
		seconds = stmt_end.tv_sec - stmt_begin->tv_sec;
		microseconds = stmt_end.tv_usec - stmt_begin->tv_usec;
		*(cur_duration) += seconds*1000 + microseconds/1000; /* in ms unit */
	}
}

static inline void 
initialize_trace(uint64_t trace_mode, ExecStat **stat, struct timeval *proc_begin, size_t size)
{
    if (trace_exec_enabled(trace_mode))
    {
        *stat = create_stat(size, trace_mode);
        gettimeofday(proc_begin, NULL);
    }
}

static inline void 
finalize_trace(uint64_t trace_mode, ExecCodes *exec_codes, ExecStat *stat, struct timeval *proc_begin)
{
	if (trace_exec_enabled(trace_mode))
    {
        long seconds, microseconds;
        StringInfoData buf;
        struct timeval proc_end; 

        gettimeofday(&proc_end, NULL);
        seconds = proc_end.tv_sec - proc_begin->tv_sec;
        microseconds = proc_end.tv_usec - proc_begin->tv_usec;

        stat->total_duration = seconds*1000 + microseconds/1000;  /* in ms unit  */
        initStringInfo(&buf);
        get_stat_trace(exec_codes, stat, &buf);
        ereport(LOG, (errmsg("Execution Trace: \n%s", buf.data)));
        pfree(buf.data);
        destroy_stat(stat);
    }
}
         
ExecStat *create_stat(size_t code_size, uint64_t trace_mode)
{
    static size_t init_val = 0;
    ExecStat *stat;

    if (!trace_exec_enabled(trace_mode))
        return NULL;

    stat = palloc(sizeof(ExecStat));
    stat->counts = NULL;
    stat->durations = NULL;
    stat->total_duration = 0;
    stat->code_size = code_size;

    if (trace_exec_counts_enabled(trace_mode))
    {
        stat->counts = create_vector3(sizeof(size_t), code_size, &init_val);
    }
    if (trace_exec_time_enabled(trace_mode))
    {
        stat->durations = create_vector3(sizeof(time_t), code_size, &init_val);
    }

    return stat;
}

void destroy_stat(ExecStat *stat)
{
    if (!stat)
        return;
    if (stat->counts)
        destroy_vector(stat->counts);
    if (stat->durations)
        destroy_vector(stat->durations);
    pfree(stat);
}

static void desc_stmt_goto(PLtsql_stmt_goto *stmt, char *buf)
{
    if (stmt->cond)
        snprintf(buf, TRACE_LOCAL_BUF_SIZE, "COND GOTO %d", stmt->target_pc);
    else
        snprintf(buf, TRACE_LOCAL_BUF_SIZE, "GOTO %d", stmt->target_pc);
}

static void desc_stmt_save_ctx(PLtsql_stmt_save_ctx *stmt, char *buf)
{
    snprintf(buf, TRACE_LOCAL_BUF_SIZE, "SAVE CONTEXT, GOTO %d", stmt->target_pc);
}

static void get_code_desc(PLtsql_stmt *stmt, const char *namespace, const char * name, StringInfo buf)
{
    char local_buf[TRACE_LOCAL_BUF_SIZE];
    char detail_buf[TRACE_LOCAL_BUF_SIZE];
    char line_detail_buf[TRACE_LOCAL_BUF_SIZE];

    if (!namespace && !name)
        snprintf(line_detail_buf, TRACE_LOCAL_BUF_SIZE,
                "(DO STMT:%d)", stmt->lineno);
    else
        snprintf(line_detail_buf, TRACE_LOCAL_BUF_SIZE,
                "(%s.%s:%d)", namespace, name, stmt->lineno); 

    switch (stmt->cmd_type)
    {
        case PLTSQL_STMT_GOTO:
            desc_stmt_goto((PLtsql_stmt_goto *) stmt, detail_buf); 
            snprintf(local_buf, TRACE_LOCAL_BUF_SIZE, "%s %s", 
                                detail_buf, line_detail_buf);
            break;
        case PLTSQL_STMT_SAVE_CTX:
            desc_stmt_save_ctx((PLtsql_stmt_save_ctx *) stmt, detail_buf); 
            snprintf(local_buf, TRACE_LOCAL_BUF_SIZE, "%s %s", 
                                detail_buf, line_detail_buf);
            break;
        default:
            snprintf(local_buf, TRACE_LOCAL_BUF_SIZE, "%s %s", 
                     pltsql_stmt_typename(stmt), line_detail_buf);
            break;
    }
    
    appendStringInfoString(buf, local_buf);
}

static void get_stat_desc(ExecStat *stat, size_t index, StringInfo buf)
{
    bool first = true;
    char local_buf[TRACE_LOCAL_BUF_SIZE];

    if (!stat->counts && !stat->durations)
        return;
    
    appendStringInfoString(buf, "("); 

    /* Count */
    if (stat->counts)
    {
        snprintf(local_buf, TRACE_LOCAL_BUF_SIZE, "C:%3zu", *(size_t *) vec_at(stat->counts, index));
        appendStringInfoString(buf, local_buf); 
        first = false;
    }

    /* Duration */
    if (stat->durations)
    {
        if (!first)
            appendStringInfoString(buf, ", ");
        snprintf(local_buf, TRACE_LOCAL_BUF_SIZE, "T:%6zums", *(size_t *) vec_at(stat->durations, index));
        appendStringInfoString(buf, local_buf); 
        first = false;
    }
    appendStringInfoString(buf, ")"); 
}

static void get_stat_trace(ExecCodes *exec_code, ExecStat *stat, StringInfo buf)
{
    size_t code_size = vec_size(exec_code->codes);
    size_t i;
    char   local_buf[TRACE_LOCAL_BUF_SIZE];
    PLtsql_stmt *stmt;

    StringInfoData code_desc, stat_desc;
    initStringInfo(&code_desc);
    initStringInfo(&stat_desc);

    /* Header */
    snprintf(local_buf, TRACE_LOCAL_BUF_SIZE,
             "Execution Summary: %s.%s total execution code size %zu, total execution time %zums\n", 
             exec_code->proc_namespace, exec_code->proc_name,
             code_size, stat->total_duration);
    appendStringInfoString(buf, local_buf);

    /* Body */
    for (i=0 ; i < code_size; i++)
    {
        stmt = *(PLtsql_stmt **) vec_at(exec_code->codes, i);
        resetStringInfo(&code_desc);
        resetStringInfo(&stat_desc);
        get_code_desc(stmt, exec_code->proc_namespace, exec_code->proc_name, &code_desc);
        get_stat_desc(stat, i, &stat_desc);
        snprintf(local_buf, TRACE_LOCAL_BUF_SIZE, "[%3zu] %-69s %s\n", i, code_desc.data, stat_desc.data);      
        appendStringInfoString(buf, local_buf);
    }

    pfree(code_desc.data);
    pfree(stat_desc.data);
}

/***************************************************************************************
 *                                  MAIN EXECUTION
 **************************************************************************************/

static inline int dispatch_stmt(PLtsql_execstate *estate, PLtsql_stmt *stmt);
static PLtsql_errctx *create_error_ctx(PLtsql_execstate *estate, int target_pc);

static inline int dispatch_stmt(PLtsql_execstate *estate, PLtsql_stmt *stmt)
{
    int rc = PLTSQL_RC_OK;  /* only used to test return is called */

	/* Store the Current Line Number of the current query, incase we stumble upon a runtime error. */
	CurrentLineNumber = stmt->lineno;
	estate->err_stmt = stmt;

	/* reset number of tuple processed in previous command */
	estate->eval_processed = 0;

    switch(stmt->cmd_type)
    {
        case PLTSQL_STMT_ASSIGN:
            exec_stmt_assign(estate, (PLtsql_stmt_assign *) stmt);
            break;
        case PLTSQL_STMT_RETURN:
            rc = exec_stmt_return(estate, (PLtsql_stmt_return *)stmt);
            break;
        case PLTSQL_STMT_RETURN_QUERY:
            exec_stmt_return_query(estate, (PLtsql_stmt_return_query *)stmt);
            break;
        case PLTSQL_STMT_EXECSQL:
            exec_stmt_execsql(estate, (PLtsql_stmt_execsql *) stmt);
            break;
		case PLTSQL_STMT_OPEN:
			exec_stmt_open(estate, (PLtsql_stmt_open *) stmt);
			break;
		case PLTSQL_STMT_FETCH:
			exec_stmt_fetch(estate, (PLtsql_stmt_fetch *) stmt);
			break;
		case PLTSQL_STMT_CLOSE:
			exec_stmt_close(estate, (PLtsql_stmt_close *) stmt);
			break;
		case PLTSQL_STMT_COMMIT:
			exec_stmt_commit(estate, (PLtsql_stmt_commit *) stmt);
			break;
		case PLTSQL_STMT_ROLLBACK:
			exec_stmt_rollback(estate, (PLtsql_stmt_rollback *) stmt);
			break;
	    /* TSQL-only statement types follow */
        case PLTSQL_STMT_GOTO:
            exec_stmt_goto(estate, (PLtsql_stmt_goto *) stmt);
            break;
        case PLTSQL_STMT_PRINT:
            exec_stmt_print(estate, (PLtsql_stmt_print *)stmt);
            break;
		case PLTSQL_STMT_QUERY_SET:
			exec_stmt_query_set(estate, (PLtsql_stmt_query_set *) stmt);
			break;
        case PLTSQL_STMT_PUSH_RESULT:
            exec_stmt_push_result(estate, (PLtsql_stmt_push_result *) stmt);
            break;
		case PLTSQL_STMT_EXEC:
			exec_stmt_exec(estate, (PLtsql_stmt_exec *) stmt);
			break;
		case PLTSQL_STMT_EXEC_BATCH:
			exec_stmt_exec_batch(estate, (PLtsql_stmt_exec_batch *) stmt);
			break;
		case PLTSQL_STMT_EXEC_SP:
			exec_stmt_exec_sp(estate, (PLtsql_stmt_exec_sp *) stmt);
			break;
		case PLTSQL_STMT_DECL_TABLE:
			exec_stmt_decl_table(estate, (PLtsql_stmt_decl_table *) stmt);
			break;
		case PLTSQL_STMT_RETURN_TABLE:
			exec_stmt_return_table(estate, (PLtsql_stmt_return_query *) stmt);
			break;
        case PLTSQL_STMT_DEALLOCATE:
            exec_stmt_deallocate(estate, (PLtsql_stmt_deallocate *) stmt);
            break;
        case PLTSQL_STMT_DECL_CURSOR:
            exec_stmt_decl_cursor(estate, (PLtsql_stmt_decl_cursor *) stmt);
            break;
		case PLTSQL_STMT_RAISERROR:
			exec_stmt_raiserror(estate, (PLtsql_stmt_raiserror *) stmt);
			break;
		case PLTSQL_STMT_THROW:
			exec_stmt_throw(estate, (PLtsql_stmt_throw *) stmt);
			break;
		case PLTSQL_STMT_USEDB:
			exec_stmt_usedb(estate, (PLtsql_stmt_usedb *) stmt);
			break;
        case PLTSQL_STMT_INSERT_BULK:
            exec_stmt_insert_bulk(estate, (PLtsql_stmt_insert_bulk *) stmt);
            break;
        /* TSQL-only executable node */
        case PLTSQL_STMT_INIT_VARS:
            exec_stmt_init_vars(estate, (PLtsql_stmt_init_vars *) stmt);
            break;
        case PLTSQL_STMT_RESTORE_CTX_FULL:
            exec_stmt_restore_ctx_full(estate, (PLtsql_stmt_restore_ctx_full *) stmt);
            break;
        case PLTSQL_STMT_RESTORE_CTX_PARTIAL:
            exec_stmt_restore_ctx_partial(estate, (PLtsql_stmt_restore_ctx_partial *) stmt);
            break;
        default:
            ereport(ERROR,
                    (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                     errmsg("Unsupported statment type %d in executor", stmt->cmd_type)));
    }

    return rc;
}

static PLtsql_errctx *create_error_ctx(PLtsql_execstate *estate, int target_pc)
{
    PLtsql_errctx *context = palloc(sizeof(PLtsql_errctx));

    context->save_exception_stack = PG_exception_stack;
    context->save_context_stack = error_context_stack;
    context->target_pc = target_pc;

    context->oldcontext = CurrentMemoryContext;
    context->oldowner = CurrentResourceOwner;
    context->old_eval_econtext = estate->eval_econtext;
	
	context->save_cur_error = pltsql_clone_estate_err(estate->cur_error);
    /*
     * We will need a stmt_mcontext to hold the error data if an error
     * occurs.  It seems best to force it to exist before entering the
     * subtransaction, so that we reduce the risk of out-of-memory during
     * error recovery, and because this greatly simplifies restoring the
     * stmt_mcontext stack to the correct state after an error.  We can
     * ameliorate the cost of this by allowing the called statements to
     * use this mcontext too; so we don't push it down here.
     */
    context->stmt_mcontext = get_stmt_mcontext(estate);

	context->partial_restored = false;

    return context;
}

/*
 * If current statement is part of try/catch block
 * at current or any higher batch level, it does
 * not consider PG_TRY/PG_CATCH in code or C based
 * procedures/functions
 */
static
bool is_part_of_pltsql_trycatch_block(PLtsql_execstate *estate)
{
	PLExecStateCallStack *cur;

	Assert(estate == exec_state_call_stack->estate);
	cur = exec_state_call_stack;
	while (cur != NULL)
	{
		/* There is at-least one try block active for sure */
		if (vec_size(cur->estate->err_ctx_stack) > 1)
			return true;
		/* Either try or catch block is active */
		if (vec_size(cur->estate->err_ctx_stack) == 1)
		{
			PLtsql_errctx *err_ctx = *(PLtsql_errctx **) vec_at(cur->estate->err_ctx_stack, 0);
			/* Make sure that we are not inside the catch block */
			if (!err_ctx->partial_restored)
				return true;
		}
		cur = cur->next;
	}
	return false;
}

/*
 * If current statement is part of trigger execution
 * at current or any higher batch level
 */
static
bool is_part_of_pltsql_trigger(PLtsql_execstate *estate)
{
	PLExecStateCallStack *cur;

	Assert(estate == exec_state_call_stack->estate);
	cur = exec_state_call_stack;
	while (cur != NULL)
	{
		if (cur->estate->trigdata != NULL || cur->estate->evtrigdata != NULL)
			return true;
		cur = cur->next;
	}
	return false;
}

/* Control command like GOTO, RETURN */
static
bool is_control_command(PLtsql_stmt *stmt)
{
	switch(stmt->cmd_type)
	{
		case PLTSQL_STMT_GOTO:
		case PLTSQL_STMT_RETURN:
		case PLTSQL_STMT_RESTORE_CTX_FULL:
		case PLTSQL_STMT_RESTORE_CTX_PARTIAL:
			return true;
		default:
			return false;
	}
}

static
bool is_start_implicit_txn_command(PLtsql_stmt *stmt)
{
	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_DECL_CURSOR:
		case PLTSQL_STMT_OPEN:
		case PLTSQL_STMT_FETCH:
		case PLTSQL_STMT_EXECSQL:
		case PLTSQL_STMT_QUERY_SET:
		case PLTSQL_STMT_RETURN_QUERY:
		case PLTSQL_STMT_PUSH_RESULT:
			return true;
		default :
			return false;
	}
}

/* Batch commands like EXEC, SP_EXECUTESQL */
static
bool is_batch_command(PLtsql_stmt *stmt)
{
    switch(stmt->cmd_type)
    {
		case PLTSQL_STMT_EXEC:
		case PLTSQL_STMT_EXEC_BATCH:
		case PLTSQL_STMT_EXEC_SP:
			return true;
		case PLTSQL_STMT_EXECSQL:
			return ((PLtsql_stmt_execsql *)stmt)->insert_exec;
		default:
			return false;
	}
}

static
void record_error_state(PLtsql_execstate *estate)
{
	if (exec_state_call_stack->error_data.error_estate == NULL)
	{
		exec_state_call_stack->error_data.error_estate = estate;
		if (pltsql_xact_abort)
			exec_state_call_stack->error_data.xact_abort_on = true;
		if (estate->trigdata != NULL || estate->evtrigdata != NULL)
			exec_state_call_stack->error_data.trigger_error = true;
		exec_state_call_stack->error_data.error_procedure = get_proc_name(estate);
	}
}

/*
 * Only the batch where error is raised first time is considered
 * as its error scope. Any parent batch is outer scope and errors work
 * like statement terminating errors
 */
static
bool is_error_raising_batch(PLtsql_execstate *estate)
{
	if (exec_state_call_stack->error_data.error_estate == estate)
		return true;
	return false;
}

static
bool is_xact_abort_on_error(PLtsql_execstate *estate)
{
	if (exec_state_call_stack->error_data.xact_abort_on)
		return true;
	return false;
}

/* Cases where transaction is no longer committable */
static
bool abort_transaction(PLtsql_execstate *estate, ErrorData *edata)
{
	/* Batch aborting errors which also terminate the transaction */
	if (is_batch_txn_aborting_error(edata->sqlerrcode))
		return true;

	/*
	 * If error is raised inside trigger execution then default behaviour is
	 * to rollback the transaction.
	 */
	if (is_part_of_pltsql_trigger(estate) || exec_state_call_stack->error_data.trigger_error)
		return true;

	/* Transaction count mismatch error inside try catch block */
	if (edata->sqlerrcode == ERRCODE_T_R_INTEGRITY_CONSTRAINT_VIOLATION &&
		is_part_of_pltsql_trycatch_block(estate))
		return true;

	if (is_xact_abort_on_error(estate))
	{
		if (is_part_of_pltsql_trycatch_block(estate))
			return true;
		if (!ignore_xact_abort_error(edata->sqlerrcode))
			return true;
	}

	return false;
}

/* If error only terminates current batch */
static
bool abort_only_current_batch(PLtsql_execstate *estate, ErrorData *edata)
{
	if (is_current_batch_aborting_error(edata->sqlerrcode) &&
		is_error_raising_batch(estate))
		return true;
	return false;
}

/* Cases where execution needs to terminate */
static
bool abort_execution(PLtsql_execstate *estate, ErrorData *edata, bool *terminate_batch)
{
	/* Exclude ignorable errors */
	if (!is_ignorable_error(edata->sqlerrcode))
		return true;

	/* Current batch aborting errors */
	if (abort_only_current_batch(estate, edata))
	{
		*terminate_batch = true;
		return true;
	}

	/* If any error inside trigger execution. */
	if (is_part_of_pltsql_trigger(estate) || exec_state_call_stack->error_data.trigger_error)
		return true;

	if (exec_state_call_stack->error_data.rethrow_error)
		return true;

	/* Any error inside try catch block */
	if (is_part_of_pltsql_trycatch_block(estate))
		return true;

	if (is_xact_abort_on_error(estate) &&
		!ignore_xact_abort_error(edata->sqlerrcode))
		return true;

	return false;
}

/*
 * Handle errors based on error code and various other constructs
 * like transactions, try/catch, xact_abort
 */
static
void handle_error(PLtsql_execstate *estate, ErrorData *edata, SimpleEcontextStackEntry *volatile topEntry, bool *terminate_batch)
{
	record_error_state(estate);
	/* Mark transaction for termination */
	if (IsTransactionBlockActive() && (last_error_mapping_failed || abort_transaction(estate, edata)))
	{
		elog(DEBUG1, "TSQL TXN Mark transaction for rollback error mapping failed : %d", last_error_mapping_failed);
		AbortCurTransaction = true;
	}

	/* Recreate evaluation context in case needed */
	if (estate->use_shared_simple_eval_state && simple_econtext_stack == NULL)
		estate->simple_eval_estate = NULL;
	if (simple_econtext_stack == NULL || topEntry != simple_econtext_stack)
		pltsql_create_econtext(estate);

	/* In case of errors which terminate execution, let outer layer handle it */
	if (last_error_mapping_failed || abort_execution(estate, edata, terminate_batch))
	{
		elog(DEBUG1, "TSQL TXN Stop execution error mapping failed : %d current batch status %d", last_error_mapping_failed, *terminate_batch);
		FreeErrorData(edata);
		PG_RE_THROW();
	}

	/* Report error but let execution continue */
	EmitErrorReport();
	FlushErrorState();

	FreeErrorData(edata);
}

/*
 * To support undo in case of errors, dispatch statements inside
 * internal savepiont wrapper.
 */
static
int dispatch_stmt_handle_error(PLtsql_execstate *estate,
							   PLtsql_stmt *stmt,
							   bool *terminate_batch,
							   int active_non_tsql_procs,
							   int active_sys_functions)
{
	int rc = PLTSQL_RC_OK;
	volatile bool internal_sp_started;
	volatile int before_lxid = MyProc->lxid;
	volatile int before_subtxn_id;
	MemoryContext cur_ctxt = CurrentMemoryContext;
	ResourceOwner oldowner = CurrentResourceOwner;
	SimpleEcontextStackEntry *volatile topEntry = simple_econtext_stack;
	bool support_tsql_trans = pltsql_support_tsql_transactions();
	uint32 before_tran_count = NestedTranCount;

	PG_TRY();
	{
		/*
		 * If no transaction is running, start implicit transaction
		 * for qualified commands when implicit_transactions config
		 * option is on
		 */
		if (support_tsql_trans &&
			pltsql_implicit_transactions &&
			!IsTransactionBlockActive() &&
			is_start_implicit_txn_command(stmt))
		{
			elog(DEBUG2, "TSQL TXN Start implicit transaction");
			estate->impl_txn_type = PLTSQL_IMPL_TRAN_START;
			pltsql_start_txn();
		}
		else
			estate->impl_txn_type = PLTSQL_IMPL_TRAN_OFF;

		estate->tsql_trigger_flags = 0;

		/*
		 * Start an internal savepoint if transaction block
		 * is active to handle undo of failed command
		 * We do not start savepoint for batch commands as
		 * error handling must be taken care of at statement
		 * level
		 */
		if ((!pltsql_disable_internal_savepoint && !is_batch_command(stmt) && IsTransactionBlockActive()))
		{
			elog(DEBUG5, "TSQL TXN Start internal savepoint");
			BeginInternalSubTransaction(NULL);
			internal_sp_started = true;
			before_subtxn_id = GetCurrentSubTransactionId();
			MemoryContextSwitchTo(cur_ctxt);
		}
		else
			internal_sp_started = false;

		rc = dispatch_stmt(estate, stmt);

		/* Restore PG proc and sys function counts */
		pltsql_non_tsql_proc_entry_count = active_non_tsql_procs;
		pltsql_sys_func_entry_count = active_sys_functions;

		/* Release internal savepoint if it is current active savepoint */
		if (internal_sp_started &&
			before_lxid == MyProc->lxid &&
			before_subtxn_id == GetCurrentSubTransactionId())
		{
			elog(DEBUG5, "TSQL TXN Release internal savepoint");
			ReleaseCurrentSubTransaction();
			MemoryContextSwitchTo(cur_ctxt);
			if (!support_tsql_trans)
				CurrentResourceOwner = oldowner;
		}

		estate->impl_txn_type = PLTSQL_IMPL_TRAN_OFF;

		/* Handle transaction count mismatch for batch execution if implicit_transaction config is off*/
		topEntry = simple_econtext_stack;
		if (!pltsql_implicit_transactions &&
			is_batch_command(stmt) &&
			!is_part_of_pltsql_trigger(estate) &&
			before_tran_count != NestedTranCount)
			ereport(ERROR,
					(errcode(ERRCODE_T_R_INTEGRITY_CONSTRAINT_VIOLATION),
					 errmsg("Transaction count after execution indicates a mismatch number of BEGIN and COMMIT statements. Previous count %u current count %u", before_tran_count, NestedTranCount)));
	}
	PG_CATCH();
	{
		ErrorData *edata;
		int last_error;
		bool error_mapped;
		support_tsql_trans = pltsql_support_tsql_transactions();

		/* Close trigger nesting in engine */
		if (estate->tsql_trigger_flags & TSQL_TRIGGER_STARTED)
			EndCompositeTriggers(true);

		/*
		 * Non TDS clients will just throw the error in all cases
		 */
		if (!support_tsql_trans && !pltsql_sys_function_pop())
		{
			if (internal_sp_started)
			{
				elog(DEBUG1, "TSQL TXN PG semantics : Rollback internal savepoint");
				RollbackAndReleaseCurrentSubTransaction();
				MemoryContextSwitchTo(cur_ctxt);
				CurrentResourceOwner = oldowner;
			}
			else if (!IsTransactionBlockActive())
			{
				if (is_part_of_pltsql_trycatch_block(estate))
				{
					elog(DEBUG1, "TSQL TXN PG semantics : Rollback current transaction");
					HoldPinnedPortals();
					SPI_setCurrentInternalTxnMode(true);
					AbortCurrentTransaction();
					StartTransactionCommand();
					SPI_setCurrentInternalTxnMode(false);
					MemoryContextSwitchTo(cur_ctxt);
				}
			}
			else
			{
				elog(DEBUG1, "TSQL TXN PG semantics : Mark transaction for rollback");
				AbortCurTransaction = true;
			}
			/* Recreate evaluation context in case needed */
			if (estate->use_shared_simple_eval_state && simple_econtext_stack == NULL)
				estate->simple_eval_estate = NULL;
			if (simple_econtext_stack == NULL || topEntry != simple_econtext_stack)
				pltsql_create_econtext(estate);
			PG_RE_THROW();
		}

		MemoryContextSwitchTo(cur_ctxt);

		edata = CopyErrorData();
		error_mapped = get_tsql_error_code(edata, &last_error);
		exec_set_error(estate, last_error, edata->sqlerrcode, !error_mapped);
		if (internal_sp_started &&
			before_lxid == MyProc->lxid &&
			before_subtxn_id == GetCurrentSubTransactionId())
		{
			elog(DEBUG1, "TSQL TXN TSQL semantics : Rollback internal savepoint");
			/* Rollback internal savepoint if it is current savepoint */
			RollbackAndReleaseCurrentSubTransaction();
			MemoryContextSwitchTo(cur_ctxt);
		}
		else if (!IsTransactionBlockActive())
		{
			/*
			 * In case of no transaction, rollback the whole transaction
			 * to match auto commit behavior
			 */

			elog(DEBUG1, "TSQL TXN TSQL semantics : Rollback current transaction");
			/* Hold portals to make sure that cursors work */
			HoldPinnedPortals();
			AbortCurrentTransaction();
			StartTransactionCommand();
			MemoryContextSwitchTo(cur_ctxt);
		}
		else if (estate->tsql_trigger_flags & TSQL_TRAN_STARTED)
		{
			/*
			 * Trigger must run inside an explicit transaction
			 * In case of error, rollback the transaction
			 */
			elog(DEBUG1, "TSQL TXN TSQL semantics : Rollback internal transaction");
			HoldPinnedPortals();
			pltsql_rollback_txn();
			estate->tsql_trigger_flags &= ~TSQL_TRAN_STARTED;
			MemoryContextSwitchTo(cur_ctxt);
		}


		/*
		 * If we started an implicit transaction in the iterative executor
		 * but we encounter an error before we prepare the plan, we rollback
		 * the transaction to align with the default autocommit behaviour
		 *
		 * TODO: Test this
		 *
		 */
		if (pltsql_implicit_transactions &&
				IsTransactionBlockActive() && (estate->impl_txn_type == PLTSQL_IMPL_TRAN_START))
		{
			elog(DEBUG1, "TSQL TXN TSQL semantics : Rollback implicit transaction");
			pltsql_rollback_txn();
			MemoryContextSwitchTo(cur_ctxt);
		}

		estate->impl_txn_type = PLTSQL_IMPL_TRAN_OFF;

		/*
		 * In case of error, cleanup all snapshots.
		 * It is expected that next command will establish
		 * required new snapshot
		 */
		while (ActiveSnapshotSet())
			PopActiveSnapshot();
		if (pltsql_snapshot_portal != NULL)
			pltsql_snapshot_portal->portalSnapshot = NULL;

		handle_error(estate, edata, topEntry, terminate_batch);

		rc = PLTSQL_RC_OK;
	}
	PG_END_TRY();
	return rc;
}

bool is_recursive_trigger(PLtsql_execstate *estate){
	if (estate == NULL)
		return false;
	return is_part_of_pltsql_trigger(estate); 
}

#define INITIAL_ERR_STACK_SIZE 8
int exec_stmt_iterative(PLtsql_execstate *estate, ExecCodes *exec_codes, ExecConfig_t *config)
{
    size_t     *pc = &(estate->pc);
    size_t     size;
    int        rc = PLTSQL_RC_OK;
    ExecStat *stat = NULL;
    struct timeval proc_begin, stmt_begin;
	PLtsql_stmt *stmt = NULL;
	bool		terminate_batch = false;
	int			active_non_tsql_procs = pltsql_non_tsql_proc_entry_count;
	int			active_sys_functions = pltsql_sys_func_entry_count ;

    if (!exec_codes)
        ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR), errmsg("Empty execution code")));


    size = vec_size(exec_codes->codes);
    initialize_trace(config->trace_mode, &stat, &proc_begin, size);

	/* Guard against stack overflow due to complex, recursive statements */
	check_stack_depth();

    /* execution starts from here */

    /* initialize error context and stacks */
    estate->err_ctx_stack = create_vector2(sizeof(PLtsql_errctx* ), INITIAL_ERR_STACK_SIZE);

	PG_TRY();
	{	

		for ( *pc = 0 ; *pc < size; (*pc)++ )
		{
			int cur_pc = *pc;
			stmt = *(PLtsql_stmt **) vec_at(exec_codes->codes, cur_pc);

			pre_exec_measure(config->trace_mode, stat, &stmt_begin, cur_pc);

			reset_exec_error_data(estate);

			/* Let the protocol plugin know that we are about to execute this statement */
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->stmt_beg)
				((*pltsql_protocol_plugin_ptr)->stmt_beg) (estate, stmt);

			/* single statement execution starts from here */

			if (stmt->cmd_type == PLTSQL_STMT_SAVE_CTX)
			{
				/*
				 * This stmt is handled by executor's main loop,
				 * because sigsetjmp MUST be called in uppper stack without a function return
				 */
				PLtsql_stmt_save_ctx *save_err = (PLtsql_stmt_save_ctx *) stmt;
				PLtsql_errctx *cur_err_ctx = create_error_ctx(estate, save_err->target_pc);
				estate->err_text = gettext_noop("during statement block entry");

				/* Want to run statements inside function's memory context */
				MemoryContextSwitchTo(cur_err_ctx->oldcontext);

				if (sigsetjmp(cur_err_ctx->local_sigjmp_buf, 0) == 0)
				{
					PG_exception_stack = &cur_err_ctx->local_sigjmp_buf;

					estate->err_text = NULL;

					/* preserve context */
					vec_push_back(estate->err_ctx_stack, &cur_err_ctx);
					estate->cur_err_ctx_idx = vec_size(estate->err_ctx_stack) - 1;
				}
				else
				{
					int err_handler_pc;
					int i;
					PLtsql_errctx *cur_err_ctx = *(PLtsql_errctx **) vec_at(estate->err_ctx_stack,
																			estate->cur_err_ctx_idx);

					/* restore error context */
					err_handler_pc = cur_err_ctx->target_pc;

					/*  Cleanup dangling errors */
					for (i = (int) vec_size(estate->err_ctx_stack) - 1 ; i > (int) estate->cur_err_ctx_idx; i--)
						restore_ctx_partial2(estate);

					/* 
					 * partial1 is called here to avoid adding a new node to the exec code 
					 * Also set up cur_error so the error data is accessible
					 * inside the CATCH block.
					 */
					estate->cur_error->error = restore_ctx_partial1(estate);
					estate->cur_error->procedure = exec_state_call_stack->error_data.error_procedure;
					estate->cur_error->number = exec_state_call_stack->error_data.error_number;
					estate->cur_error->severity = exec_state_call_stack->error_data.error_severity;
					estate->cur_error->state = exec_state_call_stack->error_data.error_state;

					/* Goto error handling blocks */
					*pc = err_handler_pc - 1;  /* same as how goto handles PC */

					/* find new active index */
					for (i = (int) (estate->cur_err_ctx_idx) -1 ; i >= 0; i--)
					{
						PLtsql_errctx *err_ctx = *(PLtsql_errctx **) vec_at(estate->err_ctx_stack, i);
						if (!err_ctx->partial_restored)
						{
							estate->cur_err_ctx_idx = i;
							break;  /* cur_err_ctx_idx is pointing to this error context */
						}
					}
					if (last_error_mapping_failed || terminate_batch)
					{
						elog(DEBUG1, "TSQL TXN Ignore catch block error mapping failed : %d", last_error_mapping_failed);
						ReThrowError(estate->cur_error->error);
					}

					/* Restore PG proc and sys function counts */
					pltsql_non_tsql_proc_entry_count = active_non_tsql_procs;
					pltsql_sys_func_entry_count = active_sys_functions;
				}
			}
			else if (stmt->cmd_type == PLTSQL_STMT_RESTORE_CTX_FULL ||
					 stmt->cmd_type == PLTSQL_STMT_RESTORE_CTX_PARTIAL)
			{
				/* Restore context cannot run inside TRY/CATCH block */
				dispatch_stmt(estate, stmt);
			}
			else  /* normal execution */
			{
				int cur_rc;
				cur_rc = dispatch_stmt_handle_error(estate, stmt, &terminate_batch, active_non_tsql_procs, active_sys_functions);
				if (cur_rc == PLTSQL_RC_RETURN)
					rc = cur_rc;
			}

			/* single statement execution ends here */
			post_exec_measure(config->trace_mode, stat, &stmt_begin, cur_pc);

			/*
			 * We do not want to reset error code when
			 * executing control commands like RETURN,
			 * GOTO, CTX RESTORE etc. Batch commands will
			 * also not reset the error code for underlying
			 * statements.
			 * We check error_state to make sure that we do
			 * not reset error right after setting it.
			 * Also, we'll skip the reset if the SETERROR
			 * option is specified in RAISERROR stmt.
			 */
			if (!is_seterror_on(stmt) && 
				!is_control_command(stmt) &&
				!is_batch_command(stmt) &&
				exec_state_call_stack->error_data.error_estate == NULL)
				exec_set_error(estate, 0, 0, false /* error_mapping_failed */);

			/* Let the protocol plugin know that we have finished executing this statement */
			if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->stmt_end)
				((*pltsql_protocol_plugin_ptr)->stmt_end) (estate, stmt);
		}
	}
	PG_CATCH();
	{
		/*
		 * Let the protocol plugin know that there is an exception while  executing
		 * this statement.
		 * N.B. We can reach here for three error cases:
		 * 1. error that should terminate the entire batch
		 * 2. error that cannot be ignored inside the current exec_stmt_execsql
		 * 3. non-trivial server errors
		 * 4. there is a try-catch in the path
		 * It seems in all of the cases apart from 4, we terminate the entire
		 * batch of execution.  So, let the protocol layer know that we're
		 * terminating this batch and it should not send any done token from
		 * this level.
		 */
		if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->stmt_exception)
			((*pltsql_protocol_plugin_ptr)->stmt_exception) (estate, stmt,
															 (terminate_batch ||
															 !is_part_of_pltsql_trycatch_block(estate)));

		destroy_vector(estate->err_ctx_stack);
		/* execution ends here */
		finalize_trace(config->trace_mode, exec_codes, stat, &proc_begin);
		PG_RE_THROW();
	}
	PG_END_TRY();
	{
		reset_exec_error_data(estate);
		destroy_vector(estate->err_ctx_stack);
		/* execution ends here */
		finalize_trace(config->trace_mode, exec_codes, stat, &proc_begin);
	}

	return rc;
}

/***************************************************************************************
 *                         Execution Code Cleanup
 **************************************************************************************/

void free_exec_codes(ExecCodes *exec_codes)
{
    if (!exec_codes)
        return;

    destroy_vector(exec_codes->codes);
    if (exec_codes->proc_namespace)
        pfree(exec_codes->proc_namespace);
    if (exec_codes->proc_name)
        pfree(exec_codes->proc_name);
    pfree(exec_codes);
}

/***************************************************************************************
 *                         Helper Functions
 **************************************************************************************/

static 
void set_exec_error_data(char *procedure, int number, int severity, int state, bool rethrow)
{
	exec_state_call_stack->error_data.rethrow_error = rethrow;
	exec_state_call_stack->error_data.error_procedure = procedure;
	exec_state_call_stack->error_data.error_number = number;
	exec_state_call_stack->error_data.error_severity = severity;
	exec_state_call_stack->error_data.error_state = state;
}

static
void reset_exec_error_data(PLtsql_execstate *estate)
{
	exec_state_call_stack->error_data.xact_abort_on = false;
	exec_state_call_stack->error_data.rethrow_error = false;
	if (estate->trigdata == NULL && estate->evtrigdata == NULL)
		exec_state_call_stack->error_data.trigger_error = false;
	exec_state_call_stack->error_data.error_estate = NULL;
	exec_state_call_stack->error_data.error_procedure = NULL;
	exec_state_call_stack->error_data.error_number = -1;
	exec_state_call_stack->error_data.error_severity = -1;
	exec_state_call_stack->error_data.error_state = -1;
}

static
void assert_equal_estate_err(PLtsql_estate_err *err1, PLtsql_estate_err *err2)
{
	Assert(err1->error == err2->error &&
		   err1->procedure == err2->procedure &&
		   err1->number == err2->number &&
		   err1->severity == err2->severity &&
		   err1->state == err2->state);
}

static void read_raiserror_params(PLtsql_execstate *estate, List *params, int paramno,
								  char **msg, int *msg_id, int *severity, int *state)
{
	PLtsql_expr		*expr;
	Datum			val;
	bool			isnull = true;
	Oid				restype;
	int32			restypmod;

	Datum			*args;
	Oid				*argtypes;
	bool			*argisnull;
	StringInfoData	buf;

	Assert(paramno <= 23);

	/* msg_id or msg_str */
	expr = (PLtsql_expr *) list_nth(params, 0);
	val = exec_eval_expr(estate, expr, &isnull, &restype, &restypmod);
	if (isnull)
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				errmsg("msg_id/msg_str argument of RAISERROR is null")));

	/* Check if the input type is convertible to INT */
	if (TypeCategory(restype) == TYPCATEGORY_NUMERIC)
	{
		*msg_id = DatumGetInt32(exec_cast_value(estate, val, &isnull, 
												restype, restypmod, 
												INT4OID, -1));
		if (*msg_id < 50000)
			ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					errmsg("msg_id argument of RAISERROR should be no less than 50000")));
		*msg = psprintf("No. %d in sys.messages", *msg_id);
	}
	/* If not convertible to INT, try convert to string */
	else
	{
		*msg = convert_value_to_string(estate, val, restype);
		*msg_id = 50000;
	}

	/* severity */
	expr = (PLtsql_expr *) list_nth(params, 1);
	*severity = exec_eval_int(estate, expr, &isnull);
	if (isnull)
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				errmsg("severity argument of RAISERROR is null")));

	/* state */
	expr = (PLtsql_expr *) list_nth(params, 2);
	*state = exec_eval_int(estate, expr, &isnull);
	if (isnull)
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				errmsg("state argument of RAISERROR is null")));

	/* substitution arguments */
	args = (Datum *) palloc(sizeof(Datum) * (paramno - 3));
	argtypes = (Oid *) palloc(sizeof(Oid) * (paramno - 3));
	argisnull = (bool *) palloc(sizeof(bool) * (paramno - 3));

	for (int i = 0; i < paramno - 3; i++)
	{
		expr = (PLtsql_expr *) list_nth(params, i + 3);
		val = exec_eval_expr(estate, expr, &isnull, &restype, &restypmod);
		args[i] = val;
		argtypes[i] = restype;
		argisnull[i] = isnull;
	}
		
	initStringInfo(&buf);
	prepare_format_string(&buf, *msg, paramno - 3, args, argtypes, argisnull);
	*msg = buf.data;
}

static void read_throw_params(PLtsql_execstate *estate, List *params,
							  char **msg, int *err_no, int *state)
{
	PLtsql_expr *expr;
	Datum val;
	bool isnull = true;
	Oid restype;
	int32 restypmod;

	/* error number */
	expr = (PLtsql_expr *) list_nth(params, 0);
	*err_no = exec_eval_int(estate, expr, &isnull);
	if (isnull)
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				errmsg("err_no argument of THROW is null")));
	if (*err_no < 50000)
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("err_no argument of THROW should be no less than 50000")));
	
	expr = (PLtsql_expr *) list_nth(params, 1);
	val = exec_eval_expr(estate, expr, &isnull, &restype, &restypmod);
	if (isnull)
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				errmsg("message argument of THROW is null")));
	*msg = convert_value_to_string(estate, val, restype);

	/* state */
	expr = (PLtsql_expr *) list_nth(params, 2);
	*state = exec_eval_int(estate, expr, &isnull);
	if (isnull)
		ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				errmsg("state argument of THROW is null")));	
}

static char *get_proc_name(PLtsql_execstate *estate)
{
	char *result = NULL;
	if (estate && estate->func && estate->func->exec_codes &&
		estate->func->exec_codes->proc_name)
		result = pstrdup(estate->func->exec_codes->proc_name);
	return result;
}

static bool is_seterror_on(PLtsql_stmt *stmt)
{
	if (stmt->cmd_type != PLTSQL_STMT_RAISERROR)
		return false;
	if (!((PLtsql_stmt_raiserror *) stmt)->seterror)
		return false;
	return true;
}
