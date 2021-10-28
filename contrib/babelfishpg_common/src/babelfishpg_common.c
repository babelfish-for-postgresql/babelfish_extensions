#include "postgres.h"

#include "fmgr.h"
#include "instr.h"

extern Datum init_tcode_trans_tab(PG_FUNCTION_ARGS);

PG_MODULE_MAGIC;

/* Module callbacks */
void	_PG_init(void);
void	_PG_fini(void);

void
_PG_init(void)
{
	FunctionCallInfo fcinfo  = NULL;  /* empty interface */

	init_instr();
	init_tcode_trans_tab(fcinfo);
}

void
_PG_fini(void)
{
}
