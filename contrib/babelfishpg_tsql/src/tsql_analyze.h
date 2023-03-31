#ifndef TSQL_ANALYZE_H
#define TSQL_ANALYZE_H

#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "nodes/pg_list.h"
#include "nodes/primnodes.h"
#include "postgres.h"
#include "parser/parse_node.h"
#include "utils/relcache.h"

extern RangeVar *pltsql_get_target_table(RangeVar *orig_target, List *fromClause);
extern void pltsql_update_query_result_relation(Query *qry, Relation target_rel, List *rtable);
extern void handle_rowversion_target_in_update_stmt(RangeVar *target_table, UpdateStmt *stmt);
extern void rewrite_update_outer_join(Node *stmt, CmdType command, RangeVar *target);
extern void push_namespace_stack(void);
extern void pre_transform_sort_clause(ParseState *pstate, Query *qry, Query *leftmostQuery);
extern void post_transform_sort_clause(Query *qry);
extern void post_transform_from_clause(ParseState *pstate);

typedef struct namespace_stack {
	struct namespace_stack *prev;
	List *namespace;
} NamespaceStack;

extern NamespaceStack *set_op_ns_stack;

#endif							/* TSQL_ANALYZE_H */
