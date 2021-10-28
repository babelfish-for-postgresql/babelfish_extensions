
/*-------------------------------------------------------------------------
 *
 * tds.c
 *	  TDS Listener extension entrypoint
 *
 * Portions Copyright (c) 2020, AWS
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  contrib/babelfishpg_tds/src/backend/tds/tds.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/printtup.h"
#include "src/include/tds_int.h"
#include "src/include/tds_secure.h"
#include "src/include/tds_instr.h"
#include "commands/defrem.h"
#include "fmgr.h"
#include "miscadmin.h"
#include "libpq/libpq.h"
#include "libpq/libpq-be.h"
#include "miscadmin.h"
#include "parser/parse_expr.h"
#include "postmaster/postmaster.h"
#include "utils/elog.h"
#include "utils/pidfile.h"
#include "utils/lsyscache.h"

#include "src/include/err_handler.h"

PG_MODULE_MAGIC;

extern void _PG_init(void);
extern void _PG_fini(void);

TdsInstrPlugin **tds_instr_plugin_ptr = NULL;

/* Hook for plugins */
static struct PLtsql_protocol_plugin pltsql_plugin_handler;
PLtsql_protocol_plugin *pltsql_plugin_handler_ptr = &pltsql_plugin_handler;

static Oid tvp_lookup(const char *relname, Oid relnamespace);
static relname_lookup_hook_type prev_relname_lookup_hook = NULL;

/*
 * Module initialization function
 */
void
_PG_init(void)
{
	/* Be sure we do initialization only once */
	static bool inited = false;

	if (inited)
		return;

	/* Must be loaded with shared_preload_libaries */
	if (!process_shared_preload_libraries_in_progress)
		ereport(ERROR, (errcode(ERRCODE_OBJECT_NOT_IN_PREREQUISITE_STATE),
				errmsg("babelfishpg_tds must be loaded via shared_preload_libraries")));

	TdsDefineGucs();

	tds_instr_plugin_ptr = (TdsInstrPlugin **) find_rendezvous_variable("TdsInstrPlugin");

	pe_init();

	prev_relname_lookup_hook = relname_lookup_hook;
	relname_lookup_hook = tvp_lookup;

	inited = true;
}

/*
 * Module unload function
 */
void
_PG_fini(void)
{
	pe_fin();
	relname_lookup_hook = prev_relname_lookup_hook;
}

/*
 * For table-valued parameter that's not handled by pltsql, we set up a hook so
 * that we can look up a TVP's underlying table.
 */
static Oid
tvp_lookup(const char *relname, Oid relnamespace)
{
	Oid 		relid;
	ListCell 	*lc;

	if (prev_relname_lookup_hook)
		relid = (*prev_relname_lookup_hook) (relname, relnamespace);
	else
		relid = get_relname_relid(relname, relnamespace);

	/*
	 * If we find a TVP whose name matches relname, return its
	 * underlying table's relid. Otherwise, just return relname's relid.
	 */
	foreach (lc, tvp_lookup_list)
	{
		TvpLookupItem *item = (TvpLookupItem *) lfirst(lc);

		if (strcmp(relname, item->name) == 0)
		{
			if (OidIsValid(item->tableRelid))
				return item->tableRelid;
			else
				return get_relname_relid(item->tableName, relnamespace);
		}
	}

	return relid;
}
