/*-------------------------------------------------------------------------
 *
 * pl_handler.c		- Handler for the PL/tsql
 *			  procedural language
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/pl/pltsql/src/pl_handler.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "access/attnum.h"
#include "access/relation.h"
#include "access/htup_details.h"
#include "access/parallel.h"
#include "access/table.h"
#include "catalog/heap.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_language.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "catalog/pg_default_acl.h"
#include "catalog/pg_shdepend.h"
#include "commands/createas.h"
#include "commands/dbcommands.h"
#include "commands/defrem.h"
#include "commands/extension.h"
#include "commands/sequence.h"
#include "commands/tablecmds.h"
#include "commands/trigger.h"
#include "commands/user.h"
#include "common/md5.h"
#include "common/string.h"
#include "funcapi.h"
#include "mb/pg_wchar.h"
#include "nodes/makefuncs.h"
#include "nodes/nodeFuncs.h"
#include "nodes/pg_list.h"
#include "parser/analyze.h"
#include "parser/parser.h"
#include "parser/parse_clause.h"
#include "parser/parse_expr.h"
#include "parser/parse_relation.h"
#include "parser/parse_target.h"
#include "parser/parse_type.h"
#include "parser/parse_utilcmd.h"
#include "parser/scansup.h"
#include "pgstat.h"				/* for pgstat related activities */
#include "tcop/pquery.h"
#include "tcop/tcopprot.h"
#include "tcop/utility.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/guc_tables.h"
#include "utils/lsyscache.h"
#include "utils/plancache.h"
#include "utils/ps_status.h"
#include "utils/queryenvironment.h"
#include "utils/rel.h"
#include "utils/relcache.h"
#include "utils/snapmgr.h"
#include "utils/syscache.h"
#include "utils/varlena.h"
#include "utils/guc.h"

#include "analyzer.h"
#include "catalog.h"
#include "codegen.h"
#include "collation.h"
#include "dbcmds.h"
#include "err_handler.h"
#include "extendedproperty.h"
#include "guc.h"
#include "hooks.h"
#include "iterative_exec.h"
#include "rolecmds.h"
#include "multidb.h"
#include "schemacmds.h"
#include "session.h"
#include "pltsql.h"
#include "pltsql_partition.h"
#include "pl_explain.h"
#include "table_variable_mvcc.h"

#include "access/xact.h"

extern int  escape_hatch_set_transaction_isolation_level;
extern bool pltsql_recursive_triggers;
extern bool restore_tsql_tabletype;
extern bool babelfish_dump_restore;
extern bool pltsql_nocount;

extern List *babelfishpg_tsql_raw_parser(const char *str, RawParseMode mode);
extern bool install_backend_gram_hooks();

static bool check_identity_insert(char **newal, void **extra, GucSource source);
static void assign_identity_insert(const char *newval, void *extra);
static void assign_textsize(int newval, void *extra);
extern Datum init_collid_trans_tab(PG_FUNCTION_ARGS);
extern Datum init_like_ilike_table(PG_FUNCTION_ARGS);
extern Datum init_tsql_coerce_hash_tab(PG_FUNCTION_ARGS);
extern Datum init_tsql_datatype_precedence_hash_tab(PG_FUNCTION_ARGS);
extern Datum init_tsql_cursor_hash_tab(PG_FUNCTION_ARGS);
extern PLtsql_execstate *get_current_tsql_estate(void);
extern PLtsql_execstate *get_outermost_tsql_estate(int *nestlevel);
extern void pre_check_trigger_schema(List *object, bool missing_ok);
static void get_language_procs(const char *langname, Oid *compiler, Oid *validator);
static void get_func_language_oids(Oid *lang_handler, Oid *lang_validator);
extern bool pltsql_suppress_string_truncation_error();
static Oid	bbf_table_var_lookup(const char *relname, Oid relnamespace);
extern void assign_object_access_hook_drop_relation(void);
extern void uninstall_object_access_hook_drop_relation(void);
static Oid	pltsql_seq_type_map(Oid typid);
bool		canCommitTransaction(void);
extern void assign_tablecmds_hook(void);
static void bbf_ProcessUtility(PlannedStmt *pstmt,
							   const char *queryString,
							   bool readOnlyTree,
							   ProcessUtilityContext context,
							   ParamListInfo params,
							   QueryEnvironment *queryEnv,
							   DestReceiver *dest,
							   QueryCompletion *qc);
static void call_prev_ProcessUtility(PlannedStmt *pstmt,
						 const char *queryString,
						 bool readOnlyTree,
						 ProcessUtilityContext context,
						 ParamListInfo params,
						 QueryEnvironment *queryEnv,
						 DestReceiver *dest,
						 QueryCompletion *qc);
static void set_pgtype_byval(List *name, bool byval);
static void pltsql_proc_get_oid_proname_proacl(AlterFunctionStmt *stmt, ParseState *pstate, Oid *oid, Acl **acl, bool *isSameFunc, bool is_proc);
static void pg_proc_update_oid_acl(ObjectAddress address, Oid oid, Acl *acl);
static bool pltsql_truncate_identifier(char *ident, int len, bool warn);
static Name pltsql_cstr_to_name(char *s, int len);
extern void pltsql_add_guc_plan(CachedPlanSource *plansource);
extern bool pltsql_check_guc_plan(CachedPlanSource *plansource);
bool		pltsql_function_as_checker(const char *lang, List *as, char **prosrc_str_p, char **probin_str_p);
extern void pltsql_function_probin_writer(CreateFunctionStmt *stmt, Oid languageOid, char **probin_str_p);
extern void pltsql_function_probin_reader(ParseState *pstate, List *fargs, Oid *actual_arg_types, Oid *declared_arg_types, Oid funcid);
static void check_nullable_identity_constraint(RangeVar *relation, ColumnDef *column);
static bool is_identity_constraint(ColumnDef *column);
extern PLtsql_function *find_cached_batch(int handle);
extern void apply_post_compile_actions(PLtsql_function *func, InlineCodeBlockArgs *args);
Datum		sp_prepare(PG_FUNCTION_ARGS);
Datum		sp_unprepare(PG_FUNCTION_ARGS);
static List *transformSelectIntoStmt(CreateTableAsStmt *stmt);
static char *get_oid_type_string(int type_oid);
static int64 get_identity_into_args(Node *node);
extern char *construct_unique_index_name(char *index_name, char *relation_name);
extern int	CurrentLineNumber;
static non_tsql_proc_entry_hook_type prev_non_tsql_proc_entry_hook = NULL;
static void pltsql_non_tsql_proc_entry(int proc_count, int sys_func_count);
static void set_procid(Oid oid);
static bool is_rowversion_column(ParseState *pstate, ColumnDef *column);
static void validate_rowversion_column_constraints(ColumnDef *column);
static void validate_rowversion_table_constraint(Constraint *c, char *rowversion_column_name);
static Constraint *get_rowversion_default_constraint(TypeName *typname);
static void revoke_type_permission_from_public(PlannedStmt *pstmt, const char *queryString, bool readOnlyTree,
											   ProcessUtilityContext context, ParamListInfo params, QueryEnvironment *queryEnv, DestReceiver *dest, QueryCompletion *qc, List *type_name);
static void set_current_query_is_create_tbl_check_constraint(Node *expr);
static void validateUserAndRole(char *name);

static void bbf_ExecDropStmt(DropStmt *stmt);

static int isolation_to_int(char *isolation_level);
static void bbf_set_tran_isolation(char *new_isolation_level_str);

typedef struct {
	int oid;
	char *alias;
	int nestLevel;
} forjson_table;

static bool handleForJsonAuto(Query *query, forjson_table **tableInfoArr, int numTables);
static bool isJsonAuto(List* target);
static bool check_json_auto_walker(Node *node, ParseState *pstate);
static TargetEntry* buildJsonEntry(int nestLevel, char* tableAlias, TargetEntry* te);
static void modifyColumnEntries(List* targetList, forjson_table **tableInfoArr, int numTables, Alias *colnameAlias, bool isCve);

extern bool pltsql_ansi_defaults;
extern bool pltsql_quoted_identifier;
extern bool pltsql_concat_null_yields_null;
extern bool pltsql_ansi_nulls;
extern bool pltsql_ansi_null_dflt_on;
extern bool pltsql_ansi_padding;
extern bool pltsql_ansi_warnings;
extern bool pltsql_arithabort;
extern int	pltsql_datefirst;
extern char *pltsql_language;
extern int	pltsql_lock_timeout;

PG_FUNCTION_INFO_V1(pltsql_inline_handler);

static Oid	lang_handler_oid = InvalidOid;	/* Oid of language handler
											 * function */
static Oid	lang_validator_oid = InvalidOid;	/* Oid of language validator
												 * function */

PG_MODULE_MAGIC;

/* Module callbacks */
void		_PG_init(void);
void		_PG_fini(void);

/* Custom GUC variable */
static const struct config_enum_entry variable_conflict_options[] = {
	{"error", PLTSQL_RESOLVE_ERROR, false},
	{"use_variable", PLTSQL_RESOLVE_VARIABLE, false},
	{"use_column", PLTSQL_RESOLVE_COLUMN, false},
	{NULL, 0, false}
};

static const struct config_enum_entry schema_mapping_options[] = {
	{"db_schema", PLTSQL_DB_SCHEMA, false},
	{"db", PLTSQL_DB, false},
	{"schema", PLTSQL_SCHEMA, false},
	{NULL, 0, false}
};

Oid			procid_var = InvalidOid;

int			pltsql_variable_conflict = PLTSQL_RESOLVE_ERROR;

int			pltsql_schema_mapping;

int			pltsql_extra_errors;
bool		pltsql_debug_parser = false;
char	   *identity_insert_string;
bool		output_update_transformation = false;
bool		output_into_insert_transformation = false;
char	   *update_delete_target_alias = NULL;
int			pltsql_trigger_depth = 0;

PLExecStateCallStack *exec_state_call_stack = NULL;
int			text_size;
Portal		pltsql_snapshot_portal = NULL;
int			pltsql_non_tsql_proc_entry_count = 0;
int			pltsql_sys_func_entry_count = 0;
static 		slist_head guc_stack_list;
static int	PltsqlGUCNestLevel = 0;
static guc_push_old_value_hook_type prev_guc_push_old_value_hook = NULL;
static validate_set_config_function_hook_type prev_validate_set_config_function_hook = NULL;
static void pltsql_guc_push_old_value(struct config_generic *gconf, GucAction action);
bool		current_query_is_create_tbl_check_constraint = false;

/* Configurations */
bool		pltsql_trace_tree = false;
bool		pltsql_trace_exec_codes = false;
bool		pltsql_trace_exec_counts = false;
bool		pltsql_trace_exec_time = false;

tsql_identity_insert_fields tsql_identity_insert = {false, InvalidOid, InvalidOid};

/* Hook for plugins */
PLtsql_plugin **pltsql_plugin_ptr = NULL;
PLtsql_instr_plugin **pltsql_instr_plugin_ptr = NULL;
PLtsql_protocol_plugin **pltsql_protocol_plugin_ptr = NULL;

/* Save hook values in case of unload */
static pre_parse_analyze_hook_type prev_pre_parse_analyze_hook = NULL;
static post_parse_analyze_hook_type prev_post_parse_analyze_hook = NULL;
static pltsql_sequence_validate_increment_hook_type prev_pltsql_sequence_validate_increment_hook = NULL;
static pltsql_identity_datatype_hook_type prev_pltsql_identity_datatype_hook = NULL;
static pltsql_sequence_datatype_hook_type prev_pltsql_sequence_datatype_hook = NULL;
static relname_lookup_hook_type prev_relname_lookup_hook = NULL;
static ProcessUtility_hook_type prev_ProcessUtility = NULL;
static get_func_language_oids_hook_type prev_get_func_language_oids_hook = NULL;
static tsql_has_linked_srv_permissions_hook_type prev_tsql_has_linked_srv_permissions_hook = NULL;
plansource_complete_hook_type prev_plansource_complete_hook = NULL;
plansource_revalidate_hook_type prev_plansource_revalidate_hook = NULL;
planner_node_transformer_hook_type prev_planner_node_transformer_hook = NULL;
pltsql_nextval_hook_type prev_pltsql_nextval_hook = NULL;
pltsql_resetcache_hook_type prev_pltsql_resetcache_hook = NULL;
pltsql_setval_hook_type prev_pltsql_setval_hook = NULL;

static void
set_procid(Oid oid)
{
	procid_var = oid;
}

static bool
check_identity_insert(char** newval, void **extra, GucSource source)
{
	/*
	 * Workers synchronize the parameter at the beginning of each parallel
	 * operation. Avoid performing parameter assignment uring parallel operation.
	 */
	if (IsParallelWorker() && !InitializingParallelWorker)
	{
        /*
         * A change other than during startup, for example due to a SET clause
         * attached to a function definition, should be rejected, as there is
         * nothing we can do inside the worker to make it take effect.
         */
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_TRANSACTION_STATE),
				 errmsg("cannot change identity_insert during a parallel operation")));
	}

	return true;
}

static void
assign_identity_insert(const char *newval, void *extra)
{
	if (IsParallelWorker())
		return;

	if (strcmp(newval, "") != 0)
	{
		List	   *elemlist;
		Oid			rel_oid;
		Oid			schema_oid;
		char	   *option_flag;
		char	   *rel_name;
		char	   *schema_name = NULL;
		char	   *input_string = pstrdup(newval);
		char	   *id_insert_rel_name = NULL;
		char	   *id_insert_schema_name = NULL;
		char	   *cur_db_name;

		cur_db_name = get_cur_db_name();

		/* Check if IDENTITY_INSERT is valid and get names. If not, reset it. */
		if (tsql_identity_insert.valid)
		{
			id_insert_rel_name = get_rel_name(tsql_identity_insert.rel_oid);

			if (!id_insert_rel_name)
				tsql_identity_insert.valid = false;
			else
				id_insert_schema_name = get_namespace_name(tsql_identity_insert.schema_oid);
		}

		/* Parse user input string into list of identifiers */
		if (!SplitGUCList(input_string, '.', &elemlist))
		{
			/* syntax error in list */
			GUC_check_errdetail("List syntax is invalid.");
			pfree(input_string);
			list_free(elemlist);
			return;
		}

		option_flag = (char *) linitial(elemlist);
		rel_name = (char *) lsecond(elemlist);

		/* Check the user provided schema value */
		if (list_length(elemlist) >= 3)
		{
			schema_name = (char *) lthird(elemlist);

			if (cur_db_name)
				schema_name = get_physical_schema_name(cur_db_name,
													   schema_name);

			schema_oid = LookupExplicitNamespace(schema_name, true);
			if (!OidIsValid(schema_oid))
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_SCHEMA),
						 errmsg("schema \"%s\" does not exist",
								schema_name)));

			rel_oid = get_relname_relid(rel_name, schema_oid);
			if (!OidIsValid(rel_oid))
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_TABLE),
						 errmsg("relation \"%s\" does not exist",
								rel_name)));
		}

		/* Check the catalog name then ignore it */
		if (list_length(elemlist) == 4)
		{
			char	   *catalog_name = (char *) lfourth(elemlist);

			if (strcmp(catalog_name, get_database_name(MyDatabaseId)) != 0)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("cross-database references are not implemented: \"%s.%s.%s\"",
								catalog_name, schema_name, rel_name)));
		}

		/* If schema is not provided, find it from the search path. */
		if (!schema_name)
		{
			/*
			 * If the relation exists, retrieve the relation Oid from the
			 * first schema that contains it.
			 */
			rel_oid = RelnameGetRelid(rel_name);
			if (!OidIsValid(rel_oid))
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_TABLE),
						 errmsg("relation \"%s\" does not exist",
								rel_name)));

			schema_oid = get_rel_namespace(rel_oid);
			schema_name = get_namespace_name(schema_oid);
		}

		/* Process assignment logic */
		if (strcmp(option_flag, "on") == 0)
		{
			if (!tsql_identity_insert.valid)
			{
				/* Check if relation has identity property */
				Relation	rel;
				TupleDesc	tupdesc;
				int			attnum;
				bool		has_ident = false;

				rel = RelationIdGetRelation(rel_oid);
				tupdesc = RelationGetDescr(rel);

				for (attnum = 0; attnum < tupdesc->natts; attnum++)
				{
					Form_pg_attribute attr = TupleDescAttr(tupdesc, attnum);

					if (attr->attidentity)
					{
						has_ident = true;
						break;
					}
				}

				RelationClose(rel);

				if (!has_ident)
					ereport(ERROR,
							(errcode(ERRCODE_UNDEFINED_COLUMN),
							 errmsg("Table '%s.%s' does not have the identity property. Cannot perform SET operation.",
									schema_name, rel_name)));

				/* Set IDENTITY_INSERT to the user value */
				tsql_identity_insert.rel_oid = rel_oid;
				tsql_identity_insert.schema_oid = schema_oid;
				tsql_identity_insert.valid = true;
			}
			else if (rel_oid != tsql_identity_insert.rel_oid)
			{
				/* IDENTITY_INSERT is already on and tables do not match */
				ereport(ERROR,
						(errcode(ERRCODE_RESTRICT_VIOLATION),
						 errmsg("IDENTITY_INSERT is already ON for table \'%s.%s.%s\'",
								get_database_name(MyDatabaseId),
								id_insert_schema_name,
								id_insert_rel_name)));
			}
			/* IDENTITY_INSERT is already set to the table. Keep the value */
		}
		else if (strcmp(option_flag, "off") == 0)
		{
			if (rel_oid == tsql_identity_insert.rel_oid)
			{
				/*
				 * IDENTITY_INSERT is currently set and tables match. Set to
				 * off
				 */
				tsql_identity_insert.valid = false;
			}

			/*
			 * User sets to off and already off or different table. Keep the
			 * value
			 */
		}
		else
		{
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("unknown option value")));
		}

		/* Clean up */
		pfree(input_string);
		list_free(elemlist);
	}
}

static void
assign_textsize(int newval, void *extra)
{
	if (pltsql_protocol_plugin_ptr && *pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr)->set_guc_stat_var)
		(*pltsql_protocol_plugin_ptr)->set_guc_stat_var("babelfishpg_tsql.textsize", false, NULL, newval);
}

static void
pltsql_pre_parse_analyze(ParseState *pstate, RawStmt *parseTree)
{
	if (prev_pre_parse_analyze_hook)
		prev_pre_parse_analyze_hook(pstate, parseTree);

	switch (parseTree->stmt->type)
	{
		case T_InsertStmt:
			{
				InsertStmt *stmt = (InsertStmt *) parseTree->stmt;
				SelectStmt *selectStmt = (SelectStmt *) stmt->selectStmt;
				Oid			relid;
				ListCell   *lc;

				if (!babelfish_dump_restore || IsBinaryUpgrade)
					break;

				relid = RangeVarGetRelid(stmt->relation, NoLock, false);

				/*
				 * Insert new dbid, owner, function_id and scheme_id column values
				 * in babelfish catalog if dump did not provide it.
				 */
				if (relid == sysdatabases_oid ||
					relid == namespace_ext_oid ||
					relid == bbf_view_def_oid ||
					relid == bbf_extended_properties_oid ||
					relid == bbf_schema_perms_oid ||
					relid == bbf_partition_function_oid ||
					relid == bbf_partition_scheme_oid ||
					relid == bbf_partition_depend_oid)
				{
					ResTarget	*col = NULL;
					A_Const 	*dbidValue = NULL;
					A_Const 	*ownerValue = NULL;
					bool    	dbid_found = false;
					bool    	owner_found = false;
					bool    	function_id_found = false;
					bool    	scheme_id_found = false;


					/* Skip if dbid, owner, function_id and scheme_id column already exists */
					foreach(lc, stmt->cols)
					{
						ResTarget  *col1 = (ResTarget *) lfirst(lc);

						if (pg_strcasecmp(col1->name, "dbid") == 0)
							dbid_found = true;
						if (relid == sysdatabases_oid &&
							pg_strcasecmp(col1->name, "owner") == 0)
							owner_found = true;
						if (relid == bbf_partition_function_oid &&
							pg_strcasecmp(col1->name, "function_id") == 0)
							function_id_found = true;
						if (relid == bbf_partition_scheme_oid &&
							pg_strcasecmp(col1->name, "scheme_id") == 0)
							scheme_id_found = true;
					}
					if (dbid_found && (owner_found || relid != sysdatabases_oid)
							&& (function_id_found || relid != bbf_partition_function_oid)
							&& (scheme_id_found || relid != bbf_partition_scheme_oid))
						break;

					/*
					 * Populate dbid column in Babelfish catalog tables with
					 * new one.
					 */
					if (!dbid_found)
					{
						/* const value node to store into values clause */
						dbidValue = makeNode(A_Const);
						dbidValue->val.ival.type = T_Integer;
						dbidValue->val.ival.ival = getDbidForLogicalDbRestore(relid);
						dbidValue->location = -1;

						/* dbid column to store into InsertStmt's target list */
						col = makeNode(ResTarget);
						col->name = "dbid";
						col->name_location = -1;
						col->indirection = NIL;
						col->val = NULL;
						col->location = -1;
						stmt->cols = lappend(stmt->cols, col);
					}

					/*
					 * Populate owner column in babelfish_sysdatabases catalog table with
					 * SA of the current database.
					 */
					if (!owner_found && relid == sysdatabases_oid)
					{
						/* const value node to store into values clause */
						ownerValue = makeNode(A_Const);
						ownerValue->val.sval.type = T_String;
						ownerValue->val.sval.sval = GetUserNameFromId(get_sa_role_oid(), false);
						ownerValue->location = -1;

						/* owner column to store into InsertStmt's target list */
						col = makeNode(ResTarget);
						col->name = "owner";
						col->name_location = -1;
						col->indirection = NIL;
						col->val = NULL;
						col->location = -1;
						stmt->cols = lappend(stmt->cols, col);
					}

					/*
					 * Populate function_id column in babelfish_partition_function catalog with
					 * new one.
					 */
					if (!function_id_found && relid == bbf_partition_function_oid)
					{
						/* function_id column to store into InsertStmt's target list */
						col = makeNode(ResTarget);
						col->name = "function_id";
						col->name_location = -1;
						col->indirection = NIL;
						col->val = NULL;
						col->location = -1;
						stmt->cols = lappend(stmt->cols, col);
					}

					/*
					 * Populate scheme_id column in babelfish_partition_scheme catalog with
					 * new one.
					 */
					if (!scheme_id_found && relid == bbf_partition_scheme_oid)
					{
						/* scheme_id column to store into InsertStmt's target list */
						col = makeNode(ResTarget);
						col->name = "scheme_id";
						col->name_location = -1;
						col->indirection = NIL;
						col->val = NULL;
						col->location = -1;
						stmt->cols = lappend(stmt->cols, col);
					}

					foreach(lc, selectStmt->valuesLists)
					{
						List	   *sublist = (List *) lfirst(lc);

						if (!dbid_found)
							sublist = lappend(sublist, dbidValue);
						if (!owner_found && relid == sysdatabases_oid)
							sublist = lappend(sublist, ownerValue);
						/*
						 * For babelfish_partition_function and babelfish_partition_scheme catalog,
						 * new ID needs to be added for each value in values clause.
						 */
						if (!function_id_found && relid == bbf_partition_function_oid)
						{
							/* const value node to store into value clause */
							A_Const *functionidValue = makeNode(A_Const);
							functionidValue->val.ival.type = T_Integer;
							functionidValue->location = -1;
							functionidValue->val.ival.ival = get_available_partition_function_id();
							sublist = lappend(sublist, functionidValue);
						}
						if (!scheme_id_found && relid == bbf_partition_scheme_oid)
						{
							/* const value node to store into value clause */
							A_Const *schemeidValue = makeNode(A_Const);
							schemeidValue->val.ival.type = T_Integer;
							schemeidValue->location = -1;
							schemeidValue->val.ival.ival = get_available_partition_scheme_id();
							sublist = lappend(sublist, schemeidValue);
						}
					}
				}
				break;
			}
		default:
			break;
	}

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	if (parseTree->stmt->type == T_CreateFunctionStmt)
	{
		ListCell   *option;
		CreateTrigStmt *trigStmt;
		CreateFunctionStmt *funcStmt = (CreateFunctionStmt *) parseTree->stmt;
		char	   *trig_schema;

		foreach(option, ((CreateFunctionStmt *) parseTree->stmt)->options)
		{
			DefElem    *defel = (DefElem *) lfirst(option);

			if (strcmp(defel->defname, "trigStmt") == 0)
			{
				trigStmt = (CreateTrigStmt *) defel->arg;
				if (trigStmt->args != NIL)
				{
					trig_schema = ((String *) list_nth(((CreateTrigStmt *) trigStmt)->args, 0))->sval;
					if ((trigStmt->relation->schemaname != NULL && strcasecmp(trig_schema, trigStmt->relation->schemaname) != 0)
						|| trigStmt->relation->schemaname == NULL)
					{
						ereport(ERROR,
								(errcode(ERRCODE_INTERNAL_ERROR),
								 errmsg("Cannot create trigger '%s.%s' because its schema is different from the schema of the target table or view.",
										trig_schema, trigStmt->trigname)));
					}
					trigStmt->args = NIL;
				}
				else
				{
					Assert(list_length(funcStmt->funcname) == 1);

					/*
					 * Add schemaname to trigger's function name.
					 */
					if (trigStmt->relation->schemaname != NULL)
					{
						funcStmt->funcname = lcons(makeString(trigStmt->relation->schemaname), funcStmt->funcname);
					}
				}
			}
		}
	}

	if (parseTree->stmt->type == T_DropStmt)
	{
		DropStmt   *dropStmt;

		dropStmt = (DropStmt *) parseTree->stmt;
		if (dropStmt->removeType == OBJECT_TRIGGER)
		{
			ListCell   *cell1;

			/* in case we have multi triggers in one stmt */
			foreach(cell1, dropStmt->objects)
			{
				Node	   *object = lfirst(cell1);

				pre_check_trigger_schema(castNode(List, object), dropStmt->missing_ok);
			}
		}
	}

	if (parseTree->stmt->type == T_AlterTableStmt)
	{
		AlterTableStmt *atstmt = (AlterTableStmt *) parseTree->stmt;
		ListCell *lc;
		char *trig_schema;
		char *rel_schema;

		foreach(lc, atstmt->cmds)
		{
			AlterTableCmd *cmd = (AlterTableCmd *)lfirst(lc);
			if (cmd->subtype == AT_EnableTrig || cmd->subtype == AT_DisableTrig)
			{
				if (atstmt->objtype == OBJECT_TRIGGER)
				{
					trig_schema = cmd->schemaname;
				}
				else
				{
					trig_schema = NULL;
				}

				if (atstmt->relation->schemaname != NULL)
				{
					rel_schema = atstmt->relation->schemaname;
				}
				else
				{
					rel_schema = get_authid_user_ext_schema_name(get_cur_db_name(), GetUserNameFromId(GetUserId(), false));
				}

				if (trig_schema != NULL && strcmp(trig_schema, rel_schema) != 0)
				{
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							errmsg("Trigger %s.%s on table %s.%s does not exists or table %s.%s does not exists",
									trig_schema, cmd->name, rel_schema, atstmt->relation->relname, rel_schema, atstmt->relation->relname)));
				}

				if(atstmt->relation->schemaname == NULL && rel_schema)
				{
					pfree((char *) rel_schema);
				}
			}
		}
	}

	if (enable_schema_mapping())
		rewrite_object_refs(parseTree->stmt);

	switch (parseTree->stmt->type)
	{
		case T_CreateStmt:
			{
				CreateStmt *create_stmt = (CreateStmt *) parseTree->stmt;
				ListCell   *elements;

				/*
				 * We should not allow "create if not exists" in TSQL
				 * semantics. The only reason for allowing temp tables for now
				 * is that they are used internally to declare table type.
				 * Please see exec_stmt_decl_table().
				 */
				if (create_stmt->if_not_exists &&
					create_stmt->relation->relpersistence != RELPERSISTENCE_TEMP)
				{
					ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							 errmsg("Incorrect syntax near '%s'", create_stmt->relation->relname)));

				}

				/* SYSNAME datatype is default not null */
				foreach(elements, create_stmt->tableElts)
				{
					Node	   *element = lfirst(elements);
					ColumnDef  *coldef;

					if (nodeTag(element) != T_ColumnDef)
						continue;

					coldef = castNode(ColumnDef, element);

					if (!is_sysname_column(coldef))
						continue;

					/*
					 * If the SYSNAME column is not explicitly defined as
					 * NULL, take it as not NULL
					 */
					if (!have_null_constr(coldef->constraints))
					{
						Constraint *c = makeNode(Constraint);

						c->contype = CONSTR_NOTNULL;
						c->location = -1;
						coldef->constraints = lappend(coldef->constraints, c);
					}
				}
				break;
			}
		case T_AlterTableStmt:
			{
				AlterTableStmt *atstmt = (AlterTableStmt *) parseTree->stmt;
				ListCell   *lc;

				foreach(lc, atstmt->cmds)
				{
					AlterTableCmd *cmd = (AlterTableCmd *) lfirst(lc);

					switch (cmd->subtype)
					{
						case AT_AddColumn:
							{
								/* SYSNAME datatype is default not null */
								ColumnDef  *coldef = castNode(ColumnDef, cmd->def);

								if (!is_sysname_column(coldef))
									continue;

								/*
								 * If the SYSNAME column is not explicitly
								 * defined as NULL, take it as not NULL
								 */
								if (!have_null_constr(coldef->constraints))
								{
									Constraint *c = makeNode(Constraint);

									c->contype = CONSTR_NOTNULL;
									c->location = -1;
									coldef->constraints = lappend(coldef->constraints, c);
								}
								break;
							}

							/*
							 * TODO: After ALTER TABLE ALTER COLUMN [NOT] NULL
							 * is supported, we should add same SYSNAME check
							 * code for ALTER TABLE ALTER COLUMN
							 */
						default:
							break;
					}
				}
				break;
			}
		case T_GrantStmt:
			{
				/* detect object type */
				GrantStmt  *grant = (GrantStmt *) parseTree->stmt;
				ListCell   *cell;
				List	   *plan_name = NIL;
				ObjectWithArgs *func = NULL;

				Assert(list_length(grant->objects) == 1);
				foreach(cell, grant->objects)
				{
					RangeVar   *rv = (RangeVar *) lfirst(cell);
					char	   *schema = rv->schemaname;	/* this is physical name */
					char	   *obj = rv->relname;
					Oid			func_oid;

					/* table, sequence, view, materialized view */
					/* don't distinguish table sequence here */
					if (RangeVarGetRelid(rv, NoLock, true) != InvalidOid)
						break;	/* do nothing */


					if (schema)
						plan_name = list_make2(makeString(schema), makeString(obj));
					else
						plan_name = list_make1(makeString(obj));

					func = makeNode(ObjectWithArgs);
					func->objname = plan_name;
					func->args_unspecified = true;

					/* function, procedure */
					func_oid = LookupFuncWithArgs(OBJECT_ROUTINE, func, true);
					if (func_oid != InvalidOid)
					{
						char		kind = get_func_prokind(func_oid);

						if (kind == PROKIND_PROCEDURE)
							grant->objtype = OBJECT_PROCEDURE;
						else
							grant->objtype = OBJECT_FUNCTION;

						break;
					}

					/* type */
					if (LookupTypeNameOid(NULL, makeTypeNameFromNameList(plan_name), true) != InvalidOid)
					{
						grant->objtype = OBJECT_TYPE;
						break;
					}
				}

				/* Adjust datatype structre if needed */
				if (grant->objtype == OBJECT_PROCEDURE || grant->objtype == OBJECT_FUNCTION)
					grant->objects = list_make1(func);
				else if (grant->objtype == OBJECT_TYPE)
					grant->objects = list_make1(plan_name);

				break;
			}
		default:
			break;
	}
}

static void
pltsql_post_parse_analyze(ParseState *pstate, Query *query, JumbleState *jstate)
{

	if (prev_post_parse_analyze_hook)
		prev_post_parse_analyze_hook(pstate, query, jstate);

	if (query->commandType == CMD_UTILITY && nodeTag((Node *) (query->utilityStmt)) == T_CreateStmt)
		set_current_query_is_create_tbl_check_constraint(query->utilityStmt);

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;
	
	(void) check_json_auto_walker((Node*) query, pstate);

	if (query->commandType == CMD_INSERT)
	{
		ListCell   *lc;
		bool		has_ident = false;

		/* Loop through column attribute list */
		foreach(lc, query->targetList)
		{
			TargetEntry *tle = (TargetEntry *) lfirst(lc);
			TupleDesc	tupdesc = RelationGetDescr(pstate->p_target_relation);
			int			attr_num = tle->resno - 1;
			Form_pg_attribute attr;

			attr = TupleDescAttr(tupdesc, attr_num);

			/* Check if explicitly inserting into identity column. */
			if (attr->attidentity)
			{
				has_ident = true;
			}

			/* Disallow insert into a ROWVERSION column */
			if ((*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (attr->atttypid))
			{
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Cannot insert an explicit value into a timestamp column.")));
			}
		}

		/* Set to override value if IDENTITY_INSERT */
		if (tsql_identity_insert.valid)
		{
			Oid			schema_oid = RelationGetNamespace(pstate->p_target_relation);
			char	   *rel_name = RelationGetRelationName(pstate->p_target_relation);
			Oid			rel_oid = get_relname_relid(rel_name, schema_oid);

			if (rel_oid == tsql_identity_insert.rel_oid)
			{
				ColumnRef  *n;
				ResTarget  *rt;
				List	   *returningList;

				if (!has_ident)
					ereport(ERROR,
							(errcode(ERRCODE_UNDEFINED_COLUMN),
							 errmsg("Explicit value must be specified for identity column in table '%s' when IDENTITY_INSERT is set to ON", rel_name)));

				query->override = OVERRIDING_SYSTEM_VALUE;

				n = makeNode(ColumnRef);
				n->fields = list_make1(makeNode(A_Star));
				n->location = query->stmt_location;

				rt = makeNode(ResTarget);
				rt->name = NULL;
				rt->indirection = NIL;
				rt->val = (Node *) n;
				rt->location = query->stmt_location;

				returningList = list_make1(rt);

				pstate->p_namespace = NIL;
				addNSItemToQuery(pstate, pstate->p_target_nsitem, false, true, true);
				query->returningList = transformReturningList(pstate,
															  returningList,
															  EXPR_KIND_RETURNING);
			}
			else
			{
				/* Double check the validity to avoid redundant checks */
				if (!get_rel_name(tsql_identity_insert.rel_oid))
					tsql_identity_insert.valid = false;
			}
		}
	}
	else if (query->commandType == CMD_UTILITY)
	{
		Node	   *parsetree = query->utilityStmt;

		switch (nodeTag(parsetree))
		{
			case T_CreateFunctionStmt:
			{
				ListCell 		*option;
				CreateTrigStmt *trigStmt;
				Relation rel;
				foreach (option, ((CreateFunctionStmt *) parsetree)->options){
					DefElem *defel = (DefElem *) lfirst(option);
					if (strcmp(defel->defname, "trigStmt") == 0)
					{
						trigStmt = (CreateTrigStmt *) defel->arg;
						rel = table_openrv(trigStmt->relation, ShareRowExclusiveLock);
						if (rel->rd_islocaltemp){
							ereport(ERROR,
							(errcode(ERRCODE_WRONG_OBJECT_TYPE),
							errmsg("Cannot create trigger on a temporary object."),
							"Cannot create trigger on a temporary object."
							));
						}
						table_close(rel, NoLock);
					}
				}
			}
			break;
			case T_CreateStmt:
				{
					CreateStmt *stmt = (CreateStmt *) parsetree;
					ListCell   *elements;
					bool		seen_identity = false;
					bool		seen_rowversion = false;
					char	   *rowversion_column_name = NULL;

					foreach(elements, stmt->tableElts)
					{
						Node	   *element = lfirst(elements);

						switch (nodeTag(element))
						{
							case T_ColumnDef:
								check_nullable_identity_constraint(stmt->relation,
																   (ColumnDef *) element);
								if (is_identity_constraint((ColumnDef *) element))
								{
									if (seen_identity)
										ereport(ERROR,
												(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
												 errmsg("Only one identity column is allowed in a table")));
									seen_identity = true;
								}
								if (is_rowversion_column(pstate, (ColumnDef *) element))
								{
									ColumnDef  *def = (ColumnDef *) element;

									if (seen_rowversion)
										ereport(ERROR,
												(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
												 errmsg("Only one timestamp column is allowed in a table.")));
									seen_rowversion = true;
									rowversion_column_name = def->colname;
									validate_rowversion_column_constraints(def);
									def->constraints = lappend(def->constraints, get_rowversion_default_constraint(def->typeName));
								}
								break;
							case T_Constraint:
								{
									Constraint *c = (Constraint *) element;

									if (rowversion_column_name)
										validate_rowversion_table_constraint(c, rowversion_column_name);
								}
								break;
							default:
								break;
						}
					}
				}
				break;

			case T_AlterTableStmt:
				{
					AlterTableStmt *atstmt = (AlterTableStmt *) parsetree;
					ListCell   *lcmd;
					bool		seen_identity = false;
					bool		seen_rowversion = false;
					Oid			relid;
					Relation	rel;
					TupleDesc	tupdesc;
					AttrNumber	attr_num;
					char	   *rowversion_column_name = NULL;

					/* Search through existing relation attributes */
					relid = RangeVarGetRelid(atstmt->relation, NoLock, false);
					rel = RelationIdGetRelation(relid);
					tupdesc = RelationGetDescr(rel);

					for (attr_num = 0; attr_num < tupdesc->natts; attr_num++)
					{
						Form_pg_attribute attr;

						attr = TupleDescAttr(tupdesc, attr_num);

						/* Skip dropped columns */
						if (attr->attisdropped)
							continue;

						/* Check for identity attribute */
						if (attr->attidentity)
							seen_identity = true;

						/* Check for rowversion attribute */
						if ((*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (attr->atttypid))
						{
							seen_rowversion = true;
							rowversion_column_name = NameStr(attr->attname);
						}
					}

					RelationClose(rel);

					foreach(lcmd, atstmt->cmds)
					{
						AlterTableCmd *cmd = (AlterTableCmd *) lfirst(lcmd);

						switch (cmd->subtype)
						{
							case AT_AddColumn:
								check_nullable_identity_constraint(atstmt->relation,
																   castNode(ColumnDef, cmd->def));
								if (is_identity_constraint(castNode(ColumnDef, cmd->def)))
								{
									if (seen_identity)
										ereport(ERROR,
												(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
												 errmsg("Only one identity column is allowed in a table")));
									seen_identity = true;
								}
								if (is_rowversion_column(pstate, castNode(ColumnDef, cmd->def)))
								{
									ColumnDef  *def = castNode(ColumnDef, cmd->def);

									if (seen_rowversion)
										ereport(ERROR,
												(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
												 errmsg("Only one timestamp column is allowed in a table.")));
									seen_rowversion = true;
									rowversion_column_name = def->colname;
									validate_rowversion_column_constraints(def);
									def->constraints = lappend(def->constraints, get_rowversion_default_constraint(def->typeName));
								}
								break;
							case AT_AddConstraint:
								{
									Constraint *c = castNode(Constraint, cmd->def);

									if (rowversion_column_name)
										validate_rowversion_table_constraint(c, rowversion_column_name);
								}
								break;
							case AT_AlterColumnType:
								{
									int			colnamelen = strlen(cmd->name);

									/*
									 * Check if rowversion column type is
									 * being changed.
									 */
									if (rowversion_column_name != NULL &&
										strlen(rowversion_column_name) == colnamelen)
									{
										bool		found = false;

										if (pltsql_case_insensitive_identifiers)
										{
											char	   *colname = downcase_identifier(cmd->name, colnamelen, false, false);
											char	   *dc_rv_name = downcase_identifier(rowversion_column_name, colnamelen, false, false);

											if (strncmp(dc_rv_name, colname, colnamelen) == 0)
												found = true;
										}
										else if (strncmp(rowversion_column_name, cmd->name, colnamelen) == 0)
										{
											found = true;
										}

										if (found)
											ereport(ERROR,
													(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
													 errmsg("Cannot alter column \"%s\" because it is timestamp.", cmd->name)));
									}

									/*
									 * Check if a column type is being changed
									 * to rowversion.
									 */
									if (is_rowversion_column(pstate, castNode(ColumnDef, cmd->def)))
										ereport(ERROR,
												(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
												 errmsg("Cannot alter column \"%s\" to be data type timestamp.", cmd->name)));
								}
								break;
							case AT_ColumnDefault:
								{
									int			colnamelen = strlen(cmd->name);

									/*
									 * Disallow defaults on a rowversion
									 * column.
									 */
									if (rowversion_column_name != NULL &&
										strlen(rowversion_column_name) == colnamelen)
									{
										bool		found = false;

										if (pltsql_case_insensitive_identifiers)
										{
											char	   *colname = downcase_identifier(cmd->name, colnamelen, false, false);
											char	   *dc_rv_name = downcase_identifier(rowversion_column_name, colnamelen, false, false);

											if (strncmp(dc_rv_name, colname, colnamelen) == 0)
												found = true;
										}
										else if (strncmp(rowversion_column_name, cmd->name, colnamelen) == 0)
										{
											found = true;
										}

										if (found)
											ereport(ERROR,
													(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
													 errmsg("Defaults cannot be created on columns of data type timestamp.")));
									}
								}
								break;
							default:
								break;
						}
					}
				}
				break;
			case T_IndexStmt:
				{
					IndexStmt  *stmt = (IndexStmt *) parsetree;

					stmt->idxname = construct_unique_index_name(stmt->idxname, stmt->relation->relname);
				}
				break;
			case T_CreateTableAsStmt:
				{
					CreateTableAsStmt *stmt = (CreateTableAsStmt *) parsetree;
					Node	   *n = stmt->query;

					if (n && n->type == T_Query)
					{
						Query	   *q = (Query *) n;

						if (q->commandType == CMD_SELECT)
						{
							ListCell   *t;
							bool		seen_rowversion = false;

							/*
							 * Varify if SELECT INTO ... statement not
							 * inserting multiple rowversion columns.
							 */
							foreach(t, q->targetList)
							{
								TargetEntry *tle = (TargetEntry *) lfirst(t);
								Oid			typeid = InvalidOid;

								if (!tle->resjunk)
									typeid = exprType((Node *) tle->expr);

								if (OidIsValid(typeid) && (*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (typeid))
								{
									if (seen_rowversion)
										ereport(ERROR,
												(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
												 errmsg("Only one timestamp column is allowed in a table.")));
									seen_rowversion = true;
								}
							}

						}
					}
				}
				break;
			default:
				break;
		}
	}
	else if (query->commandType == CMD_UPDATE)
	{
		ListCell   *lc;

		/* Disallow updating a ROWVERSION column */
		foreach(lc, query->targetList)
		{
			TargetEntry *tle = (TargetEntry *) lfirst(lc);
			TupleDesc	tupdesc = RelationGetDescr(pstate->p_target_relation);
			int			attr_num = tle->resno - 1;
			Form_pg_attribute attr;

			attr = TupleDescAttr(tupdesc, attr_num);

			if ((*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (attr->atttypid) && !IsA(tle->expr, SetToDefault))
			{
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Cannot update a timestamp column.")));
			}
		}
	}
}

static bool
handleForJsonAuto(Query *query, forjson_table **tableInfoArr, int numTables)
{
	Query* subq;
	List* target = query->targetList;
	List* rtable;
	List* subqRtable;
	ListCell* lc;
	ListCell* lc2;
	RangeTblEntry* rte;
	RangeTblEntry* subqRte;
	RangeTblEntry* queryRte;
	Alias *colnameAlias;
	int newTables = 0;
	int currTables = numTables;
	
	if(!isJsonAuto(target))
		return false;

	// Modify query to be of the form "JSONAUTOALIAS.[nest_level].[table_alias]" 
	rtable = (List*) query->rtable;
	if(rtable != NULL && list_length(rtable) > 0) {
		rte = linitial_node(RangeTblEntry, rtable);
		if(rte != NULL) {
			subq = (Query*) rte->subquery;
			if(subq != NULL && (subq->cteList == NULL || list_length(subq->cteList) == 0)) {
				subqRtable = (List*) subq->rtable;
				if(subqRtable != NULL && list_length(subqRtable) > 0) {
					forjson_table **tempArr;
					foreach(lc, subqRtable) {
						subqRte = castNode(RangeTblEntry, lfirst(lc));
						if(subqRte->rtekind == RTE_RELATION) {
							newTables++;
						} else if(subqRte->rtekind == RTE_SUBQUERY) {
							ereport(ERROR,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
										errmsg("sub-select and values for json auto are not currently supported.")));
						}
					}

					if(numTables + newTables == 0) {
						ereport(ERROR,
									(errcode(ERRCODE_UNDEFINED_TABLE),
										errmsg("FOR JSON AUTO requires at least one table for generating JSON objects. Use FOR JSON PATH or add a FROM clause with a table name.")));
					}

					tempArr = palloc((numTables + newTables) * sizeof(forjson_table));
					for(int j = 0; j < numTables; j++) {
						tempArr[j] = tableInfoArr[j];
					}
					tableInfoArr = tempArr;
					tempArr = NULL;
					queryRte = linitial_node(RangeTblEntry, query->rtable);
					colnameAlias = (Alias*) queryRte->eref;

					foreach(lc, subqRtable) {
						subqRte = castNode(RangeTblEntry, lfirst(lc));
						if(subqRte->rtekind == RTE_RELATION) {
							forjson_table *table = palloc(sizeof(forjson_table));
							Alias* a = (Alias*) subqRte->eref;
							table->oid = subqRte->relid;
							table->nestLevel = -1;
							table->alias = a->aliasname;
							tableInfoArr[currTables] = table;
							currTables++;
						}
					}
					numTables = numTables + newTables;
					modifyColumnEntries(subq->targetList, tableInfoArr, numTables, colnameAlias, false);
					return true;
				}
			} else if(subq->cteList != NULL && list_length(subq->cteList) > 0) {
				Query* ctequery;
				CommonTableExpr* cte;
				forjson_table **tempArr;
				foreach(lc, subq->cteList) {
					cte = castNode(CommonTableExpr, lfirst(lc));
					ctequery = (Query*) cte->ctequery;
					foreach(lc2, ctequery->rtable) {
						subqRte = castNode(RangeTblEntry, lfirst(lc2));
						if(subqRte->rtekind == RTE_RELATION)
							newTables++;
					}
				}

				if(newTables == 0) {
					forjson_table *table = palloc(sizeof(forjson_table));
					tempArr = palloc((numTables + 1) * sizeof(forjson_table));
					table->oid = 0;
					table->nestLevel = -1;
					table->alias = "cteplaceholder";
					tempArr[numTables] = table;
					newTables++;
				} else {
					tempArr = palloc((numTables + newTables) * sizeof(forjson_table));
				}

				for(int j = 0; j < numTables; j++) {
					tempArr[j] = tableInfoArr[j];
				}

				tableInfoArr = tempArr;
				tempArr = NULL;
				numTables = numTables + newTables;
				queryRte = linitial_node(RangeTblEntry, query->rtable);
				colnameAlias = (Alias*) queryRte->eref;

				foreach(lc, subq->cteList) {
					cte = castNode(CommonTableExpr, lfirst(lc));
					ctequery = (Query*) cte->ctequery;
					foreach(lc2, ctequery->rtable) {
						subqRte = castNode(RangeTblEntry, lfirst(lc2));
						if(subqRte->rtekind == RTE_RELATION) {
							forjson_table *table = palloc(sizeof(forjson_table));
							Alias* a = (Alias*) subqRte->eref;
							table->oid = subqRte->relid;
							table->nestLevel = -1;
							table->alias = a->aliasname;
							tableInfoArr[currTables] = table;
							currTables++;
						}
					}
				}

				modifyColumnEntries(subq->targetList, tableInfoArr, numTables, colnameAlias, true);
				
				return true;
			}
		}
	}

	ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_TABLE),
					errmsg("FOR JSON AUTO requires at least one table for generating JSON objects. Use FOR JSON PATH or add a FROM clause with a table name.")));
	return true;
}

static bool
isJsonAuto(List* target)
{
	if(target != NULL && list_length(target) > 0) {
		ListCell* lc = list_nth_cell(target, 0);
		if(lc != NULL && nodeTag(lfirst(lc)) == T_TargetEntry) {
			TargetEntry* te = lfirst_node(TargetEntry, lc);
			if(te && strcmp(te->resname, "json") == 0 && te->expr != NULL && nodeTag(te->expr) == T_FuncExpr) {
				List* args = ((FuncExpr*) te->expr)->args;
				if(args != NULL && nodeTag(linitial(args)) == T_Aggref) {
					Aggref* agg = linitial_node(Aggref, args);
					List* aggargs = agg->args;
					if(aggargs != NULL && list_length(aggargs) > 1 && nodeTag(lsecond(aggargs)) == T_TargetEntry) {
						TargetEntry* te2 = lsecond_node(TargetEntry, aggargs);
						if(te2->expr != NULL && nodeTag(te2->expr) == T_Const) {
							Const* c = (Const*) te2->expr;
							if(c->constvalue == 0)
								return true;
						}
					}
				}
			}
		}
	}
	return false;
}

static TargetEntry*
buildJsonEntry(int nestLevel, char* tableAlias, TargetEntry* te)
{
	char nest[NAMEDATALEN]; // check size appropriate
	StringInfo new_resname = makeStringInfo();
	sprintf(nest, "%d", nestLevel);
	// Adding JSONAUTOALIAS prevents us from modifying
	// a column more than once
	if(!strcmp(te->resname, "\?column\?")) {
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					errmsg("column expressions and data sources without names or aliases cannot be formatted as JSON text using FOR JSON clause. Add alias to the unnamed column or table")));
	} 
	appendStringInfoString(new_resname, "JSONAUTOALIAS.");
	appendStringInfoString(new_resname, nest);
	appendStringInfoChar(new_resname, '.');
	appendStringInfoString(new_resname, tableAlias);
	appendStringInfoChar(new_resname, '.');
	appendStringInfoString(new_resname, te->resname);
	te->resname = new_resname->data;
	return te;
}

static void modifyColumnEntries(List* targetList, forjson_table **tableInfoArr, int numTables, Alias *colnameAlias, bool isCve)
{
	int i = 0;
	int currMax = 0;
	ListCell* lc;
	foreach(lc, targetList) {
		TargetEntry* te = castNode(TargetEntry, lfirst(lc));
		int oid = te->resorigtbl;
		String* s = castNode(String, lfirst(list_nth_cell(colnameAlias->colnames, i)));
		if(te->expr != NULL && nodeTag(te->expr) == T_SubLink) {
			SubLink *sl = castNode(SubLink, te->expr);
			if(sl->subselect != NULL && nodeTag(sl->subselect) == T_Query) {
				if(handleForJsonAuto(castNode(Query, sl->subselect), tableInfoArr, numTables)) {
					CoerceViaIO *iocoerce = makeNode(CoerceViaIO);
					iocoerce->arg = (Expr*) sl;
					iocoerce->resulttype = TypenameGetTypid("json");
					iocoerce->resultcollid = 0;
					iocoerce->coerceformat = COERCE_EXPLICIT_CAST;
					buildJsonEntry(1, "temp", te);
					s->sval = te->resname;
					te->expr = (Expr*) iocoerce;
					continue;
				}
			}
		}
		for(int j = 0; j < numTables; j++) {
			if(tableInfoArr[j]->oid == oid) {
				// build entry
				if(tableInfoArr[j]->nestLevel == -1) {
					currMax++;
					tableInfoArr[j]->nestLevel = currMax;
				}
				te = buildJsonEntry(tableInfoArr[j]->nestLevel, tableInfoArr[j]->alias, te);
				s->sval = te->resname;
				break;
			} else if(!isCve && oid == 0 && j == numTables - 1) {
				te = buildJsonEntry(1, "temp", te);
				s->sval = te->resname;
				break;
			}
		}
		i++;
	}
}

static bool check_json_auto_walker(Node *node, ParseState *pstate)
{
	if (node == NULL)
		return false;
	if (IsA(node, Query)) {
		if(handleForJsonAuto((Query*) node, NULL, 0))
			return true;
		else {
			return query_tree_walker((Query*) node,
								 check_json_auto_walker,
								 (void *) pstate, 0);
		}
	}
	return expression_tree_walker(node, check_json_auto_walker,
								  (void *) pstate);
}

static bool
is_identity_constraint(ColumnDef *column)
{
	ListCell   *clist;
	bool		is_identity = false;

	foreach(clist, column->constraints)
	{
		Constraint *constraint = lfirst_node(Constraint, clist);

		switch (constraint->contype)
		{
			case CONSTR_IDENTITY:
				is_identity = true;
				break;

			default:
				break;
		}
	}

	return is_identity;
}

static bool
is_rowversion_column(ParseState *pstate, ColumnDef *column)
{
	Type		ctype;
	Oid			typeOid;

	ctype = LookupTypeName(pstate, column->typeName, NULL, true);

	if (!ctype)
		return false;

	typeOid = ((Form_pg_type) GETSTRUCT(ctype))->oid;
	ReleaseSysCache(ctype);

	if ((*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (typeOid))
		return true;

	return false;
}

/*
* 1. We will only allow NULL/NOT-NULL constraint on a rowversion column.
* 2. Unique/Primary/Foreign constraints are not allowed as multiple
*    rows can have same rowversion value in a single transaction.
*    Moreover sql server documentation also states rowversion
*    column a poor candidate for keys.
* 3. Default constraint is not allowed on a rowversion column.
*/
static void
validate_rowversion_column_constraints(ColumnDef *column)
{
	ListCell   *lc;

	foreach(lc, column->constraints)
	{
		Constraint *c = lfirst_node(Constraint, lc);

		switch (c->contype)
		{
			case CONSTR_UNIQUE:
				{
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Unique constraint is not supported on a timestamp column.")));
					break;
				}
			case CONSTR_PRIMARY:
				{
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Primary key constraint is not supported on a timestamp column.")));
					break;
				}
			case CONSTR_FOREIGN:
				{
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Foreign key constraint is not supported on a timestamp column.")));
					break;
				}
			case CONSTR_DEFAULT:
				{
					ereport(ERROR,
							(errcode(ERRCODE_INVALID_COLUMN_DEFINITION),
							 errmsg("Defaults cannot be created on columns of data type timestamp.")));
					break;
				}
			default:
				break;
		}
	}
}

static void
validate_rowversion_table_constraint(Constraint *c, char *rowversion_column_name)
{
	List	   *colnames = NIL;
	ListCell   *lc;
	char	   *conname = NULL;
	int			rv_colname_len = strlen(rowversion_column_name);
	char	   *dc_rv_name = downcase_identifier(rowversion_column_name, rv_colname_len, false, false);

	switch (c->contype)
	{
		case CONSTR_UNIQUE:
			{
				conname = "Unique";
				colnames = c->keys;
				break;
			}
		case CONSTR_PRIMARY:
			{
				conname = "Primary key";
				colnames = c->keys;
				break;
			}
		case CONSTR_FOREIGN:
			{
				conname = "Foreign key";
				colnames = c->fk_attrs;
				break;
			}
		default:
			break;
	}

	if (colnames == NIL)
		return;

	foreach(lc, colnames)
	{
		char *colname = NULL;
		bool found = false;

		/* T-SQL Parser might have directly prepared IndexElem instead of String*/
		if (nodeTag(lfirst(lc)) == T_IndexElem) {
			IndexElem *ie = (IndexElem *) lfirst(lc);
			colname = ie->name;
		} else {
			colname = strVal(lfirst(lc));
		}

		if (strlen(colname) == rv_colname_len)
		{
			if (pltsql_case_insensitive_identifiers)
			{
				char	   *dc_colname = downcase_identifier(colname, strlen(colname), false, false);

				if (strncmp(dc_rv_name, dc_colname, rv_colname_len) == 0)
					found = true;
			}
			else if (strncmp(rowversion_column_name, colname, rv_colname_len) == 0)
			{
				found = true;
			}

			if (found)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("%s constraint is not supported on a timestamp column.", conname)));
		}
	}
}

/*
 * Helper function to create a default constraint node for rowversion
 * column with FuncCall to sys.get_current_full_xact_id(), which outputs
 * current full transaction ID.
 */
static Constraint *
get_rowversion_default_constraint(TypeName *typname)
{
	TypeCast   *castnode;
	FuncCall   *funccallnode;
	Constraint *constraint;

	funccallnode = makeFuncCall(list_make2(makeString("sys"), makeString("get_current_full_xact_id")), NIL, COERCE_EXPLICIT_CALL, -1);
	castnode = makeNode(TypeCast);
	castnode->typeName = typname;
	castnode->arg = (Node *) funccallnode;
	castnode->location = -1;
	constraint = makeNode(Constraint);
	constraint->contype = CONSTR_DEFAULT;
	constraint->location = -1;
	constraint->raw_expr = (Node *) castnode;
	constraint->cooked_expr = NULL;

	return constraint;
}

static void
revoke_type_permission_from_public(PlannedStmt *pstmt, const char *queryString, bool readOnlyTree,
								   ProcessUtilityContext context, ParamListInfo params, QueryEnvironment *queryEnv, DestReceiver *dest, QueryCompletion *qc, List *type_name)
{
	const char *template = "REVOKE ALL ON TYPE dummy FROM PUBLIC";
	List	   *res;
	GrantStmt  *revoke;
	PlannedStmt *wrapper;

	/* TSQL specific behavior */
	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/* Need CCI between commands */
	CommandCounterIncrement();

	/* prepare subcommand */
	res = raw_parser(template, RAW_PARSE_DEFAULT);

	if (list_length(res) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Expected 1 statement but get %d statements after parsing",
						list_length(res))));

	revoke = (GrantStmt *) parsetree_nth_stmt(res, 0);
	revoke->objects = list_make1(type_name);

	wrapper = makeNode(PlannedStmt);
	wrapper->commandType = CMD_UTILITY;
	wrapper->canSetTag = false;
	wrapper->utilityStmt = (Node *) revoke;
	wrapper->stmt_location = pstmt->stmt_location;
	wrapper->stmt_len = pstmt->stmt_len;

	ProcessUtility(wrapper,
				   queryString,
				   readOnlyTree,
				   PROCESS_UTILITY_SUBCOMMAND,
				   params,
				   queryEnv,
				   None_Receiver,
				   qc);

	/* Need CCI between commands */
	CommandCounterIncrement();
}


static void
check_nullable_identity_constraint(RangeVar *relation, ColumnDef *column)
{
	ListCell   *clist;
	bool		is_null = false;
	bool		is_identity = false;

	foreach(clist, column->constraints)
	{
		Constraint *constraint = lfirst_node(Constraint, clist);

		switch (constraint->contype)
		{
			case CONSTR_NULL:
				is_null = true;
				break;

			case CONSTR_IDENTITY:
				is_identity = true;
				break;

			default:
				break;
		}
	}

	if (is_null && is_identity)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_COLUMN),
				 errmsg("Could not create IDENTITY attribute on nullable column '%s', table '%s'.",
						column->colname,
						relation->relname)));
}

static void
pltsql_sequence_validate_increment(int64 increment_by,
								   int64 max_value,
								   int64 min_value)
{
	unsigned long inc;
	unsigned long min_max_diff;

	inc = increment_by >= 0 ? (unsigned long) increment_by : (unsigned long) (-1L * increment_by);
	min_max_diff = (unsigned long) (max_value - min_value);

	if (inc > min_max_diff)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("The absolute value of the increment must be less than or equal to the "
						"difference between the minimum and maximum value of the sequence object.")));
}

static void
pltsql_identity_datatype_map(ParseState *pstate, ColumnDef *column)
{
	Type		ctype;
	Oid			typeOid;
	Oid			tsqlSeqTypOid;

	if (prev_pltsql_identity_datatype_hook)
		prev_pltsql_identity_datatype_hook(pstate, column);

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/* Map IDENTITY type for sequences */
	ctype = typenameType(pstate, column->typeName, NULL);
	typeOid = ((Form_pg_type) GETSTRUCT(ctype))->oid;
	tsqlSeqTypOid = pltsql_seq_type_map(typeOid);

	ReleaseSysCache(ctype);

	if (tsqlSeqTypOid != InvalidOid)
	{
		column->typeName->names = NIL;
		column->typeName->typeOid = tsqlSeqTypOid;
	}
	else if (typeOid == NUMERICOID || getBaseType(typeOid) == NUMERICOID)
	{
		int32		typmod_p;
		uint8_t		scale;
		uint8_t		precision;

		Type		typ = typenameType(pstate, column->typeName, &typmod_p);

		if (typeOid != NUMERICOID)
		{
			if (column->typeName->typemod != -1)
				typmod_p = column->typeName->typemod;

			if (typmod_p == -1)
				typmod_p = 1179652; /* decimal(18,0) */
		}

		scale = (typmod_p - VARHDRSZ) & 0xffff;
		precision = ((typmod_p - VARHDRSZ) >> 16) & 0xffff;

		ReleaseSysCache(typ);

		if (scale > 0)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("identity column must have scale 0")));

		if (precision > 18)
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("identity column must have precision 18 or less")));

		column->typeName->typmods = NIL;
		column->typeName->names = NIL;
		column->typeName->typeOid = INT8OID;
	}
}

static void
pltsql_sequence_datatype_map(ParseState *pstate,
							 Oid *newtypid,
							 bool for_identity,
							 DefElem *as_type,
							 DefElem **max_value,
							 DefElem **min_value)
{
	int32		typmod_p;
	Type		typ;
	char	   *typname;
	Oid			tsqlSeqTypOid;
	TypeName   *type_def;
	List	   *type_names;
	List	   *new_type_names = NULL;
	AclResult	aclresult;
	Oid			base_type;
	int			list_len;

	if (prev_pltsql_sequence_datatype_hook)
		prev_pltsql_sequence_datatype_hook(pstate,
										   newtypid,
										   for_identity,
										   as_type,
										   max_value,
										   min_value);

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	type_def = defGetTypeName(as_type);
	type_names = type_def->names;
	list_len = list_length(type_names);

	switch (list_len)
	{
		case 2:
			new_type_names = list_make2(type_names->elements[0].ptr_value, type_names->elements[1].ptr_value);
			strVal(linitial(new_type_names)) = get_physical_schema_name(get_cur_db_name(), strVal(linitial(type_names)));
			break;
		case 3:
			/* Changing three part name of data type to physcial schema name */
			new_type_names = list_make2(type_names->elements[1].ptr_value, type_names->elements[2].ptr_value);
			strVal(linitial(new_type_names)) = get_physical_schema_name(strVal(linitial(type_names)), strVal(lsecond(type_names)));
			break;
	}

	if (list_len > 1)
		type_def->names = new_type_names;

	*newtypid = typenameTypeId(pstate, type_def);
	typ = typenameType(pstate, type_def, &typmod_p);
	typname = typeTypeName(typ);
	type_def->names = type_names;

	if (list_len > 1)
		list_free(new_type_names);

	aclresult = object_aclcheck(TypeRelationId, *newtypid, GetUserId(), ACL_USAGE);
	if (aclresult != ACLCHECK_OK)
		aclcheck_error_type(aclresult, *newtypid);

	tsqlSeqTypOid = pltsql_seq_type_map(*newtypid);

	if (type_def->typemod != -1)
		typmod_p = type_def->typemod;

	ReleaseSysCache(typ);
	base_type = getBaseType(*newtypid);

	if (tsqlSeqTypOid != InvalidOid)
	{
		*newtypid = tsqlSeqTypOid;

		/* Verified sys type. Set tinyint constraint 0 to 255 */
		if (strcmp(typname, "tinyint") == 0)
		{
			int64		tinyint_max;
			int64		tinyint_min;

			/* NULL arg means no value so check max_value then the arg */
			if (*max_value == NULL)
				*max_value = makeDefElem("maxvalue", NULL, -1);

			if ((*max_value)->arg == NULL)
				(*max_value)->arg = (Node *) makeFloat(psprintf(INT64_FORMAT, (int64) 255));

			tinyint_max = defGetInt64(*max_value);

			if (tinyint_max < 0 || tinyint_max > 255)
			{
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("MAXVALUE (%lld) is out of range for sequence data type tinyint",
								(long long) tinyint_max)));
			}

			/* NULL arg means no value so check min_value then the arg */
			if (*min_value == NULL)
				*min_value = makeDefElem("minvalue", NULL, -1);

			if ((*min_value)->arg == NULL)
				(*min_value)->arg = (Node *) makeFloat(psprintf(INT64_FORMAT, (int64) 0));

			tinyint_min = defGetInt64(*min_value);

			if (tinyint_min < 0 || tinyint_min > 255)
			{
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("MINVALUE (%lld) is out of range for sequence data type tinyint",
								(long long) tinyint_min)));
			}
		}
	}
	else if ((*newtypid == NUMERICOID) || (base_type == NUMERICOID))
	{
		/*
		 * Identity column drops the typmod upon sequence creation so it gets
		 * its own check
		 */

		/*
		 * When sequence is created using user-defined data type,
		 * !for_identity == true and typmod_p == -1, which results in
		 * calculating incorrect scale and precision therefore we update
		 * typmod_p to that of numeric(18,0)
		 */
		if (typmod_p == -1)
			typmod_p = 1179652;

		if (!for_identity || typmod_p != -1)
		{
			uint8_t		scale = (typmod_p - VARHDRSZ) & 0xffff;
			uint8_t		precision = ((typmod_p - VARHDRSZ) >> 16) & 0xffff;

			if (scale > 0)
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						 errmsg("sequence type must have scale 0")));

			if (precision > 18)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("sequence type must have precision 18 or less")));
		}

		base_type = INT8OID;
		ereport(WARNING,
				(errmsg("NUMERIC or DECIMAL type is cast to BIGINT")));
	}

	/*
	 * To add support for User-Defined Data types for sequences, data type of
	 * sequence is changed to its basetype
	 */
	*newtypid = base_type;
}

static Oid
bbf_table_var_lookup(const char *relname, Oid relnamespace)
{
	Oid			relid;
	ListCell   *lc;
	int			n;
	PLtsql_tbl *tbl;
	PLtsql_execstate *estate = get_current_tsql_estate();

	if (prev_relname_lookup_hook)
		relid = (*prev_relname_lookup_hook) (relname, relnamespace);
	else
		relid = get_relname_relid(relname, relnamespace);

	/* estate not set up, or not a table variable */
	if (!estate || strncmp(relname, "@", 1) != 0)
		return relid;

	/*
	 * If we find a table variable whose name matches relname, return its
	 * underlying table's relid. Otherwise, just return relname's relid.
	 */
	foreach(lc, estate->func->table_varnos)
	{
		n = lfirst_int(lc);
		if (estate->datums[n]->dtype != PLTSQL_DTYPE_TBL)
			continue;

		tbl = (PLtsql_tbl *) estate->datums[n];
		if (strcmp(relname, tbl->refname) == 0 && tbl->tblname)
		{
			return get_relname_relid(tbl->tblname, relnamespace);
		}
	}

	return relid;
}

/*
 * It returns TRUE when we should not execute the utility statement,
 * e.g., CREATE FUNCTION, in EXPLAIN ONLY MODE.
 * If it returns FALSE, it means we can execute the utility statement.
 * For some cases, e.g., EXEC procedure, we need to execute the procedure
 * even in EXPLAIN ONLY MODE. In that case, EXPLAIN ONLY MODE should be considered
 * for individual statements inside the procedure.
 */
static inline bool
process_utility_stmt_explain_only_mode(const char *queryString, Node *parsetree)
{
	CallStmt   *callstmt;
	HeapTuple	proctuple;
	Oid			procid;
	Oid			langoid;
	char	   *langname;

	if (!pltsql_explain_only)
		return false;

	append_explain_info(NULL, queryString);

	if (nodeTag(parsetree) != T_CallStmt)
		return true;

	callstmt = (CallStmt *) parsetree;
	procid = callstmt->funcexpr->funcid;
	proctuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(procid));
	if (!HeapTupleIsValid(proctuple))
		return true;

	langoid = ((Form_pg_proc) GETSTRUCT(proctuple))->prolang;
	ReleaseSysCache(proctuple);

	langname = get_language_name(langoid, true);
	if (!langname)
		return true;

	/*
	 * If a procedure language is pltsql, it is safe to execute the procedure.
	 * EXPLAIN ONLY MODE will be considered for each statements inside the
	 * procedure.
	 */
	if (pg_strcasecmp("pltsql", langname) == 0)
		return false;

	return true;
}

/*
 * check whether role contains '\' or not and SQL_USER contains '\' or not
 * If yes, throw error.
 */
static void
validateUserAndRole(char *name)
{
	if (strchr(name, '\\') != NULL)
		ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
						errmsg("'%s' is not a valid name because it contains invalid characters.", name)));
}


/*
 * Use this hook to handle utility statements that needs special treatment, and
 * use the standard ProcessUtility for other statements.
 * CreateFunctionStmt could have elements in the options list that are specific
 * to tsql, like trigStmt and tbltypStmt.
 */
static void
bbf_ProcessUtility(PlannedStmt *pstmt,
				   const char *queryString,
				   bool readOnlyTree,
				   ProcessUtilityContext context,
				   ParamListInfo params,
				   QueryEnvironment *queryEnv,
				   DestReceiver *dest,
				   QueryCompletion *qc)
{
	Node	   *parsetree = pstmt->utilityStmt;
	ParseState *pstate = make_parsestate(NULL);

	pstate->p_sourcetext = queryString;

	if (process_utility_stmt_explain_only_mode(queryString, parsetree))
	{
		if (qc && parsetree) {
			/*
			* Some utility statements return a row count, even though the
			* tuples are not returned to the caller.
			*/
			Assert(qc->commandTag == CMDTAG_UNKNOWN);
			if (IsA(parsetree, CreateTableAsStmt))
				SetQueryCompletion(qc, CMDTAG_SELECT, 0);
			else if (IsA(parsetree, CopyStmt))
				SetQueryCompletion(qc, CMDTAG_COPY, 0);
		}

		return;                                 /* Don't execute anything */
	}

	/*
	 * Block ALTER VIEW and CREATE OR REPLACE VIEW statements from PG dialect
	 * executed on TSQL views which has entries in view_def catalog Note:
	 * Changes made by ALTER VIEW or CREATE [OR REPLACE] VIEW statements in
	 * TSQL dialect from PG client won't be reflected in babelfish_view_def
	 * catalog.
	 */
	if (sql_dialect == SQL_DIALECT_PG && !babelfish_dump_restore && !pltsql_enable_create_alter_view_from_pg)
	{
		switch (nodeTag(parsetree))
		{
			case T_ViewStmt:
				{
					ViewStmt   *vstmt = (ViewStmt *) parsetree;
					Oid			relid = RangeVarGetRelid(vstmt->view, NoLock, true);

					if (vstmt->replace && check_is_tsql_view(relid))
					{
						ereport(ERROR,
								(errcode(ERRCODE_INTERNAL_ERROR),
								 errmsg("REPLACE VIEW is blocked in PG dialect on TSQL view present in babelfish_view_def catalog. Please set babelfishpg_tsql.enable_create_alter_view_from_pg to true to enable.")));
					}
					break;
				}
			case T_AlterTableStmt:
				{
					AlterTableStmt *atstmt = (AlterTableStmt *) parsetree;

					if (atstmt->objtype == OBJECT_VIEW)
					{
						Oid			relid = RangeVarGetRelid(atstmt->relation, NoLock, true);

						if (check_is_tsql_view(relid))
						{
							ereport(ERROR,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									 errmsg("ALTER VIEW is blocked in PG dialect on TSQL view present in babelfish_view_def catalog. Please set babelfishpg_tsql.enable_create_alter_view_from_pg to true to enable.")));
						}
					}
					break;
				}
			case T_RenameStmt:
				{
					RenameStmt *rnstmt = (RenameStmt *) parsetree;

					if (rnstmt->renameType == OBJECT_VIEW ||
						(rnstmt->renameType == OBJECT_COLUMN &&
						 rnstmt->relationType == OBJECT_VIEW))
					{
						Oid			relid = RangeVarGetRelid(rnstmt->relation, NoLock, true);

						if (check_is_tsql_view(relid))
						{
							ereport(ERROR,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									 errmsg("ALTER VIEW is blocked in PG dialect on TSQL view present in babelfish_view_def catalog. Please set babelfishpg_tsql.enable_create_alter_view_from_pg to true to enable.")));
						}
					}
					break;
				}
			case T_AlterObjectSchemaStmt:
				{
					AlterObjectSchemaStmt *altschstmt = (AlterObjectSchemaStmt *) parsetree;

					if (altschstmt->objectType == OBJECT_VIEW)
					{
						Oid			relid = RangeVarGetRelid(altschstmt->relation, NoLock, true);

						if (check_is_tsql_view(relid))
						{
							ereport(ERROR,
									(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									 errmsg("ALTER VIEW is blocked in PG dialect on TSQL view present in babelfish_view_def catalog. Please set babelfishpg_tsql.enable_create_alter_view_from_pg to true to enable.")));
						}
					}
					break;
				}
			default:
				break;
		}
	}

	switch (nodeTag(parsetree))
	{
		case T_AlterFunctionStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
				    /*
					* For ALTER PROC/FUNC, we will:
					* 1. Save important pg_proc metadata from the current proc/func (oid, proacl)
					* 2. drop the current proc/func
					* 3. create the new proc/func
					* 4. update the pg_proc entry for the new proc with metadata from the old proc/func
					* 5. update the babelfish_function_ext entry for the existing proc/func with new metadata based on the new proc/func
					*/
					AlterFunctionStmt *stmt = (AlterFunctionStmt *) parsetree;
					bool 				isCompleteQuery = (context != PROCESS_UTILITY_SUBCOMMAND);
					bool 				needCleanup;
					Oid					oldoid;
					Acl					*proacl;
					bool				isSameProc;
					ObjectAddress 		address, tbltyp, originalFunc;
					CreateFunctionStmt	*cfs;
					ListCell 			*option;
					int 				origname_location = -1;
					bool 				with_recompile = false;
					Node                *tbltypStmt = NULL;
					ListCell            *parameter;

					cfs = makeNode(CreateFunctionStmt);
					cfs->returnType = NULL;
					cfs->is_procedure = true;

					if (!IS_TDS_CLIENT())
					{
						ereport(ERROR,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								errmsg("TSQL ALTER PROCEDURE is not supported from PostgreSQL endpoint.")));
					}

					if (stmt->objtype != OBJECT_PROCEDURE)
						break;

					/* All event trigger calls are done only when isCompleteQuery is true */
					needCleanup = isCompleteQuery && EventTriggerBeginCompleteQuery();

					/* PG_TRY block is to ensure we call EventTriggerEndCompleteQuery */
					PG_TRY();
					{
						StartTransactionCommand();
						if (isCompleteQuery)
							EventTriggerDDLCommandStart(parsetree);

						foreach (option, stmt->actions)
						{
							DefElem *defel = (DefElem *) lfirst(option);
							if (strcmp(defel->defname, "location") == 0)
							{
							       /*
								* location is an implicit option in tsql dialect,
								* we use this mechanism to store location of function
								* name so that we can extract original input function
								* name from queryString.
								*/
								origname_location = intVal((Node *) defel->arg);
								stmt->actions = foreach_delete_current(stmt->actions, option);
								pfree(defel);
							}
							else if (strcmp(defel->defname, "recompile") == 0)
							{
							       /*
								* ALTER PROCEDURE ... WITH RECOMPILE
								* Record RECOMPILE in catalog
								*/
								with_recompile = true;
							}
							else if (strcmp(defel->defname, "return") == 0)
							{
								cfs->returnType = (TypeName *) defel->arg;
								cfs->is_procedure = false;
								stmt->actions = foreach_delete_current(stmt->actions, option);
								pfree(defel);
								stmt->objtype = OBJECT_FUNCTION;
							}
							else if (strcmp(defel->defname, "tbltypStmt") == 0)
							{
								 tbltypStmt = defel->arg;
							}
						}

						/* make a CreateFunctionStmt to pass into CreateFunction() */
						cfs->replace = true;
						cfs->funcname = stmt->func->objname;
						cfs->parameters = stmt->func->objfuncargs;
						cfs->options = stmt->actions;

						foreach(parameter, cfs->parameters)
						{
							FunctionParameter* fp = (FunctionParameter*) lfirst(parameter);
							if(fp->mode == FUNC_PARAM_TABLE)
							{
								fp->argType->setof = false;
							}
						}

						pltsql_proc_get_oid_proname_proacl(stmt, pstate, &oldoid, &proacl, &isSameProc, cfs->is_procedure);
						originalFunc.objectId = oldoid;
						originalFunc.classId = ProcedureRelationId;
						originalFunc.objectSubId = 0;
						if(get_bbf_function_tuple_from_proctuple(SearchSysCache1(PROCOID, ObjectIdGetDatum(oldoid))) == NULL)
						{
							/* Detect PSQL functions and throw error */
							ereport(ERROR,
								(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
									errmsg("No existing TSQL procedure found with the name for ALTER PROCEDURE")));
						}
						if(!cfs->is_procedure)
						{
							/*
							 * Postgres does not allow us to create functions with different return types
							 * so we need to delete and recreate them 
							 */
							performDeletion(&originalFunc, DROP_RESTRICT, 0);
							isSameProc = false;
							CommandCounterIncrement();
						}
						else if (!isSameProc) /* i.e. different signature */
						{
							performDeletion(&originalFunc, DROP_RESTRICT, 0);
						}

						if(tbltypStmt)
						{
							PlannedStmt *wrapper;
							RangeVar* rv = ((CreateStmt*) tbltypStmt)->relation;

							if(rv->schemaname != NULL)
							{
								List* cfs_rettype_names = cfs->returnType->names;
								ListCell* x;
								int i = 1;
								int len = list_length(cfs->parameters);
								char *physical_schema_name = get_physical_schema_name(get_cur_db_name(), rv->schemaname);

								rv->schemaname = physical_schema_name;
								cfs_rettype_names = list_delete_first(cfs_rettype_names);
								cfs_rettype_names = lcons(makeString(physical_schema_name), cfs_rettype_names);


								foreach(x, cfs->parameters)
								{
									if(i == len)
									{
										FunctionParameter *fp = (FunctionParameter *) lfirst(x);
										TypeName *t = fp->argType;
										t->names =  list_delete_first(t->names);
										t->names = lcons(makeString(physical_schema_name), t->names);
									}
									i++;
								}
							}

							/*
							 * Process create stmt
							 */
							wrapper = makeNode(PlannedStmt);
							wrapper->commandType = CMD_UTILITY;
							wrapper->canSetTag = false;
							wrapper->utilityStmt = tbltypStmt;
							wrapper->stmt_location = pstmt->stmt_location;
							wrapper->stmt_len = pstmt->stmt_len;

							ProcessUtility(wrapper,
										queryString,
										false,
										PROCESS_UTILITY_SUBCOMMAND,
										params,
										NULL,
										None_Receiver,
										NULL);

							/* Need CCI between commands */
							CommandCounterIncrement();

							/*
							 * Update dependency on oldoid
							 */
							tbltyp.classId = TypeRelationId;
							tbltyp.objectId = typenameTypeId(pstate,
															cfs->returnType);
							tbltyp.objectSubId = 0;
							recordDependencyOn(&tbltyp, &originalFunc, DEPENDENCY_INTERNAL);
						}

						/* if this is the same procedure, it will update the existing one */
						address = CreateFunction(pstate, cfs);
						/* Update function/procedure related metadata in babelfish catalog */
						pltsql_store_func_default_positions(address, cfs->parameters, queryString, origname_location, with_recompile);
						/* Increase counter after bbf_func_ext modified in pltsql_store_func_default_positions*/
						CommandCounterIncrement();
						pg_proc_update_oid_acl(address, oldoid, proacl);
						if (!isSameProc) {
						       /*
							* When the signatures differ we need to manually update the 'function_args' column in 
							* the 'bbf_schema_permissions' catalog
							*/
							alter_bbf_schema_permissions_catalog(stmt->func, cfs->parameters, stmt->objtype, oldoid);
						}
						/* Clean up table entries for the create function statement */
						deleteDependencyRecordsFor(DefaultAclRelationId, address.objectId, false);
						deleteDependencyRecordsFor(ProcedureRelationId, address.objectId, false);
						deleteSharedDependencyRecordsFor(ProcedureRelationId, address.objectId, 0);
						CommitTransactionCommand();
					}
					PG_FINALLY();
					{
						if (needCleanup)
							EventTriggerEndCompleteQuery();
					}
					PG_END_TRY();
					return;
				}
				break;
			}
		case T_AlterTableStmt:
			{
				AlterTableStmt *atstmt = (AlterTableStmt *) parsetree;
				ListCell *lc;

				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					foreach(lc, atstmt->cmds)
					{
						AlterTableCmd *cmd = (AlterTableCmd *)lfirst(lc);
						if (cmd->subtype == AT_EnableTrig || cmd->subtype == AT_DisableTrig)
						{
							if (atstmt->relation->schemaname != NULL)
							{
								/*
								* As syntax1 ( { ENABLE | DISABLE } TRIGGER <trigger> ON <table> )
								* is mapped to syntax2 ( ALTER TABLE <table> { ENABLE | DISABLE } TRIGGER <trigger> ),
								* objtype of atstmt for syntax1 is temporarily set to OBJECT_TRIGGER to identify whether the
								* query was originally of syntax1 or syntax2, here astmt->objtype is reset back to OBJECT_TABLE
								*/
								if (atstmt->objtype == OBJECT_TRIGGER)
								{
									int16 dbid = get_cur_db_id();
									int16 stmt_dbid = get_dbid_from_physical_schema_name(atstmt->relation->schemaname, true);

									if (dbid != stmt_dbid)	/* Check to identify cross-db referencing */
									{
										ereport(ERROR,
												(errcode(ERRCODE_INTERNAL_ERROR),
												errmsg("Cannot %s trigger on '%s.%s.%s' as the target is not in the current database."
													, cmd->subtype == AT_EnableTrig ? "enable" : "disable", get_db_name(stmt_dbid), get_logical_schema_name(atstmt->relation->schemaname, true), atstmt->relation->relname)));
									}
									atstmt->objtype = OBJECT_TABLE;
								}
							}
						}
					}
				}
				
				/*
				 * Babelfish partitioned tables have specific security requirements to maintain data integrity.
				 * Non-superusers should not be permitted to attach, detach, or modify partitions of these tables.
				 */
				if (!babelfish_dump_restore && atstmt->objtype == OBJECT_TABLE && !superuser())
				{
					bbf_alter_handle_partitioned_table(atstmt);
				}
				break;
			}
		case T_TruncateStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					TruncateStmt *stmt = (TruncateStmt *) parsetree;

					stmt->restart_seqs = true;	/* Always restart owned
												 * sequences */
				}
				break;
			}
		case T_CreateRoleStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL && strcmp(queryString, "(CREATE LOGICAL DATABASE )") != 0)
				{
					CreateRoleStmt *stmt = (CreateRoleStmt *) parsetree;
					List	   *login_options = NIL;
					List	   *user_options = NIL;
					ListCell   *option;
					bool		islogin = false;
					bool		isuser = false;
					bool		isrole = false;
					bool		from_windows = false;
					Oid 		save_userid;
					int 		save_sec_context;
					const char	*old_createrole_self_grant;

					/* Check if creating login or role. Expect islogin first */
					if (stmt->options != NIL)
					{
						DefElem    *headel = (DefElem *) linitial(stmt->options);

						/*
						 * If islogin set the options list to after the head.
						 * Save the list of login specific options.
						 */
						if (strcmp(headel->defname, "islogin") == 0)
						{
							char	   *orig_loginname = NULL;

							islogin = true;
							stmt->options = list_delete_cell(stmt->options,
															 list_head(stmt->options));
							pfree(headel);

							/* Filter login options from default role options */
							foreach(option, stmt->options)
							{
								DefElem    *defel = (DefElem *) lfirst(option);

								if (strcmp(defel->defname, "default_database") == 0)
									login_options = lappend(login_options, defel);
								else if (strcmp(defel->defname, "name_location") == 0)
								{
									int			location = defel->location;

									orig_loginname = extract_identifier(queryString + location, NULL);
									login_options = lappend(login_options, defel);
								}
								else if (strcmp(defel->defname, "from_windows") == 0)
								{
									if (!pltsql_allow_windows_login)
										ereport(ERROR,
												(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
												 errmsg("Windows login is not supported in babelfish")));
									from_windows = true;
									login_options = lappend(login_options, defel);
								}
							}

							foreach(option, login_options)
							{
								stmt->options = list_delete_ptr(stmt->options,
																lfirst(option));
							}

							if (orig_loginname)
							{
								login_options = lappend(login_options,
														makeDefElem("original_login_name",
																	(Node *) makeString(orig_loginname),
																	-1));
							}

							if (from_windows && orig_loginname)
							{
								char* domain_name = NULL;

								/*
								 * The login name must contain '\' if it is
								 * windows login or else throw error.
								 */
								if ((strchr(orig_loginname, '\\')) == NULL)
									ereport(ERROR,
											(errcode(ERRCODE_INVALID_NAME),
											 errmsg("'%s' is not a valid Windows NT name. Give the complete name: <domain\\username>.",
													orig_loginname)));

								/*
								 * Check whether domain name is empty. If the
								 * first character is '\', that ensures domain
								 * is empty.
								 */
								if (orig_loginname[0] == '\\')
									ereport(ERROR,
											(errcode(ERRCODE_INVALID_NAME),
											 errmsg("The login name '%s' is invalid. The domain can not be empty.",
													orig_loginname)));

								/*
								 * Check whether login_name has valid length
								 * or not.
								 */
								if (!check_windows_logon_length(orig_loginname))
									ereport(ERROR,
											(errcode(ERRCODE_INVALID_NAME),
											 errmsg("The login name '%s' has invalid length. Login name length should be between %d and %d for windows login.",
													orig_loginname, (LOGON_NAME_MIN_LEN + 1), (LOGON_NAME_MAX_LEN - 1))));

								/*
								 * Check whether the login_name contains
								 * invalid characters or not.
								 */
								if (windows_login_contains_invalid_chars(orig_loginname))
									ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
													errmsg("'%s' is not a valid name because it contains invalid characters.", orig_loginname)));

								/* 
								 * Check whether the domain name is supported 
								 * or not
								 */
								domain_name = get_windows_domain_name(orig_loginname);
								if(windows_domain_is_not_supported(domain_name))
									ereport(ERROR,
											(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
												errmsg("'%s' domain is not yet supported in Babelfish.", domain_name)));

								/*
								 * Check whether the domain name contains invalid characters or not.
								 */
								if (windows_domain_contains_invalid_chars(orig_loginname))
									ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
													errmsg("'%s' is not valid because the domain name contains invalid characters.", orig_loginname)));

								pfree(stmt->role);
								stmt->role = convertToUPN(orig_loginname);

								/*
								 * Check for duplicate login
								 */
								if (get_role_oid(stmt->role, true) != InvalidOid)
									ereport(ERROR, (errcode(ERRCODE_DUPLICATE_OBJECT),
													errmsg("The Server principal '%s' already exists", stmt->role)));
							}

							/*
							 * Length of login name should be less than 128.
							 * Throw an error here if it is not. XXX: Below
							 * check is to work around BABEL-3868.
							 */
							if (strlen(stmt->role) >= NAMEDATALEN)
							{
								ereport(ERROR,
										(errcode(ERRCODE_INVALID_NAME),
										 errmsg("The login name '%s' is too long. Maximum length is %d.",
												stmt->role, (NAMEDATALEN - 1))));
							}

							/*
							 * If the login name contains '\' and it is not a
							 * windows login then throw error. For windows
							 * login, all cases are handled beforehand, so if
							 * the below condition is hit that means it is
							 * password based authentication and login name
							 * contains '\', which is not allowed
							 */
							if (!from_windows && strchr(stmt->role, '\\') != NULL)
								ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
												errmsg("'%s' is not a valid name because it contains invalid characters.", stmt->role)));

							from_windows = false;
						}
						else if (strcmp(headel->defname, "isuser") == 0)
						{
							int			location = -1;

							isuser = true;
							stmt->options = list_delete_cell(stmt->options,
															 list_head(stmt->options));
							pfree(headel);

							/* Filter user options from default role options */
							foreach(option, stmt->options)
							{
								DefElem    *defel = (DefElem *) lfirst(option);

								if (strcmp(defel->defname, "default_schema") == 0)
									user_options = lappend(user_options, defel);
								else if (strcmp(defel->defname, "name_location") == 0)
								{
									location = defel->location;
									user_options = lappend(user_options, defel);
								}
								else if (strcmp(defel->defname, "rolemembers") == 0)
								{
									RoleSpec   *login = (RoleSpec *) linitial((List *) defel->arg);

									if (strchr(login->rolename, '\\') != NULL)
									{
										/*
										 * If login->rolename contains '\'
										 * then treat it as windows login.
										 */
										char	   *upn_login = convertToUPN(login->rolename);

										if (upn_login != login->rolename)
										{
											pfree(login->rolename);
											login->rolename = upn_login;
										}
										from_windows = true;
										if (!pltsql_allow_windows_login)
											ereport(ERROR,
													(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
													 errmsg("Windows login is not supported in babelfish")));
									}
									/* If login is a member of sysadmin, creating user for that login should not be allowed. */
									if (has_privs_of_role(get_role_oid(login->rolename, false), get_sysadmin_oid()))
										ereport(ERROR, (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
														errmsg("Cannot create user for sysadmin role.")));
								}
							}

							foreach(option, user_options)
							{
								stmt->options = list_delete_ptr(stmt->options,
																lfirst(option));
							}

							if (location >= 0)
							{
								char	   *orig_user_name;

								orig_user_name = extract_identifier(queryString + location, NULL);
								user_options = lappend(user_options,
													   makeDefElem("original_user_name",
																   (Node *) makeString(orig_user_name),
																   -1));
							}
						}
						else if (strcmp(headel->defname, "isrole") == 0)
						{
							int			location = -1;
							bool		orig_username_exists = false;

							isrole = true;
							stmt->options = list_delete_cell(stmt->options,
															 list_head(stmt->options));
							pfree(headel);

							/*
							 * Filter TSQL role options from default role
							 * options
							 */
							foreach(option, stmt->options)
							{
								DefElem    *defel = (DefElem *) lfirst(option);

								if (strcmp(defel->defname, "name_location") == 0)
								{
									location = defel->location;
									user_options = lappend(user_options, defel);
								}

								/*
								 * This condition is to handle create role
								 * when using sp_addrole procedure because
								 * there we add original_user_name before hand
								 */
								if (strcmp(defel->defname, "original_user_name") == 0)
								{
									user_options = lappend(user_options, defel);
									orig_username_exists = true;
								}

							}


							foreach(option, user_options)
							{
								stmt->options = list_delete_ptr(stmt->options,
																lfirst(option));
							}

							if (location >= 0 && !orig_username_exists)
							{
								char	   *orig_user_name;

								orig_user_name = extract_identifier(queryString + location, NULL);
								user_options = lappend(user_options,
													   makeDefElem("original_user_name",
																   (Node *) makeString(orig_user_name),
																   -1));
							}
						}

					}

					if (islogin)
					{
						if (!has_privs_of_role(GetSessionUserId(), get_role_oid("sysadmin", false)))
							ereport(ERROR,
									(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
									 errmsg("Current login %s does not have permission to create new login",
											GetUserNameFromId(GetSessionUserId(), true))));

						if (get_role_oid(stmt->role, true) != InvalidOid)
							ereport(ERROR, (errcode(ERRCODE_DUPLICATE_OBJECT),
											errmsg("The Server principal '%s' already exists", stmt->role)));
					}
					else if (isuser || isrole)
					{
						char *db_owner_name;

						db_owner_name = get_db_owner_name(get_cur_db_name());
						if (!has_privs_of_role(GetUserId(),get_role_oid(db_owner_name, false)))
							ereport(ERROR,
									(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
									 errmsg("User does not have permission to perform this action.")));

						pfree(db_owner_name);
					}

					/*
					 * check whether sql user name and role name contains
					 * '\' or not
					 */
					if (isrole || !from_windows)
						validateUserAndRole(stmt->role);

					/* Save the previous user to be restored after creating the login. */
					GetUserIdAndSecContext(&save_userid, &save_sec_context);
					old_createrole_self_grant = pstrdup(GetConfigOption("createrole_self_grant", false, true));

					PG_TRY();
					{
						/*
						 * We have performed all the permissions checks.
						 * Set current user to bbf_role_admin for create permissions.
						 * Set createrole_self_grant to "inherit" so that bbf_role_admin
						 * inherits the new role.
						 */
						SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
						SetConfigOption("createrole_self_grant", "inherit", PGC_USERSET, PGC_S_OVERRIDE);

						if (prev_ProcessUtility)
							prev_ProcessUtility(pstmt, queryString, readOnlyTree, context,
												params, queryEnv, dest,
												qc);
						else
							standard_ProcessUtility(pstmt, queryString, readOnlyTree, context,
													params, queryEnv, dest,
													qc);

						if (islogin)
						{
							stmt->options = list_concat(stmt->options,
														login_options);
							create_bbf_authid_login_ext(stmt);
						}
						else
						{
							/*
								* If the stmt is CREATE USER, it must have a
								* corresponding login and a schema name
								*/
							stmt->options = list_concat(stmt->options,
														user_options);
							create_bbf_authid_user_ext(stmt, isuser, isuser, from_windows);
						}

					}
					PG_FINALLY();
					{
						SetConfigOption("createrole_self_grant", old_createrole_self_grant, PGC_USERSET, PGC_S_OVERRIDE);
						SetUserIdAndSecContext(save_userid, save_sec_context);
					}
					PG_END_TRY();

					return;
				}
				break;
			}
		case T_AlterRoleStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					AlterRoleStmt *stmt = (AlterRoleStmt *) parsetree;
					List	   *login_options = NIL;
					List	   *user_options = NIL;
					ListCell   *option;
					bool		islogin = false;
					bool		isuser = false;
					bool		isrole = false;

					/* Check if creating login or role. Expect islogin first */
					if (stmt->options != NIL)
					{
						DefElem    *headel = (DefElem *) linitial(stmt->options);

						/*
						 * Set the options list to after the head. Save the
						 * list of babelfish specific options.
						 */
						if (strcmp(headel->defname, "islogin") == 0)
						{
							islogin = true;
							stmt->options = list_delete_cell(stmt->options,
															 list_head(stmt->options));
							pfree(headel);

							/* Filter login options from default role options */
							foreach(option, stmt->options)
							{
								DefElem    *defel = (DefElem *) lfirst(option);

								if (strcmp(defel->defname, "default_database") == 0)
									login_options = lappend(login_options, defel);
							}

							foreach(option, login_options)
							{
								stmt->options = list_delete_ptr(stmt->options,
																lfirst(option));
							}
						}
						else if (strcmp(headel->defname, "isuser") == 0)
						{
							isuser = true;
							stmt->options = list_delete_cell(stmt->options,
															 list_head(stmt->options));
							pfree(headel);

							/* Filter user options from default role options */
							foreach(option, stmt->options)
							{
								DefElem    *defel = (DefElem *) lfirst(option);

								if (strcmp(defel->defname, "default_schema") == 0)
									user_options = lappend(user_options, defel);
								else if (strcmp(defel->defname, "rename") == 0)
									user_options = lappend(user_options, defel);
								else if (strcmp(defel->defname, "rolemembers") == 0)
								{
									RoleSpec   *login = (RoleSpec *) linitial((List *) defel->arg);

									if (strchr(login->rolename, '\\') != NULL)
									{
										/*
										 * If login->rolename contains '\'
										 * then treat it as windows login.
										 */
										char	   *upn_login = convertToUPN(login->rolename);

										if (upn_login != login->rolename)
										{
											pfree(login->rolename);
											login->rolename = upn_login;
										}
										if (!pltsql_allow_windows_login)
											ereport(ERROR,
													(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
													 errmsg("Windows login is not supported in babelfish")));
									}
								}
							}

							foreach(option, user_options)
							{
								stmt->options = list_delete_ptr(stmt->options,
																lfirst(option));
							}
						}
						else if (strcmp(headel->defname, "isrole") == 0)
						{
							isrole = true;
							stmt->options = list_delete_cell(stmt->options,
															 list_head(stmt->options));
							pfree(headel);

							/* Filter user options from default role options */
							foreach(option, stmt->options)
							{
								DefElem    *defel = (DefElem *) lfirst(option);

								if (strcmp(defel->defname, "rename") == 0)
									user_options = lappend(user_options, defel);
							}

							foreach(option, user_options)
							{
								stmt->options = list_delete_ptr(stmt->options,
																lfirst(option));
							}
						}
					}

					if (islogin)
					{
						Oid 		datdba;
						bool		has_password = false;
						char	   *temp_login_name = NULL;
						Oid 		save_userid;
						int 		save_sec_context;

						datdba = get_role_oid("sysadmin", false);

						/*
						 * Check if the current login has privileges to alter
						 * password.
						 */
						foreach(option, stmt->options)
						{
							DefElem    *defel = (DefElem *) lfirst(option);

							if (strcmp(defel->defname, "password") == 0)
							{
								if (get_role_oid(stmt->role->rolename, true) != GetSessionUserId() && !is_member_of_role(GetSessionUserId(), datdba))
									ereport(ERROR,(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
											 errmsg("Cannot alter the login '%s', because it does not exist or you do not have permission.", stmt->role->rolename)));

								has_password = true;
							}
						}

						/*
						 * Leveraging the fact that convertToUPN API returns
						 * the login name in UPN format if login name contains
						 * '\' i,e,. windows login. For windows login '\' must
						 * be present and for password based login '\' is not
						 * acceptable. So, combining these, if the login is of
						 * windows then it will be converted to UPN format or
						 * else it will be as it was
						 */
						temp_login_name = convertToUPN(stmt->role->rolename);

						/*
						 * If the previous rolname is same as current, then it
						 * is password based login else, it is windows based
						 * login. If, user is trying to alter password for
						 * windows login, throw error
						 */
						if (temp_login_name != stmt->role->rolename)
						{
							if (has_password)
								ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
												errmsg("Cannot use parameter PASSWORD for a windows login")));

							pfree(stmt->role->rolename);
							stmt->role->rolename = temp_login_name;
						}

						if (!has_privs_of_role(GetSessionUserId(), datdba) && !has_password)
							ereport(ERROR,(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
								errmsg("Cannot alter the login '%s', because it does not exist or you do not have permission.", stmt->role->rolename)));

						if (get_role_oid(stmt->role->rolename, true) == InvalidOid)
							ereport(ERROR, (errcode(ERRCODE_DUPLICATE_OBJECT),
											errmsg("Cannot drop the login '%s', because it does not exist or you do not have permission.", stmt->role->rolename)));

						/*
						 * We have performed all the permissions checks.
						 * Set current user to bbf_role_admin for alter permissions.
						 */
						GetUserIdAndSecContext(&save_userid, &save_sec_context);
						SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);

						PG_TRY();
						{
							if (prev_ProcessUtility)
								prev_ProcessUtility(pstmt, queryString, readOnlyTree, context,
													params, queryEnv, dest,
													qc);
							else
								standard_ProcessUtility(pstmt, queryString, readOnlyTree, context,
														params, queryEnv, dest,
														qc);

							stmt->options = list_concat(stmt->options,
														login_options);
							alter_bbf_authid_login_ext(stmt);
						}
						PG_FINALLY();
						{
							SetUserIdAndSecContext(save_userid, save_sec_context);
						}
						PG_END_TRY();

						return;
					}
					else if (isuser || isrole)
					{
						char	   *dbo_name;
						char	   *db_name;
						char	   *user_name;
						char	   *cur_user;
						Oid     	prev_current_user;

						db_name = get_cur_db_name();
						dbo_name = get_dbo_role_name(db_name);
						user_name = stmt->role->rolename;
						cur_user = GetUserNameFromId(GetUserId(), false);

						/*
						 * Check if the current user has privileges.
						 */
						foreach(option, user_options)
						{
							DefElem    *defel = (DefElem *) lfirst(option);

							if (strcmp(defel->defname, "default_schema") == 0)
							{
								if (strcmp(cur_user, dbo_name) != 0 &&
									strcmp(cur_user, user_name) != 0)
									ereport(ERROR,
											(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
											 errmsg("Current user does not have privileges to change schema")));
							}
							else if (strcmp(defel->defname, "rename") == 0)
							{
								if (strcmp(cur_user, dbo_name) != 0 &&
									strcmp(cur_user, user_name) != 0)
									ereport(ERROR,
											(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
											 errmsg("Current user does not have privileges to change user name")));
							}
						}

						foreach(option, stmt->options)
						{
							DefElem    *defel = (DefElem *) lfirst(option);

							if (strcmp(defel->defname, "rolemembers") == 0)
							{
								if (strcmp(cur_user, dbo_name) != 0 &&
									strcmp(cur_user, user_name) != 0)
									ereport(ERROR,
											(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
											 errmsg("Current user does not have privileges to change login")));
							}
						}

						/*
						 * We have performed all the permissions checks.
						 * Set current user to bbf_role_admin for alter permissions.
						 */
						prev_current_user = GetUserId();
						SetCurrentRoleId(get_bbf_role_admin_oid(), true);

						PG_TRY();
						{
							if (prev_ProcessUtility)
								prev_ProcessUtility(pstmt, queryString, readOnlyTree, context,
													params, queryEnv, dest,
													qc);
							else
								standard_ProcessUtility(pstmt, queryString, readOnlyTree, context,
														params, queryEnv, dest,
														qc);

							stmt->options = list_concat(stmt->options,
														user_options);
							alter_bbf_authid_user_ext(stmt);
						}
						PG_FINALLY();
						{
							SetCurrentRoleId(prev_current_user, true);
						}
						PG_END_TRY();

						set_session_properties(db_name);
						pfree(cur_user);
						pfree(db_name);
						pfree(dbo_name);

						return;
					}
				}
				break;
			}
		case T_DropRoleStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL && strcmp(queryString, "(DROP DATABASE )") != 0)
				{
					DropRoleStmt *stmt = (DropRoleStmt *) parsetree;
					bool		drop_user = false;
					bool		drop_role = false;
					bool        drop_login = false;
					bool		all_logins = false;
					bool		all_users = false;
					bool		all_roles = false;
					char	   *role_name = NULL;
					bool		other = false;
					ListCell   *item;
					char	   *db_name;
					Oid 		save_userid;
					int 		save_sec_context;

					/* Check if roles are users that need role name mapping */
					if (stmt->roles != NIL)
					{
						RoleSpec   *headrol = linitial(stmt->roles);

						if (strcmp(headrol->rolename, "is_user") == 0)
							drop_user = true;
						else if (strcmp(headrol->rolename, "is_role") == 0)
							drop_role = true;
						else
							drop_login = true;

						if (drop_user || drop_role)
						{
							stmt->roles = list_delete_cell(stmt->roles,
														   list_head(stmt->roles));
							pfree(headrol);
							headrol = NULL;
							db_name = get_cur_db_name();

							if (db_name != NULL && strcmp(db_name, "") != 0)
							{
								foreach(item, stmt->roles)
								{
									RoleSpec	*rolspec = lfirst(item);
									char		*user_name;
									const char	*db_principal_type = drop_user ? "user" : "role";
									char		*db_owner_name;
									int		role_oid;
									int		rolename_len;
									bool		is_tsql_db_principal = false;
									bool		is_psql_db_principal = false;
									Oid		dbowner;

									user_name = get_physical_user_name(db_name, rolspec->rolename, false, true);
									db_owner_name = get_db_owner_name(db_name);
									dbowner = get_role_oid(db_owner_name, false);
									role_oid = get_role_oid(user_name, true);
									rolename_len = strlen(rolspec->rolename);
									is_tsql_db_principal = OidIsValid(role_oid) &&
														   ((drop_user && is_user(role_oid)) ||
															(drop_role && is_role(role_oid)));
									is_psql_db_principal = OidIsValid(role_oid) && !is_tsql_db_principal;

									/* If user is dbo or role is db_owner, restrict dropping */
									if ((drop_user && rolename_len == 3 && strncmp(rolspec->rolename, "dbo", 3) == 0) ||
										(drop_role && rolename_len == 8 && strncmp(rolspec->rolename, "db_owner", 8) == 0))
										ereport(ERROR,
												(errcode(ERRCODE_CHECK_VIOLATION),
												 errmsg("Cannot drop the %s '%s'.", db_principal_type, rolspec->rolename)));

									/* 
									 * Check for current_user's privileges 
									 * must be database owner to drop user/role
									 */
									if ((!stmt->missing_ok && !is_tsql_db_principal) ||
										!is_member_of_role(GetUserId(), dbowner) ||
										(is_tsql_db_principal && !is_member_of_role(dbowner, role_oid)) || is_psql_db_principal)
										ereport(ERROR,
												(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
												 errmsg("Cannot drop the %s '%s', because it does not exist or you do not have permission.", db_principal_type, rolspec->rolename)));
									
									/*
									 * If a role has members, do not drop it.
									 * Note that here we don't handle invalid
									 * roles.
									 */
									if (drop_role && !is_empty_role(role_oid))
										ereport(ERROR,
												(errcode(ERRCODE_CHECK_VIOLATION),
												 errmsg("The role has members. It must be empty before it can be dropped.")));

									/*
									 * If the statement is drop_user and the
									 * user is guest: 1. If the db is "master"
									 * or "tempdb", don't disable the guest
									 * user. 2. Else, disable the guest user
									 * if enabled. 3. Otherwise throw an
									 * error.
									 */
									if (drop_user && strcmp(rolspec->rolename, "guest") == 0)
									{
										if (guest_has_dbaccess(db_name))
										{
											if (strcmp(db_name, "master") == 0 || strcmp(db_name, "tempdb") == 0)
												ereport(ERROR,
														(errcode(ERRCODE_CHECK_VIOLATION),
														 errmsg("Cannot disable access to the guest user in master or tempdb.")));

											alter_user_can_connect(false, rolspec->rolename, db_name);

											pfree(db_owner_name);
											
											return;
										}
										else
											ereport(ERROR,
													(errcode(ERRCODE_CHECK_VIOLATION),
													 errmsg("User 'guest' cannot be dropped, it can only be disabled. "
															"The user is already disabled in the current database.")));
									}

									pfree(rolspec->rolename);
									pfree(db_owner_name);

									rolspec->rolename = user_name;
								}
							}
							else
								ereport(ERROR,
										(errcode(ERRCODE_UNDEFINED_DATABASE),
										 errmsg("Current database missing. "
												"Can only drop users in current database. ")));
						}
					}

					/*
					 * List must be all one type of babelfish role. Cannot
					 * mix.
					 */
					foreach(item, stmt->roles)
					{
						RoleSpec   *rolspec = lfirst(item);
						Form_pg_authid roleform;
						HeapTuple	tuple;

						role_name = rolspec->rolename;
						tuple = SearchSysCache1(AUTHNAME,
												PointerGetDatum(role_name));
						/* Let DropRole handle missing roles */
						if (HeapTupleIsValid(tuple))
							roleform = (Form_pg_authid) GETSTRUCT(tuple);
						else
						{
							/*
							 * Supplied login name might be in windows format
							 * i.e, domain\login form
							 */
							if (strchr(role_name, '\\') != NULL)
							{
								/*
								 * This means that provided login name is in
								 * windows format so let's update role_name
								 * with UPN format.
								 */
								role_name = convertToUPN(role_name);
								tuple = SearchSysCache1(AUTHNAME,
														PointerGetDatum(role_name));
								if (HeapTupleIsValid(tuple))
								{
									roleform = (Form_pg_authid) GETSTRUCT(tuple);
									pfree(rolspec->rolename);
									rolspec->rolename = role_name;
								}
								else
								{
									continue;
								}
							}
							else
							{
								continue;
							}
						}

						if (is_login(roleform->oid))
							all_logins = true;
						else if (is_user(roleform->oid))
							all_users = true;
						else if (is_role(roleform->oid))
							all_roles = true;
						else
							other = true;

						if (drop_login && is_login(roleform->oid) && !has_privs_of_role(GetSessionUserId(), get_role_oid("sysadmin", false))){
							ereport(ERROR,
									(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
									errmsg("Cannot drop the login '%s', because it does not exist or you do not have permission.", role_name)));
						}

						ReleaseSysCache(tuple);

						/* Only one should be true */
						if (all_logins + all_users + all_roles + other != 1)
							ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									 errmsg("cannot mix dropping babelfish role types")));
					}

					/* If not user or role, then login */
					if (drop_login)
					{
						int			role_oid = get_role_oid(role_name, true);

						if (!OidIsValid(role_oid) ||
							!is_member_of_role(GetSessionUserId(), get_sysadmin_oid()) ||
							role_oid == get_bbf_role_admin_oid())
							ereport(ERROR, (errcode(ERRCODE_DUPLICATE_OBJECT),
											errmsg("Cannot drop the login '%s', because it does not exist or you do not have permission.", role_name)));

						/*
						 * Prevent if it is active login (begin used by other
						 * sessions)
						 */
						if (is_active_login(role_oid))
							ereport(ERROR,
									(errcode(ERRCODE_OBJECT_IN_USE),
									 errmsg("Could not drop login '%s' as the user is currently logged in.", role_name)));
					}

					/*
					 * We have performed all the permissions checks.
					 * Set current user to bbf_role_admin for drop permissions.
					 */
					GetUserIdAndSecContext(&save_userid, &save_sec_context);
					SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);

					PG_TRY();
					{
						if (prev_ProcessUtility)
							prev_ProcessUtility(pstmt, queryString, readOnlyTree, context,
												params, queryEnv, dest,
												qc);
						else
							standard_ProcessUtility(pstmt, queryString, readOnlyTree, context,
													params, queryEnv, dest,
													qc);
					}
					PG_FINALLY();
					{
						SetUserIdAndSecContext(save_userid, save_sec_context);
					}
					PG_END_TRY();

					return;
				}
				break;
			}
		case T_CreateSchemaStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					CreateSchemaStmt *create_schema = (CreateSchemaStmt *) parsetree;
					const char *orig_schema = NULL;
					const char *grant_query = "GRANT USAGE ON SCHEMA dummy TO public";
					List	   *res;
					GrantStmt  *stmt;
					PlannedStmt *wrapper;
					RoleSpec *rolspec = create_schema->authrole;

					if (strcmp(queryString, "(CREATE LOGICAL DATABASE )") == 0
						&& context == PROCESS_UTILITY_SUBCOMMAND)
					{
						if (pstmt->stmt_len == 19)
							orig_schema = "guest";
						else
							orig_schema = "dbo";
					}

					if (prev_ProcessUtility)
						prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
											queryEnv, dest, qc);
					else
						standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
												queryEnv, dest, qc);

					add_ns_ext_info(create_schema, queryString, orig_schema);

					res = raw_parser(grant_query, RAW_PARSE_DEFAULT);

					if (list_length(res) != 1)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("Expected 1 statement, but got %d statements after parsing",
										list_length(res))));

					stmt = (GrantStmt *) parsetree_nth_stmt(res, 0);
					stmt->objects = list_truncate(stmt->objects, 0);
					stmt->objects = lappend(stmt->objects, makeString(pstrdup(create_schema->schemaname)));

					wrapper = makeNode(PlannedStmt);
					wrapper->commandType = CMD_UTILITY;
					wrapper->canSetTag = false;
					wrapper->utilityStmt = (Node *) stmt;
					wrapper->stmt_location = pstmt->stmt_location;
					wrapper->stmt_len = pstmt->stmt_len;

					ProcessUtility(wrapper,
								   queryString,
								   readOnlyTree,
								   PROCESS_UTILITY_SUBCOMMAND,
								   params,
								   NULL,
								   None_Receiver,
								   NULL);

					CommandCounterIncrement();
					/* Grant ALL schema privileges to the user.*/
					if (rolspec && strcmp(queryString, "(CREATE LOGICAL DATABASE )") != 0)
					{
						int i;
						for (i = 0; i < NUMBER_OF_PERMISSIONS; i++)
						{
							/* Execute the GRANT SCHEMA subcommands. */
							exec_grantschema_subcmds(create_schema->schemaname, rolspec->rolename, true, false, permissions[i], true);
						}
					}
					return;
				}
				else
					break;
			}
		case T_DropStmt:
			{
				DropStmt   *drop_stmt = (DropStmt *) parsetree;

				if (drop_stmt->removeType == OBJECT_TABLE)
					bbf_drop_handle_partitioned_table(drop_stmt);

				if (drop_stmt->removeType != OBJECT_SCHEMA)
				{
					bbf_ExecDropStmt(drop_stmt);
					break;
				}

				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					/*
					 * Prevent dropping guest schema unless it is part of drop
					 * database command.
					 */
					const char *schemaname = strVal(lfirst(list_head(drop_stmt->objects)));
					char	   *cur_db = get_cur_db_name();
					const char	*logicalschema = get_logical_schema_name(schemaname, true);
					bool	is_drop_db_statement = 0 == strcmp(queryString, "(DROP DATABASE )");

					if (!is_drop_db_statement)
					{
						char	   *guest_schema_name = get_physical_schema_name(cur_db, "guest");

						if (strcmp(schemaname, guest_schema_name) == 0)
						{
							ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									 errmsg("Cannot drop the schema \'%s\'", schemaname)));
						}
					}

					bbf_ExecDropStmt(drop_stmt);
					del_ns_ext_info(schemaname, drop_stmt->missing_ok);
					if (!is_drop_db_statement)
					{
						/*
						 * Prevent cleaning up the catalog here if it is a part
						 * of drop database command.
						 */
						clean_up_bbf_schema_permissions(logicalschema, NULL, true);
					}

					if (prev_ProcessUtility)
						prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
											queryEnv, dest, qc);
					else
						standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
												queryEnv, dest, qc);
					return;
				}
				else
				{
					if (prev_ProcessUtility)
						prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
											queryEnv, dest, qc);
					else
						standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
												queryEnv, dest, qc);
					check_extra_schema_restrictions(parsetree);
					return;
				}
			}
		case T_GrantRoleStmt:
			if (sql_dialect == SQL_DIALECT_TSQL && strcmp(queryString, "(CREATE LOGICAL DATABASE )") != 0)
			{
				GrantRoleStmt *grant_role = (GrantRoleStmt *) parsetree;
				Oid 	save_userid;
				int 	save_sec_context;

				if (is_alter_server_stmt(grant_role))
				{
					StringInfoData query;
					RoleSpec   *spec;
					check_alter_server_stmt(grant_role);
					spec = (RoleSpec *) linitial(grant_role->grantee_roles);
					initStringInfo(&query);
					if (grant_role->is_grant)
						appendStringInfo(&query, "ALTER ROLE dummy WITH createrole createdb; ");
					else
						appendStringInfo(&query, "ALTER ROLE dummy WITH nocreaterole nocreatedb; ");
					
					/*
					 * Set to bbf_role_admin to grant the role
					 * We have already checked for permissions
					 */
					GetUserIdAndSecContext(&save_userid, &save_sec_context);
					SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
					PG_TRY();
					{

						if (prev_ProcessUtility)
							prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
												queryEnv, dest, qc);
						else
							standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
													queryEnv, dest, qc);
						exec_alter_role_cmd(query.data, spec);

					}
					PG_FINALLY();
					{
						/* Clean up. Restore previous state. */
						SetUserIdAndSecContext(save_userid, save_sec_context);
						pfree(query.data);
					}
					PG_END_TRY();
					return;
				}
				else if (is_alter_role_stmt(grant_role))
				{
					check_alter_role_stmt(grant_role);

					/*
					 * We have performed all the permissions checks.
					 * Set current user to bbf_role_admin for grant permissions.
					 */
					GetUserIdAndSecContext(&save_userid, &save_sec_context);
					SetUserIdAndSecContext(get_bbf_role_admin_oid(), save_sec_context | SECURITY_LOCAL_USERID_CHANGE);
					PG_TRY();
					{
						if (prev_ProcessUtility)
							prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
												queryEnv, dest, qc);
						else
							standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
													queryEnv, dest, qc);

					}
					PG_FINALLY();
					{
						/* Clean up. Restore previous state. */
						SetUserIdAndSecContext(save_userid, save_sec_context);
					}
					PG_END_TRY();
					return;
				}
			}
			break;
		case T_RenameStmt:
			{
				RenameStmt *stmt = (RenameStmt *) parsetree;

				if (prev_ProcessUtility)
					prev_ProcessUtility(pstmt, queryString, readOnlyTree, context,
										params, queryEnv, dest, qc);
				else
					standard_ProcessUtility(pstmt, queryString, readOnlyTree, context,
											params, queryEnv, dest, qc);
				
				if (stmt->renameType == OBJECT_TABLE)
					bbf_rename_handle_partitioned_table(stmt);
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					rename_update_bbf_catalog(stmt);
					/* Clean up. Restore previous state. */
					return;
				}
				check_extra_schema_restrictions(parsetree);

				return;
			}
		case T_CreateTableAsStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					CreateTableAsStmt *stmt = (CreateTableAsStmt *) parsetree;
					Oid			relid;
					Relation	rel;
					TupleDesc	tupdesc;
					AttrNumber	attr_num;

					if (prev_ProcessUtility)
						prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
											queryEnv, dest, qc);
					else
						standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
												queryEnv, dest, qc);

					relid = RangeVarGetRelid(stmt->into->rel, NoLock, false);
					rel = RelationIdGetRelation(relid);
					tupdesc = RelationGetDescr(rel);

					/*
					 * If table contains a rowversion column add a default
					 * node to that column. It is needed as table created with
					 * SELECT-INTO will not get the column defaults from
					 * parent table.
					 */
					for (attr_num = 0; attr_num < tupdesc->natts; attr_num++)
					{
						Form_pg_attribute attr;

						attr = TupleDescAttr(tupdesc, attr_num);

						/* Skip dropped columns */
						if (attr->attisdropped)
							continue;

						if ((*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (attr->atttypid))
						{
							RawColumnDefault *rawEnt;
							Constraint *con;

							con = get_rowversion_default_constraint(makeTypeNameFromOid(attr->atttypid, attr->atttypmod));
							rawEnt = (RawColumnDefault *) palloc0(sizeof(RawColumnDefault));
							rawEnt->attnum = attr_num + 1;
							rawEnt->raw_default = (Node *) con->raw_expr;
							AddRelationNewConstraints(rel, list_make1(rawEnt), NIL,
													  false, true, true, NULL);
							break;
						}
					}

					RelationClose(rel);
					return;
				}
				break;
			}
		case T_CreateStmt:
			{
				CreateStmt *create_stmt = (CreateStmt *) parsetree;
				RangeVar   *rel = create_stmt->relation;
				bool		isTableVariable = (rel->relname[0] == '@');

				if (restore_tsql_tabletype)
					create_stmt->tsql_tabletype = true;

				if (prev_ProcessUtility)
					prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
										queryEnv, dest, qc);
				else
					standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
											queryEnv, dest, qc);

				/*
				 * Create partitions of babelfish partitioned table
				 * using the partition scheme and partitioning column.
				 */
				if (create_stmt->partspec && create_stmt->partspec->tsql_partition_scheme)
				{
					bbf_create_partition_tables(create_stmt);
				}

				if (create_stmt->tsql_tabletype || isTableVariable)
				{
					List	   *name;

					if (rel->schemaname)
						name = list_make2(makeString(rel->schemaname), makeString(rel->relname));
					else
						name = list_make1(makeString(rel->relname));

					set_pgtype_byval(name, true);

					if (create_stmt->tsql_tabletype)
						revoke_type_permission_from_public(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, qc, name);
				}

				return;
			}
		case T_IndexStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					IndexStmt *stmt = (IndexStmt *) parsetree;

					/*
					 * Create partitioned index if partition scheme is specified.
					 * Allow only aligned-index.
					 */
					if (stmt->excludeOpNames != NIL)
					{
						List *partition_schemes = stmt->excludeOpNames;
						stmt->excludeOpNames = NIL;

						/*
						 * Create the index first so that columns and table name
						 * checks get done before index alignment check.
						 */
						if (prev_ProcessUtility)
							prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
										queryEnv, dest, qc);
						else
							standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
											queryEnv, dest, qc);
						
						stmt->excludeOpNames = partition_schemes;

						/* Validate that index is aligned-index. */
						if (!bbf_validate_partitioned_index_alignment(stmt))
						{
							ereport(ERROR,
								(errcode(ERRCODE_UNDEFINED_OBJECT),
									errmsg("Un-aligned Index is not supported in Babelfish.")));
						}
						return;
					}
				}
				break;
			}
		case T_CreateDomainStmt:
			{
				HeapTuple			typeTup;
				Form_pg_type		baseType;
				int32				basetypeMod;
				CreateDomainStmt	*create_domain = (CreateDomainStmt *) parsetree;

				if (sql_dialect == SQL_DIALECT_TSQL && !create_domain->collClause)
				{
					/* check if base type is collatable? */
					typeTup = typenameType(NULL, create_domain->typeName, &basetypeMod);
					baseType = (Form_pg_type) GETSTRUCT(typeTup);

					if (OidIsValid(baseType->typcollation))
					{
						CollateClause *n;
						/*
						* Always set collation corresponding to database default or server default
						* for new type being defined.
						*/
						char *coll = get_collation_name(tsql_get_database_or_server_collation_oid_internal(false));

						if (coll == NULL)
						{
							ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									errmsg("Default collation couldn't be determined for new data type.")));
						}

						n = makeNode(CollateClause);
						n->arg = NULL;
						n->collname = list_make1(makeString(coll));
						n->location = -1;
						create_domain->collClause = n;
					}
					ReleaseSysCache(typeTup);
				}

				if (prev_ProcessUtility)
					prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
										queryEnv, dest, qc);
				else
					standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
											queryEnv, dest, qc);

				revoke_type_permission_from_public(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, qc, create_domain->domainname);
				return;
			}
		case T_VariableSetStmt:
			{
				VariableSetStmt *variable_set = (VariableSetStmt *) parsetree;

				if(strcmp(variable_set->name, "SESSION CHARACTERISTICS") == 0)
				{
					ListCell   		*head;

					foreach(head, variable_set->args)
					{
						DefElem		*item = (DefElem *) lfirst(head);
						A_Const		*isolation_level = (A_Const *) item->arg;

						if(strcmp(item->defname, "transaction_isolation") == 0)
						{
							bbf_set_tran_isolation(strVal(&isolation_level->val));
							return;
						}
					}
				}

				if(IS_TDS_CLIENT() &&
				   (strcmp(variable_set->name, "session_authorization") == 0 ||
					strcmp(variable_set->name, "role") == 0))
				{
					ereport(ERROR,
							(errcode(ERRCODE_INTERNAL_ERROR),
							 errmsg("SET/RESET %s not is not supported from TDS endpoint.",
							        variable_set->name)));
				}
				break;
			}
		case T_GrantStmt:
			{
				GrantStmt *grant = (GrantStmt *) parsetree;
				char	   *dbname = get_cur_db_name();
				const char *current_user = GetUserNameFromId(GetUserId(), false);
				/* Ignore when GRANT statement has no specific named object. */
				if (sql_dialect != SQL_DIALECT_TSQL || grant->targtype != ACL_TARGET_OBJECT)
					break;
				Assert(list_length(grant->objects) == 1);
				if (grant->objtype == OBJECT_SCHEMA)
						break;
				else if (grant->objtype == OBJECT_TABLE && strcmp("(CREATE LOGICAL DATABASE )", queryString) != 0)
				{
					/*
					 * Ignore GRANT statements that are executed implicitly as a part of
					 * CREATE database statements. Refer: create_bbf_db_internal().
					 * These GRANT statement are just executed at the end, without checking any
					 * schema permission or adding catalog entry.
					 */
					RangeVar   *rv = (RangeVar *) linitial(grant->objects);
					const char *logical_schema = NULL;
					char	   *obj = rv->relname;
					bool exec_pg_command = false;
					ListCell   *lc;
					ListCell	*lc1;
					if (rv->schemaname != NULL)
						logical_schema = get_logical_schema_name(rv->schemaname, false);
					else
						logical_schema = get_authid_user_ext_schema_name(dbname, current_user);

					/* If ALL PRIVILEGES is granted/revoked. */
					if (list_length(grant->privileges) == 0)
					{
						if (grant->is_grant)
						{
							foreach(lc, grant->grantees)
							{
								RoleSpec	   *rol_spec = (RoleSpec *) lfirst(lc);
								add_or_update_object_in_bbf_schema(logical_schema, obj, ALL_PERMISSIONS_ON_RELATION, rol_spec->rolename, OBJ_RELATION, true, NULL);
							}
						}
						else
						{
							foreach(lc, grant->grantees)
							{
								RoleSpec	   *rol_spec = (RoleSpec *) lfirst(lc);
								/*
								 * 1. If permission on schema exists, don't revoke any permission from the object.
								 * 2. If permission on object exists, update the privilege in the catalog and revoke permission.
								 */
								update_privileges_of_object(logical_schema, obj, ALL_PERMISSIONS_ON_RELATION, rol_spec->rolename, OBJ_RELATION, false);
								if (privilege_exists_in_bbf_schema_permissions(logical_schema, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, rol_spec->rolename))
									return;
							}
						}
						exec_pg_command = true;
					}
					foreach(lc1, grant->privileges)
					{
						AccessPriv *ap = (AccessPriv *) lfirst(lc1);
						AclMode privilege = string_to_privilege(ap->priv_name);
						if (grant->is_grant)
						{
							exec_pg_command = true;
							/* Don't add/update an entry, if the permission is granted on column list.*/
							if (ap->cols == NULL)
							{
								foreach(lc, grant->grantees)
								{
									RoleSpec	   *rol_spec = (RoleSpec *) lfirst(lc);
									add_or_update_object_in_bbf_schema(logical_schema, obj, privilege, rol_spec->rolename, OBJ_RELATION, true, NULL);
								}
							}
						}
						else
						{
							/* Don't update an entry, if the permission is granted on column list.*/
							if (ap->cols == NULL)
							{
								foreach(lc, grant->grantees)
								{
									RoleSpec	   *rol_spec = (RoleSpec *) lfirst(lc);
									/*
									 * If permission on schema exists, don't revoke any permission from the object.
									 */
									if (!exec_pg_command && !privilege_exists_in_bbf_schema_permissions(logical_schema, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, rol_spec->rolename))
										exec_pg_command = true;

									update_privileges_of_object(logical_schema, obj, privilege, rol_spec->rolename, OBJ_RELATION, false);
								}
							}
						}
					}
					if (exec_pg_command)
						call_prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, qc);
					return;
				}
				else if ((grant->objtype == OBJECT_PROCEDURE) || (grant->objtype == OBJECT_FUNCTION))
				{
					ObjectWithArgs  *ob = (ObjectWithArgs *) linitial(grant->objects);
					ListCell   *lc;
					ListCell	*lc1;
					bool exec_pg_command = false;
					const char *logicalschema = NULL;
					char *funcname = NULL;
					const char *obj_type = NULL;
					Oid func_oid = LookupFuncWithArgs(OBJECT_ROUTINE, ob, true);
					const char *func_args = NULL;
					if (OidIsValid(func_oid))
						func_args = gen_func_arg_list(func_oid);
					if (grant->objtype == OBJECT_FUNCTION)
						obj_type = OBJ_FUNCTION;
					else
						obj_type = OBJ_PROCEDURE;
					if (list_length(ob->objname) == 1)
					{
						Node *func = (Node *) linitial(ob->objname);
						funcname = strVal(func);
						logicalschema = get_authid_user_ext_schema_name(dbname, current_user);
					}
					else
					{
						Node *schema = (Node *) linitial(ob->objname);
						char *schemaname = strVal(schema);
						Node *func = (Node *) lsecond(ob->objname);
						logicalschema = get_logical_schema_name(schemaname, true);
						funcname = strVal(func);
					}

					/* If ALL PRIVILEGES is granted/revoked. */
					if (list_length(grant->privileges) == 0)
					{
						/*
						 * Case: When ALL PRIVILEGES is revoked internally during create function.
						 * pstmt->stmt_len = 0 means it is an implicit REVOKE statement issued at the time of create function/procedure.
						 * For more details, please refer revoke_func_permission_from_public().
						 * If schema entry exists in the catalog, implicitly grant permission on the new object to the user.
						 */
						if ((pstmt->stmt_len == 0) && privilege_exists_in_bbf_schema_permissions(logicalschema, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, NULL))
						{
							call_prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, qc);
							exec_internal_grant_on_function(logicalschema, funcname, obj_type);
							return;
						}

						if (grant->is_grant)
						{
							foreach(lc, grant->grantees)
							{
								RoleSpec	   *rol_spec = (RoleSpec *) lfirst(lc);
								add_or_update_object_in_bbf_schema(logicalschema, funcname, ALL_PERMISSIONS_ON_FUNCTION, rol_spec->rolename, obj_type, true, func_args);
							}
						}
						else
						{
							foreach(lc, grant->grantees)
							{
								RoleSpec	   *rol_spec = (RoleSpec *) lfirst(lc);
								/*
								 * 1. If permission on schema exists, don't revoke any permission from the object.
								 * 2. If permission on object exists, update the privilege in the catalog and revoke permission.
								 */
								update_privileges_of_object(logicalschema, funcname, ALL_PERMISSIONS_ON_FUNCTION, rol_spec->rolename, obj_type, false);
								if (privilege_exists_in_bbf_schema_permissions(logicalschema, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, rol_spec->rolename))
									return;
							}
						}
						exec_pg_command = true;
					}
					foreach(lc1, grant->privileges)
					{
						AccessPriv *ap = (AccessPriv *) lfirst(lc1);
						AclMode privilege = string_to_privilege(ap->priv_name);
						if (grant->is_grant)
						{
							exec_pg_command = true;
							if (strcmp("(GRANT STATEMENT )", queryString) != 0)
							{
								/*
								 * If it is an implicit GRANT issued by exec_internal_grant_on_function, then we should not add catalog
								 * entry. Catalog entry is supposed to be added only by explicit GRANTs.
								 */
								foreach(lc, grant->grantees)
								{
									RoleSpec	   *rol_spec = (RoleSpec *) lfirst(lc);
									add_or_update_object_in_bbf_schema(logicalschema, funcname, privilege, rol_spec->rolename, obj_type, true, func_args);
								}
							}
						}
						else
						{
							foreach(lc, grant->grantees)
							{
								RoleSpec	   *rol_spec = (RoleSpec *) lfirst(lc);

								/*
								 * If permission on schema exists, don't revoke any permission from the object.
								 */
								if (!exec_pg_command && !privilege_exists_in_bbf_schema_permissions(logicalschema, PERMISSIONS_FOR_ALL_OBJECTS_IN_SCHEMA, rol_spec->rolename))
									exec_pg_command = true;
								/* Update the privilege in the catalog. */
								update_privileges_of_object(logicalschema, funcname, privilege, rol_spec->rolename, obj_type, false);
							}
						}
					}
					if (exec_pg_command)
						call_prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, qc);
					return;
				}
			}
		default:
			break;
	}

	call_prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, qc);

	/* Cleanup babelfish_server_options catalog when tds_fdw extension is dropped */
	if (sql_dialect == SQL_DIALECT_PG && nodeTag(parsetree) == T_DropStmt)
	{
		DropStmt   *drop_stmt = (DropStmt *) parsetree;
		if (drop_stmt != NULL && drop_stmt->removeType == OBJECT_EXTENSION)
		{
			char *ext_name = strVal(lfirst(list_head(drop_stmt->objects)));
			if ((strcmp(ext_name, "tds_fdw") == 0) && drop_stmt->behavior == DROP_CASCADE)
			{
				clean_up_bbf_server_def();
			}
		}
	}
}

static void
call_prev_ProcessUtility(PlannedStmt *pstmt,
						 const char *queryString,
						 bool readOnlyTree,
						 ProcessUtilityContext context,
						 ParamListInfo params,
						 QueryEnvironment *queryEnv,
						 DestReceiver *dest,
						 QueryCompletion *qc)
{
	if (prev_ProcessUtility)
		prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
							queryEnv, dest, qc);
	else
		standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
								queryEnv, dest, qc);
}

/*
 * Get the oid and acl of a TSQL proc by name. Raises an error if the proc doesn't exist, or if there are
 * multiple procs with the same name (and different parameters). Also sets isSameFunc based on whether
 * the found proc is the exact same proc as requested (i.e. the parameters match).
 */
static void 
pltsql_proc_get_oid_proname_proacl(AlterFunctionStmt *stmt, ParseState *pstate, Oid *oid, Acl **acl, bool *isSameFunc, bool is_proc)
{
	int					spi_rc;
	char				*funcname, *query;
	bool				isnull;
	Oid					schemaOid, funcOid;
	Datum				aclDatum;

	MemoryContext oldMemoryContext = CurrentMemoryContext;

	/* Look up the proc */
	schemaOid = QualifiedNameGetCreationNamespace(stmt->func->objname, &funcname);

	if ((spi_rc = SPI_connect()) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect() failed in pltsql_proc_get_oid_proname_proacl with return code %d", spi_rc);

	query = psprintf("SELECT oid, proacl FROM pg_catalog.pg_proc WHERE proname = '%s' AND pronamespace = %d", funcname, schemaOid);
	SPI_execute(query, true, 0);

	if (SPI_processed > 1)
		ereport(ERROR, 
			(errcode(ERRCODE_AMBIGUOUS_FUNCTION),
				errmsg("Multiple procedures are defined with the same name and different parameters. Please ensure that there is only one procedure with the target name before calling ALTER PROCEDURE")));

	if (SPI_processed == 0)
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
				errmsg("No existing procedure found with the name for ALTER PROCEDURE")));

	/* exactly one existing procedure with the given name found, retrieve its oid and acl */
	*oid = DatumGetObjectId(SPI_getbinval(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 1, &isnull));

	MemoryContextSwitchTo(oldMemoryContext);
	aclDatum = SPI_getbinval(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 2, &isnull);
	if(DatumGetPointer(aclDatum) == NULL)
		*acl = NULL;
	else
		*acl = aclcopy(DatumGetAclP(aclDatum));

	if ((spi_rc = SPI_finish()) != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish() failed in pltsql_proc_get_oid_proname_proacl with return code %d", spi_rc);

	/* now we need to check if the function is exactly the same proc (i.e. the params match as well) or else
	 * we will run into issues if we try to delete it.
	 */
	funcOid = LookupFuncWithArgs(stmt->objtype, stmt->func, true);

	*isSameFunc = OidIsValid(funcOid);
}

/*
 * Update the oid and acl of a pg_proc entry given its address
 */
static void
pg_proc_update_oid_acl(ObjectAddress address, Oid oid, Acl *acl)
{
	Relation		rel;
	HeapTuple		proctup;
	Form_pg_proc	form_proctup;
	char		*physical_schemaname;

	Datum		values[Natts_pg_proc];
	bool		nulls[Natts_pg_proc];
	bool		replaces[Natts_pg_proc];
	HeapTuple	newtup;

	proctup = SearchSysCache1(PROCOID, ObjectIdGetDatum(address.objectId));
	if (!HeapTupleIsValid(proctup))
		return;

	form_proctup = (Form_pg_proc) GETSTRUCT(proctup);

	if (!is_pltsql_language_oid(form_proctup->prolang))
	{
		ReleaseSysCache(proctup);
		return;
	}

	physical_schemaname = get_namespace_name(form_proctup->pronamespace);
	if (physical_schemaname == NULL)
	{
		elog(ERROR,
				"Could not find physical schemaname for %u",
				 form_proctup->pronamespace);
	}

	rel = table_open(ProcedureRelationId, RowExclusiveLock);

	memset(values, 0, sizeof(values));
	memset(nulls, 0, sizeof(nulls));
	memset(replaces, 0, sizeof(replaces));
	values[Anum_pg_proc_oid - 1] = ObjectIdGetDatum(oid);
	replaces[Anum_pg_proc_oid - 1] = true;
	if(acl)
		values[Anum_pg_proc_proacl - 1] = PointerGetDatum(acl);
	else
		nulls[Anum_pg_proc_proacl - 1] = true;
	replaces[Anum_pg_proc_proacl - 1] = true;

	newtup = heap_modify_tuple(proctup, RelationGetDescr(rel), values, nulls, replaces);
	CatalogTupleUpdate(rel, &newtup->t_self, newtup);

	/* Clean up */
	ReleaseSysCache(proctup);
	heap_freetuple(newtup);

	table_close(rel, RowExclusiveLock);
}

/*
 * Update the pg_type catalog entry for the given name to have
 * typbyval set to the given value.
 */
static void
set_pgtype_byval(List *name, bool byval)
{
	Relation	catalog;
	TypeName   *typename;
	HeapTuple	tup;

	Datum		values[Natts_pg_type];
	bool		nulls[Natts_pg_type];
	bool		replaces[Natts_pg_type];
	HeapTuple	newtup;

	/*
	 * Table types need to set the typbyval column in pg_type to 't'
	 */
	catalog = table_open(TypeRelationId, RowExclusiveLock);
	typename = makeTypeNameFromNameList(name);
	tup = typenameType(NULL, typename, NULL);

	/* Update the current type's tuple */
	memset(values, 0, sizeof(values));
	memset(nulls, 0, sizeof(nulls));
	memset(replaces, 0, sizeof(replaces));
	replaces[Anum_pg_type_typbyval - 1] = true;
	values[Anum_pg_type_typbyval - 1] = BoolGetDatum(byval);

	newtup = heap_modify_tuple(tup, RelationGetDescr(catalog), values, nulls, replaces);
	CatalogTupleUpdate(catalog, &newtup->t_self, newtup);

	/* Clean up */
	ReleaseSysCache(tup);

	table_close(catalog, RowExclusiveLock);

}

/*
 * Hook to truncate identifer whose length is more than 63.
 * We will generate a truncated identifier by
 * substr(identifier, 0, 31) || md5(identifier).
 */
#define MD5_HASH_LEN 32

static bool
pltsql_truncate_identifier(char *ident, int len, bool warn)
{
	char		md5[MD5_HASH_LEN + 1];
	char		buf[NAMEDATALEN];
	bool		success;
	const char *errstr = NULL;

	if (sql_dialect != SQL_DIALECT_TSQL)
		return false;			/* will rely on existing PG behavior */

	Assert(len >= NAMEDATALEN); /* should be already checked */

	if (tsql_is_database_or_server_collation_CI())
	{
		/* md5 should be generated by case-insensitive way */
		char	   *downcased_ident = downcase_identifier(ident, len, false, false);

		success = pg_md5_hash(downcased_ident, strlen(downcased_ident), md5, &errstr);
	}
	else
		success = pg_md5_hash(ident, len, md5, &errstr);

	if (unlikely(!success))		/* OOM */
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("could not compute %s hash: %s", "MD5", errstr)));

	len = pg_mbcliplen(ident, len, NAMEDATALEN - MD5_HASH_LEN - 1);
	Assert(len + MD5_HASH_LEN < NAMEDATALEN);
	memcpy(buf, ident, len);
	memcpy(buf + len, md5, MD5_HASH_LEN);
	buf[len + MD5_HASH_LEN] = '\0';

	if (warn)
		ereport(NOTICE,
				(errcode(ERRCODE_NAME_TOO_LONG),
				 errmsg("identifier \"%s\" will be truncated to \"%s\"",
						ident, buf)));

	memcpy(ident, buf, len + MD5_HASH_LEN + 1);
	return true;
}

Name
pltsql_cstr_to_name(char *s, int len)
{
	Name result;
	char		buf[NAMEDATALEN];

	/* Truncate oversize input */
	if (len >= NAMEDATALEN)
	{
		if (sql_dialect == SQL_DIALECT_TSQL)
		{
			char		md5[MD5_HASH_LEN + 1];
			bool		success;
			const char *errstr = NULL;

			if (tsql_is_database_or_server_collation_CI())
			{
				/* md5 should be generated in a case-insensitive way */
				char	   *downcased_s = downcase_identifier(s, len, false, false);

				success = pg_md5_hash(downcased_s, strlen(downcased_s), md5, &errstr);
			}
			else
				success = pg_md5_hash(s, len, md5, &errstr);

			if (unlikely(!success)) /* OOM */
				ereport(ERROR,
						(errcode(ERRCODE_INTERNAL_ERROR),
						 errmsg("could not compute %s hash: %s", "MD5", errstr)));

			len = pg_mbcliplen(s, len, NAMEDATALEN - MD5_HASH_LEN - 1);
			Assert(len + MD5_HASH_LEN < NAMEDATALEN);
			memcpy(buf, s, len);
			memcpy(buf + len, md5, MD5_HASH_LEN);
			buf[len + MD5_HASH_LEN] = '\0';

			s = buf;
			len += MD5_HASH_LEN;

		}
		else
		{
			/* PG default implementation */
			len = pg_mbcliplen(s, len, NAMEDATALEN - 1);
		}
	}

	/* We use palloc0 here to ensure result is zero-padded */
	result = (Name) palloc0(NAMEDATALEN);

	memcpy(NameStr(*result), s, len);

	return result;
}

PG_FUNCTION_INFO_V1(pltsql_truncate_identifier_func);

Datum
pltsql_truncate_identifier_func(PG_FUNCTION_ARGS)
{
	char	   *name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			len = strlen(name);
	const char *saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		/* this is BBF help function. use BBF truncation logic */
		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		truncate_identifier(name, len, false);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
						  GUC_CONTEXT_CONFIG,
						  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		PG_RE_THROW();
	}
	PG_END_TRY();
	set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
					  GUC_CONTEXT_CONFIG,
					  PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

	PG_RETURN_TEXT_P(cstring_to_text(name));
}

/*
 * _PG_init()			- library load-time initialization
 *
 * DO NOT make this static nor change its name!
 */
void
_PG_init(void)
{
	/* Be sure we do initialization only once (should be redundant now) */
	static bool inited = false;
	FunctionCallInfo fcinfo = NULL; /* empty interface */

	if (inited)
		return;

	/* Fixme: Handle loading of pgtsql_common_library_name library cleanly. */
	load_libraries("babelfishpg_common", NULL, false);
	init_and_check_common_utility();

	if (OidIsValid(get_extension_oid("vector", true)))
		load_libraries("vector", NULL, false);

	pg_bindtextdomain(TEXTDOMAIN);

	DefineCustomBoolVariable("babelfishpg_tsql.debug_parser",
							 gettext_noop("Write PL/tsql parser messages to server log (for debugging)."),
							 NULL,
							 &pltsql_debug_parser,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);


	DefineCustomEnumVariable("babelfishpg_tsql.variable_conflict",
							 gettext_noop("Sets handling of conflicts between PL/tsql variable names and table column names."),
							 NULL,
							 &pltsql_variable_conflict,
							 PLTSQL_RESOLVE_ERROR,
							 variable_conflict_options,
							 PGC_SUSET, 0,
							 NULL, NULL, NULL);

	DefineCustomEnumVariable("babelfishpg_tsql.schema_mapping",
							 gettext_noop("Sets the db schema in babelfishpg_tsql"),
							 NULL,
							 &pltsql_schema_mapping,
							 PLTSQL_RESOLVE_ERROR,
							 schema_mapping_options,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomStringVariable("babelfishpg_tsql.identity_insert",
							   gettext_noop("Enable inserts into identity columns."),
							   NULL,
							   &identity_insert_string,
							   "",
							   PGC_USERSET,
							   GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							   check_identity_insert,
							   assign_identity_insert,
							   NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.trace_tree",
							 gettext_noop("Dump compiled parse tree prior to code generation"),
							 NULL,
							 &pltsql_trace_tree,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.trace_exec_codes",
							 gettext_noop("Trace execution code of iterative executor"),
							 NULL,
							 &pltsql_trace_exec_codes,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.trace_exec_counts",
							 gettext_noop("Trace execution count of each code for iterative executor"),
							 NULL,
							 &pltsql_trace_exec_counts,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomBoolVariable("babelfishpg_tsql.trace_exec_time",
							 gettext_noop("Trace execution time of each code for iterative executor"),
							 NULL,
							 &pltsql_trace_exec_time,
							 false,
							 PGC_SUSET,
							 GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							 NULL, NULL, NULL);

	DefineCustomIntVariable("babelfishpg_tsql.textsize",
							gettext_noop("set TEXTSIZE"),
							NULL,
							&text_size,
							0, -1, INT_MAX,
							PGC_USERSET,
							GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_DISALLOW_IN_AUTO_FILE,
							NULL, assign_textsize, NULL);

	define_custom_variables();

	EmitWarningsOnPlaceholders("pltsql");

	pltsql_HashTableInit();

	init_tsql_coerce_hash_tab(fcinfo);
	init_tsql_datatype_precedence_hash_tab(fcinfo);
	init_special_function_list();
	init_tsql_cursor_hash_tab(fcinfo);
	RegisterXactCallback(pltsql_xact_cb, NULL);
	RegisterSubXactCallback(pltsql_subxact_cb, NULL);
	assign_object_access_hook_drop_relation();
	assign_tablecmds_hook();
	install_backend_gram_hooks();
	init_catalog(fcinfo);

	/* Set up a rendezvous point with optional instrumentation plugin */
	pltsql_plugin_ptr = (PLtsql_plugin **) find_rendezvous_variable("PLtsql_plugin");
	pltsql_instr_plugin_ptr = (PLtsql_instr_plugin **) find_rendezvous_variable("PLtsql_instr_plugin");

	/* Set up a rendezvous point with optional protocol plugin */
	pltsql_protocol_plugin_ptr = (PLtsql_protocol_plugin **)
		find_rendezvous_variable("PLtsql_protocol_plugin");

	/* If a protocol extension is loaded, initialize the inline handler. */
	if (*pltsql_protocol_plugin_ptr)
	{
		(*pltsql_protocol_plugin_ptr)->pltsql_nocount_addr = &pltsql_nocount;
		(*pltsql_protocol_plugin_ptr)->sql_batch_callback = &pltsql_inline_handler;
		(*pltsql_protocol_plugin_ptr)->sp_executesql_callback = &pltsql_inline_handler;
		(*pltsql_protocol_plugin_ptr)->sp_prepare_callback = &sp_prepare;
		(*pltsql_protocol_plugin_ptr)->sp_execute_callback = &pltsql_inline_handler;
		(*pltsql_protocol_plugin_ptr)->sp_prepexec_callback = &pltsql_inline_handler;
		(*pltsql_protocol_plugin_ptr)->sp_unprepare_callback = &sp_unprepare;
		(*pltsql_protocol_plugin_ptr)->reset_session_properties = &reset_session_properties;
		(*pltsql_protocol_plugin_ptr)->bulk_load_callback = &execute_bulk_load_insert;
		(*pltsql_protocol_plugin_ptr)->pltsql_rollback_txn_callback = &pltsql_rollback_txn;
		(*pltsql_protocol_plugin_ptr)->pltsql_abort_any_transaction_callback = &pltsql_abort_any_transaction;
		(*pltsql_protocol_plugin_ptr)->pltsql_declare_var_callback = &pltsql_declare_variable;
		(*pltsql_protocol_plugin_ptr)->pltsql_read_out_param_callback = &pltsql_read_composite_out_param;
		(*pltsql_protocol_plugin_ptr)->sqlvariant_set_metadata = common_utility_plugin_ptr->TdsSetMetaData;
		(*pltsql_protocol_plugin_ptr)->sqlvariant_get_metadata = common_utility_plugin_ptr->TdsGetMetaData;
		(*pltsql_protocol_plugin_ptr)->sqlvariant_inline_pg_base_type = common_utility_plugin_ptr->TdsPGbaseType;
		(*pltsql_protocol_plugin_ptr)->sqlvariant_get_pg_base_type = common_utility_plugin_ptr->TdsGetPGbaseType;
		(*pltsql_protocol_plugin_ptr)->sqlvariant_get_variant_base_type = common_utility_plugin_ptr->TdsGetVariantBaseType;
		(*pltsql_protocol_plugin_ptr)->pltsql_read_proc_return_status = &pltsql_proc_return_code;
		(*pltsql_protocol_plugin_ptr)->sp_cursoropen_callback = &execute_sp_cursoropen_old;
		(*pltsql_protocol_plugin_ptr)->sp_cursorclose_callback = &execute_sp_cursorclose;
		(*pltsql_protocol_plugin_ptr)->sp_cursorfetch_callback = &execute_sp_cursorfetch;
		(*pltsql_protocol_plugin_ptr)->sp_cursorexecute_callback = &execute_sp_cursorexecute;
		(*pltsql_protocol_plugin_ptr)->sp_cursorprepexec_callback = &execute_sp_cursorprepexec;
		(*pltsql_protocol_plugin_ptr)->sp_cursorunprepare_callback = &execute_sp_cursorunprepare;
		(*pltsql_protocol_plugin_ptr)->sp_cursorprepare_callback = &execute_sp_cursorprepare;
		(*pltsql_protocol_plugin_ptr)->sp_cursoroption_callback = &execute_sp_cursoroption;
		(*pltsql_protocol_plugin_ptr)->sp_cursor_callback = &execute_sp_cursor;
		(*pltsql_protocol_plugin_ptr)->pltsql_read_procedure_info = &pltsql_read_procedure_info;
		(*pltsql_protocol_plugin_ptr)->pltsql_current_lineno = &CurrentLineNumber;
		(*pltsql_protocol_plugin_ptr)->pltsql_read_numeric_typmod = &probin_read_ret_typmod;
		(*pltsql_protocol_plugin_ptr)->pltsql_get_errdata = &pltsql_get_errdata;
		(*pltsql_protocol_plugin_ptr)->pltsql_get_database_oid = &get_db_id;
		(*pltsql_protocol_plugin_ptr)->pltsql_get_login_default_db = &get_login_default_db;
		(*pltsql_protocol_plugin_ptr)->pltsql_is_login = &is_login;
		(*pltsql_protocol_plugin_ptr)->pltsql_get_generic_typmod = &probin_read_ret_typmod;
		(*pltsql_protocol_plugin_ptr)->pltsql_get_logical_schema_name = &get_logical_schema_name;
		(*pltsql_protocol_plugin_ptr)->pltsql_is_fmtonly_stmt = &pltsql_fmtonly;
		(*pltsql_protocol_plugin_ptr)->pltsql_get_user_for_database = &get_user_for_database;
		(*pltsql_protocol_plugin_ptr)->get_insert_bulk_rows_per_batch = &get_insert_bulk_rows_per_batch;
		(*pltsql_protocol_plugin_ptr)->get_insert_bulk_kilobytes_per_batch = &get_insert_bulk_kilobytes_per_batch;
		(*pltsql_protocol_plugin_ptr)->tsql_varchar_input = common_utility_plugin_ptr->tsql_varchar_input;
		(*pltsql_protocol_plugin_ptr)->tsql_char_input = common_utility_plugin_ptr->tsql_bpchar_input;
		(*pltsql_protocol_plugin_ptr)->get_cur_db_name = &get_cur_db_name;
		(*pltsql_protocol_plugin_ptr)->get_physical_schema_name = &get_physical_schema_name;

		(*pltsql_protocol_plugin_ptr)->quoted_identifier = pltsql_quoted_identifier;
		(*pltsql_protocol_plugin_ptr)->arithabort = pltsql_arithabort;
		(*pltsql_protocol_plugin_ptr)->ansi_null_dflt_on = pltsql_ansi_null_dflt_on;
		(*pltsql_protocol_plugin_ptr)->ansi_defaults = pltsql_ansi_defaults;
		(*pltsql_protocol_plugin_ptr)->ansi_warnings = pltsql_ansi_warnings;
		(*pltsql_protocol_plugin_ptr)->ansi_padding = pltsql_ansi_padding;
		(*pltsql_protocol_plugin_ptr)->ansi_nulls = pltsql_ansi_nulls;
		(*pltsql_protocol_plugin_ptr)->concat_null_yields_null = pltsql_concat_null_yields_null;
		(*pltsql_protocol_plugin_ptr)->textsize = text_size;
		(*pltsql_protocol_plugin_ptr)->datefirst = pltsql_datefirst;
		(*pltsql_protocol_plugin_ptr)->lock_timeout = pltsql_lock_timeout;
		(*pltsql_protocol_plugin_ptr)->language = pltsql_language;
	}

	get_language_procs("pltsql", &lang_handler_oid, &lang_validator_oid);

	/* Install hooks. */
	raw_parser_hook = babelfishpg_tsql_raw_parser;

	check_or_set_default_typmod_hook = &pltsql_check_or_set_default_typmod;

	prev_pre_parse_analyze_hook = pre_parse_analyze_hook;
	pre_parse_analyze_hook = pltsql_pre_parse_analyze;

	prev_post_parse_analyze_hook = post_parse_analyze_hook;
	post_parse_analyze_hook = pltsql_post_parse_analyze;

	prev_pltsql_sequence_validate_increment_hook = pltsql_sequence_validate_increment_hook;
	pltsql_sequence_validate_increment_hook = pltsql_sequence_validate_increment;

	prev_pltsql_identity_datatype_hook = pltsql_identity_datatype_hook;
	pltsql_identity_datatype_hook = pltsql_identity_datatype_map;

	prev_pltsql_sequence_datatype_hook = pltsql_sequence_datatype_hook;
	pltsql_sequence_datatype_hook = pltsql_sequence_datatype_map;

	prev_plansource_complete_hook = plansource_complete_hook;
	plansource_complete_hook = pltsql_add_guc_plan;

	prev_plansource_revalidate_hook = plansource_revalidate_hook;
	plansource_revalidate_hook = pltsql_check_guc_plan;

	prev_planner_node_transformer_hook = planner_node_transformer_hook;
	planner_node_transformer_hook = pltsql_planner_node_transformer;

	prev_pltsql_nextval_hook = pltsql_nextval_hook;
	pltsql_nextval_hook = pltsql_nextval_identity;

	prev_pltsql_resetcache_hook = pltsql_resetcache_hook;
	pltsql_resetcache_hook = pltsql_resetcache_identity;

	prev_pltsql_setval_hook = pltsql_setval_hook;
	pltsql_setval_hook = pltsql_setval_identity;

	suppress_string_truncation_error_hook = pltsql_suppress_string_truncation_error;
	prev_relname_lookup_hook = relname_lookup_hook;
	relname_lookup_hook = bbf_table_var_lookup;
	prev_ProcessUtility = ProcessUtility_hook;
	ProcessUtility_hook = bbf_ProcessUtility;
	check_lang_as_clause_hook = pltsql_function_as_checker;
	write_stored_proc_probin_hook = pltsql_function_probin_writer;
	make_fn_arguments_from_stored_proc_probin_hook = pltsql_function_probin_reader;
	truncate_identifier_hook = pltsql_truncate_identifier;
	cstr_to_name_hook = pltsql_cstr_to_name;
	tsql_has_pgstat_permissions_hook = tsql_has_pgstat_permissions;

	if (pltsql_enable_linked_servers)
	{
		prev_tsql_has_linked_srv_permissions_hook = tsql_has_linked_srv_permissions_hook;
		tsql_has_linked_srv_permissions_hook = tsql_has_linked_srv_permissions;
	}

	InstallExtendedHooks();

	prev_guc_push_old_value_hook = guc_push_old_value_hook;
	guc_push_old_value_hook = pltsql_guc_push_old_value;

	prev_validate_set_config_function_hook = validate_set_config_function_hook;
	validate_set_config_function_hook = pltsql_validate_set_config_function;

	prev_non_tsql_proc_entry_hook = non_tsql_proc_entry_hook;
	non_tsql_proc_entry_hook = pltsql_non_tsql_proc_entry;

	prev_get_func_language_oids_hook = get_func_language_oids_hook;
	get_func_language_oids_hook = get_func_language_oids;
	coalesce_typmod_hook = coalesce_typmod_hook_impl;

	check_pltsql_support_tsql_transactions_hook = pltsql_support_tsql_transactions;

	inited = true;
}

void
_PG_fini(void)
{
	/* Uninstall hooks */
	pre_parse_analyze_hook = prev_pre_parse_analyze_hook;
	post_parse_analyze_hook = prev_post_parse_analyze_hook;
	pltsql_sequence_validate_increment_hook = prev_pltsql_sequence_validate_increment_hook;
	pltsql_identity_datatype_hook = prev_pltsql_identity_datatype_hook;
	pltsql_sequence_datatype_hook = prev_pltsql_sequence_datatype_hook;
	plansource_complete_hook = prev_plansource_complete_hook;
	plansource_revalidate_hook = prev_plansource_revalidate_hook;
	planner_node_transformer_hook = prev_planner_node_transformer_hook;
	pltsql_nextval_hook = prev_pltsql_nextval_hook;
	pltsql_resetcache_hook = prev_pltsql_resetcache_hook;
	pltsql_setval_hook = prev_pltsql_setval_hook;
	relname_lookup_hook = prev_relname_lookup_hook;
	uninstall_object_access_hook_drop_relation();
	ProcessUtility_hook = prev_ProcessUtility;
	guc_push_old_value_hook = prev_guc_push_old_value_hook;
	validate_set_config_function_hook = prev_validate_set_config_function_hook;
	non_tsql_proc_entry_hook = prev_non_tsql_proc_entry_hook;
	get_func_language_oids_hook = prev_get_func_language_oids_hook;
	tsql_has_linked_srv_permissions_hook = prev_tsql_has_linked_srv_permissions_hook;

	UninstallExtendedHooks();
}

/*
 * Send error to client at batch end for failures
 * We use exec_state_call_stack to distinguish
 * top batch execution from sp_* execution.
 * Also, cleanup aborted transaction here.
 */

static void
terminate_batch(bool send_error, bool compile_error, int SPI_depth)
{
	bool		error_mapping_failed = false;
	int			rc;
	int 		current_spi_stack_depth;

	HOLD_INTERRUPTS();

	elog(DEBUG2, "TSQL TXN finish current batch, error : %d compilation error : %d", send_error, compile_error);

	/*
	 * Disconnect from SPI manager
	 * Also cleanup remnant SPI connections
	 * Ideally current depth should be same as 
	 * when caller was connecting to SPI Manager
	 */
	current_spi_stack_depth = SPI_get_depth();
	
	if (current_spi_stack_depth < SPI_depth)
		elog(FATAL, "SPI connection stack is inconsistent, spi stack depth" 
			 "expected count:%d, current count:%d",
			 SPI_depth, current_spi_stack_depth);
	
	if (current_spi_stack_depth > SPI_depth)
		elog(WARNING, "SPI connection leak found, expected count:%d, current count:%d",
			 SPI_depth, current_spi_stack_depth);
		
	while (current_spi_stack_depth-- >= SPI_depth)
		if ((rc = SPI_finish()) != SPI_OK_FINISH)
			elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

	if (send_error)
	{
		ErrorData  *edata;
		MemoryContext oldCtx = CurrentMemoryContext;

		MemoryContextSwitchTo(MessageContext);
		edata = CopyErrorData();
		MemoryContextSwitchTo(oldCtx);
		latest_pg_error_code = edata->sqlerrcode;
		if (!get_tsql_error_code(edata, &latest_error_code))
			error_mapping_failed = true;
		FreeErrorData(edata);
	}

	if (IS_TDS_CLIENT() && exec_state_call_stack == NULL)
	{
		elog(DEBUG3, "TSQL TXN finish command, PG procedures : %d rollback transaction : %d", pltsql_non_tsql_proc_entry_count, AbortCurTransaction);

		pltsql_non_tsql_proc_entry_count = 0;
		Assert(pltsql_sys_func_entry_count == 0);

		if (pltsql_snapshot_portal != NULL)
		{
			/* Must be active portal, otherwise should not be installed */
			Assert(ActivePortal == pltsql_snapshot_portal);
			/* Clean pending snapshot from portal */
			if (pltsql_snapshot_portal->portalSnapshot != NULL && ActiveSnapshotSet())
			{
				/*
				 * Cleanup all snapshots, some might have been leaked during
				 * SPI execution
				 */
				while (ActiveSnapshotSet())
					PopActiveSnapshot();
				pltsql_snapshot_portal->portalSnapshot = NULL;
			}
			MarkPortalDone(pltsql_snapshot_portal);
			PortalDrop(pltsql_snapshot_portal, false);
			pltsql_snapshot_portal = NULL;
			ActivePortal = NULL;
		}

		if (compile_error && IsTransactionBlockActive())
		{
			if (error_mapping_failed ||
				is_txn_aborting_compilation_error(latest_error_code) ||
				(pltsql_xact_abort && is_xact_abort_txn_compilation_error(latest_error_code)))
				AbortCurTransaction = true;
		}

		if (AbortCurTransaction)
		{
			MemoryContext oldcontext = CurrentMemoryContext;

			pltsql_xact_cb(XACT_EVENT_ABORT, NULL);
			PLTsqlRollbackTransaction(NULL, NULL, false);
			CommitTransactionCommand();
			StartTransactionCommand();
			MemoryContextSwitchTo(oldcontext);

			AbortCurTransaction = false;

			if (!send_error)
			{
				RESUME_INTERRUPTS();
				ereport(ERROR,
						(errcode(ERRCODE_TRANSACTION_ROLLBACK),
						 errmsg("Uncommittable transaction is detected at the end of the batch. The transaction is rolled back.")));
			}
		}
		else if (send_error && !IsTransactionBlockActive())
		{
			/*
			 * In case of error without active transaction, cleanup active
			 * transaction state
			 */
			MemoryContext oldcontext = CurrentMemoryContext;

			AbortCurrentTransaction();
			StartTransactionCommand();
			MemoryContextSwitchTo(oldcontext);
		}
	}

	RESUME_INTERRUPTS();
	if (send_error)
	{
		PG_RE_THROW();
	}
}

void
static
pltsql_non_tsql_proc_entry(int proc_count, int sys_func_count)
{
	elog(DEBUG4, "TSQL TXN PG procedure entry PG count : %d SYS count : %d", proc_count, sys_func_count);

	pltsql_non_tsql_proc_entry_count += proc_count;
	pltsql_sys_func_entry_count += sys_func_count;
}

bool
pltsql_support_tsql_transactions(void)
{
	if (IS_TDS_CLIENT())
	{
		return (pltsql_non_tsql_proc_entry_count == 0 && pltsql_sys_func_entry_count == 0);
	}
	return false;
}

bool
pltsql_sys_function_pop(void)
{
	if (pltsql_sys_func_entry_count > 0)
	{
		pltsql_sys_func_entry_count = 0;
		if (pltsql_non_tsql_proc_entry_count == 0 && IS_TDS_CLIENT())
			return true;
	}
	return false;
}

/* ----------
 * pltsql_call_handler
 *
 * The PostgreSQL function manager and trigger manager
 * call this function for execution of PL/tsql procedures.
 * ----------
 */
PG_FUNCTION_INFO_V1(pltsql_call_handler);

Datum
pltsql_call_handler(PG_FUNCTION_ARGS)
{
	bool		nonatomic;
	PLtsql_function *func;
	PLtsql_execstate *save_cur_estate;
	Datum		retval;
	int			rc;
	int			save_nestlevel;
	int			scope_level;
	MemoryContext savedPortalCxt;
	bool		support_tsql_trans = pltsql_support_tsql_transactions();
	Oid			prev_procid = InvalidOid;
	int			save_pltsql_trigger_depth = pltsql_trigger_depth;
	int			saved_dialect = sql_dialect;
	int 		current_spi_stack_depth;
	bool 		send_error = false;

	create_queryEnv2(CacheMemoryContext, false);

	nonatomic = support_tsql_trans ||
		(fcinfo->context &&
		 IsA(fcinfo->context, CallContext) &&
		 !castNode(CallContext, fcinfo->context)->atomic);

	/*
	 * Connect to SPI manager
	 */

	/*
	 * Override portal context with message context when portal context is
	 * NULL otherwise SPI connect will create procedure context as top context
	 * without any parent. Ideally should be done inside SPI connect but is it
	 * OK to modify SPI connect?
	 */
	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect_ext(nonatomic ? SPI_OPT_NONATOMIC : 0)) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	SPI_setCurrentInternalTxnMode(true);
	current_spi_stack_depth = SPI_get_depth();

	elog(DEBUG2, "TSQL TXN call handler, nonatomic : %d Tsql transaction support %d", nonatomic, support_tsql_trans);

	PG_TRY();
	{
		/*
		 * Set the dialect to tsql - we have to do that here because the fmgr
		 * has set the dialect to postgres. That happens when we are
		 * validating a PL/tsql program because the validator function is not
		 * written in PL/tsql, it's written in C.
		 */
		sql_dialect = SQL_DIALECT_TSQL;

		/* Find or compile the function */
		func = pltsql_compile(fcinfo, false);

		/* Must save and restore prior value of cur_estate */
		save_cur_estate = func->cur_estate;

		/* Mark the function as busy, so it can't be deleted from under us */
		func->use_count++;

		save_nestlevel = pltsql_new_guc_nest_level();
		scope_level = pltsql_new_scope_identity_nest_level();

		prev_procid = procid_var;
		PG_TRY(2);
		{
			set_procid(func->fn_oid);

			/*
			 * Determine if called as function or trigger and call appropriate
			 * subhandler
			 */
			if (CALLED_AS_TRIGGER(fcinfo))
			{
				if (!pltsql_recursive_triggers && save_cur_estate != NULL
					&& is_recursive_trigger(save_cur_estate))
				{
					retval = (Datum) 0;
				}
				else
				{
					pltsql_trigger_depth++;
					retval = PointerGetDatum(pltsql_exec_trigger(func,
																 (TriggerData *) fcinfo->context));
					pltsql_trigger_depth = save_pltsql_trigger_depth;
				}
			}
			else if (CALLED_AS_EVENT_TRIGGER(fcinfo))
			{
				pltsql_exec_event_trigger(func,
										  (EventTriggerData *) fcinfo->context);
				retval = (Datum) 0;
			}
			else
				retval = pltsql_exec_function(func, fcinfo, NULL, false);

			set_procid(prev_procid);
		}
		PG_CATCH(2);
		{
			set_procid(prev_procid);
			pltsql_trigger_depth = save_pltsql_trigger_depth;
			
			send_error = true;
		}
		PG_END_TRY(2);
		
		/* Decrement use-count, restore cur_estate, and propagate error */
		func->use_count--;

		func->cur_estate = save_cur_estate;

		pltsql_remove_current_query_env();
		pltsql_revert_guc(save_nestlevel);
		pltsql_revert_last_scope_identity(scope_level);
	}
	PG_FINALLY();
	{
		sql_dialect = saved_dialect;
	}
	PG_END_TRY();

	terminate_batch(send_error /* send_error */ , false /* compile_error */ , current_spi_stack_depth);

	return retval;
}

/* ----------
 * pltsql_inline_handler
 *
 * Called by PostgreSQL to execute an anonymous code block
 * ----------
 */

Datum
pltsql_inline_handler(PG_FUNCTION_ARGS)
{
	InlineCodeBlock *codeblock = castNode(InlineCodeBlock, DatumGetPointer(PG_GETARG_DATUM(0)));
	InlineCodeBlockArgs *codeblock_args = NULL;
	PLtsql_function *func;
	FmgrInfo	flinfo;
	EState	   *simple_eval_estate;
	Datum		retval = 0;
	int			rc;
	int			saved_dialect = sql_dialect;
	int			nargs = PG_NARGS();
	int			i;
	int 		current_spi_stack_depth;
	MemoryContext savedPortalCxt;
	FunctionCallInfo fake_fcinfo = palloc0(SizeForFunctionCallInfo(nargs));
	bool		nonatomic;
	bool		support_tsql_trans = pltsql_support_tsql_transactions();
	ReturnSetInfo rsinfo;		/* for INSERT ... EXECUTE */

	/*
	 * FIXME: We leak sp_describe_first_result_set_inprogress if CREATE VIEW
	 * fails internally when executing sp_describe_first_result_set procedure.
	 * So we reset sp_describe_first_result_set_inprogress here to work around
	 * this.
	 */
	sp_describe_first_result_set_inprogress = false;

	Assert((nargs > 2 ? nargs - 2 : 0) <= PREPARE_STMT_MAX_ARGS);
	Assert(exec_state_call_stack != NULL || !AbortCurTransaction);

	/* TSQL transactions are always non atomic */
	nonatomic = support_tsql_trans || !codeblock->atomic;

	/* Set statement_timestamp() */
	SetCurrentStatementStartTimestamp();

	set_ps_display("active");
	pgstat_report_activity(STATE_RUNNING, codeblock->source_text);

	if (nargs > 1)
		codeblock_args = (InlineCodeBlockArgs *) DatumGetPointer(PG_GETARG_DATUM(1));

	sql_dialect = SQL_DIALECT_TSQL;

	/*
	 * Connect to SPI manager
	 */
	savedPortalCxt = PortalContext;
	if (PortalContext == NULL)
		PortalContext = MessageContext;
	if ((rc = SPI_connect_ext(nonatomic ? SPI_OPT_NONATOMIC : 0)) != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));
	PortalContext = savedPortalCxt;

	SPI_setCurrentInternalTxnMode(true);
	current_spi_stack_depth = SPI_get_depth();

	elog(DEBUG2, "TSQL TXN inline handler, nonatomic : %d Tsql transaction support %d", nonatomic, support_tsql_trans);

	PG_TRY();
	{
		if (OPTION_ENABLED(codeblock_args, EXEC_CACHED_PLAN))
		{
			func = find_cached_batch(codeblock_args->handle);
			if (!func)
				ereport(ERROR, (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
								errmsg("Prepared statement not found: %d", codeblock_args->handle)));
			/* Mark the function as busy, just pro forma */
			func->use_count++;
		}
		else
		{
			/* Compile the anonymous code block */
			func = pltsql_compile_inline(codeblock->source_text, codeblock_args);

			/* Mark the function as busy, just pro forma */
			func->use_count++;

			apply_post_compile_actions(func, codeblock_args);

			if (OPTION_ENABLED(codeblock_args, NO_EXEC))
			{
				func->use_count--;

				/*
				 * Disconnect from SPI manager
				 */
				if ((rc = SPI_finish()) != SPI_OK_FINISH)
					elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

				sql_dialect = saved_dialect;
				fcinfo->isnull = false;
				return (Datum) 0;
			}
		}
	}
	PG_CATCH();
	{
		terminate_batch(true /* send_error */ , true /* compile_error */ , current_spi_stack_depth);
		return retval;
	}
	PG_END_TRY();

	/*
	 * Set up a fake fcinfo with just enough info to satisfy
	 * pltsql_exec_function().  In particular note that this sets things up
	 * with no arguments passed.
	 */
	MemSet(fake_fcinfo, 0, SizeForFunctionCallInfo(nargs));
	MemSet(&flinfo, 0, sizeof(flinfo));
	fake_fcinfo->flinfo = &flinfo;
	flinfo.fn_oid = InvalidOid;
	flinfo.fn_mcxt = CurrentMemoryContext;
	fake_fcinfo->nargs = nargs > 2 ? nargs - 2 : 0;
	for (i = 0; i < fake_fcinfo->nargs; i++)
	{
		fake_fcinfo->args[i].value = PG_GETARG_DATUM(i + 2);
		fake_fcinfo->args[i].isnull = PG_ARGISNULL(i + 2);
	}

	/* Create a private EState for simple-expression execution */
	if (OPTION_ENABLED(codeblock_args, NO_FREE))
		simple_eval_estate = NULL;
	else
		simple_eval_estate = CreateExecutorState();

	/*
	 * If we are here for INSERT ... EXECUTE, prepare a resultinfo node for
	 * communication before invoking the function, which can accumulate the
	 * result sets.
	 */
	if (codeblock->relation && codeblock->attrnos)
	{
		Oid			reltypeid;
		TupleDesc	reldesc;
		TupleDesc	retdesc;
		int			natts = 0;
		ListCell   *lc;
		ListCell   *next;

		/* look up the INSERT target relation rowtype's tupdesc */
		reltypeid = get_rel_type_id(codeblock->relation);
		reldesc = lookup_rowtype_tupdesc(reltypeid, -1);

		/* build a tupdesc that only contains relevant INSERT columns */
		retdesc = CreateTemplateTupleDesc(list_length(codeblock->attrnos));
		for (lc = list_head(codeblock->attrnos); lc != NULL; lc = next)
		{
			natts += 1;
			TupleDescCopyEntry(retdesc, natts, reldesc, lfirst_int(lc));
			next = lnext(codeblock->attrnos, lc);
		}

		fake_fcinfo->resultinfo = (Node *) &rsinfo;
		rsinfo.type = T_ReturnSetInfo;
		rsinfo.econtext = CreateExprContext(simple_eval_estate);
		rsinfo.expectedDesc = retdesc;
		rsinfo.allowedModes = (int) (SFRM_ValuePerCall | SFRM_Materialize);
		/* note we do not set SFRM_Materialize_Random or _Preferred */
		rsinfo.returnMode = SFRM_ValuePerCall;
		rsinfo.isDone = ExprSingleResult;
		rsinfo.setResult = NULL;
		rsinfo.setDesc = NULL;
		ReleaseTupleDesc(reldesc);
	}

	/* And run the function */
	PG_TRY();
	{
		/*
		 * If the number of arguments supplied are not equal to what is
		 * expected then throw error.
		 */
		if (fake_fcinfo->nargs != func->fn_nargs)
			ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
							errmsg("The parameterized query expects %d number of parameters, but %d were supplied", func->fn_nargs, fake_fcinfo->nargs)));

		retval = pltsql_exec_function(func, fake_fcinfo, simple_eval_estate, codeblock->atomic);
		fcinfo->isnull = false;
	}
	PG_CATCH();
	{
		/*
		 * We need to clean up what would otherwise be long-lived resources
		 * accumulated by the failed DO block, principally cached plans for
		 * statements (which can be flushed with pltsql_free_function_memory)
		 * and execution trees for simple expressions, which are in the
		 * private EState.
		 *
		 * Before releasing the private EState, we must clean up any
		 * simple_econtext_stack entries pointing into it. It is done inside
		 * pltsql_exec_function
		 */

		/* Function should now have no remaining use-counts ... */
		func->use_count--;
		Assert(func->use_count == 0);

		/* ... so we can free subsidiary storage */
		if (!OPTION_ENABLED(codeblock_args, NO_FREE))
		{
			/* Clean up the private EState */
			FreeExecutorState(simple_eval_estate);
			pltsql_free_function_memory(func);
		}
		sql_dialect = saved_dialect;

		terminate_batch(true /* send_error */ , false /* compile_error */ , current_spi_stack_depth);
		return retval;
	}
	PG_END_TRY();

	if (codeblock->dest && rsinfo.setDesc && rsinfo.setResult)
	{
		/*
		 * If we are here for INSERT ... EXECUTE, send all tuples accumulated
		 * in resultinfo to the DestReceiver, which will later be consumed by
		 * the INSERT execution.
		 */
		TupleTableSlot *slot = MakeSingleTupleTableSlot(rsinfo.expectedDesc,
														&TTSOpsMinimalTuple);
		DestReceiver *dest = (DestReceiver *) codeblock->dest;

		for (;;)
		{
			if (!tuplestore_gettupleslot(rsinfo.setResult, true, false, slot))
				break;
			dest->receiveSlot(slot, dest);
			ExecClearTuple(slot);
		}
		ReleaseTupleDesc(rsinfo.expectedDesc);
		ExecDropSingleTupleTableSlot(slot);
	}

	/* Function should now have no remaining use-counts ... */
	func->use_count--;
	Assert(func->use_count == 0);

	/* ... so we can free subsidiary storage */
	if (!OPTION_ENABLED(codeblock_args, NO_FREE))
	{
		FreeExecutorState(simple_eval_estate);
		pltsql_free_function_memory(func);
	}
	sql_dialect = saved_dialect;

	terminate_batch(false /* send_error */ , false /* compile_error */ , current_spi_stack_depth);

	return retval;
}

/* ----------
 * pltsql_validator
 *
 * This function attempts to validate a PL/tsql function at
 * CREATE FUNCTION time.
 * ----------
 */
PG_FUNCTION_INFO_V1(pltsql_validator);

Datum
pltsql_validator(PG_FUNCTION_ARGS)
{
	Oid			funcoid = PG_GETARG_OID(0);
	HeapTuple	tuple;
	Form_pg_proc proc;
	char		functyptype;
	int			numargs;
	Oid		   *argtypes;
	char	  **argnames;
	char	   *argmodes;
	bool		is_dml_trigger = false;
	bool		is_event_trigger = false;
	bool		has_table_var = false;
	char		prokind;
	int			i;

	/* Special handling is neede for Inline Table-Valued Functions */
	bool 		is_itvf;
	char		*prosrc = NULL;
	bool		is_mstvf = false;

	MemoryContext oldMemoryContext = CurrentMemoryContext;
	int			saved_dialect = sql_dialect;

	if (!CheckFunctionValidatorAccess(fcinfo->flinfo->fn_oid, funcoid))
		PG_RETURN_VOID();

	/* Get the new function's pg_proc entry */
	tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcoid));
	if (!HeapTupleIsValid(tuple))
		elog(ERROR, "cache lookup failed for function %u", funcoid);
	proc = (Form_pg_proc) GETSTRUCT(tuple);

	prokind = proc->prokind;

	/* Disallow text, ntext, and image type result */
	if (!babelfish_dump_restore &&
		((*common_utility_plugin_ptr->is_tsql_text_datatype) (proc->prorettype) ||
		 (*common_utility_plugin_ptr->is_tsql_ntext_datatype) (proc->prorettype) ||
		 (*common_utility_plugin_ptr->is_tsql_image_datatype) (proc->prorettype)))
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
				 errmsg("PL/tsql functions cannot return type %s",
						format_type_be(proc->prorettype))));
	}

	functyptype = get_typtype(proc->prorettype);

	/* Disallow pseudotype result */
	/* except for TRIGGER, RECORD, VOID, or polymorphic */
	if (functyptype == TYPTYPE_PSEUDO)
	{
		/*
		 * we assume OPAQUE with no arguments means a trigger.
		 */
		if (proc->prorettype == TRIGGEROID)
			is_dml_trigger = true;
		else if (proc->prorettype == EVENT_TRIGGEROID)
			is_event_trigger = true;
		else if (proc->prorettype != RECORDOID &&
				 proc->prorettype != VOIDOID &&
				 !IsPolymorphicType(proc->prorettype))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("PL/tsql functions cannot return type %s",
							format_type_be(proc->prorettype))));
	}

	/* Disallow pseudotypes in arguments (either IN or OUT) */
	/* except for RECORD and polymorphic */
	numargs = get_func_arg_info(tuple,
								&argtypes, &argnames, &argmodes);
	for (i = 0; i < numargs; i++)
	{
		if (get_typtype(argtypes[i]) == TYPTYPE_PSEUDO)
		{
			if (argtypes[i] != RECORDOID &&
				!IsPolymorphicType(argtypes[i]))
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("PL/tsql functions cannot accept type %s",
								format_type_be(argtypes[i]))));
		}
	}

	is_itvf = proc->prokind == PROKIND_FUNCTION && proc->proretset &&
		get_typtype(proc->prorettype) != TYPTYPE_COMPOSITE;

	PG_TRY();
	{
		/*
		 * Set the dialect to tsql - we have to do that here because the fmgr
		 * has set the dialect to postgres. That happens when we are
		 * validating a PL/tsql program because the validator function is not
		 * written in PL/tsql, it's written in C.
		 */
		sql_dialect = SQL_DIALECT_TSQL;

		/*
		 * Postpone body checks if !check_function_bodies, except for itvf
		 * which we always needs to test-compile to record the query.
		 */
		if (check_function_bodies || is_itvf)
		{
			LOCAL_FCINFO(fake_fcinfo, 0);
			FmgrInfo	flinfo;
			int			rc;
			TriggerData trigdata;
			EventTriggerData etrigdata;
			PLtsql_function *func;

			/*
			 * Connect to SPI manager (is this needed for compilation?)
			 */
			if ((rc = SPI_connect()) != SPI_OK_CONNECT)
				elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));

			/*
			 * Set up a fake fcinfo with just enough info to satisfy
			 * pltsql_compile().
			 */
			MemSet(fake_fcinfo, 0, SizeForFunctionCallInfo(0));
			MemSet(&flinfo, 0, sizeof(flinfo));
			fake_fcinfo->flinfo = &flinfo;
			flinfo.fn_oid = funcoid;
			flinfo.fn_mcxt = CurrentMemoryContext;
			if (is_dml_trigger)
			{
				MemSet(&trigdata, 0, sizeof(trigdata));
				trigdata.type = T_TriggerData;
				fake_fcinfo->context = (Node *) &trigdata;
			}
			else if (is_event_trigger)
			{
				MemSet(&etrigdata, 0, sizeof(etrigdata));
				etrigdata.type = T_EventTriggerData;
				fake_fcinfo->context = (Node *) &etrigdata;
			}

			/* Test-compile the function */
			if (is_itvf && !babelfish_dump_restore)
			{
				PLtsql_stmt_return_query *returnQueryStmt;

				/*
				 * For inline table-valued function, we need to record its
				 * query so that we can construct the column definition list.
				 */
				func = pltsql_compile(fake_fcinfo, true);
				returnQueryStmt = (PLtsql_stmt_return_query *) linitial(func->action->body);

				/*
				 * ITVF should contain 2 statements - RETURN QUERY and PUSH
				 * RESULT
				 */
				if (list_length(func->action->body) != 2 ||
					(returnQueryStmt && returnQueryStmt->cmd_type != PLTSQL_STMT_RETURN_QUERY))
					ereport(ERROR,
							(errcode(ERRCODE_RESTRICT_VIOLATION),
							 errmsg("Inline table-valued function must have a single RETURN SELECT statement")));

				prosrc = MemoryContextStrdup(oldMemoryContext, returnQueryStmt->query->itvf_query);
			}
			else
				func = pltsql_compile(fake_fcinfo, true);

			if(func && func->table_varnos)
			{
				is_mstvf = func->is_mstvf;
				/*
				 * if a function has tvp declared or as argument in the function
				 * or it is a TVF has_table_var will be true
				 */
				has_table_var = true;
			}

			/*
			 * Disconnect from SPI manager
			 */
			if ((rc = SPI_finish()) != SPI_OK_FINISH)
				elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));
		}

		ReleaseSysCache(tuple);

		/*
		 * If the function has TVP in its arguments or function body
		 * it should be declared as VOLATILE by default
		 * TVF are VOLATILE by default so we donot need to update tuple for it
		 */
		if(prokind == PROKIND_FUNCTION && (has_table_var && !is_itvf && !is_mstvf))
		{
			Relation rel;
			HeapTuple tup;
			HeapTuple oldtup;
			bool nulls[Natts_pg_proc];
			Datum values[Natts_pg_proc];
			bool replaces[Natts_pg_proc];
			TupleDesc tupDesc;
			char volatility = PROVOLATILE_VOLATILE;

			/* Existing atts in pg_proc entry - no need to replace */
			for (i = 0; i < Natts_pg_proc; ++i)
			{
				nulls[i] = false;
				values[i] = PointerGetDatum(NULL);
				replaces[i] = false;
			}

			rel = table_open(ProcedureRelationId, RowExclusiveLock);
			tupDesc = RelationGetDescr(rel);
			oldtup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcoid));

			values[Anum_pg_proc_provolatile - 1] = CharGetDatum(volatility);
			replaces[Anum_pg_proc_provolatile - 1] = true;

			tup = heap_modify_tuple(oldtup, tupDesc, values, nulls, replaces);
			CatalogTupleUpdate(rel, &tup->t_self, tup);

			ReleaseSysCache(oldtup);

			heap_freetuple(tup);
			table_close(rel, RowExclusiveLock);
		}

		/*
		 * For inline table-valued function, we need to construct the column
		 * definition list by planning the query in the function, and
		 * modifying the pg_proc entry for this function.
		 */
		if (is_itvf && !babelfish_dump_restore)
		{
			SPIPlanPtr	spi_plan;
			int			spi_rc;
			Relation	rel;
			HeapTuple	tup;
			HeapTuple	oldtup;
			bool		nulls[Natts_pg_proc];
			Datum		values[Natts_pg_proc];
			bool		replaces[Natts_pg_proc];
			TupleDesc	tupDesc;
			ArrayType  *allParameterTypesPointer;
			ArrayType  *parameterModesPointer;
			ArrayType  *parameterNamesPointer;
			Datum	   *allTypesNew;
			Datum	   *paramModesNew;
			Datum	   *paramNamesNew;
			int			parameterCountNew;
			List	   *plansources;
			CachedPlanSource *plansource;
			Query	   *query;
			TupleDesc	tupdesc;
			int			targetListLength;
			ListCell   *lc;
			MemoryContext SPIMemoryContext;
			Oid			rettypeNew = InvalidOid;
			int			numresjunks = 0;

			if ((spi_rc = SPI_connect()) != SPI_OK_CONNECT)
				elog(ERROR, "SPI_connect() failed in pltsql_validator with return code %d", spi_rc);

			spi_plan = SPI_prepare(prosrc, numargs, argtypes);
			if (spi_plan == NULL)
				elog(WARNING, "SPI_prepare_params failed for \"%s\": %s",
					 prosrc, SPI_result_code_string(SPI_result));

			plansources = SPI_plan_get_plan_sources(spi_plan);
			Assert(list_length(plansources) == 1);
			plansource = (CachedPlanSource *) linitial(plansources);
			Assert(list_length(plansource->query_list) == 1);
			query = (Query *) linitial(plansource->query_list);
			tupdesc = ExecCleanTypeFromTL(query->targetList);
			targetListLength = list_length(query->targetList);

			/* Existing atts in pg_proc entry - no need to replace */
			for (i = 0; i < Natts_pg_proc; ++i)
			{
				nulls[i] = false;
				values[i] = PointerGetDatum(NULL);
				replaces[i] = false;
			}

			rel = table_open(ProcedureRelationId, RowExclusiveLock);
			tupDesc = RelationGetDescr(rel);
			oldtup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcoid));

			parameterCountNew = numargs + targetListLength;
			SPIMemoryContext = MemoryContextSwitchTo(oldMemoryContext);
			allTypesNew = (Datum *) palloc(parameterCountNew * sizeof(Datum));
			paramModesNew = (Datum *) palloc(parameterCountNew * sizeof(Datum));
			paramNamesNew = (Datum *) palloc(parameterCountNew * sizeof(Datum));

			/* Copy existing args into the array */
			for (i = 0; i < numargs; ++i)
			{
				allTypesNew[i] = ObjectIdGetDatum(argtypes[i]);
				paramModesNew[i] = argmodes ? CharGetDatum(argmodes[i]) : CharGetDatum(PROARGMODE_IN);
				paramNamesNew[i] = argnames ? CStringGetTextDatum(argnames[i]) : PointerGetDatum(NULL);
			}

			/* Copy new table args into the array */
			i = 0;
			foreach(lc, query->targetList)
			{
				TargetEntry *te = (TargetEntry *) lfirst(lc);
				int			new_i;
				Oid			new_type;
				ListCell   *prev_lc;

				/*
				 * If resjunk is true then the column is a working column and
				 * should be removed from the final output of the query,
				 * according to the definition of TargetEntry.
				 */
				if (te->resjunk)
				{
					numresjunks += 1;
					continue;
				}

				if (!te->resname || strcmp(te->resname, "?column?") == 0)
				{
					pfree(prosrc);
					pfree(allTypesNew);
					pfree(paramModesNew);
					pfree(paramNamesNew);
					elog(ERROR,
						 "CREATE FUNCTION failed because a column name is not specified for column %d",
						 i + 1);
				}

				foreach(prev_lc, query->targetList)
				{
					TargetEntry *prev_te = (TargetEntry *) lfirst(prev_lc);

					if (prev_te == te)
						break;

					if (strcmp(prev_te->resname, te->resname) == 0)
						ereport(ERROR,
								(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
								 errmsg("parameter name \"%s\" used more than once",
										te->resname)));
				}

				new_i = i + numargs;
				new_type = SPI_gettypeid(tupdesc, te->resno);

				/*
				 * Record the type in case we need to change the function
				 * return type to it later
				 */
				rettypeNew = new_type;

				allTypesNew[new_i] = ObjectIdGetDatum(new_type);
				paramModesNew[new_i] = CharGetDatum(PROARGMODE_TABLE);
				paramNamesNew[new_i] = CStringGetTextDatum(te->resname);
				++i;
			}
			MemoryContextSwitchTo(SPIMemoryContext);

			if ((spi_rc = SPI_finish()) != SPI_OK_FINISH)
				elog(ERROR, "SPI_finish() failed in pltsql_validator with return code %d", spi_rc);

			/*
			 * For table functions whose return table only has one column,
			 * Postgres considers them as scalar functions. So, we need to
			 * update the function's return type to be the type of that
			 * column, instead of RECORD.
			 */
			if (i == 1)
			{
				values[Anum_pg_proc_prorettype - 1] = ObjectIdGetDatum(rettypeNew);
				replaces[Anum_pg_proc_prorettype - 1] = true;
			}

			parameterCountNew -= numresjunks;
			allParameterTypesPointer = construct_array(allTypesNew, parameterCountNew, OIDOID,
													   sizeof(Oid), true, 'i');
			parameterModesPointer = construct_array(paramModesNew, parameterCountNew, CHAROID,
													1, true, 'c');
			parameterNamesPointer = construct_array(paramNamesNew, parameterCountNew, TEXTOID,
													-1, false, 'i');

			values[Anum_pg_proc_proallargtypes - 1] = PointerGetDatum(allParameterTypesPointer);
			values[Anum_pg_proc_proargmodes - 1] = PointerGetDatum(parameterModesPointer);
			values[Anum_pg_proc_proargnames - 1] = PointerGetDatum(parameterNamesPointer);
			replaces[Anum_pg_proc_proallargtypes - 1] = true;
			replaces[Anum_pg_proc_proargmodes - 1] = true;
			replaces[Anum_pg_proc_proargnames - 1] = true;

			tup = heap_modify_tuple(oldtup, tupDesc, values, nulls, replaces);
			CatalogTupleUpdate(rel, &tup->t_self, tup);

			ReleaseSysCache(oldtup);

			heap_freetuple(tup);
			table_close(rel, RowExclusiveLock);

			pfree(prosrc);
			pfree(allTypesNew);
			pfree(paramModesNew);
			pfree(paramNamesNew);
		}
	}
	PG_FINALLY();
	{
		sql_dialect = saved_dialect;
	}
	PG_END_TRY();

	PG_RETURN_VOID();
}

/*
 * Returns the OID of the handler proc, and, if defined, the OID of the
 * validator for the given language
 */

static void
get_language_procs(const char *langname, Oid *compiler, Oid *validator)
{
	HeapTuple	langTup = SearchSysCache1(LANGNAME, PointerGetDatum(langname));

	if (HeapTupleIsValid(langTup))
	{
		Form_pg_language langStruct = (Form_pg_language) GETSTRUCT(langTup);

		*compiler = langStruct->oid;
		*validator = langStruct->lanvalidator;

		ReleaseSysCache(langTup);
	}
	else
	{
		*compiler = InvalidOid;
		*validator = InvalidOid;
	}
}

/*
 * Engine hook to get OID for language handler and validator for
 * TSQL language
 */
static void
get_func_language_oids(Oid *lang_handler, Oid *lang_validator)
{
	if (lang_handler_oid == InvalidOid || lang_validator_oid == InvalidOid)
	{
		get_language_procs("pltsql", &lang_handler_oid, &lang_validator_oid);
	}
	*lang_handler = lang_handler_oid;
	*lang_validator = lang_validator_oid;
}

/*
 * Map custom PLTSQL datatype OIDs to built-in PG sequence types based on the
 * schema name and type name. This is to ensure we map the correct DOMAIN type.
 * Return InvalidOid if there is no match.
 */
static Oid
pltsql_seq_type_map(Oid typid)
{
	HeapTuple	tp;
	Form_pg_type typtup;
	char	   *typname;
	char	   *nspname;

	tp = SearchSysCache1(TYPEOID, ObjectIdGetDatum(typid));
	if (!HeapTupleIsValid(tp))
		elog(ERROR, "cache lookup failed for type %u", typid);
	typtup = (Form_pg_type) GETSTRUCT(tp);
	typname = NameStr(typtup->typname);

	nspname = get_namespace_name(typtup->typnamespace);
	if (!nspname)
		elog(ERROR, "cache lookup failed for namespace %u",
			 typtup->typnamespace);

	ReleaseSysCache(tp);

	if (strcmp(nspname, "sys") != 0)
		return InvalidOid;

	/* Sequences do not support tinyint so we map it to smallint */
	if (strcmp(typname, "smallint") == 0 ||
		strcmp(typname, "tinyint") == 0)
		return INT2OID;
	else if (strcmp(typname, "int") == 0)
		return INT4OID;
	else if (strcmp(typname, "bigint") == 0)
		return INT8OID;
	else
		return InvalidOid;
}

/*
 * 	canCommitTransaction
 *
 *	This returns true if transaction can be committed
 *
 *	TODO: Implementation
 */
bool
canCommitTransaction(void)
{
	return (AbortCurTransaction == false);
}

static void
pltsql_guc_push_old_value(struct config_generic *gconf, GucAction action)
{
	GucStack   *stack;

	/* If we're not inside a nest level, do nothing */
	if (PltsqlGUCNestLevel == 0)
		return;

	/* Do we already have a stack entry of the current nest level? */
	stack = gconf->session_stack;
	if (stack && stack->nest_level >= PltsqlGUCNestLevel)
	{
		/* Yes, so adjust its state if necessary */
		Assert(stack->nest_level == PltsqlGUCNestLevel);
		switch (action)
		{
			case GUC_ACTION_SET:
				stack->state = GUC_SET;
				break;
			case GUC_ACTION_SAVE:
				stack->state = GUC_SAVE;
				break;
			default:
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Set action not supported")));
		}
		return;
	}

	/*
	 * Push a new stack entry
	 *
	 */
	stack = (GucStack *) MemoryContextAllocZero(TopMemoryContext,
												sizeof(GucStack));

	stack->prev = gconf->session_stack;
	stack->nest_level = PltsqlGUCNestLevel;
	switch (action)
	{
		case GUC_ACTION_SET:
			stack->state = GUC_SET;
			break;
		case GUC_ACTION_SAVE:
			stack->state = GUC_SAVE;
			break;
		default:
			Assert(false);
	}
	stack->source = gconf->source;
	stack->scontext = gconf->scontext;
	guc_set_stack_value(gconf, &stack->prior);

	if (gconf->session_stack == NULL)
		slist_push_head(&guc_stack_list, &gconf->stack_link);
	gconf->session_stack = stack;
}

int
pltsql_new_guc_nest_level(void)
{
	return ++PltsqlGUCNestLevel;
}

void
pltsql_revert_guc(int nest_level)
{
	slist_mutable_iter iter;

	Assert(nest_level > 0 && nest_level == PltsqlGUCNestLevel);

	slist_foreach_modify(iter, &guc_stack_list)
	{
		struct config_generic *gconf = slist_container(struct config_generic,
													   stack_link, iter.cur);
		GucStack   *stack = gconf->session_stack;

		if (stack != NULL && stack->nest_level == nest_level)
		{
			GucStack   *prev = stack->prev;

			/* Perform appropriate restoration of the stacked value */
			config_var_value newvalue = stack->prior;
			GucSource	newsource = stack->source;
			GucContext	newscontext = stack->scontext;

			switch (gconf->vartype)
			{
				case PGC_BOOL:
					{
						struct config_bool *conf = (struct config_bool *) gconf;
						bool		newval = newvalue.val.boolval;
						void	   *newextra = newvalue.extra;

						if (*conf->variable != newval || conf->gen.extra != newextra)
						{
							if (conf->assign_hook)
								conf->assign_hook(newval, newextra);
							*conf->variable = newval;
							guc_set_extra_field(&conf->gen, &conf->gen.extra, newextra);
						}
						break;
					}
				case PGC_INT:
					{
						struct config_int *conf = (struct config_int *) gconf;
						int			newval = newvalue.val.intval;
						void	   *newextra = newvalue.extra;

						if (*conf->variable != newval || conf->gen.extra != newextra)
						{
							if (conf->assign_hook)
								conf->assign_hook(newval, newextra);
							*conf->variable = newval;
							guc_set_extra_field(&conf->gen, &conf->gen.extra, newextra);
						}
						break;
					}
				case PGC_REAL:
					{
						struct config_real *conf = (struct config_real *) gconf;
						double		newval = newvalue.val.realval;
						void	   *newextra = newvalue.extra;

						if (*conf->variable != newval || conf->gen.extra != newextra)
						{
							if (conf->assign_hook)
								conf->assign_hook(newval, newextra);
							*conf->variable = newval;
							guc_set_extra_field(&conf->gen, &conf->gen.extra, newextra);
						}
						break;
					}
				case PGC_STRING:
					{
						struct config_string *conf = (struct config_string *) gconf;
						char	   *newval = newvalue.val.stringval;
						void	   *newextra = newvalue.extra;

						/* Special case for identity_insert */
						if (strcmp(gconf->name, "babelfishpg_tsql.identity_insert") == 0)
						{
							tsql_identity_insert = (tsql_identity_insert_fields)
							{
								false, InvalidOid, InvalidOid
							};
						}

						if (*conf->variable != newval || conf->gen.extra != newextra)
						{
							if (conf->assign_hook)
								conf->assign_hook(newval, newextra);
							guc_set_string_field(conf, conf->variable, newval);
							guc_set_extra_field(&conf->gen, &conf->gen.extra, newextra);
						}

						/*
						 * Release stacked values if not used anymore. We
						 * could use discard_stack_value() here, but since we
						 * have type-specific code anyway, might as well
						 * inline it.
						 */
						guc_set_string_field(conf, &stack->prior.val.stringval, NULL);
						guc_set_string_field(conf, &stack->masked.val.stringval, NULL);
						break;
					}
				case PGC_ENUM:
					{
						struct config_enum *conf = (struct config_enum *) gconf;
						int			newval = newvalue.val.enumval;
						void	   *newextra = newvalue.extra;

						if (*conf->variable != newval || conf->gen.extra != newextra)
						{
							if (conf->assign_hook)
								conf->assign_hook(newval, newextra);
							*conf->variable = newval;
							guc_set_extra_field(&conf->gen, &conf->gen.extra, newextra);
						}
						break;
					}
			}

			/*
			 * Release stacked extra values if not used anymore.
			 */
			guc_set_extra_field(gconf, &(stack->prior.extra), NULL);
			guc_set_extra_field(gconf, &(stack->masked.extra), NULL);

			/* And restore source information */
			babelfish_set_guc_source(gconf, newsource);
			gconf->scontext = newscontext;

			/* Finish popping the state stack */
			gconf->session_stack = prev;

			if (prev == NULL)
				slist_delete_current(&iter);
			pfree(stack);
		}						/* end of stack-popping loop */
	}

	/* Update nesting level */
	PltsqlGUCNestLevel = nest_level - 1;
}

static char *
get_oid_type_string(int type_oid)
{
	char *type_string = NULL;
	if ((*common_utility_plugin_ptr->is_tsql_decimal_datatype) (type_oid))
	{
		type_string = "decimal";
		return type_string;
	}

	switch(type_oid)
	{
		case INT2OID:
			type_string = "pg_catalog.int2";
			break;
		case INT4OID:
			type_string = "pg_catalog.int4";
			break;
		case INT8OID:
			type_string = "pg_catalog.int8";
			break;
		case NUMERICOID:
			type_string = "pg_catalog.numeric";
			break;
		default:
			ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("A user-defined data type for an IDENTITY column is not currently supported")));
			break;
	}
	return type_string;
}

static int64
get_identity_into_args(Node *node)
{
	int64 val = 0;
	Const *con = NULL;
	FuncExpr *fxpr = NULL;
	OpExpr *opxpr = NULL;
	Node *n = NULL;

	switch (nodeTag(node))
	{
		case T_Const:
			con = (Const *)node;
			val = (int64)DatumGetInt64(con->constvalue);
			break;
		case T_FuncExpr:
			fxpr = (FuncExpr *)node;
			if ((fxpr->args)->length != 1)
				ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("syntax error near 'identity'")));
			n = (Node *)list_nth(fxpr->args, 0);
			val = get_identity_into_args(n);
			break;
		case T_OpExpr:
			opxpr = (OpExpr *)node;
			if ((opxpr->args)->length != 1)
				ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("syntax error near 'identity'")));
			n = (Node *)list_nth(opxpr->args, 0);
			val = get_identity_into_args(n);
			break;
		default:
			ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("syntax error near 'identity'")));
			break;
		}
	return val;
}

static List *
transformSelectIntoStmt(CreateTableAsStmt *stmt)
{
	List *result;
	ListCell *elements;
	AlterTableStmt *altstmt;
	IntoClause *into;
	Node *n;

	n = stmt->query;
	into = stmt->into;
	result = NIL;
	altstmt = NULL;

	if (n && n->type == T_Query)
	{
		Query *q = (Query *)n;
		bool seen_identity = false;
		AttrNumber current_resno = 0;
		Index identity_ressortgroupref = 0;
		List *modifiedTargetList = NIL;

		foreach (elements, q->targetList)
		{
			TargetEntry *tle = (TargetEntry *)lfirst(elements);
			if(tle->resname != NULL && !tle->resjunk)
				tle->resname = downcase_identifier(tle->resname, strlen(tle->resname), false, false);
			if (tle->expr && IsA(tle->expr, FuncExpr) && strcasecmp(get_func_name(((FuncExpr *)(tle->expr))->funcid), "identity_into_bigint") == 0)
			{
				FuncExpr *funcexpr;
				List *seqoptions = NIL;
				ListCell *arg;
				int typeoid = 0;

				TypeName *typename = NULL;
				int64 seedvalue = 0, incrementvalue = 0;
				int argnum;
				AlterTableCmd *lcmd;
				ColumnDef *def;
				Constraint *constraint;

				if (seen_identity)
					ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
									errmsg("Attempting to add multiple identity columns to table \"%s\" using the SELECT INTO statement.", into->rel->relname)));

				if (tle->resname == NULL)
					ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR), errmsg("Incorrect syntax near the keyword 'INTO'")));

				funcexpr = (FuncExpr *)tle->expr;
				argnum = 0;
				foreach (arg, funcexpr->args)
				{
					Node *farg_node = (Node *)lfirst(arg);
					argnum++;
					switch (argnum)
					{
					case 1:
						typeoid = get_identity_into_args(farg_node);
						typename = typeStringToTypeName(get_oid_type_string(typeoid), NULL);
						break;
					case 2:
						seedvalue = get_identity_into_args(farg_node);
						seqoptions = lappend(seqoptions, makeDefElem("start", (Node *)makeFloat(psprintf(INT64_FORMAT, seedvalue)), -1));
						break;
					case 3:
						incrementvalue = get_identity_into_args(farg_node);
						seqoptions = lappend(seqoptions, makeDefElem("increment", (Node *)makeFloat(psprintf(INT64_FORMAT, incrementvalue)), -1));
						if (incrementvalue > 0)
						{
							seqoptions = lappend(seqoptions, makeDefElem("minvalue", (Node *)makeFloat(psprintf(INT64_FORMAT, seedvalue)), -1));
						}
						else
						{
							seqoptions = lappend(seqoptions, makeDefElem("maxvalue", (Node *)makeFloat(psprintf(INT64_FORMAT, seedvalue)), -1));
						}
						break;
					}
				}

				seen_identity = true;
				identity_ressortgroupref = tle->ressortgroupref; /** Save this Index to modify sortClause and distinctClause*/

				/** Add alter table add identity node after Select Into statement */
				altstmt = makeNode(AlterTableStmt);
				altstmt->relation = into->rel;
				altstmt->objtype = OBJECT_TABLE;
				altstmt->cmds = NIL;

				constraint = makeNode(Constraint);
				constraint->contype = CONSTR_IDENTITY;
				constraint->generated_when = ATTRIBUTE_IDENTITY_ALWAYS;
				constraint->options = seqoptions;

				def = makeNode(ColumnDef);
				def->colname = tle->resname;
				def->typeName = typename;
				def->identity = ATTRIBUTE_IDENTITY_ALWAYS;
				def->is_not_null = true;
				def->constraints = lappend(def->constraints, constraint);

				lcmd = makeNode(AlterTableCmd);
				lcmd->subtype = AT_AddColumn;
				lcmd->missing_ok = false;
				lcmd->def = (Node *)def;
				altstmt->cmds = lappend(altstmt->cmds, lcmd);
			}
			else
			{
				current_resno += 1;
				tle->resno = current_resno;
				modifiedTargetList = lappend(modifiedTargetList, tle);
			}
		}
		q->targetList = modifiedTargetList;

		if (seen_identity)
		{
			if (q->sortClause)
			{
				List *modifiedSortClause = NIL;
				ListCell *olitem;
				foreach (olitem, q->sortClause)
				{
					Node *sortnode = (Node *)lfirst(olitem);
					if (IsA(sortnode, SortGroupClause))
					{
						SortGroupClause *sortcl = (SortGroupClause *)sortnode;
						if (sortcl->tleSortGroupRef != identity_ressortgroupref)
							modifiedSortClause = lappend(modifiedSortClause, sortcl);
					}
				}
				q->sortClause = modifiedSortClause;
			}

			if (q->distinctClause && list_length(q->distinctClause) > (identity_ressortgroupref - 1))
				q->distinctClause = list_delete_nth_cell(q->distinctClause, identity_ressortgroupref - 1);
		}
	}

	result = lappend(result, stmt);
	if (altstmt)
		result = lappend(result, altstmt);

	return result;
}

void pltsql_bbfSelectIntoUtility(ParseState *pstate, PlannedStmt *pstmt, const char *queryString, QueryEnvironment *queryEnv,
								 ParamListInfo params, QueryCompletion *qc, ObjectAddress *address)
{

	Node *parsetree = pstmt->utilityStmt;
	List *stmts;
	stmts = transformSelectIntoStmt((CreateTableAsStmt *)parsetree);
	while (stmts != NIL)
	{
		Node *stmt = (Node *)linitial(stmts);
		stmts = list_delete_first(stmts);
		if (IsA(stmt, CreateTableAsStmt))
		{
			*address = ExecCreateTableAs(pstate, (CreateTableAsStmt *)parsetree, params, queryEnv, qc);
		}
		else
		{
			PlannedStmt *wrapper;
			wrapper = makeNode(PlannedStmt);
			wrapper->commandType = CMD_UTILITY;
			wrapper->canSetTag = false;
			wrapper->utilityStmt = stmt;
			wrapper->stmt_location = pstmt->stmt_location;
			wrapper->stmt_len = pstmt->stmt_len;

			ProcessUtility(wrapper, queryString, false, PROCESS_UTILITY_SUBCOMMAND, params, NULL, None_Receiver, NULL);
		}
		if (stmts != NIL)
			CommandCounterIncrement();
	}
}

void
set_current_query_is_create_tbl_check_constraint(Node *expr)
{
	CreateStmt *stmt = (CreateStmt *) expr;
	ListCell   *elements;

	foreach(elements, stmt->tableElts)
	{
		Node	   *element = lfirst(elements);

		if (nodeTag(element) == T_Constraint)
		{
			Constraint *c = (Constraint *) element;

			if (c->contype == CONSTR_CHECK)
			{
				current_query_is_create_tbl_check_constraint = true;
				break;
			}
		}
	}
}

void
pltsql_remove_current_query_env(void)
{
	bool old_abort_curr_txn = AbortCurTransaction;

	PG_TRY();
	{
		// see pltsql_clean_table_variables()
		AbortCurTransaction = false;

		ENRDropTempTables(currentQueryEnv);
	}
	PG_FINALLY();
	{
		remove_queryEnv();

		if (!currentQueryEnv ||
			(currentQueryEnv == topLevelQueryEnv && get_namedRelList() == NIL))
		{
			destroy_failed_transactions_map();
		}
	
		AbortCurTransaction = old_abort_curr_txn;
	}
	PG_END_TRY();
}

/*
 * Drop statement of babelfish, currently delete extended property as well.
 */
static void
bbf_ExecDropStmt(DropStmt *stmt)
{
	int16			db_id;
	const char		*type = NULL;
	char			*schema_name = NULL,
					*major_name = NULL;
	ObjectAddress	address;
	Relation		relation = NULL;
	Oid				schema_oid;
	ListCell		*cell;
	const char		*logicalschema = NULL;
	bool			is_missing = sql_dialect == SQL_DIALECT_TSQL ? true : stmt->missing_ok;

	db_id = get_cur_db_id();

	if (stmt->removeType == OBJECT_SCHEMA && sql_dialect == SQL_DIALECT_TSQL)
	{
		foreach(cell, stmt->objects)
		{
			schema_name = strVal(lfirst(cell));

			if (get_namespace_oid(schema_name, true) == InvalidOid)
				return;

			type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SCHEMA];
			delete_extended_property(db_id, type, schema_name, NULL, NULL);
		}
	}
	else if (stmt->removeType == OBJECT_TABLE ||
			 stmt->removeType == OBJECT_VIEW ||
			 stmt->removeType == OBJECT_SEQUENCE)
	{
		foreach(cell, stmt->objects)
		{
			relation = NULL;
			address = get_object_address(stmt->removeType,
										 lfirst(cell),
										 &relation,
										 AccessShareLock,
										 is_missing);

			if (!relation)
				continue;

			/* Get major_name */
			major_name = pstrdup(RelationGetRelationName(relation));
			relation_close(relation, AccessShareLock);

			/* Get schema_name */
			schema_oid = get_object_namespace(&address);
			if (OidIsValid(schema_oid))
				schema_name = get_namespace_name(schema_oid);
			if (sql_dialect == SQL_DIALECT_TSQL)
			{
				if (schema_name != NULL)
					logicalschema = get_logical_schema_name(schema_name, true);

				if (schema_name && major_name)
				{
					if (stmt->removeType == OBJECT_TABLE)
					{
						type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TABLE];
						delete_extended_property(db_id, type, schema_name,
												major_name, NULL);
						type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TABLE_COLUMN];
						delete_extended_property(db_id, type, schema_name,
												major_name, NULL);
					}
					else if (stmt->removeType == OBJECT_VIEW)
					{
						type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_VIEW];
						delete_extended_property(db_id, type, schema_name,
												major_name, NULL);
					}
					else if (stmt->removeType == OBJECT_SEQUENCE)
					{
						type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_SEQUENCE];
						delete_extended_property(db_id, type, schema_name,
												major_name, NULL);
					}
				}
				clean_up_bbf_schema_permissions(logicalschema, major_name, false);
			}
		}
	}
	else if (stmt->removeType == OBJECT_PROCEDURE ||
			 stmt->removeType == OBJECT_FUNCTION ||
			 stmt->removeType == OBJECT_TYPE)
	{
		HeapTuple	tuple;

		foreach(cell, stmt->objects)
		{
			relation = NULL;
			address = get_object_address(stmt->removeType,
										 lfirst(cell),
										 &relation,
										 AccessShareLock,
										 is_missing);
			Assert(relation == NULL);
			if (!OidIsValid(address.objectId))
				continue;
				
			/* Restrict dropping of extended stored procedures for non-superuser roles */
			if (stmt->removeType == OBJECT_PROCEDURE && !superuser())
				check_restricted_stored_procedure(address.objectId);

			/* Get major_name */
			relation = table_open(address.classId, AccessShareLock);
			tuple = get_catalog_object_by_oid(relation,
											  get_object_attnum_oid(address.classId),
											  address.objectId);
			if (!HeapTupleIsValid(tuple))
			{
				table_close(relation, AccessShareLock);
				continue;
			}

			if (stmt->removeType == OBJECT_PROCEDURE ||
				stmt->removeType == OBJECT_FUNCTION)
				major_name = pstrdup(NameStr(((Form_pg_proc) GETSTRUCT(tuple))->proname));
			else if (stmt->removeType == OBJECT_TYPE)
				major_name = pstrdup(NameStr(((Form_pg_type) GETSTRUCT(tuple))->typname));

			table_close(relation, AccessShareLock);

			/* Get schema_name */
			schema_oid = get_object_namespace(&address);
			if (OidIsValid(schema_oid))
				schema_name = get_namespace_name(schema_oid);

			if (sql_dialect == SQL_DIALECT_TSQL)
			{
				if (schema_name != NULL)
					logicalschema = get_logical_schema_name(schema_name, true);

				if (schema_name && major_name)
				{
					if (stmt->removeType == OBJECT_PROCEDURE)
						type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_PROCEDURE];
					else if (stmt->removeType == OBJECT_FUNCTION)
						type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_FUNCTION];
					else if (stmt->removeType == OBJECT_TYPE)
						type = ExtendedPropertyTypeNames[EXTENDED_PROPERTY_TYPE];

					delete_extended_property(db_id, type, schema_name, major_name,
											NULL);
				}
				clean_up_bbf_schema_permissions(logicalschema, major_name, false);
			}
		}
	}
}

static int
isolation_to_int(char *isolation_level)
{
	if (strcmp(isolation_level, "serializable") == 0)
		return XACT_SERIALIZABLE;
	else if (strcmp(isolation_level, "repeatable read") == 0)
		return XACT_REPEATABLE_READ;
	else if (strcmp(isolation_level, "read committed") == 0)
		return XACT_READ_COMMITTED;
	else if (strcmp(isolation_level, "read uncommitted") == 0)
		return XACT_READ_UNCOMMITTED;

	return 0;
}

static void
bbf_set_tran_isolation(char *new_isolation_level_str)
{
	const int 		new_isolation_int_val = isolation_to_int(new_isolation_level_str);

	if(new_isolation_int_val != DefaultXactIsoLevel)
	{
		if(FirstSnapshotSet || IsSubTransaction() ||
				(new_isolation_int_val == XACT_SERIALIZABLE && RecoveryInProgress()))
		{
			if(escape_hatch_set_transaction_isolation_level == EH_IGNORE)
				return;
			else
				elog(ERROR, "SET TRANSACTION ISOLATION failed, transaction aborted, set escape hatch "
					"'escape_hatch_set_transaction_isolation_level' to ignore such error");
		}
		else
		{
			SetConfigOption("transaction_isolation", new_isolation_level_str, PGC_USERSET, PGC_S_SESSION);
			SetConfigOption("default_transaction_isolation", new_isolation_level_str, PGC_USERSET, PGC_S_SESSION);
		}
	}
	return ;
}
