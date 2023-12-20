#ifndef PLTSQL_MULTIDB_H
#define PLTSQL_MULTIDB_H

#include "postgres.h"
#include "guc.h"
#include "nodes/parsenodes.h"

#define MAX_BBF_NAMEDATALEND (2*NAMEDATALEN + 2)	/* two identifiers + 1 '_'
													 * + 1 terminator */

/* condition for schema remapping */
extern bool enable_schema_mapping(void);

/* rewriting column/object references accoring schema mapping */
extern void rewrite_column_refs(ColumnRef *cref);
extern void rewrite_object_refs(Node *stmt);
extern List* rewrite_plain_name(List *name); /* Value Strings */

/* helper functions */
extern char *get_physical_user_name(char *db_name, char *user_name);
extern char *get_physical_schema_name(char *db_name, const char *schema_name);
extern char *get_physical_schema_name_by_mode(char *db_name, const char *schema_name, MigrationMode mode);
extern const char *get_dbo_schema_name(const char *dbname);
extern const char *get_dbo_role_name(const char *dbname);
extern const char *get_db_owner_name(const char *dbname);
extern const char *get_guest_role_name(const char *dbname);
extern const char *get_guest_schema_name(const char *dbname);
extern bool is_shared_schema(const char *name);
extern void truncate_tsql_identifier(char *ident);
extern bool physical_schema_name_exists(char *phys_schema_name);
extern bool is_builtin_database(const char *dbname);
extern bool is_user_database_singledb(const char *dbname);
extern bool is_json_modify(List *name);

#endif
