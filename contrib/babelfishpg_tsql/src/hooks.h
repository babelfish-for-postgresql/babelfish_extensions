#ifndef PLTSQL_HOOKS_H
#define PLTSQL_HOOKS_H
#include "postgres.h"
#include "catalog/catalog.h"
#include "parser/analyze.h"
#include "tcop/cmdtag.h"
#include "utils/pg_locale.h"

extern IsExtendedCatalogHookType PrevIsExtendedCatalogHook;
extern IsToastRelationHookType PrevIsToastRelationHook;
extern IsToastClassHookType PrevIsToastClassHook;

extern void InstallExtendedHooks(void);
extern void UninstallExtendedHooks(void);

void pre_wrapper_pgstat_init_function_usage(const char *);
pg_locale_t *collation_cache_entry_hook_function(Oid ,pg_locale_t *);
extern bool output_update_transformation;
extern bool output_into_insert_transformation;
extern char *extract_identifier(const char *start);
extern void pltsql_store_func_default_positions(ObjectAddress address,
                                                List *parameters,
                                                const char *queryString,
                                                int origname_location);
extern Oid  get_tsql_trigger_oid(List *object,
                                 const char *tsql_trigger_name,
                                 bool object_from_input);
extern void pltsql_bbfSelectIntoUtility(ParseState *pstate, PlannedStmt *pstmt, const char *queryString, 
                    QueryEnvironment *queryEnv, ParamListInfo params, QueryCompletion *qc);

extern char *update_delete_target_alias;
extern bool sp_describe_first_result_set_inprogress;
#endif

