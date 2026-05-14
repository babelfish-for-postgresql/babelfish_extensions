
#ifndef STABLE_FUNC_PERSISTED_H
#define STABLE_FUNC_PERSISTED_H

#include "postgres.h"
#include "nodes/parsenodes.h"

/* Hook for PERSISTED computed columns with whitelisted STABLE functions */
extern Node *stable_persisted_hook(Node *expr);

/* GUC check functions for PERSISTED computed columns */
extern bool check_persisted_gucs(void);
extern char *get_mismatched_persisted_gucs(void);

/* Check if table has PERSISTED computed columns */
extern bool table_has_persisted_computed_cols(Oid relid);

/* Check GUCs for INSERT/UPDATE into tables with PERSISTED computed columns */
extern void guc_check_insert_update(Query *parse);

/* Rewrite computed column references in SELECT when GUCs don't match */
extern void query_rewrite_persisted(Query *parse);

#endif /* STABLE_FUNC_PERSISTED_H */
