#ifndef ROLCMDS_H
#define ROLCMDS_H

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

extern void assign_object_access_hook_drop_role(void);
extern void uninstall_object_access_hook_drop_role(void);

extern bool role_is_sa(Oid roleid);
extern bool is_alter_server_stmt(GrantRoleStmt *stmt);
extern void check_alter_server_stmt(GrantRoleStmt *stmt);
extern void create_bbf_authid_login_ext(CreateRoleStmt *stmt);
extern void alter_bbf_authid_login_ext(AlterRoleStmt *stmt);

#endif
