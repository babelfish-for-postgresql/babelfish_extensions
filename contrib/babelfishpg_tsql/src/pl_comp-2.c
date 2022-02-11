#include "postgres.h"

#include "pltsql.h"
#include "err_handler.h"
#include "iterative_exec.h"

/*
 * In CREATE PROC/FUNC, PG relays the body to pltsql compiler instead of full CREATE statement.
 * This causes an issue in errorpos of compilation time error and lineno of each pltsql statement.
 *
 * 1. errorpos of compilation time error: pl/pgsql has the same issue.
 * The approach of pl/pgsql is to transpose error position by comparing the full query string with query string of body.
 * It calculates the relative position of body position so it can adjust absolute error position.
 * pl/tsql cannot use the same approach because Portal has no original full query string.
 * Instead, ANTLR parser must run on the full query string so we can keep the start position of body to
 * pltsql_curr_compile_body_position. Finally we can adjust the error position based on start position of body.
 *
 * 2. lineno of PLtsql_stmt: T-SQL statement has a lineno relative to batch start of full query (i.e. CREATE PROC/FUNC)
 * We also keep the lineno of bod in pltsql_curr_compile_body_position so that we can adjust the lineno of each PLtsql_stmt.
 *
 * Both pltsql_curr_compile_body_lineno and pltsql_curr_compile_body_posistion will be set
 * when batch level statment is compiled and it will be reset when new SQL batch comes in.
 */
int pltsql_curr_compile_body_position; /* cursor position of function/procedure body in CREATE */
int pltsql_curr_compile_body_lineno; /* lineno of function/procedure body in CREATE */

/*
 * Used in pltsql_compile_error_callback. Copied from pg_proc.c
 * Almost same as original one but not trying to find exact cursor position from original input query. (see the comment above)
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
