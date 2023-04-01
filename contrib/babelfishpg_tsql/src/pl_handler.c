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
#include "access/htup_details.h"
#include "access/table.h"
#include "catalog/heap.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_language.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "commands/dbcommands.h"
#include "commands/defrem.h"
#include "commands/sequence.h"
#include "commands/tablecmds.h"
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
#include "guc.h"
#include "hooks.h"
#include "iterative_exec.h"
#include "rolecmds.h"
#include "multidb.h"
#include "schemacmds.h"
#include "session.h"
#include "pltsql.h"
#include "pl_explain.h"

#include "access/xact.h"

extern bool escape_hatch_unique_constraint;
extern bool pltsql_recursive_triggers;
extern bool restore_tsql_tabletype;
extern bool babelfish_dump_restore;
extern bool pltsql_nocount;

extern List *babelfishpg_tsql_raw_parser(const char *str, RawParseMode mode);
extern bool install_backend_gram_hooks();

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
static void set_pgtype_byval(List *name, bool byval);
static bool pltsql_truncate_identifier(char *ident, int len, bool warn);
static Name pltsql_cstr_to_name(char *s, int len);
extern void pltsql_add_guc_plan(CachedPlanSource *plansource);
extern bool pltsql_check_guc_plan(CachedPlanSource *plansource);
bool		pltsql_function_as_checker(const char *lang, List *as, char **prosrc_str_p, char **probin_str_p);
extern void pltsql_function_probin_writer(CreateFunctionStmt *stmt, Oid languageOid, char **probin_str_p);
extern void pltsql_function_probin_reader(ParseState *pstate, List *fargs, Oid *actual_arg_types, Oid *declared_arg_types, Oid funcid);
static void check_nullable_identity_constraint(RangeVar *relation, ColumnDef *column);
static bool is_identity_constraint(ColumnDef *column);
static bool has_unique_nullable_constraint(ColumnDef *column);
static bool is_nullable_constraint(Constraint *cst, Oid rel_oid);
static bool is_nullable_index(IndexStmt *stmt);
extern PLtsql_function *find_cached_batch(int handle);
extern void apply_post_compile_actions(PLtsql_function *func, InlineCodeBlockArgs *args);
Datum		sp_prepare(PG_FUNCTION_ARGS);
Datum		sp_unprepare(PG_FUNCTION_ARGS);
static List *transformReturningList(ParseState *pstate, List *returningList);
extern char *construct_unique_index_name(char *index_name, char *relation_name);
extern int	CurrentLineNumber;
static non_tsql_proc_entry_hook_type prev_non_tsql_proc_entry_hook = NULL;
static void pltsql_non_tsql_proc_entry(int proc_count, int sys_func_count);
static bool get_attnotnull(Oid relid, AttrNumber attnum);
static void set_procid(Oid oid);
static bool is_rowversion_column(ParseState *pstate, ColumnDef *column);
static void validate_rowversion_column_constraints(ColumnDef *column);
static void validate_rowversion_table_constraint(Constraint *c, char *rowversion_column_name);
static Constraint *get_rowversion_default_constraint(TypeName *typname);
static void revoke_type_permission_from_public(PlannedStmt *pstmt, const char *queryString, bool readOnlyTree,
											   ProcessUtilityContext context, ParamListInfo params, QueryEnvironment *queryEnv, DestReceiver *dest, QueryCompletion *qc, List *type_name);
static void set_current_query_is_create_tbl_check_constraint(Node *expr);
static void validateUserAndRole(char *name);

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
static int	PltsqlGUCNestLevel = 0;
static bool pltsql_guc_dirty;
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
check_lang_as_clause_hook_type check_lang_as_clause_hook = NULL;
write_stored_proc_probin_hook_type write_stored_proc_probin_hook = NULL;
make_fn_arguments_from_stored_proc_probin_hook_type make_fn_arguments_from_stored_proc_probin_hook = NULL;
pltsql_nextval_hook_type prev_pltsql_nextval_hook = NULL;
pltsql_resetcache_hook_type prev_pltsql_resetcache_hook = NULL;
pltsql_setval_hook_type prev_pltsql_setval_hook = NULL;

static void
set_procid(Oid oid)
{
	procid_var = oid;
}

static void
assign_identity_insert(const char *newval, void *extra)
{
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
				A_Const    *value;
				Oid			relid;
				ListCell   *lc;

				if (!babelfish_dump_restore || IsBinaryUpgrade)
					break;

				relid = RangeVarGetRelid(stmt->relation, NoLock, false);

				/*
				 * Insert new dbid column value in babelfish catalog if dump
				 * did not provide it.
				 */
				if (relid == sysdatabases_oid ||
					relid == namespace_ext_oid ||
					relid == bbf_view_def_oid)
				{
					int16		dbid = 0;
					ResTarget  *dbidCol;
					bool		found = false;

					/* Skip if dbid column already exists */
					foreach(lc, stmt->cols)
					{
						ResTarget  *col = (ResTarget *) lfirst(lc);

						if (strcasecmp(col->name, "dbid") == 0)
							found = true;
					}
					if (found)
						break;

					dbid = getDbidForLogicalDbRestore(relid);

					/* const value node to store into values clause */
					value = makeNode(A_Const);
					value->val.ival.type = T_Integer;
					value->val.ival.ival = dbid;
					value->location = -1;

					/* dbid column to store into InsertStmt's target list */
					dbidCol = makeNode(ResTarget);
					dbidCol->name = "dbid";
					dbidCol->name_location = -1;
					dbidCol->indirection = NIL;
					dbidCol->val = NULL;
					dbidCol->location = -1;
					stmt->cols = lappend(stmt->cols, dbidCol);

					foreach(lc, selectStmt->valuesLists)
					{
						List	   *sublist = (List *) lfirst(lc);

						sublist = lappend(sublist, value);
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

/* Unlike PG, T-SQL treats null values as the lowest possible values.
 * So we need to set nulls_first for ASC order and nulls_last for DESC order.
 */
static inline void
pltsql_set_nulls_first(Query *query)
{
	ListCell   *lc = NULL;
	Node	   *node = NULL;
	SortGroupClause *sgc = NULL;
	char	   *opname = NULL;
	RangeTblEntry *rte = NULL;

	/* check subqueries */
	foreach(lc, query->rtable)
	{
		node = lfirst(lc);
		if (node->type != T_RangeTblEntry)
			continue;

		rte = (RangeTblEntry *) node;
		if (rte->rtekind == RTE_SUBQUERY && rte->subquery && rte->subquery->commandType == CMD_SELECT)
			pltsql_set_nulls_first(rte->subquery);
	}

	if (!query->sortClause)
		return;

	foreach(lc, query->sortClause)
	{
		node = lfirst(lc);
		if (node->type != T_SortGroupClause)
			continue;

		sgc = (SortGroupClause *) node;
		opname = get_opname(sgc->sortop);

		if (!opname)
			continue;
		else if (strcmp(opname, ">") == 0)
			sgc->nulls_first = false;
		else if (strcmp(opname, "<") == 0)
			sgc->nulls_first = true;
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
															  returningList);
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
								if (escape_hatch_unique_constraint != EH_IGNORE &&
									has_unique_nullable_constraint((ColumnDef *) element))
								{
									ereport(ERROR,
											(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
											 errmsg("Nullable UNIQUE constraint is not supported. Please use babelfishpg_tsql.escape_hatch_unique_constraint to ignore "
													"or add a NOT NULL constraint")));
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

									c->conname = construct_unique_index_name(c->conname, stmt->relation->relname);

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

									c->conname = construct_unique_index_name(c->conname, atstmt->relation->relname);

									if (escape_hatch_unique_constraint != EH_IGNORE &&
										c->contype == CONSTR_UNIQUE &&
										is_nullable_constraint(c, relid))
									{
										ereport(ERROR,
												(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
												 errmsg("Nullable UNIQUE constraint is not supported. Please use babelfishpg_tsql.escape_hatch_unique_constraint to ignore "
														"or add a NOT NULL constraint")));
									}

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
							case AT_DropConstraint:
								cmd->name = construct_unique_index_name(cmd->name, atstmt->relation->relname);
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

					if (escape_hatch_unique_constraint != EH_IGNORE &&
						stmt->unique &&
						is_nullable_index(stmt))
					{
						ereport(ERROR,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("Nullable UNIQUE index is not supported. Please use babelfishpg_tsql.escape_hatch_unique_constraint to ignore "
										"or add a NOT NULL constraint")));
					}
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

							pltsql_set_nulls_first(q);
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
	else if (query->commandType == CMD_SELECT)
	{
		pltsql_set_nulls_first(query);
	}
}

/*
 * transformReturningList -
 *	handle a RETURNING clause in INSERT/UPDATE/DELETE
 *
 *	Duplicated from analyzer
 */
static List *
transformReturningList(ParseState *pstate, List *returningList)
{
	List	   *rlist;
	int			save_next_resno;

	if (returningList == NIL)
		return NIL;				/* nothing to do */

	/*
	 * We need to assign resnos starting at one in the RETURNING list. Save
	 * and restore the main tlist's value of p_next_resno, just in case
	 * someone looks at it later (probably won't happen).
	 */
	save_next_resno = pstate->p_next_resno;
	pstate->p_next_resno = 1;

	/* transform RETURNING identically to a SELECT targetlist */
	rlist = transformTargetList(pstate, returningList, EXPR_KIND_RETURNING);

	/*
	 * Complain if the nonempty tlist expanded to nothing (which is possible
	 * if it contains only a star-expansion of a zero-column table).  If we
	 * allow this, the parsed Query will look like it didn't have RETURNING,
	 * with results that would probably surprise the user.
	 */
	if (rlist == NIL)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("RETURNING must have at least one column"),
				 parser_errposition(pstate,
									exprLocation(linitial(returningList)))));

	/* mark column origins */
	markTargetListOrigins(pstate, rlist);

	/* resolve any still-unresolved output columns as being type text */
	if (pstate->p_resolve_unknowns)
		resolveTargetListUnknowns(pstate, rlist);

	/* restore state */
	pstate->p_next_resno = save_next_resno;

	return rlist;
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
		char	   *colname = strVal(lfirst(lc));
		bool		found = false;

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

static bool
has_unique_nullable_constraint(ColumnDef *column)
{
	ListCell   *clist;
	bool		is_unique = false;
	bool		is_notnull = false;

	foreach(clist, column->constraints)
	{
		Constraint *constraint = lfirst_node(Constraint, clist);

		switch (constraint->contype)
		{
			case CONSTR_UNIQUE:
				is_unique = true;
				break;
			case CONSTR_NOTNULL:
				is_notnull = true;
				break;
			default:
				break;
		}
	}

	return is_unique & !is_notnull;
}

static bool
is_nullable_constraint(Constraint *cst, Oid rel_oid)
{
	ListCell   *lc;
	bool		is_notnull = false;

	/* Loop through the constraint keys */
	foreach(lc, cst->keys)
	{
		String	   *strval = (String *) lfirst(lc);
		const char *col_name = NULL;
		AttrNumber	attnum = InvalidAttrNumber;

		col_name = strVal(strval);
		attnum = get_attnum(rel_oid, col_name);

		if (get_attnotnull(rel_oid, attnum))
		{
			/* found a NOT NULL attr, break and return */
			is_notnull = true;
			break;
		}
	}

	return !is_notnull;
}

/*
 * get_attnotnull
 *		Given the relation id and the attribute number,
 *		return the "attnotnull" field from the attribute relation.
 */
static bool
get_attnotnull(Oid relid, AttrNumber attnum)
{
	HeapTuple	tp;
	Form_pg_attribute att_tup;

	tp = SearchSysCache2(ATTNUM,
						 ObjectIdGetDatum(relid),
						 Int16GetDatum(attnum));

	if (HeapTupleIsValid(tp))
	{
		bool result;

		att_tup = (Form_pg_attribute) GETSTRUCT(tp);
		result = att_tup->attnotnull;

		ReleaseSysCache(tp);

		return result;
	}
	/* Assume att is nullable if no valid heap tuple is found */
	return false;
}

static bool
is_nullable_index(IndexStmt *stmt)
{
	ListCell   *lc;
	bool		is_notnull = false;
	Oid			rel_oid = RangeVarGetRelid(stmt->relation, NoLock, false);

	/* Loop through the index columns */
	foreach(lc, stmt->indexParams)
	{
		IndexElem  *elem = lfirst_node(IndexElem, lc);
		const char *col_name = elem->name;
		AttrNumber	attnum = get_attnum(rel_oid, col_name);

		if (get_attnotnull(rel_oid, attnum))
		{
			is_notnull = true;
			break;
		}
	}

	return !is_notnull;
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
	List	   *new_type_names;
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

	aclresult = pg_type_aclcheck(*newtypid, GetUserId(), ACL_USAGE);
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
		if (strcmp(relname, tbl->refname) == 0)
		{
			if (!tbl->tblname)	/* FIXME: throwing an error instead of a crash
								 * until table-type is supported in ANTLR
								 * parser */
				ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR),
								errmsg("table variable underlying typename is NULL. refname: %s", tbl->refname)));
			return get_relname_relid(tbl->tblname, relnamespace);
		}
	}

	return relid;
}

/*
 * Transaction processing using tsql semantics
 */
extern void
PLTsqlProcessTransaction(Node *parsetree,
						 ParamListInfo params,
						 QueryCompletion *qc)
{
	char	   *txnName = NULL;
	TransactionStmt *stmt = (TransactionStmt *) parsetree;

	if (params != NULL && params->numParams > 0 && !params->params[0].isnull)
	{
		Oid			typOutput;
		bool		typIsVarlena;
		FmgrInfo	finfo;

		Assert(params->numParams == 1);
		getTypeOutputInfo(params->params[0].ptype, &typOutput, &typIsVarlena);
		fmgr_info(typOutput, &finfo);
		txnName = OutputFunctionCall(&finfo, params->params[0].value);
	}
	else
		txnName = stmt->savepoint_name;

	if (txnName != NULL && strlen(txnName) > TSQL_TXN_NAME_LIMIT / 2)
		ereport(ERROR,
				(errcode(ERRCODE_NAME_TOO_LONG),
				 errmsg("Transaction name length %zu above limit %u",
						strlen(txnName), TSQL_TXN_NAME_LIMIT / 2)));

	if (AbortCurTransaction)
	{
		if (stmt->kind == TRANS_STMT_BEGIN ||
			stmt->kind == TRANS_STMT_COMMIT ||
			stmt->kind == TRANS_STMT_SAVEPOINT)
			ereport(ERROR,
					(errcode(ERRCODE_TRANSACTION_ROLLBACK),
					 errmsg("The current transaction cannot be committed and cannot support operations that write to the log file. Roll back the transaction.")));
	}

	switch (stmt->kind)
	{
		case TRANS_STMT_BEGIN:
			{
				PLTsqlStartTransaction(txnName);
			}
			break;

		case TRANS_STMT_COMMIT:
			{
				if (exec_state_call_stack &&
					exec_state_call_stack->estate &&
					exec_state_call_stack->estate->insert_exec &&
					NestedTranCount <= 1)
					ereport(ERROR,
							(errcode(ERRCODE_TRANSACTION_ROLLBACK),
							 errmsg("Cannot use the COMMIT statement within an INSERT-EXEC statement unless BEGIN TRANSACTION is used first.")));

				PLTsqlCommitTransaction(qc, stmt->chain);
			}
			break;

		case TRANS_STMT_ROLLBACK:
			{
				if (exec_state_call_stack &&
					exec_state_call_stack->estate &&
					exec_state_call_stack->estate->insert_exec)
					ereport(ERROR,
							(errcode(ERRCODE_TRANSACTION_ROLLBACK),
							 errmsg("Cannot use the ROLLBACK statement within an INSERT-EXEC statement.")));

				/*
				 * Table variables should be immune to ROLLBACK, but we
				 * haven't implemented this yet so we throw an error if
				 * ROLLBACK is used with table variables.
				 */
				if (exec_state_call_stack &&
					exec_state_call_stack->estate &&
					exec_state_call_stack->estate->func &&
					list_length(exec_state_call_stack->estate->func->table_varnos) > 0)
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("ROLLBACK statement with active table variables is not yet supported.")));
				PLTsqlRollbackTransaction(txnName, qc, stmt->chain);
			}
			break;

		case TRANS_STMT_SAVEPOINT:
			RequireTransactionBlock(true, "SAVEPOINT");
			DefineSavepoint(txnName);
			break;

		default:
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_TRANSACTION_INITIATION),
					 errmsg("Unsupported transaction command : %d", stmt->kind)));
			break;
	}
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
		return;					/* Don't execute anything */

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
		case T_CreateFunctionStmt:
			{
				CreateFunctionStmt *stmt = (CreateFunctionStmt *) parsetree;
				bool		isCompleteQuery = (context != PROCESS_UTILITY_SUBCOMMAND);
				bool		needCleanup;
				ListCell   *option,
						   *location_cell = NULL;
				Node	   *tbltypStmt = NULL;
				Node	   *trigStmt = NULL;
				ObjectAddress tbltyp;
				ObjectAddress address;
				int			origname_location = -1;

				/*
				 * All event trigger calls are done only when isCompleteQuery
				 * is true
				 */
				needCleanup = isCompleteQuery && EventTriggerBeginCompleteQuery();

				/*
				 * PG_TRY block is to ensure we call
				 * EventTriggerEndCompleteQuery
				 */
				PG_TRY();
				{
					if (isCompleteQuery)
						EventTriggerDDLCommandStart(parsetree);

					foreach(option, stmt->options)
					{
						DefElem    *defel = (DefElem *) lfirst(option);

						if (strcmp(defel->defname, "tbltypStmt") == 0)
						{
							/*
							 * tbltypStmt is an implicit option in tsql
							 * dialect, we use this mechanism to create tsql
							 * style multi-statement table-valued function and
							 * its return (table) type in one statement.
							 */
							tbltypStmt = defel->arg;
						}
						else if (strcmp(defel->defname, "trigStmt") == 0)
						{
							/*
							 * trigStmt is an implicit option in tsql dialect,
							 * we use this mechanism to create tsql style
							 * function and trigger in one statement.
							 */
							trigStmt = defel->arg;
						}
						else if (strcmp(defel->defname, "location") == 0)
						{
							/*
							 * location is an implicit option in tsql dialect,
							 * we use this mechanism to store location of
							 * function name so that we can extract original
							 * input function name from queryString.
							 */
							origname_location = intVal((Node *) defel->arg);
							location_cell = option;
							pfree(defel);
						}
					}

					/*
					 * delete location cell if it exists as it is for internal
					 * use only
					 */
					if (location_cell)
						stmt->options = list_delete_cell(stmt->options, location_cell);

					/*
					 * For tbltypStmt, we need to first process the CreateStmt
					 * to create the type that will be used as the function's
					 * return type. Then, after the function is created, add a
					 * dependency between the type and the function.
					 */
					if (tbltypStmt)
					{
						/* Handle tbltypStmt, which is a CreateStmt */
						PlannedStmt *wrapper;

						wrapper = makeNode(PlannedStmt);
						wrapper->commandType = CMD_UTILITY;
						wrapper->canSetTag = false;
						wrapper->utilityStmt = tbltypStmt;
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

						/* Need CCI between commands */
						CommandCounterIncrement();
					}

					address = CreateFunction(pstate, stmt);

					/*
					 * Store function/procedure related metadata in babelfish
					 * catalog
					 */
					pltsql_store_func_default_positions(address, stmt->parameters, queryString, origname_location);

					if (tbltypStmt || restore_tsql_tabletype)
					{
						/*
						 * Add internal dependency between the table type and
						 * the function.
						 */
						tbltyp.classId = TypeRelationId;
						tbltyp.objectId = typenameTypeId(pstate,
														 stmt->returnType);
						tbltyp.objectSubId = 0;
						recordDependencyOn(&tbltyp, &address, DEPENDENCY_INTERNAL);
					}

					/*
					 * For trigStmt, we need to process the CreateTrigStmt
					 * after the function is created, and record bidirectional
					 * dependency so that Drop Trigger CASCADE will drop the
					 * implicit trigger function. Create trigger takes care of
					 * dependency addition.
					 */
					if (trigStmt)
					{
						(void) CreateTrigger((CreateTrigStmt *) trigStmt,
											 pstate->p_sourcetext, InvalidOid, InvalidOid,
											 InvalidOid, InvalidOid, address.objectId,
											 InvalidOid, NULL, false, false);
					}

					/*
					 * Remember the object so that ddl_command_end event
					 * triggers have access to it.
					 */
					EventTriggerCollectSimpleCommand(address, InvalidObjectAddress,
													 parsetree);

					if (isCompleteQuery)
					{
						EventTriggerSQLDrop(parsetree);
						EventTriggerDDLCommandEnd(parsetree);
					}

				}
				PG_CATCH();
				{
					if (needCleanup)
						EventTriggerEndCompleteQuery();
					PG_RE_THROW();
				}
				PG_END_TRY();

				if (needCleanup)
					EventTriggerEndCompleteQuery();
				return;
			}
		// case T_TransactionStmt:
		// 	{
		// 		if (NestedTranCount > 0 || (sql_dialect == SQL_DIALECT_TSQL && !IsTransactionBlockActive()))
		// 		{
		// 			PLTsqlProcessTransaction(parsetree, params, qc);
		// 			return;
		// 		}
		// 		break;
		// 	}
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
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					const char *prev_current_user;
					CreateRoleStmt *stmt = (CreateRoleStmt *) parsetree;
					List	   *login_options = NIL;
					List	   *user_options = NIL;
					ListCell   *option;
					bool		islogin = false;
					bool		isuser = false;
					bool		isrole = false;
					bool		from_windows = false;

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

									orig_loginname = extract_identifier(queryString + location);
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

								orig_user_name = extract_identifier(queryString + location);
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

								orig_user_name = extract_identifier(queryString + location);
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

						/* Set current user to sysadmin for create permissions */
						prev_current_user = GetUserNameFromId(GetUserId(), false);

						bbf_set_current_user("sysadmin");

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
							create_bbf_authid_login_ext(stmt);
						}
						PG_CATCH();
						{
							bbf_set_current_user(prev_current_user);
							PG_RE_THROW();
						}
						PG_END_TRY();

						bbf_set_current_user(prev_current_user);

						return;
					}
					else if (isuser || isrole)
					{
						/*
						 * check whether sql user name and role name contains
						 * '\' or not
						 */
						if (isrole || !from_windows)
							validateUserAndRole(stmt->role);

						/* Set current user to dbo user for create permissions */
						prev_current_user = GetUserNameFromId(GetUserId(), false);

						bbf_set_current_user(get_dbo_role_name(get_cur_db_name()));

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

							/*
							 * If the stmt is CREATE USER, it must have a
							 * corresponding login and a schema name
							 */
							create_bbf_authid_user_ext(stmt, isuser, isuser, from_windows);
						}
						PG_CATCH();
						{
							bbf_set_current_user(prev_current_user);
							PG_RE_THROW();
						}
						PG_END_TRY();

						bbf_set_current_user(prev_current_user);

						return;
					}
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
					Oid			prev_current_user;

					prev_current_user = GetUserId();

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
								if (strcmp(defel->defname, "rename") == 0)
									user_options = lappend(user_options, defel);
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
						Oid			datdba;
						bool		has_password = false;
						char	   *temp_login_name = NULL;

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
								if (!is_member_of_role(GetSessionUserId(), datdba))
									ereport(ERROR,
											(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
											 errmsg("Current login does not have privileges to alter password")));

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

						if (get_role_oid(stmt->role->rolename, true) == InvalidOid)
							ereport(ERROR, (errcode(ERRCODE_DUPLICATE_OBJECT),
											errmsg("Cannot drop the login '%s', because it does not exist or you do not have permission.", stmt->role->rolename)));


						/* Set current user to sysadmin for alter permissions */
						SetCurrentRoleId(datdba, false);

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
						PG_CATCH();
						{
							SetCurrentRoleId(prev_current_user, false);
							PG_RE_THROW();
						}
						PG_END_TRY();

						SetCurrentRoleId(prev_current_user, false);

						return;
					}
					else if (isuser || isrole)
					{
						const char *db_name;
						const char *dbo_name;
						Oid			dbo_id;

						db_name = get_cur_db_name();
						dbo_name = get_dbo_role_name(db_name);
						dbo_id = get_role_oid(dbo_name, false);

						/*
						 * Check if the current user has privileges.
						 */
						foreach(option, user_options)
						{
							DefElem    *defel = (DefElem *) lfirst(option);
							char	   *user_name;
							char	   *cur_user;

							user_name = stmt->role->rolename;
							cur_user = GetUserNameFromId(GetUserId(), false);
							if (strcmp(defel->defname, "default_schema") == 0)
							{
								if (strcmp(cur_user, dbo_name) != 0 &&
									strcmp(cur_user, user_name) != 0)
									ereport(ERROR,
											(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
											 errmsg("Current user does not have privileges to change schema")));
							}
							if (strcmp(defel->defname, "rename") == 0)
							{
								if (strcmp(cur_user, dbo_name) != 0 &&
									strcmp(cur_user, user_name) != 0)
									ereport(ERROR,
											(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
											 errmsg("Current user does not have privileges to change user name")));
							}
						}

						/* Set current user to dbo for alter permissions */
						SetCurrentRoleId(dbo_id, false);

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
						PG_CATCH();
						{
							SetCurrentRoleId(prev_current_user, false);
							PG_RE_THROW();
						}
						PG_END_TRY();

						SetCurrentRoleId(prev_current_user, false);
						set_session_properties(db_name);

						return;
					}
				}
				break;
			}
		case T_DropRoleStmt:
			{
				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					const char *prev_current_user;
					DropRoleStmt *stmt = (DropRoleStmt *) parsetree;
					bool		drop_user = false;
					bool		drop_role = false;
					bool		all_logins = false;
					bool		all_users = false;
					bool		all_roles = false;
					char	   *role_name = NULL;
					bool		other = false;
					ListCell   *item;

					/* Check if roles are users that need role name mapping */
					if (stmt->roles != NIL)
					{
						RoleSpec   *headrol = linitial(stmt->roles);

						if (strcmp(headrol->rolename, "is_user") == 0)
							drop_user = true;
						else if (strcmp(headrol->rolename, "is_role") == 0)
							drop_role = true;

						if (drop_user || drop_role)
						{
							char	   *db_name = NULL;

							stmt->roles = list_delete_cell(stmt->roles,
														   list_head(stmt->roles));
							pfree(headrol);
							headrol = NULL;
							db_name = get_cur_db_name();

							if (db_name != NULL && strcmp(db_name, "") != 0)
							{
								foreach(item, stmt->roles)
								{
									RoleSpec   *rolspec = lfirst(item);
									char	   *user_name;

									user_name = get_physical_user_name(db_name, rolspec->rolename);

									/*
									 * If a role has members, do not drop it.
									 * Note that here we don't handle invalid
									 * roles.
									 */
									if (drop_role && !is_empty_role(get_role_oid(user_name, true)))
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
											return;
										}
										else
											ereport(ERROR,
													(errcode(ERRCODE_CHECK_VIOLATION),
													 errmsg("User 'guest' cannot be dropped, it can only be disabled. "
															"The user is already disabled in the current database.")));
									}

									pfree(rolspec->rolename);
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

						ReleaseSysCache(tuple);

						/* Only one should be true */
						if (all_logins + all_users + all_roles + other != 1)
							ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									 errmsg("cannot mix dropping babelfish role types")));
					}

					/* If not user or role, then login */
					if (!drop_user && !drop_role)
					{
						int			role_oid = get_role_oid(role_name, true);

						if (role_oid == InvalidOid)
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

					if (all_logins || all_users || all_roles)
					{
						/*
						 * Set current user as appropriate for drop
						 * permissions
						 */
						prev_current_user = GetUserNameFromId(GetUserId(), false);

						/*
						 * Only use dbo if dropping a user/role in a Babelfish
						 * session.
						 */
						if (drop_user || drop_role)
							bbf_set_current_user(get_dbo_role_name(get_cur_db_name()));
						else
							bbf_set_current_user("sysadmin");

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
						PG_CATCH();
						{
							bbf_set_current_user(prev_current_user);
							PG_RE_THROW();
						}
						PG_END_TRY();

						bbf_set_current_user(prev_current_user);

						return;
					}
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

					return;
				}
				else
					break;
			}
		case T_DropStmt:
			{
				DropStmt   *drop_stmt = (DropStmt *) parsetree;

				if (drop_stmt->removeType != OBJECT_SCHEMA)
					break;

				if (sql_dialect == SQL_DIALECT_TSQL)
				{
					/*
					 * Prevent dropping guest schema unless it is part of drop
					 * database command.
					 */
					const char *schemaname = strVal(lfirst(list_head(drop_stmt->objects)));

					if (strcmp(queryString, "(DROP DATABASE )") != 0)
					{
						char	   *cur_db = get_cur_db_name();
						char	   *guest_schema_name = get_physical_schema_name(cur_db, "guest");

						if (strcmp(schemaname, guest_schema_name) == 0)
						{
							ereport(ERROR,
									(errcode(ERRCODE_INTERNAL_ERROR),
									 errmsg("Cannot drop the schema \'%s\'", schemaname)));
						}
					}

					del_ns_ext_info(schemaname, drop_stmt->missing_ok);

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
		case T_CreatedbStmt:
			if (sql_dialect == SQL_DIALECT_TSQL)
			{
				create_bbf_db(pstate, (CreatedbStmt *) parsetree);
				return;
			}
			break;
		case T_DropdbStmt:
			if (sql_dialect == SQL_DIALECT_TSQL)
			{
				DropdbStmt *stmt = (DropdbStmt *) parsetree;

				drop_bbf_db(stmt->dbname, stmt->missing_ok, false);
				return;
			}
			break;
		case T_GrantRoleStmt:
			if (sql_dialect == SQL_DIALECT_TSQL)
			{
				GrantRoleStmt *grant_role = (GrantRoleStmt *) parsetree;

				if (is_alter_server_stmt(grant_role))
				{
					const char *prev_current_user;
					const char *session_user_name;

					check_alter_server_stmt(grant_role);
					prev_current_user = GetUserNameFromId(GetUserId(), false);
					session_user_name = GetUserNameFromId(GetSessionUserId(), false);

					bbf_set_current_user(session_user_name);
					PG_TRY();
					{

						if (prev_ProcessUtility)
							prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
												queryEnv, dest, qc);
						else
							standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
													queryEnv, dest, qc);

					}
					PG_CATCH();
					{
						/* Clean up. Restore previous state. */
						bbf_set_current_user(prev_current_user);
						PG_RE_THROW();
					}
					PG_END_TRY();
					/* Clean up. Restore previous state. */
					bbf_set_current_user(prev_current_user);
					return;
				}
				else if (is_alter_role_stmt(grant_role))
				{
					const char *prev_current_user;
					const char *session_user_name;

					check_alter_role_stmt(grant_role);
					prev_current_user = GetUserNameFromId(GetUserId(), false);
					session_user_name = GetUserNameFromId(GetSessionUserId(), false);

					bbf_set_current_user(session_user_name);
					PG_TRY();
					{
						if (prev_ProcessUtility)
							prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
												queryEnv, dest, qc);
						else
							standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
													queryEnv, dest, qc);

					}
					PG_CATCH();
					{
						/* Clean up. Restore previous state. */
						bbf_set_current_user(prev_current_user);
						PG_RE_THROW();
					}
					PG_END_TRY();
					/* Clean up. Restore previous state. */
					bbf_set_current_user(prev_current_user);
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
							rawEnt = (RawColumnDefault *) palloc(sizeof(RawColumnDefault));
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
		case T_CreateDomainStmt:
			{
				CreateDomainStmt *create_domain = (CreateDomainStmt *) parsetree;

				if (prev_ProcessUtility)
					prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
										queryEnv, dest, qc);
				else
					standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
											queryEnv, dest, qc);

				revoke_type_permission_from_public(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest, qc, create_domain->domainname);
				return;
			}
		default:
			break;
	}

	if (prev_ProcessUtility)
		prev_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
							queryEnv, dest, qc);
	else
		standard_ProcessUtility(pstmt, queryString, readOnlyTree, context, params,
								queryEnv, dest, qc);
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

	if (tsql_is_server_collation_CI_AS())
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

			if (tsql_is_server_collation_CI_AS())
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
							   NULL,
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

	pre_function_call_hook = pre_function_call_hook_impl;
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
terminate_batch(bool send_error, bool compile_error)
{
	bool		error_mapping_failed = false;
	int			rc;

	elog(DEBUG2, "TSQL TXN finish current batch, error : %d compilation error : %d", send_error, compile_error);

	/*
	 * Disconnect from SPI manager
	 */
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
				ereport(ERROR,
						(errcode(ERRCODE_TRANSACTION_ROLLBACK),
						 errmsg("Uncommittable transaction is detected at the end of the batch. The transaction is rolled back.")));
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
	if (support_tsql_trans)
		SPI_setCurrentInternalTxnMode(true);

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
		PG_TRY();
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
		PG_CATCH();
		{
			set_procid(prev_procid);
			/* Decrement use-count, restore cur_estate, and propagate error */
			pltsql_trigger_depth = save_pltsql_trigger_depth;
			func->use_count--;
			func->cur_estate = save_cur_estate;
			ENRDropTempTables(currentQueryEnv);
			remove_queryEnv();
			pltsql_revert_guc(save_nestlevel);
			pltsql_revert_last_scope_identity(scope_level);
			terminate_batch(true /* send_error */ , false /* compile_error */ );
			sql_dialect = saved_dialect;
			return retval;
		}
		PG_END_TRY();
	}
	PG_FINALLY();
	{
		sql_dialect = saved_dialect;
	}
	PG_END_TRY();

	func->use_count--;

	func->cur_estate = save_cur_estate;

	ENRDropTempTables(currentQueryEnv);
	remove_queryEnv();
	pltsql_revert_guc(save_nestlevel);
	pltsql_revert_last_scope_identity(scope_level);

	terminate_batch(false /* send_error */ , false /* compile_error */ );

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
	Datum		retval;
	int			rc;
	int			saved_dialect = sql_dialect;
	int			nargs = PG_NARGS();
	int			i;
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

	if (support_tsql_trans)
		SPI_setCurrentInternalTxnMode(true);

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
		terminate_batch(true /* send_error */ , true /* compile_error */ );
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

		terminate_batch(true /* send_error */ , false /* compile_error */ );
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

	terminate_batch(false /* send_error */ , false /* compile_error */ );

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
		Assert(pltsql_guc_dirty);
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

	gconf->session_stack = stack;
	pltsql_guc_dirty = true;
}

int
pltsql_new_guc_nest_level(void)
{
	return ++PltsqlGUCNestLevel;
}

void
pltsql_revert_guc(int nest_level)
{
	bool		still_dirty;
	int			i;
	int			num_guc_variables;
	struct config_generic **guc_variables;

	Assert(nest_level > 0 && nest_level == PltsqlGUCNestLevel);

	/* Quick exit if nothing's changed in this procedure */
	if (!pltsql_guc_dirty)
	{
		PltsqlGUCNestLevel = nest_level - 1;
		return;
	}

	still_dirty = false;
	num_guc_variables = GetNumConfigOptions();
	guc_variables = get_guc_variables();
	for (i = 0; i < num_guc_variables; i++)
	{
		struct config_generic *gconf = guc_variables[i];
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
			gconf->source = newsource;
			gconf->scontext = newscontext;

			/* Finish popping the state stack */
			gconf->session_stack = prev;
			pfree(stack);
		}						/* end of stack-popping loop */

		if (stack != NULL)
			still_dirty = true;
	}

	/* If there are no remaining stack entries, we can reset guc_dirty */
	pltsql_guc_dirty = still_dirty;

	/* Update nesting level */
	PltsqlGUCNestLevel = nest_level - 1;

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
