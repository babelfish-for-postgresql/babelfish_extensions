#ifndef ROLCMDS_H
#define ROLCMDS_H

#include "catalog/objectaccess.h"
#include "nodes/parsenodes.h"

#define BBF_AUTHID_LOGIN_EXT_NUM_COLS	11
#define LOGIN_EXT_ROLNAME				0
#define LOGIN_EXT_IS_DISABLED			1
#define LOGIN_EXT_TYPE					2
#define LOGIN_EXT_CREDENTIAL_ID			3
#define LOGIN_EXT_OWNING_PRINCIPAL_ID	4
#define LOGIN_EXT_IS_FIXED_ROLE			5
#define LOGIN_EXT_CREATE_DATE			6
#define LOGIN_EXT_MODIFY_DATE			7
#define LOGIN_EXT_DEFAULT_DATABASE_NAME 8
#define LOGIN_EXT_DEFAULT_LANGUAGE_NAME 9
#define LOGIN_EXT_PROPERTIES			10

#define BBF_AUTHID_USER_EXT_NUM_COLS					15
#define USER_EXT_ROLNAME								0
#define USER_EXT_LOGIN_NAME								1
#define USER_EXT_TYPE									2
#define USER_EXT_OWNING_PRINCIPAL_ID					3
#define USER_EXT_IS_FIXED_ROLE							4
#define USER_EXT_AUTHENTICATION_TYPE					5
#define USER_EXT_DEFAULT_LANGUAGE_LCID					6
#define USER_EXT_ALLOW_ENCRYPTED_VALUE_MODIFICATIONS	7
#define USER_EXT_CREATE_DATE							8
#define USER_EXT_MODIFY_DATE							9
#define USER_EXT_ORIG_USERNAME							10
#define USER_EXT_DATABASE_NAME							11
#define USER_EXT_DEFAULT_SCHEMA_NAME					12
#define USER_EXT_DEFAULT_LANGUAGE_NAME					13
#define USER_EXT_AUTHENTICATION_TYPE_DESC				14

extern void drop_bbf_roles(ObjectAccessType access,
										Oid classId,
										Oid roleid,
										int subId,
										void *arg);
extern bool role_is_sa(Oid roleid);
extern bool tsql_has_pgstat_permissions(Oid roleid);
extern bool is_alter_server_stmt(GrantRoleStmt *stmt);
extern void check_alter_server_stmt(GrantRoleStmt *stmt);
extern bool is_alter_role_stmt(GrantRoleStmt *stmt);
extern void check_alter_role_stmt(GrantRoleStmt *stmt);
extern void create_bbf_authid_login_ext(CreateRoleStmt *stmt);
extern void alter_bbf_authid_login_ext(AlterRoleStmt *stmt);
extern void create_bbf_authid_user_ext(CreateRoleStmt *stmt, bool has_schema, bool has_login);
extern void add_to_bbf_authid_user_ext(const char *user_name,
									   const char *orig_user_name,
									   const char *db_name,
									   const char *schema_name,
									   const char *login_name,
									   bool is_role);
extern void drop_related_bbf_users(List *db_users);
extern void alter_bbf_authid_user_ext(AlterRoleStmt *stmt);

#endif
