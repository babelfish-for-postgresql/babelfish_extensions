#include "postgres.h"

#include "commands/explain.h"

#include "pl_explain.h"
#include "pltsql.h"


extern PLtsql_execstate *get_outermost_tsql_estate(int *nestlevel);
extern PLtsql_execstate *get_current_tsql_estate();
bool		pltsql_explain_only = false;
bool		pltsql_explain_analyze = false;
bool		pltsql_explain_verbose = false;
bool		pltsql_explain_costs = true;
bool		pltsql_explain_settings = false;
bool		pltsql_explain_buffers = false;
bool		pltsql_explain_wal = false;
bool		pltsql_explain_timing = true;
bool		pltsql_explain_summary = true;
int			pltsql_explain_format = EXPLAIN_FORMAT_TEXT;

static ExplainInfo *get_last_explain_info();

bool
is_explain_analyze_mode()
{
	return (pltsql_explain_analyze && !pltsql_explain_only);
}

static ExplainInfo *
get_last_explain_info()
{
	PLtsql_execstate *pltsql_estate;
	int			nestlevel;

	if (!pltsql_explain_analyze && !pltsql_explain_only)
		return NULL;

	pltsql_estate = get_outermost_tsql_estate(&nestlevel);
	if (!pltsql_estate || !pltsql_estate->explain_infos)
		return NULL;

	return (ExplainInfo *) llast(pltsql_estate->explain_infos);
}

void
increment_explain_indent()
{
	ExplainInfo *einfo = get_last_explain_info();

	if (einfo)
		einfo->next_indent++;
}

void
decrement_explain_indent()
{
	ExplainInfo *einfo = get_last_explain_info();

	if (einfo)
		einfo->next_indent--;
}

void
append_explain_info(QueryDesc *queryDesc, const char *queryString)
{
	PLtsql_execstate *pltsql_estate;
	MemoryContext oldcxt;
	ExplainState *es;
	ExplainInfo *einfo;
	const char *initial_database;
	size_t		indent;
	int			nestlevel;

	if (!pltsql_explain_analyze && !pltsql_explain_only)
		return;

	/* EXPLAIN ANALYZE needs queryDesc */
	if (pltsql_explain_analyze && !queryDesc)
		return;

	/*
	 * In some cases, PLtsql_execstate can be created during ExecutorRun. For
	 * example, in the case of ITVF (Inline Table-Valued Function),
	 * exec_stmt_return_query(...) is called inside
	 * execute_plan_and_push_result(...) and those two functions have
	 * different PLtsql_execstate.
	 *
	 * To show proper query plans we should gather all ExplainInfos until the
	 * end of a batch execution. So, we need the outermost PLtsql_execstate
	 * and add ExplainInfo to it.
	 */
	pltsql_estate = get_outermost_tsql_estate(&nestlevel);
	if (!pltsql_estate)
		return;

	/*
	 * There are some cases where oldcxt is released before the end of a batch
	 * exeuction, e.g., INSERT statements. So, we should choose the parent
	 * memory context for ExplainInfo.
	 */
	oldcxt = MemoryContextSwitchTo(pltsql_estate->stmt_mcontext_parent);

	if (queryDesc && queryDesc->totaltime)
	{
		/*
		 * Make sure stats accumulation is done.  (Note: it's okay if several
		 * levels of hook all do this.)
		 */
		InstrEndLoop(queryDesc->totaltime);
	}

	if (pltsql_estate->explain_infos)
	{
		ExplainInfo *last_einfo = (ExplainInfo *) llast(pltsql_estate->explain_infos);

		indent = last_einfo->next_indent;
		initial_database = last_einfo->initial_database;
	}
	else
	{
		indent = 0;
		initial_database = NULL;
	}

	es = NewExplainState();

	es->analyze = is_explain_analyze_mode();
	es->verbose = pltsql_explain_verbose;
	es->costs = pltsql_explain_costs;
	es->buffers = (es->analyze && pltsql_explain_buffers);
	es->wal = (es->analyze && pltsql_explain_wal);
	es->timing = (es->analyze && pltsql_explain_timing);
	es->summary = (es->analyze && pltsql_explain_summary);
	es->settings = pltsql_explain_settings;
	if (es->analyze)
	{
		es->indent = 0;
		es->format = pltsql_explain_format;
	}
	else
	{
		es->indent = (nestlevel > 0) ? (nestlevel - 1) + indent : indent;
		es->format = EXPLAIN_FORMAT_TEXT;
	}

	ExplainBeginOutput(es);
	if (queryDesc)
	{
		ExplainQueryText(es, queryDesc);
		ExplainPrintPlan(es, queryDesc);
		if (es->analyze)
			ExplainPrintTriggers(es, queryDesc);
		if (es->costs)
			ExplainPrintJITSummary(es, queryDesc);
		if (es->summary)
		{
			PLtsql_execstate *time_state = get_current_tsql_estate();

			ExplainPropertyFloat("Planning Time", "ms", 1000.0 * INSTR_TIME_GET_DOUBLE(time_state->planning_end), 3, es);
			INSTR_TIME_SET_CURRENT(time_state->execution_end);
			INSTR_TIME_SUBTRACT(time_state->execution_end, time_state->execution_start);
			ExplainPropertyFloat("Execution Time", "ms", 1000.0 * INSTR_TIME_GET_DOUBLE(time_state->execution_end), 3, es);
		}

	}
	else if (queryString)
	{
		/*
		 * In EXPLAIN ONLY mode, queryDesc can be null if it is called from
		 * ProcessUtility()
		 */
		ExplainPropertyText("Query Text", queryString, es);
	}
	else
	{
		return;
	}
	ExplainEndOutput(es);

	/* Remove last line break */
	if (es->str->len > 0 && es->str->data[es->str->len - 1] == '\n')
		es->str->data[--es->str->len] = '\0';

	/* Fix JSON to output an object */
	if (es->format == EXPLAIN_FORMAT_JSON)
	{
		es->str->data[0] = '{';
		es->str->data[es->str->len - 1] = '}';
	}

	einfo = (ExplainInfo *) palloc0(sizeof(ExplainInfo));
	einfo->data = pstrdup(es->str->data);
	einfo->initial_database = initial_database;
	einfo->next_indent = indent;
	pltsql_estate->explain_infos = lappend(pltsql_estate->explain_infos, einfo);

	/* Recover the memory context */
	MemoryContextSwitchTo(oldcxt);
}

void
set_explain_database(const char *db_name)
{
	ExplainInfo *einfo = get_last_explain_info();

	einfo->initial_database = db_name;
}

const char *
get_explain_database(void)
{
	ExplainInfo *einfo = get_last_explain_info();

	if (einfo != NULL)
		return einfo->initial_database;
	return NULL;
}

/*
 * The main purpose of this function is for displaying TSQL statements such as PRINT
 * and THROW during explain.  Since babelfish represents most expressions internally
 * as SELECT statements including scalars, this function allows us to translate to more
 * native looking TSQL by removing the redundant SELECT statements.
 *
 * This functions validates that the expression object exists, has a query text,
 * and returns a pointer to a new string representing the expression minus the "SELECT "
*/
const char *
strip_select_from_expr(void *pltsql_expr)
{
	PLtsql_expr *expr;

	expr = (PLtsql_expr *) pltsql_expr;
	if (expr == NULL || expr->query == NULL || strlen(expr->query) <= 7)
	{
		ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
						errmsg("invalid expression %p", (void *) expr)));
	}

	return pstrdup(&expr->query[7]);
}
