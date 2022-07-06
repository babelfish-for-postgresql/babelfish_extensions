#include "postgres.h"

#include "fmgr.h"
#include "instr.h"
#include "parser/parse_collate.h"
#include "parser/parse_target.h"

#include "babelfishpg_common.h"
#include "typecode.h"

extern Datum init_tcode_trans_tab(PG_FUNCTION_ARGS);

PG_MODULE_MAGIC;

/* Hook for plugins */
static struct PLtsql_protocol_plugin pltsql_plugin_handler;
PLtsql_protocol_plugin *pltsql_plugin_handler_ptr = &pltsql_plugin_handler;

/* Module callbacks */
void	_PG_init(void);
void	_PG_fini(void);

void
_PG_init(void)
{
	FunctionCallInfo fcinfo  = NULL;  /* empty interface */
	PLtsql_protocol_plugin **pltsql_plugin_handler_ptr_tmp;

	init_instr();
	init_tcode_trans_tab(fcinfo);

	/*
	 * TODO: currently we have added dependency of tsql extension on common extension 
	 * which needs to be fixed.
	 */

	/* Set up a rendezvous point with pltsql plugin */
	pltsql_plugin_handler_ptr_tmp = (PLtsql_protocol_plugin **) find_rendezvous_variable("PLtsql_protocol_plugin");

	/* unlikely */
	if (!pltsql_plugin_handler_ptr_tmp)
		elog(ERROR, "failed to setup rendezvous variable for pltsql plugin");

	*pltsql_plugin_handler_ptr_tmp = pltsql_plugin_handler_ptr;

	handle_type_and_collation_hook = handle_type_and_collation;
	avoid_collation_override_hook = check_target_type_is_sys_varchar;
}
void
_PG_fini(void)
{
	handle_type_and_collation_hook = NULL;
	avoid_collation_override_hook = NULL;
}
