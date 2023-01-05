/*-------------------------------------------------------------------------
 *
 * plan_inval.c		- Plan Invalidation for PL/tsql
 *
 * IDENTIFICATION
 *	  src/pl/pltsql/src/plan_inval.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "parser/parser.h"
#include "utils/plancache.h"

#include "pltsql.h"

const char *pltsql_identity_insert_name = "tsql_identity_insert";

/*
 * Defining enum to avoid string comparision in pltsql_check_guc_plan.
 */
typedef enum {
IDENTITY_INSERT
} plan_info_enum_list;

void pltsql_add_guc_plan(CachedPlanSource *plansource);
bool pltsql_check_guc_plan(CachedPlanSource *plansource);

static void pltsql_initialize_identity_insert_plan(CachedPlanSource *plansource);
static bool pltsql_revalidate_identity_insert_plan(CachedPlanSource *plansource,
												   List *info_sublist);

/*
 * Add global variables or GUCs to the plan info list for revalidation use.
 */
void
pltsql_add_guc_plan(CachedPlanSource *plansource)
{
	if (prev_plansource_complete_hook)
		prev_plansource_complete_hook(plansource);

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	Assert(CurrentMemoryContext == plansource->context);

	pltsql_initialize_identity_insert_plan(plansource);
}

/*
 * Check each global variable or GUC and revalidate the plan accordingly.
 */
bool
pltsql_check_guc_plan(CachedPlanSource *plansource)
{
	bool valid = plansource->is_valid;
	ListCell *lc;

	if (prev_plansource_revalidate_hook)
		valid = (* prev_plansource_revalidate_hook) (plansource);

	if (sql_dialect != SQL_DIALECT_TSQL || !valid)
		return valid;

	/* Identify each GUC by plan_info_enum_list and revalidate accordingly */
	foreach (lc, plansource->pltsql_plan_info)
	{
		List *info_sublist = (List *) lfirst(lc);
		plan_info_enum_list enum_list = (plan_info_enum_list) linitial(info_sublist);

		/* Execute revalidate function only if it is an insert query. */
		if (plansource->commandTag == CMDTAG_INSERT){
			if (valid && enum_list == IDENTITY_INSERT)
				valid = pltsql_revalidate_identity_insert_plan(plansource, info_sublist);
		}

		/* Return if invalidated */
		if (!valid)
			return false;
	}

	return valid;
}

/*
 * Initialize IDENTITY_INSERT state for plan list
 */
static void
pltsql_initialize_identity_insert_plan(CachedPlanSource *plansource)
{
	List *id_insert_info_sublist = NIL;
	plan_info_enum_list* id_insert_enum;

	tsql_identity_insert_fields *id_insert_state;
	
	/* Initialize enum */
	id_insert_enum = IDENTITY_INSERT;
	
	/* Copy state */
	id_insert_state = (tsql_identity_insert_fields *)
												palloc(sizeof *id_insert_state);
	id_insert_state->valid = tsql_identity_insert.valid;
	id_insert_state->rel_oid = tsql_identity_insert.rel_oid;
	id_insert_state->schema_oid = tsql_identity_insert.schema_oid;

	/* Create info sublist */
	id_insert_info_sublist = lappend(id_insert_info_sublist, id_insert_enum);
	id_insert_info_sublist = lappend(id_insert_info_sublist, id_insert_state);

	/* Append to plan info list */
	plansource->pltsql_plan_info = lappend(plansource->pltsql_plan_info,
										   id_insert_info_sublist);
}

/*
 * Revalidate the plan based on the state of IDENTITY_INSERT. Assert plan is
 * valid. First check if the plan is relevant to IDENTITY_INSERT. This may
 * include other plans, but invalidating the wrong plan should
 * not affect correctness. This is just a performance concern.
 */
static bool
pltsql_revalidate_identity_insert_plan(CachedPlanSource *plansource,
									   List *info_sublist)
{
	tsql_identity_insert_fields *id_insert_info;

	Assert(plansource->is_valid);

	id_insert_info = (tsql_identity_insert_fields *) lsecond(info_sublist);

	if (plansource->commandTag == CMDTAG_INSERT)
	{
		ListCell *lc_rel;

		foreach(lc_rel, plansource->relationOids)
		{
			Oid cur_rel = lfirst_oid(lc_rel);

			/* Check if plan affects previous or current relation */
			if (cur_rel == id_insert_info->rel_oid ||
				cur_rel == tsql_identity_insert.rel_oid)
			{
				/* Check for state mismatch */
				if (id_insert_info->valid != tsql_identity_insert.valid ||
					id_insert_info->rel_oid != tsql_identity_insert.rel_oid ||
					id_insert_info->schema_oid != tsql_identity_insert.schema_oid)
					return false;
			}
		}
	}

	return true;
}
