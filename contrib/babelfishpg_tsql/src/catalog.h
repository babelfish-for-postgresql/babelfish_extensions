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
#define BBF_ASSEMBLIES_TABLE_NAME "assemblies"
#define BBF_CONFIGURATIONS_TABLE_NAME "babelfish_configurations"
#define BBF_HELPCOLLATION_TABLE_NAME "babelfish_helpcollation"
#define BBF_SYSLANGUAGES_TABLE_NAME "babelfish_syslanguages"
#define BBF_SERVICE_SETTINGS_TABLE_NAME "service_settings"
#define SPT_DATATYPE_INFO_TABLE_NAME "spt_datatype_info_table"
#define BBF_VERSIONS_TABLE_NAME "versions"

/*****************************************
 * 			Catalog Hooks
 *****************************************/
extern bool IsPLtsqlExtendedCatalog(Oid relationId);
extern bool IsPltsqlToastRelationHook(Relation relation);
extern bool IsPltsqlToastClassHook(Form_pg_class pg_class_tup);
extern void pltsql_drop_relation_refcnt_hook(Relation relation);

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
#define Anum_sysdatabases_oid 1
#define Anum_sysdatabases_owner 4
#define Anum_sysdatabases_name 6
#define Anum_sysdatabases_crdate 7

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

#define BBF_ROLE 1
#define BBF_USER 2
const  int	get_db_principal_kind(Oid role_oid, const char *db_name);
extern Oid	get_authid_user_ext_oid(void);
extern Oid	get_authid_user_ext_idx_oid(void);
extern char *get_authid_user_ext_original_name(const char *physical_role_name, const char *db_name);
extern char *get_authid_user_ext_physical_name(const char *db_name, const char *login_name);
extern char *get_authid_user_ext_schema_name(const char *db_name, const char *user_name);
extern List *get_authid_user_ext_db_users(const char *db_name);
extern char *get_user_for_database(const char *db_name);
extern void alter_user_can_connect(bool is_grant, char *user_name, char *db_name);
extern bool guest_role_exists_for_db(const char *dbname);
extern void update_db_owner(const char *new_owner_name, const char *db_name);
extern void update_sysdatabases_db_name(const char *old_db_name, const char *new_db_name);
extern List *update_babelfish_namespace_ext_nsp_name(int16 db_id, char *new_db_name);
extern List *update_babelfish_authid_user_ext_db_name(const char *old_db_name, const char *new_db_name);
extern void rename_tsql_db(char *old_db_name, char *new_db_name);
extern Oid get_login_for_user(Oid user_id, const char *physical_schema_name);
extern bool user_exists_for_db(const char *db_name, const char *user_name);

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
extern void drop_bbf_schema_permission_entries(int16 dbid);

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
#define Anum_bbf_servers_def_servername 1
#define Anum_bbf_servers_def_query_timeout 2
#define Anum_bbf_servers_def_connect_timeout 3
#define BBF_SERVERS_DEF_NUM_COLS 3
extern Oid	bbf_servers_def_oid;
extern Oid	bbf_servers_def_idx_oid;

extern Oid get_bbf_servers_def_oid(void);
extern Oid get_bbf_servers_def_idx_oid(void);
extern int get_timeout_from_server_name(char *servername, int attnum);
extern int get_server_id_from_server_name(char *servername);
extern void clean_up_bbf_server_def(void);

typedef struct FormData_bbf_servers_def
{
	text		servername;
	int32		query_timeout;
	int32		connect_timeout;
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
#define FLAG_CREATED_WITH_RECOMPILE (1<<2)
extern Oid	bbf_function_ext_oid;
extern Oid	bbf_function_ext_idx_oid;

extern Oid	get_bbf_function_ext_oid(void);
extern Oid	get_bbf_function_ext_idx_oid(void);
extern HeapTuple get_bbf_function_tuple_from_proctuple(HeapTuple proctuple);
extern void clean_up_bbf_function_ext(int16 dbid);
extern bool is_created_with_recompile(Oid objectId);
extern bool is_classic_catalog(const char *name);

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
 *			SCHEMA_PERMISSIONS
 *****************************************/
#define BBF_SCHEMA_PERMS_TABLE_NAME "babelfish_schema_permissions"
#define BBF_SCHEMA_PERMS_IDX_NAME "babelfish_schema_permissions_pkey"
#define BBF_SCHEMA_PERMS_NUM_OF_COLS 8
#define Anum_bbf_schema_perms_dbid 1
#define Anum_bbf_schema_perms_schema_name 2
#define Anum_bbf_schema_perms_object_name 3
#define Anum_bbf_schema_perms_permission 4
#define Anum_bbf_schema_perms_grantee 5
#define Anum_bbf_schema_perms_object_type 6
#define Anum_bbf_schema_perms_function_args 7
#define Anum_bbf_schema_perms_grantor 8

#define PUBLIC_ROLE_NAME "public"
#define BABELFISH_SECURITYADMIN "securityadmin"
#define BABELFISH_SYSADMIN "sysadmin"
#define BABELFISH_DBCREATOR "dbcreator"
#define PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA "ALL"
#define ALL_PERMISSIONS_ON_RELATION 47 /* last 6 bits as 101111 represents ALL privileges on a relation. */
#define ALL_PERMISSIONS_ON_FUNCTION 128 /* last 8 bits as 10000000 represents ALL privileges on a procedure/function. */
#define OBJ_SCHEMA "s"
#define OBJ_RELATION "r"
#define OBJ_PROCEDURE "p"
#define OBJ_FUNCTION "f"
#define NUMBER_OF_PERMISSIONS 6

/* check if rolename is sysadmin */
#define IS_ROLENAME_SYSADMIN(rolname) \
	(strlen(rolname) == 8 && \
	strncmp(rolname, BABELFISH_SYSADMIN, 8) == 0)

/* check if rolename is securityadmin */
#define IS_ROLENAME_SECURITYADMIN(rolname) \
	(strlen(rolname) == 13 && \
	strncmp(rolname, BABELFISH_SECURITYADMIN, 13) == 0)

/* check if rolename is dbcreator */
#define IS_ROLENAME_DBCREATOR(rolname) \
	(strlen(rolname) == 9 && \
	strncmp(rolname, BABELFISH_DBCREATOR, 9) == 0)

#define IS_BBF_FIXED_SERVER_ROLE(rolename) \
	(IS_ROLENAME_SYSADMIN(rolename) || \
	IS_ROLENAME_SECURITYADMIN(rolename) || \
	IS_ROLENAME_DBCREATOR(rolename))

extern int permissions[];

extern Oid bbf_schema_perms_oid;
extern Oid bbf_schema_perms_idx_oid;

extern Oid get_bbf_schema_perms_oid(void);

typedef struct FormData_bbf_schema_perms
{
	int16		dbid;
	VarChar	schema_name;
	VarChar	object_name;
	int32		permission;
	VarChar	grantee;
	char	object_type;
	text	function_args;
} FormData_bbf_schema_perms;

typedef FormData_bbf_schema_perms *Form_bbf_schema_perms;

extern void add_entry_to_bbf_schema_perms(const char *schema_name, const char *object_name, int permission, const char *grantee, const char *object_type, const char *func_args);
extern bool privilege_exists_in_bbf_schema_permissions(const char *schema_name, const char *object_name, const char *grantee);
extern void update_privileges_of_object(const char *schema_name, const char *object_name, int new_permission, const char *grantee, const char *object_type, bool is_grant);
extern void remove_entry_from_bbf_schema_perms(const char *schema_name, const char *object_name, const char *grantee, const char *object_type);
extern void add_or_update_object_in_bbf_schema(const char *schema_name, const char *object_name, int new_permission, const char *grantee, const char *object_type, bool is_grant, const char *func_args);
extern void clean_up_bbf_schema_permissions(const char *schema_name, const char *object_name, bool is_schema);
extern void grant_perms_to_objects_in_schema(const char *schema_name, int permission, const char *grantee);
extern void exec_internal_grant_on_function(const char *logicalschema, const char *object_name, const char *object_type);

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
 *			EXTENDED_PROPERTIES
 *****************************************/
#define BBF_EXTENDED_PROPERTIES_TABLE_NAME "babelfish_extended_properties"
#define BBF_EXTENDED_PROPERTIES_IDX_NAME "babelfish_extended_properties_pkey"

#define Anum_bbf_extended_properties_dbid 1
#define Anum_bbf_extended_properties_schema_name 2
#define Anum_bbf_extended_properties_major_name 3
#define Anum_bbf_extended_properties_minor_name 4
#define Anum_bbf_extended_properties_type 5
#define Anum_bbf_extended_properties_name 6
#define Anum_bbf_extended_properties_orig_name 7
#define Anum_bbf_extended_properties_value 8
#define BBF_EXTENDED_PROPERTIES_NUM_COLS 8

extern Oid	bbf_extended_properties_oid;
extern Oid	bbf_extended_properties_idx_oid;

extern Oid	get_bbf_extended_properties_oid(void);
extern Oid	get_bbf_extended_properties_idx_oid(void);

/*****************************************
 *			PARTITION_FUNCTION
 *****************************************/
#define BBF_PARTITION_FUNCTION_TABLE_NAME "babelfish_partition_function"
#define BBF_PARTITION_FUNCTION_PK_IDX_NAME "babelfish_partition_function_pkey"
#define BBF_PARTITION_FUNCTION_ID_IDX_NAME "babelfish_partition_function_function_id_key"
#define BBF_PARTITION_FUNCTION_SEQ_NAME "babelfish_partition_function_seq"

#define Anum_bbf_partition_function_dbid 1
#define Anum_bbf_partition_function_id 2
#define Anum_bbf_partition_function_name 3
#define Anum_bbf_partition_function_input_parameter_type 4
#define Anum_bbf_partition_function_partition_option 5
#define Anum_bbf_partition_function_range_values 6

#define BBF_PARTITION_FUNCTION_NUM_COLS 8

extern Oid	bbf_partition_function_oid;
extern Oid	bbf_partition_function_pk_idx_oid;
extern Oid	bbf_partition_function_id_idx_oid;
extern Oid	bbf_partition_function_seq_oid;

extern Oid	get_bbf_partition_function_oid(void);
extern Oid	get_bbf_partition_function_pk_idx_oid(void);
extern Oid	get_bbf_partition_function_id_idx_oid(void);
extern Oid	get_bbf_partition_function_seq_oid(void);
extern int32	get_available_partition_function_id(void);
extern void	add_entry_to_bbf_partition_function(int16 dbid, const char *partition_function_name,
						char *typname, bool partition_option, ArrayType *values);
extern void	remove_entry_from_bbf_partition_function(int16 dbid, const char *partition_function_name);
extern bool	partition_function_exists(int16 dbid, const char *partition_function_name);
extern int	get_partition_count(int16 dbid, const char *partition_function_name);
extern void	clean_up_bbf_partition_metadata(int16 dbid);


/*****************************************
 *			PARTITION_SCHEME
 *****************************************/
#define BBF_PARTITION_SCHEME_TABLE_NAME "babelfish_partition_scheme"
#define BBF_PARTITION_SCHEME_PK_IDX_NAME "babelfish_partition_scheme_pkey"
#define BBF_PARTITION_SCHEME_ID_IDX_NAME "babelfish_partition_scheme_scheme_id_key"
#define BBF_PARTITION_SCHEME_SEQ_NAME "babelfish_partition_scheme_seq"

#define Anum_bbf_partition_scheme_dbid 1
#define Anum_bbf_partition_scheme_id 2
#define Anum_bbf_partition_scheme_name 3
#define Anum_bbf_partition_scheme_func_name 4
#define Anum_bbf_partition_scheme_next_used 5
#define BBF_PARTITION_SCHEME_NUM_COLS 5

extern Oid	bbf_partition_scheme_oid;
extern Oid	bbf_partition_scheme_pk_idx_oid;
extern Oid	bbf_partition_scheme_id_idx_oid;
extern Oid	bbf_partition_scheme_seq_oid;

extern Oid	get_bbf_partition_scheme_oid(void);
extern Oid	get_bbf_partition_scheme_pk_idx_oid(void);
extern Oid	get_bbf_partition_scheme_id_idx_oid(void);
extern Oid	get_bbf_partition_scheme_seq_oid(void);
extern int32	get_available_partition_scheme_id(void);
extern void	add_entry_to_bbf_partition_scheme(int16 dbid, const char *partition_scheme_name, const char *partition_function_name, bool next_used);
extern void	remove_entry_from_bbf_partition_scheme(int16 dbid, const char *partition_scheme_name);
extern bool	partition_scheme_exists(int16 dbid, const char *partition_scheme_name);
extern char	*get_partition_function_name(int16 dbid, const char *partition_scheme_name);

/*****************************************
 *			PARTITION_DEPEND
 *****************************************/
#define BBF_PARTITION_DEPEND_TABLE_NAME "babelfish_partition_depend"
#define BBF_PARTITION_DEPEND_IDX_NAME "babelfish_partition_depend_pkey"

#define Anum_bbf_partition_depend_dbid 1
#define Anum_bbf_partition_depend_scheme_name 2
#define Anum_bbf_partition_depend_table_schema_name 3
#define Anum_bbf_partition_depend_table_name 4
#define BBF_PARTITION_DEPEND_NUM_COLS 4

extern Oid	bbf_partition_depend_oid;
extern Oid	bbf_partition_depend_idx_oid;

extern Oid	get_bbf_partition_depend_oid(void);
extern Oid	get_bbf_partition_depend_idx_oid(void);
extern void	add_entry_to_bbf_partition_depend(int16 dbid, char* partition_scheme_name, char *schema_name, char *table_name);
extern void	remove_entry_from_bbf_partition_depend(int16 dbid, char *schema_name, char *table_name);
extern bool	is_bbf_partitioned_table(int16 dbid, char *schema_name, char *table_name);
extern char	*get_partition_scheme_for_partitioned_table(int16 dbid, char *schema_name, char *table_name);
extern void	rename_table_update_bbf_partition_depend_catalog(RenameStmt *stmt, char *logical_schema_name, int16 dbid);


typedef struct FormData_bbf_extended_properties
{
	int16		dbid;
	NameData	schema_name;
	NameData	major_name;
	NameData	minor_name;
	VarChar		type;
	VarChar		name;
	VarChar		orig_name;
	bytea		value;
} FormData_bbf_extended_properties;

typedef FormData_bbf_extended_properties *Form_bbf_extended_properties;

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
