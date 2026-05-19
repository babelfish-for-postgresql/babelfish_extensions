/*
 * namespace_support.c
 *
 * Implementation of is_babelfish_namespace(oid) with:
 * - Cached OID set for fast per-row execution
 * - Planner support function for accurate selectivity estimates
 */
#include "postgres.h"

#include "access/htup_details.h"
#include "access/table.h"
#include "access/tableam.h"
#include "catalog/pg_statistic.h"
#include "catalog/pg_proc_d.h"
#include "catalog/pg_class_d.h"
#include "datatype/timestamp.h"
#include "executor/tuptable.h"
#include "fmgr.h"
#include "miscadmin.h"
#include "nodes/nodeFuncs.h"
#include "nodes/plannodes.h"
#include "nodes/supportnodes.h"
#include "optimizer/optimizer.h"
#include "parser/parsetree.h"
#include "utils/builtins.h"
#include "utils/hsearch.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/selfuncs.h"
#include "utils/snapmgr.h"
#include "utils/syscache.h"

#include "catalog.h"
#include "guc.h"
#include "pltsql.h"
#include "session.h"

PG_FUNCTION_INFO_V1(is_babelfish_namespace);
PG_FUNCTION_INFO_V1(is_babelfish_namespace_support);

/* Cached namespace OID set */
static HTAB *ns_oid_cache = NULL;
static int16 ns_cache_dbid = 0;
static TransactionId ns_cache_xid = InvalidTransactionId;

/*
 * Helper: get the current database ID, handling both TDS and psql sessions.
 */
static int16
get_current_dbid(void)
{
	int16	dbid = get_cur_db_id();

	if (!DbidIsValid(dbid) && !IS_TDS_CLIENT() && pltsql_psql_logical_babelfish_db_name)
		dbid = get_db_id(pltsql_psql_logical_babelfish_db_name);

	return dbid;
}

/*
 * Build or refresh the namespace OID cache.
 * Queries babelfish_namespace_ext for the current database and stores
 * all matching namespace OIDs in a hash table.
 */
static void
ensure_ns_cache(int16 cur_dbid)
{
	TransactionId cur_xid = GetCurrentTransactionId();

	/* Return if cache is still valid for this transaction and dbid */
	if (ns_oid_cache != NULL && ns_cache_dbid == cur_dbid && ns_cache_xid == cur_xid)
		return;

	/* Destroy old cache if exists */
	if (ns_oid_cache != NULL)
	{
		hash_destroy(ns_oid_cache);
		ns_oid_cache = NULL;
	}

	/* Create new hash table */
	{
		HASHCTL		hashctl;
		Relation	rel;
		TableScanDesc scan;

		memset(&hashctl, 0, sizeof(hashctl));
		hashctl.keysize = sizeof(Oid);
		hashctl.entrysize = sizeof(Oid);
		hashctl.hcxt = TopMemoryContext;
		ns_oid_cache = hash_create("bbf_ns_oid_cache", 64, &hashctl,
								   HASH_ELEM | HASH_BLOBS | HASH_CONTEXT);

		/* Scan babelfish_namespace_ext for matching dbid */
		rel = table_open(get_relname_relid("babelfish_namespace_ext",
										   get_namespace_oid("sys", false)),
						 AccessShareLock);
		scan = table_beginscan(rel, GetActiveSnapshot(), 0, NULL);

		{
			TupleTableSlot *slot = table_slot_create(rel, NULL);

			while (table_scan_getnextslot(scan, ForwardScanDirection, slot))
			{
				bool	isnull;
				Datum	dbid_datum;
				Datum	nspname_datum;
				int16	row_dbid;
				char   *nspname;
				Oid		ns_oid;

				dbid_datum = slot_getattr(slot, 2, &isnull); /* dbid column */
				if (isnull)
					continue;
				row_dbid = DatumGetInt16(dbid_datum);
				if (row_dbid != cur_dbid)
					continue;

				nspname_datum = slot_getattr(slot, 1, &isnull); /* nspname column */
				if (isnull)
					continue;
				nspname = NameStr(*DatumGetName(nspname_datum));

				ns_oid = get_namespace_oid(nspname, true);
				if (OidIsValid(ns_oid))
				{
					bool	found;
					hash_search(ns_oid_cache, &ns_oid, HASH_ENTER, &found);
				}
			}

			ExecDropSingleTupleTableSlot(slot);
		}

		table_endscan(scan);
		table_close(rel, AccessShareLock);
	}

	ns_cache_dbid = cur_dbid;
	ns_cache_xid = cur_xid;
}

/*
 * is_babelfish_namespace(oid) - returns true if the given namespace OID
 * belongs to the current Babelfish database. Uses cached OID set.
 */
Datum
is_babelfish_namespace(PG_FUNCTION_ARGS)
{
	Oid		ns_oid = PG_GETARG_OID(0);
	int16	cur_dbid;
	bool	found;

	if (!OidIsValid(ns_oid))
		PG_RETURN_BOOL(false);

	cur_dbid = get_current_dbid();
	if (!DbidIsValid(cur_dbid))
		PG_RETURN_BOOL(false);

	ensure_ns_cache(cur_dbid);

	hash_search(ns_oid_cache, &ns_oid, HASH_FIND, &found);
	PG_RETURN_BOOL(found);
}

/*
 * compute_namespace_selectivity - compute selectivity from MCV stats
 */
static Selectivity
compute_namespace_selectivity(SupportRequestSelectivity *req)
{
	Node	   *arg;
	Var		   *var;
	Oid			relid;
	HeapTuple	statsTuple;
	Selectivity sel = -1.0;
	int16		cur_dbid;
	RangeTblEntry *rte;

	if (list_length(req->args) != 1)
		return -1.0;

	arg = (Node *) linitial(req->args);
	while (IsA(arg, RelabelType))
		arg = (Node *) ((RelabelType *) arg)->arg;

	if (!IsA(arg, Var))
		return -1.0;

	var = (Var *) arg;
	cur_dbid = get_current_dbid();
	if (!DbidIsValid(cur_dbid))
		return -1.0;

	if (req->root == NULL || req->root->parse == NULL)
		return -1.0;
	if (var->varno < 1 || var->varno > list_length(req->root->parse->rtable))
		return -1.0;

	rte = rt_fetch(var->varno, req->root->parse->rtable);
	if (rte == NULL || rte->rtekind != RTE_RELATION)
		return -1.0;

	relid = rte->relid;
	if (!OidIsValid(relid))
		return -1.0;

	statsTuple = SearchSysCache3(STATRELATTINH,
								ObjectIdGetDatum(relid),
								Int16GetDatum(var->varattno),
								BoolGetDatum(false));
	if (!HeapTupleIsValid(statsTuple))
		return -1.0;

	{
		AttStatsSlot sslot;
		bool		have_mcv;

		have_mcv = get_attstatsslot(&sslot, statsTuple,
									STATISTIC_KIND_MCV, InvalidOid,
									ATTSTATSSLOT_VALUES | ATTSTATSSLOT_NUMBERS);
		if (have_mcv && sslot.nvalues > 0)
		{
			int		i;

			/* Build cache for selectivity computation */
			ensure_ns_cache(cur_dbid);
			sel = 0.0;

			for (i = 0; i < sslot.nvalues; i++)
			{
				Oid		mcv_oid = DatumGetObjectId(sslot.values[i]);
				bool	found;

				hash_search(ns_oid_cache, &mcv_oid, HASH_FIND, &found);
				if (found)
					sel += sslot.numbers[i];
			}
			free_attstatsslot(&sslot);
		}
	}

	ReleaseSysCache(statsTuple);
	return sel;
}

/*
 * is_babelfish_namespace_support - planner support function
 */
Datum
is_babelfish_namespace_support(PG_FUNCTION_ARGS)
{
	Node	   *rawreq = (Node *) PG_GETARG_POINTER(0);

	if (IsA(rawreq, SupportRequestSelectivity))
	{
		SupportRequestSelectivity *req = (SupportRequestSelectivity *) rawreq;

		if (!req->is_join)
		{
			Selectivity sel = compute_namespace_selectivity(req);

			if (sel < 0.0)
				sel = 0.9;

			req->selectivity = sel;
			PG_RETURN_POINTER(req);
		}
	}

	PG_RETURN_POINTER(NULL);
}

PG_FUNCTION_INFO_V1(has_privilege_support);

/*
 * has_privilege_support - planner support for has_*_privilege() functions.
 *
 * Computes selectivity dynamically:
 * - Superuser: 1.0 (all objects accessible)
 * - Regular user: compute from pg_proc/pg_class stats what fraction of
 *   objects are in accessible (Babelfish) namespaces, since privilege checks
 *   almost always pass for objects in the user's own namespaces.
 */
Datum
has_privilege_support(PG_FUNCTION_ARGS)
{
	Node	   *rawreq = (Node *) PG_GETARG_POINTER(0);

	if (!DbidIsValid(get_current_dbid()))
		PG_RETURN_POINTER(NULL);

	if (IsA(rawreq, SupportRequestSelectivity))
	{
		SupportRequestSelectivity *req = (SupportRequestSelectivity *) rawreq;
		Selectivity sel;

		if (superuser())
		{
			sel = 1.0;
		}
		else
		{
			/*
			 * For non-superusers, estimate selectivity from the catalog's
			 * namespace column stats. Most objects in Babelfish namespaces
			 * are accessible to the connected user.
			 */
			Oid			catalog_relid;
			AttrNumber	ns_attnum;
			HeapTuple	statsTuple;

			/*
			 * Determine which catalog based on the privilege function:
			 * has_function_privilege (2261) -> pg_proc.pronamespace
			 * has_table_privilege (1927) -> pg_class.relnamespace
			 * has_column_privilege (3022) -> pg_class.relnamespace
			 */
			if (req->funcid == 2261)
			{
				catalog_relid = ProcedureRelationId;
				ns_attnum = Anum_pg_proc_pronamespace;
			}
			else
			{
				catalog_relid = RelationRelationId;
				ns_attnum = Anum_pg_class_relnamespace;
			}

			/* Ensure namespace cache is populated */
			{
				int16 cur_dbid = get_current_dbid();
				if (!DbidIsValid(cur_dbid))
				{
					sel = 0.95;
					req->selectivity = sel;
					PG_RETURN_POINTER(req);
				}
				ensure_ns_cache(cur_dbid);
			}

			/* Get MCV stats on the namespace column */
			statsTuple = SearchSysCache3(STATRELATTINH,
										 ObjectIdGetDatum(catalog_relid),
										 Int16GetDatum(ns_attnum),
										 BoolGetDatum(false));

			if (HeapTupleIsValid(statsTuple))
			{
				AttStatsSlot sslot;
				bool have_mcv;

				have_mcv = get_attstatsslot(&sslot, statsTuple,
											STATISTIC_KIND_MCV, InvalidOid,
											ATTSTATSSLOT_VALUES | ATTSTATSSLOT_NUMBERS);
				if (have_mcv && sslot.nvalues > 0)
				{
					sel = 0.0;
					for (int i = 0; i < sslot.nvalues; i++)
					{
						Oid ns_oid = DatumGetObjectId(sslot.values[i]);
						bool found;

						hash_search(ns_oid_cache, &ns_oid, HASH_FIND, &found);
						if (found)
							sel += sslot.numbers[i];
					}
					/* Clamp to reasonable bounds */
					if (sel < 0.5)
						sel = 0.95;
				}
				else
				{
					sel = 0.95;
				}
				free_attstatsslot(&sslot);
				ReleaseSysCache(statsTuple);
			}
			else
			{
				sel = 0.95;
			}
		}

		req->selectivity = sel;
		PG_RETURN_POINTER(req);
	}

	PG_RETURN_POINTER(NULL);
}

/*
 * babelfish_opexpr_selectivity_hook
 *
 * Handles CaseExpr = Const pattern by decomposing the CASE into
 * branch probabilities.
 */
bool
babelfish_opexpr_selectivity_hook(PlannerInfo *root,
								  Node *clause,
								  int varRelid,
								  JoinType jointype,
								  SpecialJoinInfo *sjinfo,
								  bool use_extended_stats,
								  Selectivity *selec)
{
	OpExpr	   *opclause = (OpExpr *) clause;
	Node	   *left;
	Node	   *right;
	CaseExpr   *caseexpr = NULL;
	Const	   *constval = NULL;

	if (list_length(opclause->args) != 2)
		return false;

	left = (Node *) linitial(opclause->args);
	right = (Node *) lsecond(opclause->args);

	/* Strip RelabelType/CoerceViaIO/FuncExpr wrappers */
	while (IsA(left, RelabelType))
		left = (Node *) ((RelabelType *) left)->arg;
	while (IsA(left, CoerceViaIO))
		left = (Node *) ((CoerceViaIO *) left)->arg;
	if (IsA(left, FuncExpr) && list_length(((FuncExpr *) left)->args) == 1)
		left = (Node *) linitial(((FuncExpr *) left)->args);
	while (IsA(left, RelabelType))
		left = (Node *) ((RelabelType *) left)->arg;
	while (IsA(left, CoerceViaIO))
		left = (Node *) ((CoerceViaIO *) left)->arg;

	if (IsA(left, CaseExpr) && IsA(right, Const))
	{
		caseexpr = (CaseExpr *) left;
		constval = (Const *) right;
	}
	else if (IsA(right, CaseExpr) && IsA(left, Const))
	{
		caseexpr = (CaseExpr *) right;
		constval = (Const *) left;
	}

	if (caseexpr && constval && !constval->constisnull)
	{
		Selectivity remaining = 1.0;
		Selectivity match_sel = 0.0;
		ListCell   *lc;
		bool		else_matches = false;

		/* Check if ELSE result matches target */
		if (caseexpr->defresult)
		{
			Node *defres = (Node *) caseexpr->defresult;
			while (IsA(defres, RelabelType))
				defres = (Node *) ((RelabelType *) defres)->arg;
			while (IsA(defres, CoerceViaIO))
				defres = (Node *) ((CoerceViaIO *) defres)->arg;
			if (IsA(defres, Const) && !((Const *) defres)->constisnull)
			{
				Const *dc = (Const *) defres;
				if (dc->consttype == constval->consttype)
					else_matches = (dc->constvalue == constval->constvalue);
				else
				{
					int64 dv = 0, tv = 0;
					if (dc->constlen <= 4)
						dv = DatumGetInt32(dc->constvalue);
					if (constval->constlen <= 4)
						tv = DatumGetInt32(constval->constvalue);
					else_matches = (dv == tv);
				}
			}
		}

		/* Compute branch selectivities */
		foreach(lc, caseexpr->args)
		{
			CaseWhen *when = (CaseWhen *) lfirst(lc);
			Selectivity branch_sel;
			bool branch_matches_target = false;
			Node *res = (Node *) when->result;

			while (IsA(res, RelabelType))
				res = (Node *) ((RelabelType *) res)->arg;
			while (IsA(res, CoerceViaIO))
				res = (Node *) ((CoerceViaIO *) res)->arg;

			if (IsA(res, Const) && !((Const *) res)->constisnull)
			{
				Const *rc = (Const *) res;
				if (rc->consttype == constval->consttype)
					branch_matches_target = (rc->constvalue == constval->constvalue);
				else
				{
					int64 rv = 0, tv = 0;
					if (rc->constlen <= 4)
						rv = DatumGetInt32(rc->constvalue);
					if (constval->constlen <= 4)
						tv = DatumGetInt32(constval->constvalue);
					branch_matches_target = (rv == tv);
				}
			}

			branch_sel = clause_selectivity_ext(root,
												(Node *) when->expr,
												varRelid, jointype,
												sjinfo, use_extended_stats);

			if (branch_matches_target)
				match_sel += remaining * branch_sel;

			remaining *= (1.0 - branch_sel);
		}

		if (else_matches)
			match_sel += remaining;

		CLAMP_PROBABILITY(match_sel);
		*selec = match_sel;
		return true;
	}

	return false;
}

/*
 * babelfish_nulltest_selectivity_hook
 *
 * For SubPlan arguments, uses plan_rows to estimate NULL probability.
 */
bool
babelfish_nulltest_selectivity_hook(PlannerInfo *root,
									NullTestType nulltesttype,
									Node *arg,
									int varRelid,
									Selectivity *selec)
{
	if (IsA(arg, SubPlan))
	{
		SubPlan    *subplan = (SubPlan *) arg;
		Plan	   *plan = (Plan *) list_nth(root->glob->subplans,
										    subplan->plan_id - 1);

		if (plan && plan->plan_rows <= 1.0)
		{
			*selec = (nulltesttype == IS_NULL) ? 1.0 : 0.0;
		}
		else if (plan)
		{
			double match_prob = Min(plan->plan_rows, 1.0);
			*selec = (nulltesttype == IS_NULL) ? (1.0 - match_prob) : match_prob;
		}
		else
		{
			*selec = (nulltesttype == IS_NULL) ? 0.005 : 0.995;
		}
		return true;
	}

	return false;
}
