
#ifndef STABLE_FUNC_PERSISTED_H
#define STABLE_FUNC_PERSISTED_H

#include "postgres.h"
#include "nodes/parsenodes.h"
#include "nodes/plannodes.h"

/*
 * Extra condition for functions that are only deterministic for certain
 * arguments.  argname is the parameter to inspect, from the whitelist entry.
 * f is the call site, and is NULL when there are no arguments to look at (an
 * operator or a type I/O coercion), so such rules must fail closed.
 */
typedef bool (*whitelist_validator) (HeapTuple procTup, FuncExpr *f,
                                     const char *argname);

/* Entry for whitelisted function lookup */
typedef struct {
    const char          *funcname;
    const char          *nspname;
    whitelist_validator  validate;      /* NULL: nothing beyond volatility */
    const char          *validate_arg;  /* parameter the validator inspects */
} FuncEntry;

typedef struct
{
    int   varno;
    int   varattno;
    Node  *expr;
} RewriteCtx;

/* Hook for PERSISTED computed columns with whitelisted STABLE functions */
extern Node *stable_persisted_hook(Node *expr);

/* GUC check functions for PERSISTED computed columns */
extern bool has_mismatched_set_options(void);
extern char *get_mismatched_persisted_gucs(void);

/* Check if table has PERSISTED computed columns */
extern bool table_has_persisted_computed_cols(Oid relid);

/*
 * Check GUCs for DML into tables with PERSISTED computed columns.
 * Called from ExecutorStart so that cached plans are still checked.
 */
extern void guc_check_dml(PlannedStmt *pstmt);

/* Rewrite computed column references in SELECT when GUCs don't match */
extern void query_rewrite_persisted(Query *parse);

#endif /* STABLE_FUNC_PERSISTED_H */
