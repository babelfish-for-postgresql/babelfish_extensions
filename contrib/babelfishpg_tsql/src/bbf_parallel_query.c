
#include "postgres.h"

#include "access/parallel.h"
#include "catalog/pg_class.h"
#include "executor/executor.h"
#include "fmgr.h"
#include "nodes/bitmapset.h"
#include "nodes/execnodes.h"
#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "nodes/pg_list.h"
#include "miscadmin.h"
#include "parser/parse_relation.h"
#include "parser/parser.h"
#include "storage/shm_toc.h"
#include "utils/acl.h"
#include "utils/elog.h"
#include "utils/lsyscache.h"
#include "utils/queryenvironment.h"

#include "bbf_parallel_query.h"
#include "pltsql.h"

/*
 * temp_relids - maintains relid list of temp table shared by leader node. This should be
 * strictly accessed within parallel worker context.
 * Here, we keep two bitmapset, one for relids <= INT32_MAX and another for relids > INT32_MAX
 * because OID is unsigned int and bitmapset will not be handle OID > INT32_MAX.
 * Overall,
 * 	if relid <= INT32_MAX
 * 		add relid to temp_relids
 * 	else
 * 		add (relid - INT32_MAX - 1) to temp_relids_beyond_int32
 */
static Bitmapset   *temp_relids = NULL;
static Bitmapset   *temp_relids_beyond_int32 = NULL;

/*
 * string representation of list of temp table oids computed by Leader node to be shared
 * with parallel worker. Check comment above temp_relids_beyond_int32 for reason to
 * keep two bitmapset string.
 */
static char		   *temp_relids_str = NULL;
static char		   *temp_relids_beyond_int32_str = NULL;

/*
 * In Babelfish, Any user under given session should be able access the temp tables. 
 * And Postgres doesn't allow parallel scan on temp tables. But it still does the permission
 * check on temp tables under parallel workers. But since Babelfish temp tables implemented
 * using ENR, it can't be accessed inside Parallel worker.
 * 
 * So we would like to avoid permission checking on temp tables under parallel workers while
 * ensuring that Leader node does require permission checks on temp table.
 * 
 * In order to achieve this, we (probably re)do permission checks on temp tables and share
 * the list of oids with parallel worker. And parallel worker will avoid permission check
 * on these oids.
 */


/*
 * bbf_ExecInitParallelPlan -- implements ExecInitParallelPlan_hook.
 * It iterates through es_range_tables checking persistence of given relation. Probably,
 * re-do permission checking (better to redo perm checking instead of never doing it) if
 * relation is temp table and adds oid/relid to the set. This set will be shared with
 * parallel worker so that parallel worker avoids permission check on temp tables.
 * When estimate = true passed then caller wants to estimate a dynamic shared memory (DSM)
 * needed by this extension to communicate additional context.
 * When estimate = false then caller wants to insert additional context to DSM.
 */
void 
bbf_ExecInitParallelPlan(EState *estate, ParallelContext *pcxt, bool estimate)
{
	if (prev_ExecInitParallelPlan_hook)
		(*prev_ExecInitParallelPlan_hook)(estate, pcxt, estimate);

	/*
	 * Dialect check is not sufficient because parallel worker might be needed while
	 * doing plpgsql function scan on leader node.
	 */
	if (!IS_TDS_CONN())
		return;

	if (estimate)
	{
		ListCell   *lc;
		Bitmapset  *temp_relids_local = NULL;				/* For relid <= INT32_MAX */
		Bitmapset  *temp_relids_beyond_int32_local = NULL;	/* For relid > INT32_MAX */
		temp_relids_str = NULL;
		temp_relids_beyond_int32_str = NULL;

		foreach(lc, estate->es_range_table)
		{
			RTEPermissionInfo *perminfo;
			RangeTblEntry *rte = (RangeTblEntry *) lfirst(lc);
			if (rte->rtekind == RTE_RELATION &&
				OidIsValid(rte->relid) &&
				get_rel_persistence(rte->relid) == RELPERSISTENCE_TEMP)
			{
				if (estate->es_plannedstmt == NULL ||
					list_length(estate->es_plannedstmt->permInfos) == 0)
				{
					/* If there is RTE present then corresponding permInfo must be there */
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("Failed to check permission of the temporary table because " \
									"corresponding Perminfo is not found while launching parallel worker(s)")));
				}

				/* getRTEPermissionInfo would return valid perfInfo, error will be raised otherwise */
				perminfo = getRTEPermissionInfo(estate->es_plannedstmt->permInfos, rte);
				/* probably (re)do perm check */
				if (!ExecCheckOneRelPerms_wrapper(perminfo))
				{
					aclcheck_error(ACLCHECK_NO_PRIV,
									get_relkind_objtype(get_rel_relkind(perminfo->relid)),
									get_rel_name(perminfo->relid));
				}
				if (rte->relid <= (Oid) INT32_MAX)
					temp_relids_local = bms_add_member(temp_relids_local, rte->relid);
				else
					temp_relids_beyond_int32_local = bms_add_member(temp_relids_beyond_int32_local, (rte->relid - (Oid) INT32_MAX - 1U));
			}
		}
		temp_relids_str = bmsToString(temp_relids_local);
		temp_relids_beyond_int32_str = bmsToString(temp_relids_beyond_int32_local);

		/*
		 * Estimate extra context for Babelfish
		 */
		shm_toc_estimate_chunk(&pcxt->estimator, strlen(temp_relids_str) + 1);
		shm_toc_estimate_keys(&pcxt->estimator, 1);
		shm_toc_estimate_chunk(&pcxt->estimator, strlen(temp_relids_beyond_int32_str) + 1);
		shm_toc_estimate_keys(&pcxt->estimator, 1);
	}
	else
	{
		char *temp_relids_space;

		/*temp_relids_str will never be NULL even if there is no temp tables in the query. */
		if (temp_relids_str == NULL || temp_relids_beyond_int32_str == NULL)
		{
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Unexpected list of temp table relids")));
		}

		temp_relids_space = shm_toc_allocate(pcxt->toc, strlen(temp_relids_str) + 1);
		memcpy(temp_relids_space, temp_relids_str, strlen(temp_relids_str) + 1);
		shm_toc_insert(pcxt->toc, BABELFISH_PARALLEL_KEY_TEMP_RELIDS, temp_relids_space);

		temp_relids_space = shm_toc_allocate(pcxt->toc, strlen(temp_relids_beyond_int32_str) + 1);
		memcpy(temp_relids_space, temp_relids_beyond_int32_str, strlen(temp_relids_beyond_int32_str) + 1);
		shm_toc_insert(pcxt->toc, BABELFISH_PARALLEL_KEY_TEMP_RELIDS_BEYOND_INT32, temp_relids_space);

		/* And reset temp_relids_str and temp_relids_beyond_int32_str */
		pfree(temp_relids_str);
		pfree(temp_relids_beyond_int32_str);
		temp_relids_str = NULL;
		temp_relids_beyond_int32_str = NULL;
	}
}
/*
 * bbf_ParallelQueryMain -- implements ParallelQueryMain_hook.
 * It constructs temp_relids which represents oid list of temp tables communicated by Leader node.
 * warning: should stricktly call under parallel worker.
 */
void
bbf_ParallelQueryMain(shm_toc *toc)
{
	if (prev_ParallelQueryMain_hook)
		(*prev_ParallelQueryMain_hook)(toc);

	/* Another line of defense to make sure no regular backend calls this function. */
	if (!IsBabelfishParallelWorker())
	{
		return;
	}

	temp_relids = (Bitmapset *) stringToNode(shm_toc_lookup(toc,
															BABELFISH_PARALLEL_KEY_TEMP_RELIDS,
															false));
	temp_relids_beyond_int32 = (Bitmapset *) stringToNode(shm_toc_lookup(toc,
															BABELFISH_PARALLEL_KEY_TEMP_RELIDS_BEYOND_INT32,
															false));
}

/*
 * bbf_ExecCheckOneRelPerms -- implements ExecCheckOneRelPerms_hook.
 * Returns true if this is Babelfish parallel worker and provided relid is Babelfish temp table. 
 * Note that temp_relids must have communicated by Leader node.
 */
bool
bbf_ExecCheckOneRelPerms(RTEPermissionInfo *perminfo)
{
	if (!OidIsValid(perminfo->relid))
	{
		ereport(ERROR,
			(errcode(ERRCODE_INTERNAL_ERROR),
			 errmsg("Invalid Oid is found while checking permission of the relation")));
	}

	/* Let regular permission check happen if its not Babelfish parallel worker. */
	if (!IsBabelfishParallelWorker())
	{
		return false;
	}

	if (perminfo->relid <= (Oid) INT32_MAX)
		return bms_is_member(perminfo->relid, temp_relids);
	else
		return bms_is_member((perminfo->relid - (Oid) INT32_MAX - 1U), temp_relids_beyond_int32);
}

