#include "postgres.h"

#include "catalog/heap.h"
#include "catalog/namespace.h"
#include "catalog/pg_proc.h"
#include "commands/tablecmds.h"
#include "funcapi.h"
#include "nodes/makefuncs.h"
#include "nodes/nodeFuncs.h"
#include "parser/parse_clause.h"
#include "parser/parse_coerce.h"
#include "parser/parse_expr.h"
#include "parser/parse_func.h"
#include "parser/parse_relation.h"
#include "parser/parse_utilcmd.h"
#include "parser/parse_target.h"
#include "parser/parser.h"
#include "parser/scanner.h"
#include "parser/scansup.h"
#include "utils/builtins.h"
#include "utils/rel.h"
#include "utils/relcache.h"
#include "utils/syscache.h"

#include "backend_parser/scanner.h"
#include "hooks.h"
#include "catalog.h"
#include "rolecmds.h"

/*****************************************
 * 			Catalog Hooks
 *****************************************/
IsExtendedCatalogHookType PrevIsExtendedCatalogHook = NULL;

/*****************************************
 * 			Analyzer Hooks
 *****************************************/
static void set_output_clause_transformation_info(bool enabled);
static bool get_output_clause_transformation_info(void);
static Node *output_update_self_join_transformation(ParseState *pstate, UpdateStmt *stmt, CmdType command);
static void handle_returning_qualifiers(CmdType command, List *returningList, ParseState *pstate);
static void check_insert_row(List *icolumns, List *exprList);
static void pltsql_post_transform_column_definition(ParseState *pstate, RangeVar* relation, ColumnDef *column, List **alist);
static void pre_transform_target_entry(ResTarget *res, ParseState *pstate, ParseExprKind exprKind);
static bool tle_name_comparison(const char *tlename, const char *identifier);
static void resolve_target_list_unknowns(ParseState *pstate, List *targetlist);
static inline bool is_identifier_char(char c);
static int find_attr_by_name_from_relation(Relation rd, const char *attname, bool sysColOK);

/*****************************************
 * 			Commands Hooks
 *****************************************/
static int find_attr_by_name_from_column_def_list(const char *attributeName, List *schema);

/*****************************************
 * 			Utility Hooks
 *****************************************/
static void pltsql_report_proc_not_found_error(List *names, List *argnames, int nargs, ParseState *pstate, int location, bool proc_call);

/* Save hook values in case of unload */
static core_yylex_hook_type prev_core_yylex_hook = NULL;
static pre_transform_returning_hook_type prev_pre_transform_returning_hook = NULL;
static post_transform_insert_row_hook_type prev_post_transform_insert_row_hook = NULL;
static pre_transform_target_entry_hook_type prev_pre_transform_target_entry_hook = NULL;
static tle_name_comparison_hook_type prev_tle_name_comparison_hook = NULL;
static resolve_target_list_unknowns_hook_type prev_resolve_target_list_unknowns_hook = NULL;
static find_attr_by_name_from_column_def_list_hook_type prev_find_attr_by_name_from_column_def_list_hook = NULL;
static find_attr_by_name_from_relation_hook_type prev_find_attr_by_name_from_relation_hook = NULL;
static report_proc_not_found_error_hook_type prev_report_proc_not_found_error_hook = NULL;

/*****************************************
 * 			Install / Uninstall
 *****************************************/
void
InstallExtendedHooks(void)
{
	if (IsExtendedCatalogHook)
		PrevIsExtendedCatalogHook = IsExtendedCatalogHook;
	IsExtendedCatalogHook = &IsPLtsqlExtendedCatalog;

	assign_object_access_hook_drop_role();

	prev_core_yylex_hook = core_yylex_hook;
	core_yylex_hook = pgtsql_core_yylex;

	get_output_clause_status_hook = get_output_clause_transformation_info;
	pre_output_clause_transformation_hook = output_update_self_join_transformation;

	prev_pre_transform_returning_hook = pre_transform_returning_hook;
	pre_transform_returning_hook = handle_returning_qualifiers;

	prev_post_transform_insert_row_hook = post_transform_insert_row_hook;
	post_transform_insert_row_hook = check_insert_row;

	post_transform_column_definition_hook = pltsql_post_transform_column_definition;

	prev_pre_transform_target_entry_hook = pre_transform_target_entry_hook;
	pre_transform_target_entry_hook = pre_transform_target_entry;

	prev_tle_name_comparison_hook = tle_name_comparison_hook;
	tle_name_comparison_hook = tle_name_comparison;

	prev_resolve_target_list_unknowns_hook = resolve_target_list_unknowns_hook;
	resolve_target_list_unknowns_hook = resolve_target_list_unknowns;

	prev_find_attr_by_name_from_column_def_list_hook = find_attr_by_name_from_column_def_list_hook;
	find_attr_by_name_from_column_def_list_hook = find_attr_by_name_from_column_def_list;

	prev_find_attr_by_name_from_relation_hook = find_attr_by_name_from_relation_hook;
	find_attr_by_name_from_relation_hook = find_attr_by_name_from_relation;

	prev_report_proc_not_found_error_hook = report_proc_not_found_error_hook;
	report_proc_not_found_error_hook = pltsql_report_proc_not_found_error;
}

void
UninstallExtendedHooks(void)
{
	IsExtendedCatalogHook = PrevIsExtendedCatalogHook;

	uninstall_object_access_hook_drop_role();

	core_yylex_hook = prev_core_yylex_hook;
	get_output_clause_status_hook = NULL;
	pre_output_clause_transformation_hook = NULL;
	pre_transform_returning_hook = prev_pre_transform_returning_hook;
	post_transform_insert_row_hook = prev_post_transform_insert_row_hook;
	post_transform_column_definition_hook = NULL;
	pre_transform_target_entry_hook = prev_pre_transform_target_entry_hook;
	tle_name_comparison_hook = prev_tle_name_comparison_hook;
	resolve_target_list_unknowns_hook = prev_resolve_target_list_unknowns_hook;
	find_attr_by_name_from_column_def_list_hook = prev_find_attr_by_name_from_column_def_list_hook;
	find_attr_by_name_from_relation_hook = prev_find_attr_by_name_from_relation_hook;
	report_proc_not_found_error_hook = prev_report_proc_not_found_error_hook;
}

/*****************************************
 * 			Hook Functions
 *****************************************/

static Node *
output_update_self_join_transformation(ParseState *pstate, UpdateStmt *stmt, CmdType command)
{
	Node	    *qual = NULL, *pre_transform_qual = NULL;
	RangeVar	*from_table = NULL;
	ColumnRef	*l_expr, *r_expr;
	A_Expr 		*where_ctid = NULL;
	Node 		*where_clone = NULL;

	/* 
	* Invoke transformWhereClause() to check for ambiguities in column name
	* of the original query before self-join transformation.
	*/
	where_clone = copyObject(stmt->whereClause);
	pre_transform_qual = transformWhereClause(pstate, stmt->whereClause,
							EXPR_KIND_WHERE, "WHERE");

	if (sql_dialect != SQL_DIALECT_TSQL)
		return pre_transform_qual;

	if (get_output_clause_transformation_info())
	{
		/* Unset the OUTPUT clause info variable to prevent unintended side-effects */
		set_output_clause_transformation_info(false);

		/* Add target table with deleted alias to the from clause */
		from_table = makeRangeVar(NULL, stmt->relation->relname, -1);
		from_table->alias = makeAlias("deleted", NIL);
		stmt->fromClause = list_make1(from_table);
		transformFromClause(pstate, stmt->fromClause);

		/* Create the self-join condition based on ctid */
		l_expr = makeNode(ColumnRef);
		l_expr->fields = list_make2(makeString(stmt->relation->relname), makeString("ctid"));
		l_expr->location = -1;

		r_expr = makeNode(ColumnRef);
		r_expr->fields = list_make2(makeString("deleted"), makeString("ctid"));
		r_expr->location = -1;
		where_ctid = makeA_Expr(AEXPR_OP, list_make1(makeString("=")), (Node*) l_expr, (Node*) r_expr, -1);

		/* Add the self-join condition to the where clause */
		if (where_clone)
		{
			BoolExpr *self_join_condition;
			self_join_condition = (BoolExpr*) makeBoolExpr(AND_EXPR, list_make2(where_clone, where_ctid), -1);
			stmt->whereClause = (Node*) self_join_condition;
		}
		else
			stmt->whereClause = (Node*) where_ctid;

		/* Set the OUTPUT clause info variable to be used in transformColumnRef() */
		set_output_clause_transformation_info(true);

		/*
		* We let transformWhereClause() be called before the invokation of this hook
		* to handle ambiguity errors. If there are any ambiguous references in the
		* query an error is thrown. At this point, we have cleared that check and 
		* know that there are no ambiguities. Therefore, we can go ahead with the
		* where clause transformation without worrying about ambiguous references.
		*/
		qual = transformWhereClause(pstate, stmt->whereClause,
								EXPR_KIND_WHERE, "WHERE");

		/* Unset the OUTPUT clause info variable because we do not need it anymore */
		set_output_clause_transformation_info(false);
	}
	else
		qual = pre_transform_qual;

	handle_returning_qualifiers(command, stmt->returningList, pstate);
	return qual;
}

static void
set_output_clause_transformation_info(bool enabled)
{
	output_update_transformation = enabled;
}

static bool
get_output_clause_transformation_info(void)
{
	return output_update_transformation;
}

static void
handle_returning_qualifiers(CmdType command, List *returningList, ParseState *pstate)
{
	ListCell   			*o_target, *expr;
	Node	   			*field1;
	char	   			*qualifier = NULL; 
	ParseNamespaceItem  *nsitem = NULL;
	int 				levels_up;
	bool 				inserted = false, deleted = false;
	List				*queue = NIL;

	if (prev_pre_transform_returning_hook)
		prev_pre_transform_returning_hook(command, returningList, pstate);

	if (sql_dialect != SQL_DIALECT_TSQL || returningList == NIL)
		return;

	if (command == CMD_INSERT || command == CMD_DELETE)
	{
		foreach(o_target, returningList)
		{
			ResTarget  *res = (ResTarget *) lfirst(o_target);
			queue = NIL;
			queue = list_make1(res->val);

			foreach(expr, queue)
			{
				Node *node = (Node *) lfirst(expr);
				if (IsA(node, ColumnRef))
				{
					ColumnRef  *cref = (ColumnRef *) node;

					if (command == CMD_INSERT)
						nsitem = refnameNamespaceItem(pstate, NULL, "inserted",
													  cref->location,
													  &levels_up);

					if (command == CMD_DELETE)
						nsitem = refnameNamespaceItem(pstate, NULL, "deleted",
													  cref->location,
													  &levels_up);

					if (nsitem)
						return;

					if (list_length(cref->fields) == 2)
					{
						field1 = (Node *) linitial(cref->fields);
						qualifier = strVal(field1);

						if ((command == CMD_INSERT && !strcmp(qualifier, "inserted"))
							|| (command == CMD_DELETE && !strcmp(qualifier, "deleted")))
							cref->fields = list_delete_first(cref->fields);
					}
				}
				else if(IsA(node, A_Expr))
				{
					A_Expr  *a_expr = (A_Expr *) node;

					if (a_expr->lexpr)
						queue = lappend(queue, a_expr->lexpr);
					if (a_expr->rexpr)
						queue = lappend(queue, a_expr->rexpr);
				}
				else if(IsA(node, FuncCall))
				{
					FuncCall *func_call = (FuncCall*) node;
					if (func_call->args)
						queue = list_concat(queue, func_call->args);
				}
			}
		}
	}
	else if (command == CMD_UPDATE)
	{
		foreach(o_target, returningList)
		{
			ResTarget  *res = (ResTarget *) lfirst(o_target);
			queue = NIL;
			queue = list_make1(res->val);

			foreach(expr, queue)
			{
				Node *node = (Node *) lfirst(expr);

				if (IsA(node, ColumnRef))
				{
					/*
					* Checks for RTEs could have been performed outside of the loop
					* but we need to perform them inside the loop so that we can pass
					* cref->location to refnameRangeTblEntry() and keep error messages
					* correct.
					*/
					ColumnRef  *cref = (ColumnRef *) node;
					nsitem = refnameNamespaceItem(pstate, NULL, "inserted",
												  cref->location,
												  &levels_up);

					if (nsitem)
						inserted = true;

					nsitem = refnameNamespaceItem(pstate, NULL, "deleted",
												  cref->location,
												  &levels_up);
					if (nsitem)
						deleted = true;

					if (inserted && deleted)
						break;
				}
				else if(IsA(node, A_Expr))
				{
					A_Expr  *a_expr = (A_Expr *) node;

					if (a_expr->lexpr)
						queue = lappend(queue, a_expr->lexpr);
					if (a_expr->rexpr)
						queue = lappend(queue, a_expr->rexpr);
				}
				else if(IsA(node, FuncCall))
				{
					FuncCall *func_call = (FuncCall*) node;
					if (func_call->args)
						queue = list_concat(queue, func_call->args);
				}
			}
		}
		foreach(o_target, returningList)
		{
			ResTarget  *res = (ResTarget *) lfirst(o_target);
			queue = NIL;
			queue = list_make1(res->val);

			foreach(expr, queue)
			{
				Node *node = (Node *) lfirst(expr);

				if (IsA(node, ColumnRef))
				{
					ColumnRef  *cref = (ColumnRef *) node;
					if (list_length(cref->fields) == 2)
					{
						field1 = (Node *) linitial(cref->fields);
						qualifier = strVal(field1);

						if ((!inserted && !strcmp(qualifier, "inserted")) || (!deleted && !strcmp(qualifier, "deleted")))
						{
							if (update_delete_target_alias)
								/*
								 * If target relation is specified by an alias
								 * in FROM clause, we should use the alias
								 * instead of the relation name, because
								 * otherwise "inserted" will still show the
								 * previous value.
								 */
								linitial(cref->fields) = makeString(update_delete_target_alias);
							else
								linitial(cref->fields) = makeString(RelationGetRelationName(pstate->p_target_relation));
						}
					}
				}
				else if(IsA(node, A_Expr))
				{
					A_Expr  *a_expr = (A_Expr *) node;

					if (a_expr->lexpr)
						queue = lappend(queue, a_expr->lexpr);
					if (a_expr->rexpr)
						queue = lappend(queue, a_expr->rexpr);
				}
				else if(IsA(node, FuncCall))
				{
					FuncCall *func_call = (FuncCall*) node;
					if (func_call->args)
						queue = list_concat(queue, func_call->args);
				}
			}
		}
	}
}

static void
check_insert_row(List *icolumns, List *exprList)
{
	if (prev_post_transform_insert_row_hook)
		prev_post_transform_insert_row_hook(icolumns, exprList);

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/* Do not allow more target columns than expressions */
	if (exprList != NIL && list_length(exprList) < list_length(icolumns))
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("Number of given values does not match target table definition")));
}

char*
extract_identifier(const char *start)
{
	/*
	 * We will extract original identifier from source query string. 'start' is a char potiner to start of identifier, which is provided from caller based on location of each token.
	 * The remaning task is to find the end position of identifier. For this, we will mimic the lexer rule.
	 * This includes plain identifier (and un-reserved keyword) as well as delimited by double-quote and squared bracket (T-SQL).
	 *
	 * Please note that, this function assumes that identifier is already valid. (otherwise, syntax error should be already thrown).
	 */

	bool dq = false;
	bool sqb = false;
	int i = 0;
	char *original_name = NULL;
	bool valid = false;
	bool found_escaped_in_dq = false;

	/* check identifier is delimited */
	Assert(start);
	if (start[0] == '"')
		dq = true;
	else if (start[0] == '[')
		sqb = true;
	++i; /* advance cursor by one. As it is already a valid identiifer, its length should be greater than 1 */

	/* valid identifier cannot be longer than 258 (2*128+2) bytes. SQL server allows up to 128 bascially. And escape character can take additional one byte for each character in worst case. And additional 2 byes for delimiter */
	while (i < 258)
	{
		char c = start[i];

		if (!dq && !sqb) /* normal case */
		{
			/* please see {tsql_ident_cont} in scan-tsql-decl.l */
			valid = is_identifier_char(c);
			if (!valid)
			{
				original_name = palloc(i + 1);
				memcpy(original_name, start, i);
				original_name[i] = '\0';
				return original_name;
			}
		}
		else if (dq)
		{
			/* please see xdinside in scan.l */
			valid = (c != '"');
			if (!valid && start[i+1] == '"') /* escaped */
			{
				++i; ++i; /* advance two characters */
				found_escaped_in_dq = true;
				continue;
			}

			if (!valid)
			{
				if (!found_escaped_in_dq)
				{
					/* no escaped character. copy whole string at once */
					original_name = palloc(i); /* exclude first/last double quote */
					memcpy(original_name, start + 1, i -1);
					original_name[i - 1] = '\0';
					return original_name;
				}
				else
				{
					/* there is escaped character. copy one by one to handle escaped character */
					int rcur = 1; /* read-cursor */
					int wcur = 0; /* write-cursor */
					original_name = palloc(i); /* exclude first/last double quote */
					for (; rcur<i; ++rcur, ++wcur)
					{
						original_name[wcur] = start[rcur];
						if (start[rcur] == '"')
							++rcur; /* skip next character */
					}
					original_name[wcur] = '\0';
					return original_name;
				}
			}
		}
		else if (sqb)
		{
			/* please see xbrinside in scan-tsql-decl.l */
			valid = (c != ']');
			if (!valid)
			{
				original_name = palloc(i); /* exclude first/last square bracket */
				memcpy(original_name, start + 1, i -1);
				original_name[i - 1] = '\0';
				return original_name;
			}
		}

		++i;
	}

	return NULL;
}

extern const char *ATTOPTION_BBF_ORIGINAL_NAME;

static void
pltsql_post_transform_column_definition(ParseState *pstate, RangeVar* relation, ColumnDef *column, List **alist)
{
	/* add "ALTER TABLE ALTER COLUMN SET (bbf_original_name=<original_name>)" to alist so that original_name will be stored in pg_attribute.attoptions */

	AlterTableStmt *stmt;
	AlterTableCmd *cmd;
	// To get original column name, utilize location of ColumnDef and query string.
	const char* column_name_start = pstate->p_sourcetext + column->location;
	char* original_name = extract_identifier(column_name_start);
	if (original_name == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("can't extract original column name")));


	cmd = makeNode(AlterTableCmd);
	cmd->subtype = AT_SetOptions;
	cmd->name = column->colname;
	cmd->def = (Node *) list_make1(makeDefElem(pstrdup(ATTOPTION_BBF_ORIGINAL_NAME), (Node *) makeString(pstrdup(original_name)), column->location));
	cmd->behavior = DROP_RESTRICT;
	cmd->missing_ok = false;

	stmt = makeNode(AlterTableStmt);
	stmt->relation = relation;
	stmt->cmds = NIL;
	stmt->relkind = OBJECT_TABLE;
	stmt->cmds = lappend(stmt->cmds, cmd);

	(*alist) = lappend(*alist, stmt);
}

static void
resolve_target_list_unknowns(ParseState *pstate, List *targetlist)
{
	ListCell   *l;

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	foreach(l, targetlist)
	{
		Const 		*con;
		TargetEntry *tle = (TargetEntry *) lfirst(l);
		Oid			restype = exprType((Node *) tle->expr);

		if (restype != UNKNOWNOID)
			continue;

		if (!IsA(tle->expr, Const))
			continue;

		con = (Const *) tle->expr;
		if (con->constisnull)
		{
			/* In T-SQL, NULL const (without explicit datatype) should be resolved as INT4 */
			tle->expr = (Expr *) coerce_type(pstate, (Node *) con,
												restype, INT4OID, -1,
												COERCION_IMPLICIT,
												COERCE_IMPLICIT_CAST,
												-1);
		}
		else
		{
			Oid sys_nspoid = get_namespace_oid("sys", false);
			Oid sys_varchartypoid = GetSysCacheOid2(TYPENAMENSP, Anum_pg_type_oid,
													CStringGetDatum("varchar"), ObjectIdGetDatum(sys_nspoid));
			tle->expr = (Expr *) coerce_type(pstate, (Node *) con,
												restype, sys_varchartypoid, -1,
												COERCION_IMPLICIT,
												COERCE_IMPLICIT_CAST,
												-1);
		}
	}
}

static inline bool
is_identifier_char(char c)
{
	/* please see {tsql_ident_cont} in scan-tsql-decl.l */
	bool valid = ((c >= 'A' && c <= 'Z') ||
		      (c >= 'a' && c <= 'z') ||
		      (c >= 0200 && c <= 0377) ||
		      (c >= '0' && c <= '9') ||
		      c == '_' || c == '$' || c == '#');

	return valid;
}

static int
find_attr_by_name_from_column_def_list(const char *attributeName, List *schema)
{
	char *attrname = downcase_identifier(attributeName, strlen(attributeName), false, false);
	int attrlen = strlen(attrname);
	int i = 1;
	ListCell *s;

	foreach(s, schema)
	{
		ColumnDef  *def = lfirst(s);

		if (strlen(def->colname) == attrlen)
		{
			char *defname;

			if (strcmp(attributeName, def->colname) == 0) // compare with original strings
				return i;

			defname = downcase_identifier(def->colname, strlen(def->colname), false, false);
			if (strncmp(attrname, defname, attrlen) == 0) // compare with downcased strings
				return i;
		}
		i++;
	}

	return InvalidAttrNumber;
}

/* specialAttNum()
 *
 * Check attribute name to see if it is "special", e.g. "xmin".
 * - thomas 2000-02-07
 *
 * Note: this only discovers whether the name could be a system attribute.
 * Caller needs to ensure that it really is an attribute of the rel.
 */
static int
specialAttNum(const char *attname)
{
	const FormData_pg_attribute *sysatt;

	sysatt = SystemAttributeByName(attname);
	if (sysatt != NULL)
		return sysatt->attnum;
	return InvalidAttrNumber;
}

static int
find_attr_by_name_from_relation(Relation rd, const char *attname, bool sysColOK)
{
	int i;

	for (i = 0; i < RelationGetNumberOfAttributes(rd); i++)
	{
		Form_pg_attribute att = TupleDescAttr(rd->rd_att, i);
		const char *origname = NameStr(att->attname);
		int rdattlen = strlen(origname);
		const char *rdattname;

		if (strlen(attname) == rdattlen && !att->attisdropped)
		{
			if (namestrcmp(&(att->attname), attname) == 0) // compare with original strings
				return i + 1;

			/*
			 * Currently, we don't have any cases where attname needs to be downcased
			 * If exists, we have to take a deeper look
			 * whether the downcasing is needed here or gram.y
			 */
			rdattname = downcase_identifier(origname, rdattlen, false, false);
			if (strcmp(rdattname, attname) == 0) // compare with downcased strings
				return i + 1;
		}
	}

	if (sysColOK)
	{
		if ((i = specialAttNum(attname)) != InvalidAttrNumber)
			return i;
	}

	/* on failure */
	return InvalidAttrNumber;
}

static void
pre_transform_target_entry(ResTarget *res, ParseState *pstate,
									   ParseExprKind exprKind)
{
	if (prev_pre_transform_target_entry_hook)
		(*prev_pre_transform_target_entry_hook) (res, pstate, exprKind);

	/* In the TSQL dialect construct an AS clause for each target list
	 * item that is a column using the capitalization from the sourcetext.
	 */
	if (sql_dialect == SQL_DIALECT_TSQL &&
		exprKind == EXPR_KIND_SELECT_TARGET)
	{
		int alias_len = 0;
		const char *colname_start;
		const char *identifier_name = NULL;

		if (res->name == NULL && res->location != -1 &&
			IsA(res->val, ColumnRef))
		{
			ColumnRef *cref = (ColumnRef *) res->val;

			/* If no alias is specified on a ColumnRef, then
			 * get the length of the name from the ColumnRef and
			 * copy the column name from the sourcetext
			 */
			if (list_length(cref->fields) == 1 &&
				IsA(linitial(cref->fields), String))
			{
				identifier_name = strVal(linitial(cref->fields));
				alias_len = strlen(identifier_name);
				colname_start = pstate->p_sourcetext + res->location;
			}
		}
		else if (res->name != NULL && res->name_location != -1)
		{
			identifier_name = res->name;
			alias_len = strlen(res->name);
			colname_start = pstate->p_sourcetext + res->name_location;
		}

		if (alias_len > 0)
		{
			char *alias = palloc0(alias_len + 1);
			bool dq = *colname_start == '"';
			bool sqb = *colname_start == '[';
			bool sq = *colname_start == '\'';
			int a = 0;
			const char *colname_end;
			bool closing_quote_reached = false;

			if (dq || sqb || sq)
			{
				colname_start++;
			}

			if (dq || sq)
			{

				for (colname_end = colname_start; a < alias_len; colname_end++)
				{
					if (dq && *colname_end == '"')
					{
						if ((*(++colname_end) != '"'))
						{
							closing_quote_reached = true;
							break; /* end of dbl-quoted identifier */
						}
					}
					else if (sq && *colname_end == '\'')
					{
						if ((*(++colname_end) != '\''))
						{
							closing_quote_reached = true;
							break; /* end of single-quoted identifier */
						}
					}

					alias[a++] = *colname_end;
				}

				// Assert(a == alias_len);
			}
			else
			{
				colname_end = colname_start + alias_len;
				memcpy(alias, colname_start, alias_len);
			}

			/* If the end of the string is a uniquifier, then copy
			 * the uniquifier into the last 32 characters of
			 * the alias
			 */
			if (alias_len == NAMEDATALEN-1 &&
			    (((sq || dq) && !closing_quote_reached) ||
			     is_identifier_char(*colname_end)))

			{
				memcpy(alias+(NAMEDATALEN-1)-32,
				       identifier_name+(NAMEDATALEN-1)-32,
				       32);
				alias[NAMEDATALEN] = '\0';
			}

			res->name = alias;
		}
	}
}

static bool
tle_name_comparison(const char *tlename, const char *identifier)
{
	if (sql_dialect == SQL_DIALECT_TSQL)
	{
		int tlelen = strlen(tlename);

		if (tlelen != strlen(identifier))
			return false;

		if (pltsql_case_insensitive_identifiers)
			return (0 == strcmp(downcase_identifier(tlename, tlelen, false, false),
					    downcase_identifier(identifier, tlelen, false, false)));
		else
			return (0 == strcmp(tlename, identifier));
	}
	else if (prev_tle_name_comparison_hook)
		return (*prev_tle_name_comparison_hook) (tlename, identifier);
	else
		return (0 == strcmp(tlename, identifier));
}

/* Generate similar error message with SQL Server when function/procedure is not found if possible. */
void
pltsql_report_proc_not_found_error(List *names, List *given_argnames, int nargs, ParseState *pstate, int location, bool proc_call)
{
	FuncCandidateList candidates = NULL, current_candidate = NULL;
	int max_nargs = -1;
	int min_nargs = INT_MAX;
	int ncandidates = 0;
	bool found = false;
	const char *obj_type = proc_call ? "procedure" : "function";

	candidates = FuncnameGetCandidates(names, -1, NIL, false, false, true); /* search all possible candidate regardless of the # of arguments */
	if (candidates == NULL)
		return; /* no candidates at all. let backend handle the proc-not-found error */

	for (current_candidate = candidates; current_candidate != NULL; current_candidate = current_candidate->next)
	{
		if (current_candidate->nargs == nargs) /* Found the proc/func having the same number of arguments. */
			found = true;
		
		ncandidates++;
		min_nargs = (current_candidate->nargs < min_nargs) ? current_candidate->nargs : min_nargs;
		max_nargs = (current_candidate->nargs > max_nargs) ? current_candidate->nargs : max_nargs;
	}

	if (max_nargs == -1 || min_nargs == INT_MAX) /* Unexpected number of arguments, let PG backend handle the error message */
		return;

	if (ncandidates > 1) /* More than one candidates exist, throwing an error message with possible number of arguments */
	{
		const char *arg_str = (max_nargs < 2) ? "argument" : "arguments";

		/* Found the proc/func having the same number of arguments. possibly data-type mistmatch. */
		if (found)
		{
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_FUNCTION),
					 errmsg("The %s %s is found but cannot be used. Possibly due to datatype mismatch and implicit casting is not allowed.", obj_type, NameListToString(names))),
					 parser_errposition(pstate, location));
		}

		if (max_nargs == min_nargs)
		{
			if (max_nargs == 0)
			{
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_FUNCTION),
						 errmsg("%s %s has too many arguments specified.", obj_type, NameListToString(names))),
						 parser_errposition(pstate, location));
			}
			else
			{
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_FUNCTION),
						 errmsg("The %s %s requires %d %s", NameListToString(names), obj_type, max_nargs, arg_str)),
						 parser_errposition(pstate, location));
			}
		}
		else
		{
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_FUNCTION),
					 errmsg("The %s %s requires %d to %d %s", NameListToString(names), obj_type, min_nargs, max_nargs, arg_str)),
					 parser_errposition(pstate, location));
		}
	}
	else /* Only one candidate exists, */
	{
		HeapTuple tup;
		bool isnull;

		tup = SearchSysCache1(PROCOID, ObjectIdGetDatum(candidates->oid));
		if (HeapTupleIsValid(tup))
		{
			(void) SysCacheGetAttr(PROCOID, tup,
									Anum_pg_proc_proargnames,
									&isnull);
			
			if(!isnull)
			{
				Form_pg_proc procform = (Form_pg_proc) GETSTRUCT(tup);
				int pronargs = procform->pronargs;
				int first_arg_with_default = pronargs - procform->pronargdefaults;
				int pronallargs;
				int ap;
				int pp;
				int numposargs = nargs - list_length(given_argnames);
				Oid *p_argtypes;
				char **p_argnames;
				char *p_argmodes;
				char *first_unknown_argname = NULL;
				bool arggiven[FUNC_MAX_ARGS];
				ListCell *lc;

				if (nargs > pronargs) /* Too many parameters provided. */
				{
					ereport(ERROR,
							(errcode(ERRCODE_UNDEFINED_FUNCTION),
							 errmsg("%s %s has too many arguments specified.",obj_type, NameListToString(names))),
							 parser_errposition(pstate, location));
				}
				
				pronallargs = get_func_arg_info(tup,
												&p_argtypes,
												&p_argnames,
												&p_argmodes);
				memset(arggiven, false, pronargs * sizeof(bool));

				/* there are numposargs positional args before the named args */
				for (ap = 0; ap < numposargs; ap++)
					arggiven[ap] = true;

				foreach(lc, given_argnames)
				{
					char *argname = (char *) lfirst(lc);
					bool match_found;
					int i;

					pp = 0;
					match_found = false;
					for (i = 0; i < pronallargs; i++)
					{
						/* consider only input parameters */
						if (p_argmodes &&
						    (p_argmodes[i] != FUNC_PARAM_IN &&
							 p_argmodes[i] != FUNC_PARAM_INOUT &&
							 p_argmodes[i] != FUNC_PARAM_VARIADIC))
							continue;
						if (p_argnames[i] && strcmp(p_argnames[i], argname) == 0)
						{
							arggiven[pp] = true;
							match_found = true;
							break;
						}
						/* increase pp only for input parameters */
						pp++;
					}
					/* Store first unknown parameter name. */
					if (!match_found && first_unknown_argname == NULL)
						first_unknown_argname = argname;
				}

				/* Traverse arggiven list to check if a non-default parameter is not supplied. */
				for (pp = numposargs; pp < first_arg_with_default; pp++)
				{
					if (arggiven[pp])
						continue;
					else
					{
						ereport(ERROR,
								(errcode(ERRCODE_UNDEFINED_FUNCTION),
								 errmsg("%s %s expects parameter \"%s\", which was not supplied.", obj_type, NameListToString(names), p_argnames[pp])),
								 parser_errposition(pstate, location));
					}
				}
				/* Default arguments are also supplied but parameter name is unknown. */
				if((nargs > first_arg_with_default) && first_unknown_argname)
				{
					ereport(ERROR,
							(errcode(ERRCODE_UNDEFINED_FUNCTION),
							 errmsg("\"%s\" is not an parameter for %s %s.", first_unknown_argname, obj_type, NameListToString(names))),
							 parser_errposition(pstate, location));
				}
				/* Still no issue with the arguments provided, possibly data-type mistmatch. */
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_FUNCTION),
						 errmsg("The %s %s is found but cannot be used. Possibly due to datatype mismatch and implicit casting is not allowed.", obj_type, NameListToString(names))),
						 parser_errposition(pstate, location));
			}
			else if(nargs > 0) /* proargnames is NULL. Procedure/function has no parameters but arguments are specified. */
			{
				ereport(ERROR,
						(errcode(ERRCODE_UNDEFINED_FUNCTION),
						 errmsg("%s %s has no parameters and arguments were supplied.", obj_type, NameListToString(names))),
						 parser_errposition(pstate, location));
			}	
		}
		ReleaseSysCache(tup);
	}
}