#ifndef PLTSQL_CATALOG_H
#define PLTSQL_CATALOG_H

#include "postgres.h"
#include "fmgr.h"

#include "catalog/catalog.h"
#include "access/attnum.h"
#include "utils/jsonb.h"

/*****************************************
 * 			Catalog General
 *****************************************/
extern Datum init_catalog(PG_FUNCTION_ARGS);
extern void rename_update_bbf_catalog(RenameStmt *stmt);

/*****************************************
 * 			Catalog Hooks
 *****************************************/
extern bool IsPLtsqlExtendedCatalog(Oid relationId);

/*****************************************
 *			SYS schema
 *****************************************/
extern Oid	sys_schema_oid;

/*****************************************
 *			SYSDATABASES
 *****************************************/
#define SYSDATABASES_TABLE_NAME "babelfish_sysdatabases"
#define SYSDATABASES_PK_NAME "babelfish_sysdatabases_pkey"
#define SYSDATABASES_OID_IDX_NAME "babelfish_sysdatabases_dboid_key"

extern Oid	sysdatabases_oid;
extern Oid	sysdatabaese_idx_oid_oid;
extern Oid	sysdatabaese_idx_name_oid;

/* MUST comply with babelfish_sysdatabases table */
#define SYSDATABASES_NUM_COLS 8
#define Anum_sysdatabaese_oid 1
#define Anum_sysdatabaese_name 6
#define Anum_sysdatabaese_crdate 7

/* MUST comply with babelfish_sysdatabases table */
typedef struct FormData_sysdatabases
{
	int16		dbid;
	int32		status;
	int32		status2;
	NameData	owner;
	NameData	default_collation;
	text		name;
	TimestampTz crdate;
	text		properties;
} FormData_sysdatabases;

typedef FormData_sysdatabases *Form_sysdatabases;

/* MUST comply with babelfish_authid_login_ext table */
typedef struct FormData_authid_login_ext
{
	NameData	rolname;
	int32		is_disabled;
	char		type;
	int32		credential_id;
	int32		owning_principal_id;
	int32		is_fixed_role;
	TimestampTz create_date;
	TimestampTz modify_date;
	VarChar		default_database_name;
	VarChar		default_language_name;
	Jsonb		properties;
	VarChar		orig_loginname;
} FormData_authid_login_ext;

typedef FormData_authid_login_ext *Form_authid_login_ext;

#define InvalidDbid 0
#define DbidIsValid(id)  ((bool) ((id) != InvalidDbid))

extern int16 get_db_id(const char *dbname);
extern char *get_db_name(int16 dbid);
extern void initTsqlSyscache(void);
extern const char *get_one_user_db_name(void);
extern bool guest_has_dbaccess(const char *db_name);

#define DEFAULT_DATABASE_COMPATIBILITY_LEVEL 80

/*****************************************
 *			NAMESPACE_EXT
 *****************************************/
#define NAMESPACE_EXT_TABLE_NAME "babelfish_namespace_ext"
#define NAMESAPCE_EXT_PK_NAME "babelfish_namespace_ext_pkey"
#define Anum_namespace_ext_namespace 1
#define Anum_namespace_ext_dbid 2
#define Anum_namespace_ext_orig_name 3
#define NAMESPACE_EXT_NUM_COLS 4

extern Oid	namespace_ext_oid;
extern Oid	namespace_ext_idx_oid_oid;
extern int	namespace_ext_num_cols;

extern const char *get_logical_schema_name(const char *physical_schema_name, bool missingOk);
extern int16 get_dbid_from_physical_schema_name(const char *physical_schema_name, bool missingOk);

/*****************************************
 *			LOGIN EXT
 *****************************************/
#define BBF_AUTHID_LOGIN_EXT_TABLE_NAME "babelfish_authid_login_ext"
#define BBF_AUTHID_LOGIN_EXT_IDX_NAME "babelfish_authid_login_ext_pkey"
#define Anum_bbf_authid_login_ext_rolname 1
#define Anum_bbf_authid_login_ext_type 3
#define Anum_bbf_authid_login_ext_orig_loginname 12

extern Oid	bbf_authid_login_ext_oid;
extern Oid	bbf_authid_login_ext_idx_oid;

extern bool is_login(Oid role_oid);
extern bool is_login_name(char *rolname);
extern char *get_login_default_db(char *login_name);
extern Oid	get_authid_login_ext_oid(void);
extern Oid	get_authid_login_ext_idx_oid(void);

/*****************************************
 *			USER EXT
 *****************************************/
#define BBF_AUTHID_USER_EXT_TABLE_NAME "babelfish_authid_user_ext"
#define BBF_AUTHID_USER_EXT_IDX_NAME "babelfish_authid_user_ext_pkey"
#define Anum_bbf_authid_user_ext_rolname				1
#define Anum_bbf_authid_user_ext_login_name				2
#define Anum_bbf_authid_user_ext_orig_username			11
#define Anum_bbf_authid_user_ext_database_name			12
#define Anum_bbf_authid_user_ext_default_schema_name	13
#define Anum_bbf_authid_user_ext_user_can_connect		16
extern Oid	bbf_authid_user_ext_oid;
extern Oid	bbf_authid_user_ext_idx_oid;

extern bool is_user(Oid role_oid);
extern bool is_role(Oid role_oid);
extern Oid	get_authid_user_ext_oid(void);
extern Oid	get_authid_user_ext_idx_oid(void);
extern char *get_authid_user_ext_physical_name(const char *db_name, const char *login_name);
extern char *get_authid_user_ext_schema_name(const char *db_name, const char *user_name);
extern List *get_authid_user_ext_db_users(const char *db_name);
extern char *get_user_for_database(const char *db_name);
extern void alter_user_can_connect(bool is_grant, char *user_name, char *db_name);
extern bool guest_role_exists_for_db(const char *dbname);

/* MUST comply with babelfish_authid_user_ext table */
typedef struct FormData_authid_user_ext
{
	NameData	rolname;
	NameData	login_name;
	BpChar		type;
	int32		owning_principal_id;
	int32		is_fixed_role;
	int32		authentication_type;
	int32		default_language_lcid;
	int32		allow_encrypted_value_modifications;
	TimestampTz create_date;
	TimestampTz modify_date;
	VarChar		orig_username;
	VarChar		database_name;
	VarChar		default_schema_name;
	VarChar		default_language_name;
	VarChar		authentication_type_desc;
	int32		user_can_connect;
} FormData_authid_user_ext;

typedef FormData_authid_user_ext *Form_authid_user_ext;

/*****************************************
 *			VIEW_DEF
 *****************************************/
#define BBF_VIEW_DEF_TABLE_NAME "babelfish_view_def"
#define BBF_VIEW_DEF_IDX_NAME "babelfish_view_def_pkey"
#define Anum_bbf_view_def_dbid 1
#define Anum_bbf_view_def_schema_name 2
#define Anum_bbf_view_def_object_name 3
#define Anum_bbf_view_def_definition 4
#define BBF_VIEW_DEF_NUM_COLS 8
#define BBF_VIEW_DEF_FLAG_IS_ANSI_NULLS_ON (1<<0)
#define BBF_VIEW_DEF_FLAG_USES_QUOTED_IDENTIFIER (1<<1)
#define BBF_VIEW_DEF_FLAG_CREATED_IN_OR_AFTER_2_4 (0<<2)
extern Oid	bbf_view_def_oid;
extern Oid	bbf_view_def_idx_oid;

extern Oid	get_bbf_view_def_oid(void);
extern Oid	get_bbf_view_def_idx_oid(void);
extern HeapTuple search_bbf_view_def(Relation bbf_view_def_rel, int16 dbid,
									 const char *logical_schema_name, const char *view_name);
extern bool check_is_tsql_view(Oid relid);
extern void clean_up_bbf_view_def(int16 dbid);

typedef struct FormData_bbf_view_def
{
	int16		dbid;
	VarChar		schema;
	VarChar		object_name;
	text		definition;
	uint64		flag_validity;
	uint64		flag_values;
	Timestamp	create_date;
	Timestamp	modify_date;
}			FormData_bbf_view_def;

typedef FormData_bbf_view_def * Form_bbf_view_def;

/*****************************************
 *			LINKED_SERVERS_DEF
 *****************************************/
#define BBF_SERVERS_DEF_TABLE_NAME "babelfish_server_options"
#define BBF_SERVERS_DEF_IDX_NAME "babelfish_server_options_pkey"
#define Anum_bbf_servers_def_server_id 1
#define Anum_bbf_servers_def_query_timeout 2
#define BBF_SERVERS_DEF_NUM_COLS 2
extern Oid			bbf_servers_def_oid;
extern Oid			bbf_servers_def_idx_oid;

extern Oid get_bbf_servers_def_oid(void);
extern Oid get_bbf_servers_def_idx_oid(void);
extern HeapTuple search_bbf_servers_def(Relation bbf_servers_def_rel, int32 server_id);
extern int get_query_timeout_from_server_name(char *servername);
extern int get_server_id_from_server_name(char *servername);
// extern bool check_is_tsql_view(Oid relid);
extern void clean_up_bbf_server_def(int32 server_id);

typedef struct FormData_bbf_servers_def
{
	int32		server_id;
	int32		query_timeout;
} FormData_bbf_servers_def;

typedef FormData_bbf_servers_def *Form_bbf_servers_def;

/*****************************************
 *			FUNCTION_EXT
 *****************************************/
#define BBF_FUNCTION_EXT_TABLE_NAME "babelfish_function_ext"
#define BBF_FUNCTION_EXT_IDX_NAME "babelfish_function_ext_pkey"
#define Anum_bbf_function_ext_nspname 1
#define Anum_bbf_function_ext_funcname 2
#define Anum_bbf_function_ext_orig_name 3
#define Anum_bbf_function_ext_funcsignature 4
#define Anum_bbf_function_ext_default_positions 5
#define Anum_bbf_function_ext_flag_validity 6
#define Anum_bbf_function_ext_flag_values 7
#define Anum_bbf_function_ext_create_date 8
#define Anum_bbf_function_ext_modify_date 9
#define Anum_bbf_function_ext_definition 10
#define BBF_FUNCTION_EXT_NUM_COLS 10
#define FLAG_IS_ANSI_NULLS_ON (1<<0)
#define FLAG_USES_QUOTED_IDENTIFIER (1<<1)
extern Oid	bbf_function_ext_oid;
extern Oid	bbf_function_ext_idx_oid;

extern Oid	get_bbf_function_ext_oid(void);
extern Oid	get_bbf_function_ext_idx_oid(void);
extern HeapTuple get_bbf_function_tuple_from_proctuple(HeapTuple proctuple);
extern void clean_up_bbf_function_ext(int16 dbid);

typedef struct FormData_bbf_function_ext
{
	NameData	schema;
	NameData	funcname;
	VarChar		orig_name;
	text		function_signature;
	text		default_positions;
	uint64		flag_validity;
	uint64		flag_values;
	Timestamp	create_date;
	Timestamp	modify_date;
	text		definition;
} FormData_bbf_function_ext;

typedef FormData_bbf_function_ext *Form_bbf_function_ext;

/*****************************************
 *			DOMAIN MAPPING
 *****************************************/
#define BBF_DOMAIN_MAPPING_TABLE_NAME "babelfish_domain_mapping"
#define BBF_DOMAIN_MAPPING_IDX_NAME "babelfish_domain_mapping_pkey"

#define Anum_bbf_domain_mapping_netbios_domain_name 1
#define Anum_bbf_domain_mapping_fq_domain_name 2
#define BBF_DOMAIN_MAPPING_NUM_COLS 2

extern Oid	bbf_domain_mapping_oid;
extern Oid	bbf_domain_mapping_idx_oid;

extern Oid	get_bbf_domain_mapping_oid(void);
extern Oid	get_bbf_domain_mapping_idx_oid(void);

/*****************************************
 *			Metadata Check Rule
 *****************************************/

/*
 * RelData stores catalog info that is used in metadata check.
 *
 * When initializing a RelData in catalog.c, the expected status of the fields
 * are
 *		tblname - mandatory
 *		tbl_oid - InvalidOid
 *		idx_oid - InvalidOid
 *		atttype - InvalidOid
 *		attnum - mandatory
 *		regproc - mandatory
 */
typedef struct RelData
{
	const char *tblname;		/* table name */
	Oid			tbl_oid;		/* table oid */
	Oid			idx_oid;		/* index oid */
	bool		index_ok;		/* if false, forces a heap scan */
	Oid			atttype;		/* index column's type oid */
	AttrNumber	attnum;			/* index column's attribute num */
	RegProcedure regproc;		/* regproc used to scan through the index */
} RelData;

/*
 * Rule defines a rule for metadata inconsistency check.
 *
 * When defining a Rule in catalog.c, the expected status of the fields are
 *		desc - mandatory
 *		tblname - mandatory
 *		colname - mandatory
 *		tupdesc - NULL
 *		func_val - mandatory
 *		func_cond - optional, can be NULL
 *		func_check - mandatory
 *		tbldata - NULL
 */
typedef struct Rule
{
	const char *desc;			/* rule description, mandatory field */
	const char *tblname;		/* catalog name, mandatory field */
	const char *colname;		/* column name, mandatory field */

	/*
	 * The expected value should be the result of a value function. A value
	 * function reads a tuple and output a Datum. Must have rules: Input tuple
	 * is NULL. Must match rules: Input tuple is provided by a catalog (often
	 * different from tblname. tupdesc is the description for the input tuple.
	 */
	TupleDesc	tupdesc;
	Datum		(*func_val) (HeapTuple tuple, TupleDesc dsc);

	/* function to check whether certain condition is satisfied */
	bool		(*func_cond) (void);
	/* function to validate the rule */
	bool		(*func_check) (void *rule_arg, HeapTuple tuple);

	RelData    *tbldata;		/* extra catalog info */
} Rule;

#endif
