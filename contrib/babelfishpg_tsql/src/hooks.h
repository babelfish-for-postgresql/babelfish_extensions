#ifndef PLTSQL_HOOKS_H
#define PLTSQL_HOOKS_H
#include "postgres.h"
#include "catalog/catalog.h"
#include "parser/analyze.h"
#include "tcop/cmdtag.h"
#include "utils/pg_locale.h"
#include "utils/xml.h"
#include "pltsql.h"

extern IsExtendedCatalogHookType PrevIsExtendedCatalogHook;
extern IsToastRelationHookType PrevIsToastRelationHook;
extern IsToastClassHookType PrevIsToastClassHook;

extern void InstallExtendedHooks(void);
extern void UninstallExtendedHooks(void);

void pre_wrapper_pgstat_init_function_usage(const char *);
pg_locale_t *collation_cache_entry_hook_function(Oid ,pg_locale_t *);
extern bool output_update_transformation;
extern bool output_into_insert_transformation;
extern char *gen_func_arg_list(Oid objectId);
extern char * gen_func_arg_list_from_params(List* parameters);
extern void pltsql_store_func_default_positions(ObjectAddress address,
                                                List *parameters,
                                                const char *queryString,
                                                int origname_location,
                                                bool with_recompile);

/*
 * Structure to hold cached parse result retrieved from catalog.
 * Contains both the parse tree and datums array.
 */
typedef struct PLtsql_cached_parse_result
{
	PLtsql_stmt_block *parse_tree;  /* Deserialized ANTLR parse tree */
	int ndatums;                     /* Number of datums */
	PLtsql_datum **datums;          /* Array of datums (variables, etc.) */
} PLtsql_cached_parse_result;

extern PLtsql_cached_parse_result *pltsql_restore_antlr_parse_cache_result(HeapTuple proctup,
																	bool *out_cache_enabled,
																	TransactionId *out_bbf_ext_xmin,
																	ItemPointerData *out_bbf_ext_tid);
extern void pltsql_fill_antlr_parse_cache_columns(PLtsql_function *function, Datum modify_date,
									  Datum *new_record, bool *new_record_nulls,
									  bool *new_record_replaces);
extern void pltsql_update_func_antlr_parse_cache(HeapTuple proctup, PLtsql_function *function);
extern void alter_bbf_schema_permissions_catalog(ObjectWithArgs *owa, 
                                                    List *parameters,
                                                    int objtypeInt);
extern Oid  get_tsql_trigger_oid(List *object,
                                 const char *tsql_trigger_name,
                                 bool object_from_input);
extern Datum pltsql_exec_tsql_cast_value(Datum value, bool *isnull,
							 Oid valtype, int32 valtypmod,
							 Oid reqtype, int32 reqtypmod);
extern void pltsql_bbfSelectIntoUtility(ParseState *pstate, PlannedStmt *pstmt, const char *queryString, 
                    QueryEnvironment *queryEnv, ParamListInfo params, QueryCompletion *qc, ObjectAddress *address);
extern char** fetch_func_input_arg_names(HeapTuple func_tuple);

extern char *update_delete_target_alias;
extern bool sp_describe_first_result_set_inprogress;
extern bool handle_bbf_view_binding_on_object_drop(const ObjectAddress *droppedObject, bool is_alter_view);
extern bool check_view_binding_dependencies(Query *viewParse);
extern void get_xml_data_and_namespace_data(int document_id, xmltype **xml_data, xmltype **ns_data);
extern void extract_namespaces_from_xml(xmltype *ns_data, char ***ns_names, char ***ns_uris, int *ns_count);
#endif

