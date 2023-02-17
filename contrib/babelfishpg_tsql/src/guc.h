#ifndef PLTSQL_GUC_H
#define PLTSQL_GUC_H

typedef enum MigrationMode { SINGLE_DB, MULTI_DB } MigrationMode;
typedef enum EscapeHatchOption { EH_STRICT, EH_IGNORE, EH_NULL } EscapeHatchOption;

extern bool pltsql_fmtonly;
extern bool pltsql_enable_create_alter_view_from_pg;
extern bool pltsql_is_windows_allowed;

extern void define_custom_variables(void);
extern void pltsql_validate_set_config_function(char *name, char *value);

/*************************************
 * 				Getters
 ************************************/
extern MigrationMode get_migration_mode(void);

extern bool metadata_inconsistency_check_enabled(void); 
/*
 * Defined in pl_handler.c for managing GUC stack
 */
int pltsql_new_guc_nest_level(void);
void pltsql_revert_guc(int nest_level);

extern int pltsql_new_scope_identity_nest_level(void);
extern void pltsql_revert_last_scope_identity(int nest_level);
#endif
