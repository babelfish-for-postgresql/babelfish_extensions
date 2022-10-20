#include "postgres.h"
#include "catalog/pg_collation.h"
#include "optimizer/pathnode.h"

#include "fmgr.h"
#include "instr.h"
#include "optimizer/planner.h"
#include "parser/parse_collate.h"
#include "parser/parse_target.h"

#include "collation.h"
#include "encoding/encoding.h"
#include "typecode.h"

extern Datum init_tcode_trans_tab(PG_FUNCTION_ARGS);

PG_MODULE_MAGIC;

const char *
BabelfishTranslateCollation(
	const char *collname, 
	Oid collnamespace, 
	int32 encoding);

CLUSTER_COLLATION_OID_hook_type prev_CLUSTER_COLLATION_OID_hook = NULL;
TranslateCollation_hook_type prev_TranslateCollation_hook = NULL;
PreCreateCollation_hook_type prev_PreCreateCollation_hook = NULL;

/* Module callbacks */
void	_PG_init(void);
void	_PG_fini(void);

void
_PG_init(void)
{
	FunctionCallInfo fcinfo  = NULL;  /* empty interface */
	collation_callbacks **coll_cb_ptr;

	init_instr();
	init_tcode_trans_tab(fcinfo);

	coll_cb_ptr = (collation_callbacks **) find_rendezvous_variable("collation_callbacks");
	*coll_cb_ptr = get_collation_callbacks();

	handle_type_and_collation_hook = handle_type_and_collation;
	avoid_collation_override_hook = check_target_type_is_sys_varchar;

	prev_CLUSTER_COLLATION_OID_hook = CLUSTER_COLLATION_OID_hook;
	CLUSTER_COLLATION_OID_hook = BABELFISH_CLUSTER_COLLATION_OID;

	prev_TranslateCollation_hook = TranslateCollation_hook;
	TranslateCollation_hook = BabelfishTranslateCollation;

	prev_PreCreateCollation_hook = PreCreateCollation_hook;
	PreCreateCollation_hook = BabelfishPreCreateCollation_hook;
}
void
_PG_fini(void)
{
	handle_type_and_collation_hook = NULL;
	avoid_collation_override_hook = NULL;
	CLUSTER_COLLATION_OID_hook = prev_CLUSTER_COLLATION_OID_hook;
	TranslateCollation_hook = prev_TranslateCollation_hook;
	PreCreateCollation_hook = prev_PreCreateCollation_hook;
}
