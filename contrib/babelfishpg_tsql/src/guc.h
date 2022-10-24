#ifndef PLTSQL_GUC_H
#define PLTSQL_GUC_H

typedef enum MigrationMode { SINGLE_DB, MULTI_DB } MigrationMode;
typedef enum EscapeHatchOption { EH_STRICT, EH_IGNORE, EH_NULL } EscapeHatchOption;

extern bool pltsql_fmtonly;
extern bool pltsql_enable_create_alter_view_from_pg;

extern void define_custom_variables(void);
extern void pltsql_validate_set_config_function(char *name, char *value);

/*************************************
 * 				Getters
 ************************************/
extern MigrationMode get_migration_mode(void);


#endif
