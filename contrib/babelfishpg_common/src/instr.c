#include "postgres.h"
#include "fmgr.h"

#include "instr.h"

instr_plugin *instr_plugin_ptr = NULL;

void
init_instr(void)
{
	instr_plugin **rendezvous;

	rendezvous = (instr_plugin **) find_rendezvous_variable("PLtsql_instr_plugin");

	if (rendezvous && *rendezvous)
		instr_plugin_ptr = *rendezvous;
}
