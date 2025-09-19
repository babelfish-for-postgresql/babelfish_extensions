#ifndef PLTSQL_PERMISSIONS_H
#define PLTSQL_PERMISSIONS_H

#include "postgres.h"
#include "nodes/parsenodes.h"
#include "nodes/nodes.h"
#include "utils/rel.h"

/* View node marking constants */
#define PNODE_UNMARKED     0
#define PNODE_INSIDE_VIEW  1
#define PNODE_OUTSIDE_VIEW 2

/* Function declarations */
extern bool mark_nodes_inside_view_walker(Node *node, Oid *context);
extern void mark_nodes_inside_view(Query *query, Oid view_owner);
extern void tsql_handle_target_view_hook(RTEPermissionInfo *new_perminfo, RangeTblEntry *view_rte, Oid view_owner, Oid base_rel_owner);
extern void mark_outside_view(Query *query);

#endif