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

/*****************************************
 * 			Catalog Hooks
 *****************************************/
extern bool IsPLtsqlExtendedCatalog(Oid relationId);

/*****************************************
 *			SYS schema
 *****************************************/
extern Oid sys_schema_oid;

/*****************************************
 *			SYSDATABASES
 *****************************************/
#define SYSDATABASES_TABLE_NAME "babelfish_sysdatabases"
#define SYSDATABASES_PK_NAME "babelfish_sysdatabases_pkey"
#define SYSDATABASES_OID_IDX_NAME "babelfish_sysdatabases_dboid_key"

extern Oid sysdatabases_oid;
extern Oid sysdatabaese_idx_oid_oid;
extern Oid sysdatabaese_idx_name_oid;

/* MUST comply with babelfish_sysdatabases table */
#define SYSDATABASES_NUM_COLS 8
#define Anum_sysdatabaese_oid 1
#define Anum_sysdatabaese_name 6
#define Anum_sysdatabaese_crdate 7

/* MUST comply with babelfish_sysdatabases table */
typedef struct FormData_sysdatabases
{
	int16  		dbid;
	int32		status;
	int32       status2;
	NameData 	owner;
	NameData    default_collation;
	text		name;
	TimestampTz crdate;
	text		properties;
} FormData_sysdatabases;

typedef FormData_sysdatabases *Form_sysdatabases;

/* MUST comply with babelfish_authid_login_ext table */
typedef struct FormData_authid_login_ext
{
	NameData  	rolname;
	int32		is_disabled;
	char        type;
	int32 	    credential_id;
	int32     	owning_principal_id;
	int32     	is_fixed_role;
	TimestampTz	create_date;
	TimestampTz	modify_date;
	VarChar		default_database_name;
	VarChar		default_language_name;
	Jsonb		properties;
} FormData_authid_login_ext;

typedef FormData_authid_login_ext *Form_authid_login_ext;

#define InvalidDbid 0
#define DbidIsValid(id)  ((bool) ((id) != InvalidDbid))

extern int16 get_db_id(const char *dbname);
extern char *get_db_name(int16 dbid);
extern void initTsqlSyscache(void);
extern const char *get_one_user_db_name(void);

#define DEFAULT_DATABASE_COMPATIBILITY_LEVEL 80

/*****************************************
 *			NAMESPACE_EXT
 *****************************************/
#define NAMESPACE_EXT_TABLE_NAME "babelfish_namespace_ext"
#define NAMESAPCE_EXT_PK_NAME "babelfish_namespace_ext_pkey"
#define Anum_namespace_ext_namespace 1
#define Anum_namespace_ext_orig_name 3
#define NAMESPACE_EXT_NUM_COLS 4

extern Oid namespace_ext_oid;
extern Oid namespace_ext_idx_oid_oid;
extern int namespace_ext_num_cols;

extern const char *get_logical_schema_name(const char *physical_schema_name, bool missingOk);

/*****************************************
 *			LOGIN EXT
 *****************************************/
#define BBF_AUTHID_LOGIN_EXT_TABLE_NAME "babelfish_authid_login_ext"
#define BBF_AUTHID_LOGIN_EXT_IDX_NAME "babelfish_authid_login_ext_pkey"
#define Anum_bbf_authid_login_ext_rolname 1
extern Oid			bbf_authid_login_ext_oid;
extern Oid			bbf_authid_login_ext_idx_oid;

extern bool is_login(Oid role_oid);
extern bool is_login_name(char *rolname);
extern char *get_login_default_db(char *login_name);
extern Oid get_authid_login_ext_oid(void);
extern Oid get_authid_login_ext_idx_oid(void);

/*****************************************
 *			USER EXT
 *****************************************/
#define BBF_AUTHID_USER_EXT_TABLE_NAME "babelfish_authid_user_ext"
#define BBF_AUTHID_USER_EXT_IDX_NAME "babelfish_authid_user_ext_pkey"
#define Anum_bbf_authid_user_ext_rolname		1
#define Anum_bbf_authid_user_ext_login_name		2
#define Anum_bbf_authid_user_ext_database_name	12
extern Oid			bbf_authid_user_ext_oid;
extern Oid			bbf_authid_user_ext_idx_oid;

extern bool is_user(Oid role_oid);
extern Oid get_authid_user_ext_oid(void);
extern Oid get_authid_user_ext_idx_oid(void);

/* MUST comply with babelfish_authid_user_ext table */
typedef struct FormData_authid_user_ext
{
	NameData  	rolname;
	NameData	login_name;
	char		type;
	int32		owning_principal_id;
	int32		is_fixed_role;
	int32		authentication_type;
	int32		default_language_lcid;
	int32		allow_encrypted_value_modifications;
	TimestampTz	create_date;
	TimestampTz	modify_date;
	VarChar		orig_username;
	VarChar		database_name;
	VarChar		default_schema_name;
	VarChar		default_language_name;
	VarChar		authentication_type_desc;
} FormData_authid_user_ext;

typedef FormData_authid_user_ext *Form_authid_user_ext;

/*****************************************
 *			Metadata Check Rule
 *****************************************/
typedef struct RelData
{
	const char		*tblname;	/* table name */
	Oid				tbl_oid;	/* table oid */
	Oid				idx_oid;	/* index oid */
	Oid				atttype;	/* index column's type oid */
	AttrNumber		attnum;		/* index column's attribute num */
	RegProcedure	regproc;	/* regproc used to scan through the index */
} RelData;

typedef struct Rule
{
	const char	*desc;		/* rule description */
	const char	*tblname;	/* catalog name */
	const char	*colname;	/* column name */

	/* 
	 * The expected value can either be a Datum or the result of a value
	 * function.
	 * A value function reads a tuple and output a Datum. 
	 * Category 1 rules: Input tuple is NULL.
	 * Category 2 rules: Input tuple is provided by a catalog (often different
	 *					 from tblname.
	 * tupdesc is the description for the input tuple.
	 */
	TupleDesc	tupdesc;
	Datum		(*func_val) (HeapTuple tuple, TupleDesc dsc);

	/* function to check whether certain condition is satisfied */
	bool		(*func_cond) (void);
	/* function to validate the rule */
	bool		(*func_check) (void *rule_arg, HeapTuple tuple);

	RelData		*tbldata;	/* extra catalog info */
} Rule;

#endif
