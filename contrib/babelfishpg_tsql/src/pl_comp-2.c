#include "postgres.h"

#include "pltsql.h"
#include "err_handler.h"
#include "iterative_exec.h"

int  pltsql_error_lineno;

/*
 * Used in pltsql_compile_error_callback. Copied from pg_proc.c
 * Almost same as original one but not trying to find exact cursor position from original input query.
 */
bool pltsql_function_parse_error_transpose(const char *prosrc);
void apply_post_compile_actions(PLtsql_function *func, InlineCodeBlockArgs *args);

extern int cache_compiled_batch(PLtsql_function *func);
extern void cache_inline_args(PLtsql_function *func, InlineCodeBlockArgs *args);
extern SPIPlanPtr prepare_exec_codes(PLtsql_function *func, ExecCodes *exec_codes);
extern void cleanup_temporal_plan(ExecCodes *exec_codes);

/*
 * Adjust a syntax error occurring inside the function body of a CREATE
 * FUNCTION or DO command.  This can be used by any function validator or
 * anonymous-block handler, not only for SQL-language functions.
 * It is assumed that the syntax error position is initially relative to the
 * function body string (as passed in).  If possible, we adjust the position
 * to reference the original command text; if we can't manage that, we set
 * up an "internal query" syntax error instead.
 *
 * Returns true if a syntax error was processed, false if not.
 */
bool pltsql_function_parse_error_transpose(const char *prosrc)
{
	int			origerrposition;

	/*
	 * Nothing to do unless we are dealing with a syntax error that has a
	 * cursor position.
	 *
	 * Some PLs may prefer to report the error position as an internal error
	 * to begin with, so check that too.
	 */
	origerrposition = geterrposition();
	if (origerrposition <= 0)
	{
		origerrposition = getinternalerrposition();
		if (origerrposition <= 0)
			return false;
	}

	/*
	 * NOTE: In batch mode, we can't access ActivePortal to queryText.
	 * Skip finding exact cursor position from original query block.
	 * This behavior just affects the cursor position of error message and even sqlcmd doesn't care of it.
	 */


	/*
	 * If unsuccessful, convert the position to an internal position
	 * marker and give the function text as the internal query.
	 */
	errposition(0);
	internalerrposition(origerrposition);
	internalerrquery(prosrc);

	return true;
}

void apply_post_compile_actions(PLtsql_function *func, InlineCodeBlockArgs *args)
{
	if (OPTION_ENABLED(args, PREPARE_PLAN))
	{
		SPIPlanPtr plan;
		Assert(func->exec_codes);
		plan = prepare_exec_codes(func, func->exec_codes);
		if(plan)
		{
			if (OPTION_ENABLED(args, SEND_METADATA))
			{
				if (*pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->send_column_metadata)
				{
					List	   *plansources;
					plansources = SPI_plan_get_plan_sources(plan);
					if (list_length(plansources) == 1)
					{
						CachedPlanSource *plansource = (CachedPlanSource *) linitial(plansources);
						List *targetlist = CachedPlanGetTargetList(plansource, NULL);

						/* Only SELECT command type should send column metadata */
						if (plansource->commandTag == CMDTAG_SELECT)
							(*(*pltsql_protocol_plugin_ptr)->send_column_metadata)(plansource->resultDesc, targetlist, NULL);
					}
				}

			}
			cleanup_temporal_plan(func->exec_codes);
		}
	}

	if (OPTION_ENABLED(args, CACHE_PLAN))
	{
		cache_inline_args(func, args);
		args->handle = cache_compiled_batch(func);
	}
}
