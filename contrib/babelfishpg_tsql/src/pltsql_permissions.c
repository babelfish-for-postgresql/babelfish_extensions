#include "postgres.h"
#include "access/relation.h"
#include "catalog/namespace.h"
#include "catalog/pg_class.h"
#include "miscadmin.h"
#include "multidb.h"
#include "nodes/nodeFuncs.h"
#include "nodes/nodes.h"
#include "parser/parse_node.h"
#include "parser/parse_relation.h"
#include "pltsql.h"
#include "pltsql_permissions.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/syscache.h"


/*
 * Walker function to mark relations and functions inside view definitions
 * 
 * Walks through the query parse tree to:
 * 1. Mark relations and functions as being inside a view context
 * 2. For relations:
 *    - Set checkAsUser to the view_owner when it matches the relation's owner,
 *      enabling permission checking to pass at the executor stage (ownership chaining)
 * 3. For procedures/functions:
 *    - Store the view_owner in the parentOwnerId field to support
 *      procedure/function-specific ownership chaining logic
 *      during permission checks at the executor stage
 * 
 */
bool
mark_nodes_inside_view_walker(Node *node, Oid *context)
{
	Oid nspid;
	char *physical_schemaname = NULL;
    Relation rel = NULL;

	if (node == NULL)
		return false;

	if (IsA(node, Query))
    {
        Query *query = (Query *) node;
        ListCell *lc;
        
        foreach(lc, query->rtable)
        {
            RangeTblEntry *rte = (RangeTblEntry *) lfirst(lc);
            RTEPermissionInfo *perminfo = NULL;
			AclMode nonDMLpermscheck = false;

			/* Process tables and view subqueries */
            if (OidIsValid(rte->relid) &&
				(rte->rtekind == RTE_RELATION ||
				 rte->relkind == RELKIND_VIEW))
            {
                rel = relation_open(rte->relid, AccessShareLock);
                physical_schemaname = get_namespace_name(rel->rd_rel->relnamespace);
                perminfo = getRTEPermissionInfo(query->rteperminfos, rte);
				/*
				 * Only allow SELECT, INSERT, UPDATE, DELETE dml operations through 
				 * ownership chaining.
				 */
				nonDMLpermscheck = perminfo->requiredPerms & ~(ACL_SELECT | ACL_INSERT | ACL_UPDATE | ACL_DELETE);
                
                if (physical_schemaname && !is_shared_schema(physical_schemaname))
                {
                    if (rel->rd_rel->relowner == *context && nonDMLpermscheck == ACL_NO_RIGHTS)
                    {
                        perminfo->checkAsUser = *context;
                    }
                    perminfo->insideView = PNODE_INSIDE_VIEW;
                }
                if (physical_schemaname)
                    pfree(physical_schemaname);
                relation_close(rel, AccessShareLock);
            }
        }

		return query_tree_walker(query, 
                            	 mark_nodes_inside_view_walker,
                            	 (void *) context,
                            	 0);
	}
	else if (IsA(node, FuncExpr))
    {
        FuncExpr *funcexpr = (FuncExpr *) node;
		nspid = get_func_namespace(funcexpr->funcid);
		physical_schemaname = get_namespace_name(nspid);
		if (physical_schemaname && !is_shared_schema(physical_schemaname))
		{
			funcexpr->parentOwnerId = *context;
			funcexpr->insideView = PNODE_INSIDE_VIEW;
		}

		if (physical_schemaname)
				pfree(physical_schemaname);
        
		/* else walk through function args */
    }

	return expression_tree_walker(node, mark_nodes_inside_view_walker,
								  (void *) context);
}

/*
 * Main entry point for marking nodes inside view definitions
 * 
 * Performs security check and initiates tree walk to:
 * - Mark relations and functions as being inside a view
 * - Set parent owner context for permission chaining
 */
void
mark_nodes_inside_view(Query *query, Oid view_owner)
{

	if (!IS_TDS_CLIENT() || InSecurityRestrictedOperation())
		return;

	mark_nodes_inside_view_walker((Node *)query,
								  &view_owner);

}

/*
 * This look will update the permsinfo of corresponding relation when there in ownership
 * chaining scenarios in case when view is specified as target for DML operations.
 */
void
tsql_handle_target_view_hook(RTEPermissionInfo *new_perminfo, RangeTblEntry *view_rte, Oid view_owner, Oid base_rel_owner)
{
	AclMode nonDMLpermscheck;

	if (!IS_TDS_CLIENT() || InSecurityRestrictedOperation())
		return;
	
	/*
	 * Note that for DML operations on views, SELECT privileges are still required.
	 * So keeping all allowed DMLs INSERT, UPDATE, DELETE along with SELECT.
	 */
	nonDMLpermscheck = new_perminfo->requiredPerms & ~(ACL_SELECT | ACL_INSERT | ACL_UPDATE | ACL_DELETE);

	if (nonDMLpermscheck)
		return;

	if (view_owner == base_rel_owner)
	{
		new_perminfo->checkAsUser = view_owner;
		new_perminfo->insideView = PNODE_INSIDE_VIEW;
	}
}

/*
 * Walker function to mark relations and functions inside view definitions
 * 
 * Walks through the query parse tree to:
 * 1. Mark relations and functions as being inside a view context
 * 2. For relations:
 *    - Set checkAsUser to the view_owner when it matches the relation's owner,
 *      enabling permission checking to pass at the executor stage (ownership chaining)
 * 3. For procedures/functions:
 *    - Store the view_owner in the parentOwnerId field to support
 *      procedure/function-specific ownership chaining logic
 *      during permission checks at the executor stage
 * 
 */
static bool
mark_outside_view_ref_walker(Node *node, void *context)
{
	if (node == NULL)
		return false;

	if (IsA(node, Query))
    {
        Query *query = (Query *) node;
        ListCell *lc;
        
        foreach(lc, query->rtable)
        {
            RangeTblEntry *rte = (RangeTblEntry *) lfirst(lc);
			if (OidIsValid(rte->relid) && rte->rtekind == RTE_RELATION)
			{
				RTEPermissionInfo *perminfo = getRTEPermissionInfo(query->rteperminfos, rte);

				if (perminfo && perminfo->insideView == PNODE_UNMARKED)
				{
					perminfo->insideView = PNODE_OUTSIDE_VIEW;
				}
			}
        }
		return query_tree_walker(query, 
                            	 mark_outside_view_ref_walker,
                            	 NULL,
                            	 0);
	}
	else if (IsA(node, FuncExpr))
    {
        FuncExpr *funcexpr = (FuncExpr *) node;

		if (funcexpr->insideView == PNODE_UNMARKED)
		{
			Oid nspid;
			char *physical_schemaname = NULL;

			nspid = get_func_namespace(funcexpr->funcid);
			physical_schemaname = get_namespace_name(nspid);
			if (physical_schemaname &&
				!is_shared_schema(physical_schemaname))
			{
				funcexpr->insideView = PNODE_OUTSIDE_VIEW;
			}

			if (physical_schemaname)
					pfree(physical_schemaname);
		}
    
		/* else walk through function args */
    }

	return expression_tree_walker(node, mark_outside_view_ref_walker, NULL);
}

/*
 * Main entry point for marking nodes inside view definitions
 * 
 * Performs security check and initiates tree walk to:
 * - Mark relations and functions as being inside a view
 * - Set parent owner context for permission chaining
 */
void
mark_outside_view(Query *query)
{

	if (!IS_TDS_CLIENT() || InSecurityRestrictedOperation())
		return;

	mark_outside_view_ref_walker((Node *)query, NULL);
}

