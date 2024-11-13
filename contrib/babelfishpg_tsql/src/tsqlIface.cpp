#include <algorithm>
#include <functional>
#include <iostream>
#include <strstream>
#include <string>
#include <unordered_map>

#pragma GCC diagnostic ignored "-Wattributes"

#include "antlr4-runtime.h" // antlr4-cpp-runtime
#include "tree/ParseTreeWalker.h" // antlr4-cpp-runtime
#include "tree/ParseTreeProperty.h" // antlr4-cpp-runtime

#include "../antlr/antlr4cpp_generated_src/TSqlLexer/TSqlLexer.h"
#include "../antlr/antlr4cpp_generated_src/TSqlParser/TSqlParser.h"
#include "../antlr/antlr4cpp_generated_src/TSqlParser/TSqlParserBaseListener.h"
#include "tsqlIface.hpp"

#define LOOP_JOIN_HINT 0
#define HASH_JOIN_HINT 1
#define MERGE_JOIN_HINT 2
#define LOOP_QUERY_HINT 3
#define HASH_QUERY_HINT 4
#define MERGE_QUERY_HINT 5
#define JOIN_HINTS_INFO_VECTOR_SIZE 6

#define RAISE_ERROR_PARAMS_LIMIT 20
#define PUBLIC_ROLE_NAME "public"


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wregister"
extern "C" {
#if 0
#include "tsqlNodes.h"
#else
#include "pltsql.h"
#include "pltsql-2.h"
#include "pl_explain.h"
#include "session.h"
#include "multidb.h"

#include "catalog/namespace.h"
#include "catalog/pg_proc.h"
#include "parser/scansup.h"

#include "guc.h"

#endif

#ifdef LOG // maybe already defined in elog.h, which is conflicted with grammar token LOG
#undef LOG
#endif
}
#pragma GCC diagnostic pop

using namespace std;
using namespace antlr4;
using namespace tree;

extern "C"
{
	ANTLR_result antlr_parser_cpp(const char *sourceText);

	void report_antlr_error(ANTLR_result result);

	extern PLtsql_type *parse_datatype(const char *string, int location);
	extern bool is_tsql_text_ntext_or_image_datatype(Oid oid);

	extern int CurrentLineNumber;

	extern int pltsql_curr_compile_body_position;
	extern int pltsql_curr_compile_body_lineno;

	extern bool pltsql_dump_antlr_query_graph;
	extern bool pltsql_enable_antlr_detailed_log;
	extern bool pltsql_enable_sll_parse_mode;

	extern bool pltsql_enable_tsql_information_schema;

	extern char *column_names_to_be_delimited[];
	extern char *pg_reserved_keywords_to_be_delimited[];

	extern size_t get_num_column_names_to_be_delimited();
	extern size_t get_num_pg_reserved_keywords_to_be_delimited();
	extern char * construct_unique_index_name(char *index_name, char *relation_name);
	extern bool enable_hint_mapping;
	extern bool check_fulltext_exist(const char *schema_name, const char *table_name);

	extern int escape_hatch_showplan_all;

	/* To store the time spent in ANTLR parsing for the current batch */
	extern instr_time antlr_parse_time;
}

static void toDotRecursive(ParseTree *t, const std::vector<std::string> &ruleNames, const std::string &sourceText);
class tsqlBuilder;
class PLtsql_expr_query_mutator;
class tsqlSelectStatementMutator;

// helper template function to get certain token from given context.
// use template here because there is no mid-level base class for similar contexts.
template <class T>
using GetTokenFunc = std::function <antlr4::tree::TerminalNode * (T)>;
template <class T>
using GetCtxFunc = std::function <ParserRuleContext * (T)>;

void handleBatchLevelStatement(TSqlParser::Batch_level_statementContext *ctx, tsqlSelectStatementMutator *ssm);
bool handleITVFBody(TSqlParser::Func_body_return_select_bodyContext *body);

PLtsql_stmt_block *makeEmptyBlockStmt(int lineno);

PLtsql_stmt *makeCfl(TSqlParser::Cfl_statementContext *ctx, tsqlBuilder &builder);
PLtsql_stmt *makeSQL(ParserRuleContext *ctx);
std::vector<PLtsql_stmt *> makeAnother(TSqlParser::Another_statementContext *ctx, tsqlBuilder &builder);
PLtsql_stmt *makeExecBodyBatch(TSqlParser::Execute_body_batchContext *ctx);
PLtsql_stmt *makeExecuteProcedure(ParserRuleContext *ctx, std::string call_type);
PLtsql_stmt *makeInsertBulkStatement(TSqlParser::Dml_statementContext *ctx);
PLtsql_stmt *makeDbccCheckidentStatement(TSqlParser::Dbcc_statementContext *ctx);
PLtsql_stmt *makeSetExplainModeStatement(TSqlParser::Set_statementContext *ctx, bool is_explain_only);
PLtsql_expr *makeTsqlExpr(const std::string &fragment, bool addSelect);
PLtsql_expr *makeTsqlExpr(ParserRuleContext *ctx, bool addSelect);
PLtsql_stmt	*makeCreateFulltextIndexStmt(TSqlParser::Create_fulltext_indexContext *ctx);
PLtsql_stmt	*makeDropFulltextIndexStmt(TSqlParser::Drop_fulltext_indexContext *ctx);
std::pair<std::string, std::string> getTableNameAndSchemaName(TSqlParser::Table_nameContext* ctx);
void * makeBlockStmt(ParserRuleContext *ctx, tsqlBuilder &builder);
void replaceTokenStringFromQuery(PLtsql_expr* expr, TerminalNode* tokenNode, const char* repl, ParserRuleContext *baseCtx);
void replaceCtxStringFromQuery(PLtsql_expr* expr, ParserRuleContext *ctx, const char *repl, ParserRuleContext *baseCtx);
void removeTokenStringFromQuery(PLtsql_expr* expr, TerminalNode* tokenNode, ParserRuleContext *baseCtx);
void removeCtxStringFromQuery(PLtsql_expr* expr, ParserRuleContext *ctx, ParserRuleContext *baseCtx);
void extractQueryHintsFromOptionClause(TSqlParser::Option_clauseContext *octx);
void extractTableHints(TSqlParser::With_table_hintsContext *tctx, std::string table_name);
std::string extractTableName(TSqlParser::Ddl_objectContext *ctx, TSqlParser::Table_source_itemContext *tctx);
std::string extractSchemaName(TSqlParser::Ddl_objectContext *ctx, TSqlParser::Table_source_itemContext *tctx);
void extractTableHint(TSqlParser::Table_hintContext *table_hint, std::string table_name);
void extractJoinHint(TSqlParser::Join_hintContext *join_hint, std::string table_name1, std::string table_names);
void extractJoinHintFromOption(TSqlParser::OptionContext *option);
std::string extractIndexValues(std::vector<TSqlParser::Index_valueContext *> index_valuesCtx, std::string table_name);

static void *makeBatch(TSqlParser::Tsql_fileContext *ctx, tsqlBuilder &builder);

static void process_execsql_destination(TSqlParser::Dml_statementContext *ctx, PLtsql_stmt_execsql *stmt);
static void process_execsql_remove_unsupported_tokens(TSqlParser::Dml_statementContext *ctx, PLtsql_expr_query_mutator *exprMutator);
static bool post_process_create_table(TSqlParser::Create_tableContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx);
static bool post_process_alter_table(TSqlParser::Alter_tableContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx);
static bool post_process_create_index(TSqlParser::Create_indexContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx);
static bool post_process_create_database(TSqlParser::Create_databaseContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx);
static bool post_process_create_type(TSqlParser::Create_typeContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx);
static void post_process_table_source(TSqlParser::Table_source_itemContext *ctx, PLtsql_expr *expr, ParserRuleContext *baseCtx, bool is_freetext_predicate = false);
static void post_process_declare_cursor_statement(PLtsql_stmt_decl_cursor *stmt, TSqlParser::Declare_cursorContext *ctx, tsqlBuilder &builder);
static void post_process_declare_table_statement(PLtsql_stmt_decl_table *stmt, TSqlParser::Table_type_definitionContext *ctx);
static bool check_freetext_predicate(TSqlParser::Search_conditionContext *ctx);
static PLtsql_var *lookup_cursor_variable(const char *varname);
static PLtsql_var *build_cursor_variable(const char *curname, int lineno);
static int read_extended_cursor_option(TSqlParser::Declare_cursor_optionsContext *ctx, int current_cursor_option);
static PLtsql_stmt *makeDeclTableStmt(PLtsql_variable *var, PLtsql_type *type, int lineno);
static void *makeReturnQueryStmt(TSqlParser::Select_statement_standaloneContext *ctx, bool itvf);
static PLtsql_stmt *makeSpStatement(const std::string& sp_name, TSqlParser::Execute_statement_argContext *sp_args, int lineno, int return_code_dno);
static void makeSpParams(TSqlParser::Execute_statement_argContext *ctx, std::vector<tsql_exec_param *> &params);
static tsql_exec_param *makeSpParam(TSqlParser::Execute_statement_arg_namedContext *ctx);
static tsql_exec_param *makeSpParam(TSqlParser::Execute_statement_arg_unnamedContext *ctx);
static int getVarno(tree::TerminalNode *localID);
static int check_assignable(tree::TerminalNode *localID);
static void check_dup_declare(const char *name);
static bool is_sp_proc(const std::string& func_proc_name);
static bool string_matches(const char *str, const char *pattern);
static void check_param_type(tsql_exec_param *param, bool is_output, Oid typoid, const char *param_str);
static PLtsql_expr *getNthParamExpr(std::vector<tsql_exec_param *> &params, size_t n);
static const char* rewrite_assign_operator(tree::TerminalNode *aop);
TSqlParser::Query_specificationContext *get_query_specification(TSqlParser::Select_statementContext *sctx);
static bool is_top_level_query_specification(TSqlParser::Query_specificationContext *ctx);
static bool is_quotation_needed_for_column_alias(TSqlParser::Column_aliasContext *ctx);
static bool is_compiling_create_function();
static void process_query_specification(TSqlParser::Query_specificationContext *qctx, PLtsql_expr_query_mutator *mutator);
static void process_select_statement(TSqlParser::Select_statementContext *selectCtx, PLtsql_expr_query_mutator *mutator);
static void process_select_statement_standalone(TSqlParser::Select_statement_standaloneContext *standaloneCtx, PLtsql_expr_query_mutator *mutator, tsqlBuilder &builder);
template <class T> static std::string rewrite_object_name_with_omitted_db_and_schema_name(T ctx, GetCtxFunc<T> getDatabase, GetCtxFunc<T> getSchema);
template <class T> static std::string rewrite_information_schema_to_information_schema_tsql(T ctx, GetCtxFunc<T> getSchema);
template <class T> static std::string rewrite_column_name_with_omitted_schema_name(T ctx, GetCtxFunc<T> getSchema, GetCtxFunc<T> getTableName);
template <class T> static void rewrite_geospatial_query_helper(T ctx, TSqlParser::Method_callContext *method, size_t geospatial_start_index);
template <class T> static void rewrite_geospatial_col_ref_query_helper(T ctx, TSqlParser::Method_callContext *method, size_t geospatial_start_index);
template <class T> static void rewrite_geospatial_func_ref_no_arg_query_helper(T ctx, TSqlParser::Method_callContext *method, size_t geospatial_start_index);
template <class T> static void rewrite_geospatial_func_ref_args_query_helper(T ctx, TSqlParser::Method_callContext *method, size_t geospatial_start_index);
template <class T> static void rewrite_function_call_geospatial_func_ref_args(T ctx);
template <class T> static void rewrite_function_call_geospatial_func_ref_no_arg(T ctx);
static void handleGeospatialFunctionsInFunctionCall(TSqlParser::Function_callContext *ctx);
static void handleClrUdtFuncCall(TSqlParser::Clr_udt_func_callContext *ctx);
static void handleFullColumnNameCtx(TSqlParser::Full_column_nameContext *ctx);
template <class T> static void handleLocalIdQuotingFuncRefNoArg(T ctx, size_t geospatial_start_index, int &offset1, std::string &expr, std::vector<size_t> keysToRemove);
static bool does_object_name_need_delimiter(TSqlParser::IdContext *id);
static std::string delimit_identifier(TSqlParser::IdContext *id);
static bool does_msg_exceeds_params_limit(const std::string& msg);
static std::string getIDName(TerminalNode *dq, TerminalNode *sb, TerminalNode *id);
static ANTLR_result antlr_parse_query(const char *sourceText, bool useSSLParsing);
std::string rewriteDoubleQuotedString(const std::string strDoubleQuoted);
std::string escapeDoubleQuotes(const std::string strWithDoubleQuote);
static bool in_execute_body_batch = false;	
static bool in_execute_body_batch_parameter = false;	
static const std::string fragment_SELECT_prefix = "SELECT "; // fragment prefix for expressions
static const std::string fragment_EXEC_prefix   = "EXEC ";   // fragment prefix for execute_body_batch
static PLtsql_stmt *makeChangeDbOwnerStatement(TSqlParser::Alter_authorizationContext *ctx);
static void handleFloatWithoutExponent(TSqlParser::ConstantContext *ctx); 
static void handleTableConstraintWithoutComma(TSqlParser::Column_def_table_constraintsContext *ctx);
static void handleBitNotOperator(TSqlParser::Unary_op_exprContext *ctx);
static void handleBitOperators(TSqlParser::Plus_minus_bit_exprContext *ctx);
static void handleModuloOperator(TSqlParser::Mult_div_percent_exprContext *ctx);
static void handleAtAtVarInPredicate(TSqlParser::PredicateContext *ctx);
static void handleOrderByOffsetFetch(TSqlParser::Order_by_clauseContext *ctx);
static void rewrite_function_trim_to_sys_trim(TSqlParser::TRIMContext *ctx);

/*
 * Structure / Utility function for general purpose of query string modification
 *
 * The difficulty of query string modification is that, upper-level general grammar (i.e. dml_clause, ddl_clause, ...)
 * actaully creates PLtsql_stmt but logic of query modification is available in low-level fine-grained grammar (i.e. full_object_name, select_list, ...)
 * We can't modify the query string in enter/exit function of low-evel grammar because it may append query string in middle of query
 * so it may lead to inconsistency between query string and token index information obtained from ANTLR parser.
 * (i.e. if we rewrite "SELECT 'a'=1 from T" to "SELECT 1 as 'a' FROM T", T appears poisition 22 after rewriting but ANTLR token still keeps position 19)
 *
 * To resolve this issue, each low-level grammar just register rewritten-query-fragement to a map (rewritten_query_fragment)
 * and all the rewriting will be done by upper-level grammar rule at once by using PLtsql_expr_query_mutator
 *
 * Here is general code snippet (but different patterns in specific query statement like itvf, batch-level statement)
 *
 * void enterUpperLevelGrammar() { // DML, DDL, ...
 *   ...
 *   clear_rewritten_query_fragment(); // clean-up before collecting rewriting information
 * }
 *
 * void exitLowLevelGrammar() { // fine-grained grammar needs actual rewirting
 *   ...
 *   // register rewritten query
 *   rewritten_query_fragment.emplace(std::make_pair(original_string_position, std::make_pair(original_string, rewritten_string));
 * }
 *
 * void exitUpperLevelGrammar() {
 *   ...
 *   PLtsql_expr* expr = ...; acutal payload query string for PLtsql_stmt;
 *   PLtsql_expr_query_mutator mutator(expr, ctx);
 *
 *   add_rewritten_query_fragment_to_mutator(&mutator); // move information of rewritten_query_fragment to mutator.
 *
 *   mutator.run(); // expr->query will be rewitten here
 *   clear_rewritten_query_fragment();
 * }
 */

// general-purpose map to store query fragement which needs to be rewritten
// intentionally use std::map to access positions by sorted order.
// global object is enough because no nesting is expected.
static std::map<size_t, pair<std::string, std::string>> rewritten_query_fragment;

// Keeping poisitions of local_ids to quote them.
// local_id can be rewritten in differeny way in some cases (itvf), don't use rewritten_query_fragment.
// TODO: incorporate local_id_positions with rewritten_query_fragment
static std::map<size_t, std::string> local_id_positions;

// should be called before visiting subclause to make PLtsql_stmt.
static void clear_rewritten_query_fragment();

// add information of rewritten_query_fragment information to mutator
static void add_rewritten_query_fragment_to_mutator(PLtsql_expr_query_mutator *mutator);

static std::unordered_map<std::string, std::string> alias_to_table_mapping;
static std::unordered_map<std::string, std::string> table_to_alias_mapping;
static std::vector<std::string> query_hints;
static std::vector<bool> join_hints_info(JOIN_HINTS_INFO_VECTOR_SIZE, false);
static bool isJoinHintInOptionClause = false;
static std::string table_names;
static int num_of_tables = 0;
static std::string leading_hint;

static void add_query_hints(PLtsql_expr_query_mutator *mutator, int contextOffset);
static void clear_query_hints();
static void clear_tables_info();

static std::string validate_and_stringify_hints();
static int find_hint_offset(const char * queryTxt);

static bool pltsql_parseonly = false;
bool has_identity_function = false;

static void
breakHere()
{

}

std::string
getFullText(ParserRuleContext *context, misc::Interval range)
{
	if (context == nullptr)
		return" ";

	return context->start->getInputStream()->getText(range);
}

std::string
getFullText(ParserRuleContext *context)
{
	if (context == nullptr)
		return "";
  
	if (context->start == nullptr || context->stop == nullptr || context->start->getStartIndex() < 0 || context->stop->getStopIndex() < 0)
		return context->getText();

	return getFullText(context, misc::Interval(context->start->getStartIndex(), context->stop->getStopIndex()));
}

template <class T>
std::string
getFullText(std::vector<T*> const &contexts)
{
	auto beg = contexts[0];
	auto end = contexts[contexts.size() - 1];

	misc::Interval textRange(beg->start->getStartIndex(), end->stop->getStopIndex());

	return getFullText(contexts[0], textRange);
}

std::string
getFullText(TerminalNode *node)
{
	return node->getText();
}

std::string
getFullText(Token* token)
{
	return token->getText();
}

std::string
stripQuoteFromId(TSqlParser::IdContext *ctx)
{
	if (ctx->DOUBLE_QUOTE_ID())
	{
		std::string val = getFullText(ctx->DOUBLE_QUOTE_ID());
		Assert(val.length() >= 2);
		return val.substr(1, val.length()-2);
	}
	else if (ctx->SQUARE_BRACKET_ID())
	{
		std::string val = getFullText(ctx->SQUARE_BRACKET_ID());
		Assert(val.length() >= 2);
		return val.substr(1, val.length()-2);
	}
	return getFullText(ctx);
}

static int
get_curr_compile_body_lineno_adjustment()
{
	if (!pltsql_curr_compile || pltsql_curr_compile->fn_oid == InvalidOid) /* not in a func/proc body */
		return 0;
	if (pltsql_curr_compile_body_lineno == 0) /* not set */
		return 0;
	return pltsql_curr_compile_body_lineno - 1; /* minus 1 for correct adjustment */
}

int getLineNo(ParserRuleContext *ctx)
{
	if (!ctx)
		return 0;

	/*
	 * in T-SQL, line number is relative to batch start of CREATE FUNCTION/PROCEDURE/...
	 * if we're running in CREATE FUNCTION/PROCEDURE/..., add a offset lineno.
	 */
	int lineno_offset = get_curr_compile_body_lineno_adjustment();
	Token *startToken = ctx->getStart();
	if (!startToken)
		return 0;
	return startToken->getLine() + lineno_offset;
}

int getLineNo(TerminalNode* node)
{
	if (!node)
		return 0;

	/*
	 * in T-SQL, line number is relative to batch start of CREATE FUNCTION/PROCEDURE/...
	 * if we're running in CREATE FUNCTION/PROCEDURE/..., add a offset lineno.
	 */
	int lineno_offset = get_curr_compile_body_lineno_adjustment();
	Token *symbol = node->getSymbol();
	if (!symbol)
		return 0;
	return symbol->getLine() + lineno_offset;
}

static int
get_curr_compile_body_position_adjustment()
{
	if (!pltsql_curr_compile || pltsql_curr_compile->fn_oid == InvalidOid) /* not in a func/proc body */
		return 0;
	if (pltsql_curr_compile_body_position == 0) /* not set */
		return 0;
	return pltsql_curr_compile_body_position - 1; /* minus 1 for correct adjustment */
}

int getPosition(ParserRuleContext *ctx)
{
	if (!ctx)
		return 0;

	/* if we're running in CREATE FUNCTION/PROCEDURE/..., add a offset position. */
	int position_offset = get_curr_compile_body_position_adjustment();
	Token *startToken = ctx->getStart();
	if (!startToken)
		return 0;
	return startToken->getStartIndex() + position_offset;
}

int getPosition(TerminalNode* node)
{
	if (!node)
		return 0;

	/* if we're running in CREATE FUNCTION/PROCEDURE/..., add a offset position. */
	int position_offset = get_curr_compile_body_position_adjustment();
	Token *symbol = node->getSymbol();
	if (!symbol)
		return 0;
	return symbol->getStartIndex() + position_offset;
}

std::pair<int,int> getLineAndPos(ParserRuleContext *ctx)
{
	return std::make_pair(getLineNo(ctx), getPosition(ctx));
}

std::pair<int,int> getLineAndPos(TerminalNode *node)
{
	return std::make_pair(getLineNo(node), getPosition(node));
}

static ParseTreeProperty<PLtsql_stmt *> fragments;

// Keeps track of location of expressions being rewritten into a fragment 'SELECT <expr>'
static std::map<ParseTree *,  std::pair<int, std::pair<int, int>>> selectFragmentOffsets;
	
// Record the offsets for a 'SELECT <expr>' fragment
void
recordSelectFragmentOffsets(ParseTree *ctx, int ixStart, int ixEnd, int ixShift)
{
	Assert(ctx);	
	selectFragmentOffsets.emplace(std::make_pair(ctx, std::make_pair(ixStart, std::make_pair(ixEnd, ixShift))));		
}	

void 
recordSelectFragmentOffsets(ParseTree *ctx, ParserRuleContext *expr)
{
	Assert(ctx);
	Assert(expr);
	recordSelectFragmentOffsets(ctx, expr->getStart()->getStartIndex(), expr->getStop()->getStopIndex(), 0);		
}

void
attachPLtsql_fragment(ParseTree *node, PLtsql_stmt *fragment)
{
	if (fragment)
	{
		const char *tsqlDesc = pltsql_stmt_typename(fragment);

		if (pltsql_enable_antlr_detailed_log)
			std::cout << "    attachPLtsql_fragment(" << (void *) node << ", " << fragment << "[" << tsqlDesc << "])" << std::endl;
		fragments.put(node, fragment);
	}
	else
	{
		if (pltsql_enable_antlr_detailed_log)
			std::cout << "    attachPLtsql_fragment(" << (void *) node << ", " << fragment << "<NULL>)" << std::endl;
	}
}

PLtsql_stmt *
getPLtsql_fragment(ParseTree *node)
{
	if (pltsql_enable_antlr_detailed_log)
		std::cout << "getPLtsql_fragment(" << (void *) node << ") returns " << fragments.get(node) << std::endl;
	return fragments.get(node);
}

static List *rootInitializers = NIL;

FormattedMessage
format_errmsg(const char *fmt, const char *arg0)
{
	FormattedMessage fm;
	fm.fmt = fmt;

	MemoryContext oldContext = MemoryContextSwitchTo(CurTransactionContext);
	fm.args.push_back(pstrdup(arg0));
	MemoryContextSwitchTo(oldContext);

	return fm;
}

FormattedMessage
format_errmsg(const char *fmt, int64_t arg0)
{
	FormattedMessage fm;
	fm.fmt = fmt;
	fm.args.push_back(reinterpret_cast<void*>(arg0));
	return fm;
}

template <typename... Types>
FormattedMessage
format_errmsg(const char *fmt, const char *arg1, Types... args)
{
	FormattedMessage fm = format_errmsg(fmt, args...);
	fm.args.insert(fm.args.begin(), pstrdup(arg1)); // push_front
	return fm;
}

template <typename... Types>
FormattedMessage
format_errmsg(const char *fmt, int64_t arg1, Types... args)
{
	FormattedMessage fm = format_errmsg(fmt, args...);
	fm.args.insert(fm.args.begin(), reinterpret_cast<void*>(arg1)); // push_front
	return fm;
}

// currently, format_errmsg with more than 1 args is not used in this file but tsqlUnsupportedHandler uses it.
// use explicit instantiation here to make compiler forcefully create that template functions.
template
FormattedMessage
format_errmsg(const char *fmt, const char *arg1, const char *arg2);

inline std::u32string utf8_to_utf32(const char* s)
{
	return antlrcpp::utf8_to_utf32(s, s + strlen(s));
}

class MyInputStream : public ANTLRInputStream
{
public:
    MyInputStream(const char *src)
	: ANTLRInputStream((string)src)
    {

    }
    
		void setText(size_t pos, const char *newText)
		{
			UTF32String	newText32 = utf8_to_utf32(newText);

			_data.replace(pos, newText32.size(), newText32);
		}
};

class PLtsql_expr_query_mutator
{
public:
	PLtsql_expr_query_mutator(PLtsql_expr *expr, ParserRuleContext* baseCtx);

	void add(int antlr_pos, std::string orig_text, std::string repl_text);
	void markSelectFragment(ParserRuleContext *ctx);

	void run();

	PLtsql_expr *expr;
	ParserRuleContext* ctx;

protected:
	// intentionally use std::map to iterate it via sorted order.
	std::map<int, std::pair<std::string, std::string>> m; // pos -> (orig_text, repl_text)
		
	int base_idx;		
		
	// Indicate the fragment being processed is an expression that was prefixed with 'SELECT ', 
	// so that offsets can be adjusted when doing the rewriting
	bool isSelectFragment = false;
	int idxStart = 0;
	int idxEnd = 0;
	int idxStartShift = 0;
};

PLtsql_expr_query_mutator::PLtsql_expr_query_mutator(PLtsql_expr *e, ParserRuleContext* baseCtx)
	: expr(e)
	, ctx(baseCtx)
	, base_idx(-1)
{
	if (!e)
		throw PGErrorWrapperException(ERROR, ERRCODE_INTERNAL_ERROR, "can't mutate an internal query. NULL expression", getLineAndPos(baseCtx));

	size_t base_index = baseCtx->getStart()->getStartIndex();
			
	if (base_index == INVALID_INDEX)
		throw PGErrorWrapperException(ERROR, ERRCODE_INTERNAL_ERROR, "can't mutate an internal query. base index is invalid", getLineAndPos(baseCtx));
	base_idx = base_index;
	isSelectFragment = false;
}

void PLtsql_expr_query_mutator::markSelectFragment(ParserRuleContext *ctx)	
{
	Assert(ctx);
	Assert(selectFragmentOffsets.count(ctx) > 0);

	auto p = selectFragmentOffsets.at(ctx);
	
	isSelectFragment = true;
	idxStart = p.first;
	idxEnd = p.second.first;
	idxStartShift = p.second.second;
}

void PLtsql_expr_query_mutator::add(int antlr_pos, std::string orig_text, std::string repl_text)
{
	int offset = antlr_pos - base_idx;
	
	if (isSelectFragment) 
	{
		// For SELECT fragments, only apply the item when antlr_pos is between idxStart and idxEnd:
		// when there are multiple expressions per statement (only for DECLARE), the rewrites must be 
		// applied to the correct expression
		if ((antlr_pos < idxStart) || (antlr_pos > idxEnd)) 
		{
			return;
		}

		// Adjust offset to reflect the fact that the expression in the fragment is now prefixed with only 'SELECT '
		offset = antlr_pos - idxStart;
			
		// Adjust offset once more if the expression was shifted left (for a compound SET @v operator)
		if (idxStartShift > 0) 
		{
			offset = offset + idxStartShift;
		}					
	}	
						
	if (!orig_text.empty() && (orig_text.front() == '"') && (orig_text.back() == '"') && !repl_text.empty() && (repl_text.front() == '\'') && (repl_text.back() == '\'')) 
	{
		// Do not validate the positions of strings as these are not replaced by their positions
	}
	else {
		/* validation check */
		if (offset < 0)
			throw PGErrorWrapperException(ERROR, ERRCODE_INTERNAL_ERROR, "can't mutate an internal query. offset value is negative", 0, 0);
		if (offset > (int)strlen(expr->query))
			throw PGErrorWrapperException(ERROR, ERRCODE_INTERNAL_ERROR, "can't mutate an internal query. offset value is too large", 0, 0);
	}

	m.emplace(std::make_pair(offset, std::make_pair(orig_text, repl_text)));
}

void PLtsql_expr_query_mutator::run()
{
	/*
	 * ANTLR parser converts all input to std::u32string (utf-32 string) internally and runs the lexer/parser on that.
	 * This indicates that Token position is based on character position not a byte offset.
	 * To rewrite query based on token position, we have to convert a query string to std::u32string first
	 * so that offset should indicate a correct position to be replaced.
	 */
	if (m.size() == 0) return;  // nothing to do
		
	std::u32string query = utf8_to_utf32(expr->query);
	std::u32string rewritten_query;
			
	size_t cursor = 0; // cursor to expr->query where next copy should start
	for (const auto &entry : m)
	{		
		size_t offset = entry.first;
		const std::u32string& orig_text = utf8_to_utf32(entry.second.first.c_str());
		const std::u32string& repl_text = utf8_to_utf32(entry.second.second.c_str());
		if (isSelectFragment) offset += fragment_SELECT_prefix.length(); // because this is an expression prefixed with 'SELECT '
					
		if (orig_text.length() == 0 || orig_text.c_str(), query.substr(offset, orig_text.length()) == orig_text) // local_id maybe already deleted in some cases such as select-assignment. check here if it still exists)
		{
			// Note: the test below does not work, and has never worked, because size_t will not be negative, 
			// and the result of the subtraction is also of type size_t.
			// This test has been in the code since day 1. 
			// When making the test work, some test cases will start failing as they run into this condition 
			// (test table_variable_xact_errors and two variants). Therefore, not touching the test for now.
			if (offset - cursor < 0)
				throw PGErrorWrapperException(ERROR, ERRCODE_INTERNAL_ERROR, "can't mutate an internal query. might be due to multiple mutations on the same position", 0, 0);
			if (offset - cursor > 0) // if offset==cursor, no need to copy
				rewritten_query += query.substr(cursor, offset - cursor); // copy substring of expr->query. ranged [cursor, offset)
			rewritten_query += repl_text;
			cursor = offset + orig_text.length();
		}
	}
	if (cursor < strlen(expr->query))
		rewritten_query += query.substr(cursor); // copy remaining expr->query
		
	// update query string
	std::string new_query = antlrcpp::utf32_to_utf8(rewritten_query);
	expr->query = pstrdup(new_query.c_str());
}

static void
clear_rewritten_query_fragment()
{
	rewritten_query_fragment.clear();
	local_id_positions.clear();
}

static void
add_rewritten_query_fragment_to_mutator(PLtsql_expr_query_mutator *mutator)
{
	Assert(mutator);
	for (auto &entry : rewritten_query_fragment)
		mutator->add(entry.first, entry.second.first, entry.second.second);
}

static void
add_query_hints(PLtsql_expr_query_mutator *mutator, int contextOffset)
{
	std::string hint = validate_and_stringify_hints();
	int baseOffset = mutator->ctx->start->getStartIndex();
	int queryOffset = contextOffset - baseOffset;
	int initialTokenOffset = find_hint_offset(&mutator->expr->query[queryOffset]);
	mutator->add(contextOffset + initialTokenOffset, "", hint);
}

static std::string
validate_and_stringify_hints()
{
	ParserRuleContext* ctx = nullptr;
	// If a query has both join hint and query hint which is a join hint, it should have all the join hints as the query hints as well
	if (isJoinHintInOptionClause && ((join_hints_info[LOOP_JOIN_HINT] && !join_hints_info[LOOP_QUERY_HINT]) || (join_hints_info[HASH_JOIN_HINT] && !join_hints_info[HASH_QUERY_HINT]) || (join_hints_info[MERGE_JOIN_HINT] && !join_hints_info[MERGE_QUERY_HINT])))
	{
		clear_query_hints();
		clear_tables_info();
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Conflicting JOIN optimizer hints specified", getLineAndPos(ctx));
	}
	std::string hint =  "/*+ ";
	for (auto q_hint: query_hints)
	{
		hint += q_hint;
		hint += " ";
	}
	if (!leading_hint.empty())
		hint += leading_hint;
	hint += "*/";
	transform(hint.begin(), hint.end(), hint.begin(), ::tolower);

	return hint;
}

static int
find_hint_offset(const char *query)
{
	std::string queryString(query);
	size_t spaceIdx = queryString.find_first_of(" \t\n\v\f\r");
	size_t commentStartIdx = queryString.find("/*");

	//if there is no space and no comment default to beginning of statement
	if (commentStartIdx == std::string::npos && spaceIdx == std::string::npos)
		return 0;

	//if no comment return spaceIdx
	if (commentStartIdx == std::string::npos && spaceIdx < INT_MAX)
		return static_cast<int>(spaceIdx);

	//if no space return comment
	if (spaceIdx == std::string::npos && commentStartIdx < INT_MAX)
		return static_cast<int>(commentStartIdx);

	//if both comments and space return the index of the smaller.
	if (commentStartIdx != std::string::npos && spaceIdx != std::string::npos) {
		size_t smallest = min(spaceIdx, commentStartIdx);
		if (smallest < INT_MAX)
			return static_cast<int>(smallest);
	}
	return 0;
}

static void
clear_query_hints()
{
	query_hints.clear();
	leading_hint.clear();
	for (size_t i=0; i<JOIN_HINTS_INFO_VECTOR_SIZE; i++)
		join_hints_info[i] = false;
	isJoinHintInOptionClause = false;
}

static void
clear_tables_info()
{
	table_names.clear();
	alias_to_table_mapping.clear();
	table_to_alias_mapping.clear();
	num_of_tables = 0;
}

/*
 * NOTE: Currently there exist several similar mutator for historical reasons.
 * tsqlMutator is the first invented one, which modifies input stream directly.
 * However it has a limiation that rewritten fragment string should be shorter than
 * original string.
 * tsqlBuilder's main role is to create PLtsql_stmt_*. But, many query rewriting
 * logic was also added here because it already had a listner implementation.
 * To overcomse the limitation of tsqlBuilder, query fragment rewriting was invented
 * (please see the comment on rewritten_query_fragment).
 * tsqlSelectMuator was introduced to cover corner cases such as CREATE-VIEW and DECLARE-CURSOR
 * which need to deal with inner SELECT statement.
 * tsqlCommonMutator was added to cover a rewriting logic which needs to be applied in
 * batch-level statement and normal statement.
 *
 * TODO:
 * The plan is to incorporate all rewriting logics to tsqlCommonMutator. Other
 * mutators will be deprecated and existing query rewriting logics in tsqlBuilder
 * will be also moved. tsqlBuilder will focus on create Pltsql_stmt_* only.
 */

////////////////////////////////////////////////////////////////////////////////
// tsql Common Mutator
////////////////////////////////////////////////////////////////////////////////
class tsqlCommonMutator : public TSqlParserBaseListener
{
	/* see comment above. */
public:
	explicit tsqlCommonMutator() = default;
	bool in_create_or_alter_function = false;

	void enterCreate_or_alter_function(TSqlParser::Create_or_alter_functionContext *ctx) override {
		in_create_or_alter_function = true;
	}

	void exitCreate_or_alter_function(TSqlParser::Create_or_alter_functionContext *ctx) override {
		in_create_or_alter_function = false;
	}

	void enterTransaction_statement(TSqlParser::Transaction_statementContext *ctx) override {
		if (in_create_or_alter_function && ctx->COMMIT()){
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'COMMIT TRANSACTION' within a function.", 0, 0);
		}
		if (in_create_or_alter_function && ctx->ROLLBACK()){
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'ROLLBACK TRANSACTION' within a function.", 0, 0);
		}
		if (in_create_or_alter_function && ctx->SAVE()){
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'SAVEPOINT' within a function.", 0, 0);
		}
	}

	void enterPrint_statement(TSqlParser::Print_statementContext *ctx) override { 
		if (in_create_or_alter_function && ctx->PRINT()){
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'PRINT' within a function.", 0, 0);
		}
	}
	void enterRaiseerror_statement(TSqlParser::Raiseerror_statementContext * ctx) override { 
		if (in_create_or_alter_function && ctx->RAISERROR()){
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'RAISERROR' within a function.", 0, 0);
		}
	}

	void enterExecute_statement(TSqlParser::Execute_statementContext *ctx) override {
		if (in_create_or_alter_function && (ctx->EXEC() || ctx->EXECUTE())){
			TSqlParser::Execute_bodyContext *body = ctx->execute_body();
			if (body->LR_BRACKET())
			{
				std::vector<TSqlParser::Execute_var_stringContext *> exec_strings = body->execute_var_string();
				if (!exec_strings.empty())
				{
					throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'EXECUTE STRING' within a function.", 0, 0);
				}
				
			}
		}
	}

	void enterWaitfor_statement(TSqlParser::Waitfor_statementContext *ctx) override {
		if (in_create_or_alter_function && ctx->WAITFOR()){
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'WAITFOR' within a function.", 0, 0);
		}
	 }
	 
	void enterWaitfor_receive_statement(TSqlParser::Waitfor_receive_statementContext * ctx) override { 
		if (in_create_or_alter_function && ctx->WAITFOR()){
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'WAITFOR' within a function.", 0, 0);
		}
	}

	void enterKill_statement(TSqlParser::Kill_statementContext *ctx) override {
		if (in_create_or_alter_function){
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Invalid use of a side-effecting operator 'KILL' within a function.", 0, 0);
		}
	}

	/* Column Name */
	void exitSimple_column_name(TSqlParser::Simple_column_nameContext *ctx) override
	{
		if (does_object_name_need_delimiter(ctx->id()))
			rewritten_query_fragment.emplace(std::make_pair(ctx->id()->start->getStartIndex(), std::make_pair(::getFullText(ctx->id()), delimit_identifier(ctx->id()))));
	}

	void exitInsert_column_id(TSqlParser::Insert_column_idContext *ctx) override
	{
		// qualifier and DOT is totally ignored
		for (auto dot : ctx->DOT())
			rewritten_query_fragment.emplace(std::make_pair(dot->getSymbol()->getStartIndex(), std::make_pair(::getFullText(dot), ""))); // remove dot
		for (auto ign : ctx->ignore)
			rewritten_query_fragment.emplace(std::make_pair(ign->start->getStartIndex(), std::make_pair(::getFullText(ign), ""))); // remove ignore

		// qualified identifier doesn't need delimiter
		if (ctx->DOT().empty() && does_object_name_need_delimiter(ctx->id().back()))
			rewritten_query_fragment.emplace(std::make_pair(ctx->id().back()->start->getStartIndex(), std::make_pair(::getFullText(ctx->id().back()), delimit_identifier(ctx->id().back()))));
	}

	void exitFunction_call(TSqlParser::Function_callContext *ctx) override
	{
		handleGeospatialFunctionsInFunctionCall(ctx);

		if (ctx->func_proc_name_server_database_schema())
		{
			auto fpnsds = ctx->func_proc_name_server_database_schema();

			if (fpnsds->DOT().empty() && fpnsds->id().back()->keyword()) /* built-in functions */
			{
				auto id = fpnsds->id().back();

				if (id->keyword()->NULLIF()) /* NULLIF */
				{
					if (ctx->function_arg_list() && !ctx->function_arg_list()->expression().empty())
					{
						auto first_arg = ctx->function_arg_list()->expression().front();
						if (dynamic_cast<TSqlParser::Constant_exprContext*>(first_arg) && static_cast<TSqlParser::Constant_exprContext*>(first_arg)->constant()->NULL_P())
							throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, "The first argument to NULLIF cannot be a constant NULL.", getLineAndPos(first_arg));
					}
				}
				if (id->keyword()->CHECKSUM())
				{
					if (ctx->function_arg_list() && !ctx->function_arg_list()->expression().empty())
					{
						for (auto arg: ctx->function_arg_list()->expression())
						{
							if (dynamic_cast<TSqlParser::Constant_exprContext*>(arg) && static_cast<TSqlParser:: Constant_exprContext*>(arg)->constant()->NULL_P())
								throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, "Argument NULL is invalid for CHECKSUM().", getLineAndPos(arg));
						}
					}
				}
				if (id->keyword()->TRIM() || id->keyword()->REPLACE() || id->keyword()->TRANSLATE() || id->keyword()->SUBSTRING())
				{
					size_t startPosition = id->keyword()->start->getStartIndex();
					rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair("", "sys.")));
				}
			}

			if (ctx->func_proc_name_server_database_schema()->procedure)
			{
				std::string proc_name = stripQuoteFromId(ctx->func_proc_name_server_database_schema()->procedure);
				if (pg_strcasecmp(proc_name.c_str(), "identity") == 0) 
				{
					has_identity_function = true;
				}
				
				if (pg_strcasecmp(proc_name.c_str(), "identity_into_bigint") == 0)
				{
					throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, 
						format_errmsg("function %s does not exist", proc_name.c_str()), getLineAndPos(ctx));
				}
			}
		}
	}

	void exitTRIM(TSqlParser::TRIMContext *ctx) override
	{
		rewrite_function_trim_to_sys_trim(ctx);
	}

	/* We are adding handling for CLR_UDT Types in:
	 * tsqlCommonMutator: for cases CREATE/ALTER View, Procedure, Function
	 */
	void exitClr_udt_func_call(TSqlParser::Clr_udt_func_callContext *ctx) override
	{
		handleClrUdtFuncCall(ctx);
	}

	void exitFull_column_name(TSqlParser::Full_column_nameContext *ctx) override
	{
		handleFullColumnNameCtx(ctx);
	}

	/* Object Name */

	void exitFull_object_name(TSqlParser::Full_object_nameContext *ctx) override
	{
		if (ctx->DOT().size() >= 3 && ctx->server) /* server.db.schema.objname */
		{
			TSqlParser::IdContext *obj_server = ctx->server;
			TSqlParser::IdContext *obj_database = ctx->database;
			TSqlParser::IdContext *obj_schema = ctx->schema;
			TSqlParser::IdContext *obj_name = ctx->object_name;

			std::string full_object_name = ::getFullText(ctx);
			std::string server_name_str;

			if (obj_server->keyword())
				server_name_str = getFullText(obj_server->keyword());
			else
				server_name_str = getIDName(obj_server->DOUBLE_QUOTE_ID(), obj_server->SQUARE_BRACKET_ID(), obj_server->ID());
				
			std::string quoted_server_str = std::string("'") + server_name_str + std::string("'");

			std::string three_part_name = ::getFullText(obj_database) + std::string(".") + ::getFullText(obj_schema) + std::string(".") + ::getFullText(obj_name);

			/*
			 * When we come across a four-part object name, we will replace it with OPENQUERY(). Currently,
			 * we only support four-part object names in read-only context. So, a call like:
			 *
			 *	SELECT col_a, col_b FROM server_name.db_name.schema_name.obj_name
			 *
			 * will be re-written as:
			 *
			 *	SELECT col_a, col_b FROM openquery_internal('server_name', 'SELECT * FROM db_name.schema_name.obj_name')
			 */
			std::string str = std::string("openquery_internal(") + quoted_server_str + std::string(", 'SELECT * FROM ") + three_part_name + std::string("')");

			rewritten_query_fragment.emplace(std::make_pair(obj_server->start->getStartIndex(), std::make_pair(::getFullText(ctx), str)));
		}
		else
		{
			GetCtxFunc<TSqlParser::Full_object_nameContext *> getDatabase = [](TSqlParser::Full_object_nameContext *o) { return o->database; };
			GetCtxFunc<TSqlParser::Full_object_nameContext *> getSchema = [](TSqlParser::Full_object_nameContext *o) { return o->schema; };
			std::string rewritten_name = rewrite_object_name_with_omitted_db_and_schema_name(ctx, getDatabase, getSchema);
			std::string rewritten_schema_name = rewrite_information_schema_to_information_schema_tsql(ctx, getSchema);
			if (!rewritten_name.empty())
				rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(::getFullText(ctx), rewritten_name)));
			if (pltsql_enable_tsql_information_schema && !rewritten_schema_name.empty())
				rewritten_query_fragment.emplace(std::make_pair(ctx->schema->start->getStartIndex(), std::make_pair(::getFullText(ctx->schema), rewritten_schema_name)));

			// qualified identifier doesn't need delimiter
			if (ctx->DOT().empty() && does_object_name_need_delimiter(ctx->object_name))
				rewritten_query_fragment.emplace(std::make_pair(ctx->object_name->start->getStartIndex(), std::make_pair(::getFullText(ctx->object_name), delimit_identifier(ctx->object_name))));
		}
	}

	void exitTable_name(TSqlParser::Table_nameContext *ctx) override
	{
		GetCtxFunc<TSqlParser::Table_nameContext *> getDatabase = [](TSqlParser::Table_nameContext *o) { return o->database; };
		GetCtxFunc<TSqlParser::Table_nameContext *> getSchema = [](TSqlParser::Table_nameContext *o) { return o->schema; };
		std::string rewritten_name = rewrite_object_name_with_omitted_db_and_schema_name(ctx, getDatabase, getSchema);
		std::string rewritten_schema_name = rewrite_information_schema_to_information_schema_tsql(ctx, getSchema);
		if (!rewritten_name.empty())
			rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(::getFullText(ctx), rewritten_name)));
		if (pltsql_enable_tsql_information_schema && !rewritten_schema_name.empty())
			rewritten_query_fragment.emplace(std::make_pair(ctx->schema->start->getStartIndex(), std::make_pair(::getFullText(ctx->schema), rewritten_schema_name)));

		// qualified identifier doesn't need delimiter
		if (ctx->DOT().empty() && does_object_name_need_delimiter(ctx->table))
			rewritten_query_fragment.emplace(std::make_pair(ctx->table->start->getStartIndex(), std::make_pair(::getFullText(ctx->table), delimit_identifier(ctx->table))));
	}

	void exitTable_alias(TSqlParser::Table_aliasContext *ctx) override
	{
		if (does_object_name_need_delimiter(ctx->id()))
			rewritten_query_fragment.emplace(std::make_pair(ctx->id()->start->getStartIndex(), std::make_pair(::getFullText(ctx->id()), delimit_identifier(ctx->id()))));
	}

	void exitSimple_name(TSqlParser::Simple_nameContext *ctx) override
	{
		GetCtxFunc<TSqlParser::Simple_nameContext *> getDatabase = [](TSqlParser::Simple_nameContext *o) { return nullptr; }; // can't exist
		GetCtxFunc<TSqlParser::Simple_nameContext *> getSchema = [](TSqlParser::Simple_nameContext *o) { return o->schema; };
		std::string rewritten_name = rewrite_object_name_with_omitted_db_and_schema_name(ctx, getDatabase, getSchema);
		std::string rewritten_schema_name = rewrite_information_schema_to_information_schema_tsql(ctx, getSchema);
		if (!rewritten_name.empty())
			rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(::getFullText(ctx), rewritten_name)));
		if (pltsql_enable_tsql_information_schema && !rewritten_schema_name.empty())
			rewritten_query_fragment.emplace(std::make_pair(ctx->schema->start->getStartIndex(), std::make_pair(::getFullText(ctx->schema), rewritten_schema_name)));

		// qualified identifier doesn't need delimiter
		if (ctx->DOT().empty() && does_object_name_need_delimiter(ctx->name))
			rewritten_query_fragment.emplace(std::make_pair(ctx->name->start->getStartIndex(), std::make_pair(::getFullText(ctx->name), delimit_identifier(ctx->name))));
	}

	void exitFunc_proc_name_schema(TSqlParser::Func_proc_name_schemaContext *ctx) override
	{
		GetCtxFunc<TSqlParser::Func_proc_name_schemaContext *> getDatabase = [](TSqlParser::Func_proc_name_schemaContext *o) { return nullptr; }; // can't exist
		GetCtxFunc<TSqlParser::Func_proc_name_schemaContext *> getSchema = [](TSqlParser::Func_proc_name_schemaContext *o) { return o->schema; };
		std::string rewritten_schema_name = rewrite_information_schema_to_information_schema_tsql(ctx, getSchema);
		std::string rewritten_name = rewrite_object_name_with_omitted_db_and_schema_name(ctx, getDatabase, getSchema);
		if (!rewritten_name.empty())
			rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(::getFullText(ctx), rewritten_name)));
		if (pltsql_enable_tsql_information_schema && !rewritten_schema_name.empty())
			rewritten_query_fragment.emplace(std::make_pair(ctx->schema->start->getStartIndex(), std::make_pair(::getFullText(ctx->schema), rewritten_schema_name)));

		// don't need to call does_object_name_need_delimiter() because problematic keywords are already allowed as function name
	}

	void exitFunc_proc_name_database_schema(TSqlParser::Func_proc_name_database_schemaContext *ctx) override
	{
		GetCtxFunc<TSqlParser::Func_proc_name_database_schemaContext *> getDatabase = [](TSqlParser::Func_proc_name_database_schemaContext *o) { return o->database; };
		GetCtxFunc<TSqlParser::Func_proc_name_database_schemaContext *> getSchema = [](TSqlParser::Func_proc_name_database_schemaContext *o) { return o->schema; };
		std::string rewritten_name = rewrite_object_name_with_omitted_db_and_schema_name(ctx, getDatabase, getSchema);
		std::string rewritten_schema_name = rewrite_information_schema_to_information_schema_tsql(ctx, getSchema);
		if (!rewritten_name.empty())
			rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(::getFullText(ctx), rewritten_name)));
		if (pltsql_enable_tsql_information_schema && !rewritten_schema_name.empty())
			rewritten_query_fragment.emplace(std::make_pair(ctx->schema->start->getStartIndex(), std::make_pair(::getFullText(ctx->schema), rewritten_schema_name)));

		// don't need to call does_object_name_need_delimiter() because problematic keywords are already allowed as function name
	}

	void enterExecute_body_batch(TSqlParser::Execute_body_batchContext *ctx) override
	{
		in_execute_body_batch = true;		
	}
		
	void exitExecute_body_batch(TSqlParser::Execute_body_batchContext *ctx) override
	{
		in_execute_body_batch = false;	
	}

	void exitFunc_proc_name_server_database_schema(TSqlParser::Func_proc_name_server_database_schemaContext *ctx) override
	{
		GetCtxFunc<TSqlParser::Func_proc_name_server_database_schemaContext *> getDatabase = [](TSqlParser::Func_proc_name_server_database_schemaContext *o) { return o->database; };
		GetCtxFunc<TSqlParser::Func_proc_name_server_database_schemaContext *> getSchema = [](TSqlParser::Func_proc_name_server_database_schemaContext *o) { return o->schema; };
		std::string rewritten_name = rewrite_object_name_with_omitted_db_and_schema_name(ctx, getDatabase, getSchema);
		std::string rewritten_schema_name = rewrite_information_schema_to_information_schema_tsql(ctx, getSchema);
		if (!rewritten_name.empty())
		{
			int EXEC_prepend_length = (in_execute_body_batch) ? fragment_EXEC_prefix.length() : 0;  // add length of prefix prepended internally for execute_body_batch 
			rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex()+EXEC_prepend_length, std::make_pair(::getFullText(ctx), rewritten_name)));
		}
		if (pltsql_enable_tsql_information_schema && !rewritten_schema_name.empty())
		{
			rewritten_query_fragment.emplace(std::make_pair(ctx->schema->start->getStartIndex(), std::make_pair(::getFullText(ctx->schema), rewritten_schema_name)));
		}
		
		// don't need to call does_object_name_need_delimiter() because problematic keywords are already allowed as function name
	}

	void exitGrant_statement(TSqlParser::Grant_statementContext* ctx) override
	{
		if (ctx->permissions())
		{
			const auto &permissions = ctx->permissions()->permission();
			for (const auto perm : permissions)
			{
				const auto exec = perm->single_permission()->EXEC();
				if (exec)
					rewritten_query_fragment.emplace(std::make_pair(exec->getSymbol()->getStartIndex(),
													 std::make_pair(::getFullText(exec), "EXECUTE")));
			}
		}
	}

	void exitRevoke_statement(TSqlParser::Revoke_statementContext* ctx) override
	{
		if (ctx->permissions())
		{
			const auto &permissions = ctx->permissions()->permission();
			for (const auto perm : permissions)
			{
				const auto exec = perm->single_permission()->EXEC();
				if (exec)
					rewritten_query_fragment.emplace(std::make_pair(exec->getSymbol()->getStartIndex(),
													 std::make_pair(::getFullText(exec), "EXECUTE")));
			}
		}
	}

	void exitOpen_query(TSqlParser::Open_queryContext *ctx) override
	{
		TSqlParser::IdContext *linked_srv = ctx->linked_server;

		/* 
		 * The calling syntax for T-SQL OPENQUERY is OPENQUERY(linked_server, 'query')
		 * which means that linked_server is passed as an identifier (without quotes)
		 * 
		 * Since we have implemented OPENQUERY as a PG function, the linked_server gets
		 * interpreted as a column. To fix this, we enclose the linked_server in single
		 * quotes, so that the function now gets called as openquery_internal('linked_server', 'query')
		 */
		if (linked_srv)
		{
			std::string linked_srv_name;

			if (linked_srv->keyword())
				linked_srv_name = getFullText(linked_srv->keyword());
			else
				linked_srv_name = getIDName(linked_srv->DOUBLE_QUOTE_ID(), linked_srv->SQUARE_BRACKET_ID(), linked_srv->ID());
				
			std::string str = std::string("'") + linked_srv_name + std::string("'");

			rewritten_query_fragment.emplace(std::make_pair(ctx->OPENQUERY()->getSymbol()->getStartIndex(), std::make_pair(::getFullText(ctx->OPENQUERY()), "openquery_internal")));
			rewritten_query_fragment.emplace(std::make_pair(linked_srv->start->getStartIndex(), std::make_pair(linked_srv_name, str)));
		}	
	}
};

////////////////////////////////////////////////////////////////////////////////
// tsql Select Statement Mutator
////////////////////////////////////////////////////////////////////////////////
class tsqlSelectStatementMutator : public TSqlParserBaseListener
{
	/*
	 * For some cases, e.g., batch level statement, declare statement, etc, we cannot rely only on tsqlBuilder.
	 * However, we need to mutate select statements regardless of having tsqlBuilder.
	 * This mutator should be used for the case where tsqlBuilder::exitSelect_statement() cannot be called.
	 */
public:
	PLtsql_expr_query_mutator *mutator;
	bool in_create_or_alter_view = false;
public:
	tsqlSelectStatementMutator() = default;
	/* Corner case check. If a view is created on a temporary table, we should throw an exception.
	 * Here we are setting up flags for later check.
	 */ 
	void enterCreate_or_alter_view(TSqlParser::Create_or_alter_viewContext *ctx)
	{
		in_create_or_alter_view = true;
	}
	
	void exitCreate_or_alter_view(TSqlParser::Create_or_alter_viewContext *ctx)
	{
		in_create_or_alter_view = false;
	}

	void exitSelect_statement(TSqlParser::Select_statementContext *ctx) override
	{
		if (mutator)
			process_select_statement(ctx, mutator);
	}

	void exitQuery_specification(TSqlParser::Query_specificationContext *ctx) override
	{
		if (mutator)
			process_query_specification(ctx, mutator);
	}

	void exitTable_source_item(TSqlParser::Table_source_itemContext *ctx) override 
	{
		std::string table_name = extractTableName(nullptr, ctx);

		if (in_create_or_alter_view && !table_name.empty() && table_name.at(0)=='#')
		{	
			in_create_or_alter_view = false;
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Views or functions are not allowed on temporary tables. Table names that begin with '#' denote temporary tables.", 0, 0);
		}
	}

	void exitDml_statement(TSqlParser::Dml_statementContext *ctx) override
	{
		process_execsql_remove_unsupported_tokens(ctx, mutator);
		if (mutator && query_hints.size() && enable_hint_mapping)
		{
			add_query_hints(mutator, ctx->start->getStartIndex());
			clear_query_hints();
		}
		if (table_names.size())
			clear_tables_info();
	}
};

////////////////////////////////////////////////////////////////////////////////
// tsqlBuilder
////////////////////////////////////////////////////////////////////////////////

/*
 * In order to exploit common rewriting logic in tsqlCommonMutator and
 * existing logic in tsqlBuilder, inherit TSqlCommonMutator, all rewriting
 * logic will run in one walker.
 * This will be refactored later. Please see the comment on TSqlCommonMutator
 * for details.
 * */
class tsqlBuilder : public tsqlCommonMutator
{
public:
	std::unique_ptr<tree::ParseTreeProperty<void *>> code;
	const std::vector<std::string> &ruleNames;
	TSqlParser::Tsql_fileContext *root;

    int nodeID = 0;
    tree::ParseTree *parser;
    MyInputStream &stream;

	const std::vector<int> double_quota_places;
	int parameterIndex = 0;

	bool is_cross_db = false;
	std::string schema_name;
	std::string db_name;
	bool is_function = false;
	bool is_schema_specified = false;	
	
	// We keep a stack of the containers that are active during a traversal.
	// A container will correspond to a block or a batch - these are containers
	// because they contain a list of the PLtsql_stmt structures.

	// When we walk the parse tree, we  push an entry onto the containers
	// stack each time we enter a block (or a batch).  We pop the top of
	// the stack when we leave (exit) a block or batch.

	// When we enter a cfl_stmt, a ddl_statement, a dml_statement, or
	// any other statement, we create a PLtsql_stmt structure and add
	// that to the list at the top of the container stack.

	// Since we don't have an otherwise convenient way to amend the
	// the ParserRuleContext class, we will use the 'bodies' hash -
	// the key to the hash is the address of the container and the
	// payload is a pointer to the List of members of tha container.
	

	std::vector<ParserRuleContext *> containers;
	std::unordered_map<ParserRuleContext  *, List *> bodies;
	std::unique_ptr<PLtsql_expr_query_mutator> statementMutator;
	
    tsqlBuilder(tree::ParseTree *p, const std::vector<std::string> &rules, MyInputStream &s, 
	std::vector<int> &quota_places)
		: code(std::make_unique<tree::ParseTreeProperty<void *>>()),
		  ruleNames(rules),
		  root(nullptr),
		  parser(p),
		  stream(s),
		  double_quota_places(quota_places)
    {
		rootInitializers = NIL;
		statementMutator = nullptr;
    }

	~tsqlBuilder()
	{
		//		ListCell *s;
		
		//		foreach(s, rootInitializers)
		//		{
			//PLtsql_stmt *stmt = (PLtsql_stmt *) lfirst(s);

		//		}
	}
	
	std::string
	getNodeDesc(ParseTree *t)
	{
		std::string result = Trees::getNodeText(t, this->ruleNames);

		return result;
	}
	
	ParserRuleContext *
	peekContainer()
	{
		return containers.back();
	}
	
	void
	pushContainer(ParserRuleContext *container)
	{
		if (pltsql_enable_antlr_detailed_log)
			std::cout << "    pushing container " << (void *) container << std::endl;

		containers.push_back(container);
		setCode(container, NIL);
	}

	ParserRuleContext *
	popContainer(ParserRuleContext *container)
	{
		auto result = containers.back();

		if (pltsql_enable_antlr_detailed_log)
			std::cout << " popping container " << (void *) result << std::endl;

		containers.pop_back();
		
		// NOTE: if the caller provided a container, we want
		//       to verify that the pointer we just popped
		//		 is the same.
		
		return result;
	}
	
    void
    setCode(tree::ParseTree *node, List *newList)
    {
		code->put(node, (void *) newList);
    }

    List *
    getCode(tree::ParseTree *node)
    {
		return (List *) (code->get(node));
    }

	// Tree listener overrides
	
	void enterEveryRule(ParserRuleContext *ctx) override
	{
		std::string desc{getNodeDesc(ctx)};

		if (pltsql_enable_antlr_detailed_log)
			std::cout << "+entering (tsqlBuilder)" << (void *) ctx << "[" << desc << "]" << std::endl;
	}

	void exitEveryRule(ParserRuleContext *ctx) override
	{
		std::string desc{getNodeDesc(ctx)};

		if (pltsql_enable_antlr_detailed_log)
			std::cout << "-leaving (tsqlBuilder)" << (void *) ctx << "[" << desc << "]" << std::endl;
	}

	void graft(PLtsql_stmt *stmt, ParserRuleContext *container)
	{
		if (stmt)
		{
			List *siblings = getCode(container);

			if (pltsql_enable_antlr_detailed_log)
				std::cout << "    grafting stmt (" << (void *) stmt << ") to list for container(" << (void *) container << ")" << std::endl;
			
			setCode(container, lappend(siblings, stmt));
		}
		else
		{
			if (pltsql_enable_antlr_detailed_log)
				std::cout << "    grafting stmt (" << (void *) stmt << ") to list for container(" << (void *) container << ")" << std::endl;
		}
	}

	// stmt is meaningless. change it to NOP
	void make_nop(PLtsql_stmt *stmt, ParserRuleContext *container)
	{
		List *siblings = getCode(container);

		if (pltsql_enable_antlr_detailed_log)
			std::cout << "    remove stmt (" << (void *) stmt << ") from list for container(" << (void *) container << ")" << std::endl;
		setCode(container, list_delete_ptr(siblings, stmt));
	}

	//////////////////////////////////////////////////////////////////////////////
	// Container statement management
	//////////////////////////////////////////////////////////////////////////////

	void enterTsql_file(TSqlParser::Tsql_fileContext *ctx) override
    {
		// The root of the parse tree is typically a batch - we
		// will store the root here (in 'root').
		//
		// A batch is also a container (the highest container in
		// the tree) so we call pushContainer() to push this
		// node onto the container stack.

		// Since this is the root of the parse tree, we expect
		// 'root' to be null on entry, if it's not null, that
		// implies that we are re-using a tsqlBuilder instead
		// creating a new one.
		
		Assert(root == nullptr);

		root = ctx;
		
		pushContainer(ctx);
    }

    void exitTsql_file(TSqlParser::Tsql_fileContext *ctx) override
    {
		// We are finished walking the parse tree (the root of the
		// parse tree is typically a batch node). We give the PLtsql_stmt
		// tree to the caller by setting pltsql_parse_result, just like
		// the (obsolete) bison parser.
		pltsql_parse_result = (PLtsql_stmt_block *) makeBatch(ctx, *this);

		// Reset 'root' to indicate that we no longer have a PLtsql_stmt tree.
		root = nullptr;
		
		// A batch is a container so we pop it off the container
		// stack.
		popContainer(ctx);
    }

  	void enterBlock_statement(TSqlParser::Block_statementContext *ctx) override
	{
		// A (BEGIN/END) block is a container so push this node to the
		// top of the container stack. As we continue to walk the ANTLR
		// parse tree and create new PLtsql_stmt nodes, we graft those
		// new nodes to the most-recently seen container node (that is,
	    // the container on top of the container stack).
		pushContainer(ctx);
	}

	void exitBlock_statement(TSqlParser::Block_statementContext *ctx) override
	{
		// We've now processed all of the descendant ANTLR parse tree nodes
		// that belong to this block (which is a container). As we walked
		// through the descendant nodes, we created a List of PLtsql_stmt
		// nodes that should be controlled by this BEGIN/END block.  We
		// can find that list by calling getCode(ctx).
		//
		// Now add these children to the PLtsql_stmt_block (which we
		// store in our parse tree parent node).  We can find that PLtsql_stmt_block
		// by calling getPLtsql_fragment()	   
		PLtsql_stmt_block *block = (PLtsql_stmt_block *) getPLtsql_fragment(ctx->parent);

		if (block)
			block->body = getCode(ctx);

		// And finally, pop this parse tree node from the container stack
		popContainer(ctx);
	}	

	void enterWhile_statement(TSqlParser::While_statementContext *ctx) override
    {
 		// A WHILE statement is a container - it stores the statements in the
		// body of the loop
		//
		// See enterBlock_statement() for a more complete description.
		pushContainer(ctx);
    }

    void exitWhile_statement(TSqlParser::While_statementContext *ctx) override
    {
		// See exitBlock_statement() for a more complete description.
		PLtsql_stmt_while *fragment = (PLtsql_stmt_while *) getPLtsql_fragment(ctx->parent);

		fragment->body = getCode(ctx);

		popContainer(ctx);
	}

	void enterIf_statement(TSqlParser::If_statementContext *ctx) override
	{
 		// An IF statement is a container - it stores the statements in the
		// then_body of the loop
		//
		// FIXME: how do we handle the else_body?
		// FIXME: how do we handle the remaining ELSIF nodes?
		//
		// See enterBlock_statement() for a more complete description.
		pushContainer(ctx);
	}

	void exitIf_statement(TSqlParser::If_statementContext *ctx) override
	{
		// See exitBlock_statement() for a more complete description.
		PLtsql_stmt_if *fragment = (PLtsql_stmt_if *) getPLtsql_fragment(ctx->parent);
		List *code = getCode(ctx);

		if (!code) // defensive code
			throw PGErrorWrapperException(ERROR, ERRCODE_INTERNAL_ERROR, "IF-block is empty. It might be an internal bug due to unsupported statements.", getLineAndPos(ctx));

		fragment->then_body = (PLtsql_stmt *) linitial(code);

		if (list_length(code) >  1)
			fragment->else_body = (PLtsql_stmt *) lsecond(code);
		
		popContainer(ctx);
	}

	void enterTry_catch_statement(TSqlParser::Try_catch_statementContext *ctx) override
	{
		pushContainer(ctx);
	}

	void exitTry_catch_statement(TSqlParser::Try_catch_statementContext *ctx) override
	{
		PLtsql_stmt_try_catch *fragment = (PLtsql_stmt_try_catch *) getPLtsql_fragment(ctx->parent);
		List *code = getCode(ctx);

		if (!code) // defensive code
			throw PGErrorWrapperException(ERROR, ERRCODE_INTERNAL_ERROR, "TRY-block is empty. It might be an internal bug due to unsupported statements.", getLineAndPos(ctx));

		fragment->body = (PLtsql_stmt *) linitial(code);

		if (list_length(code) > 1)
			fragment->handler = (PLtsql_stmt *) lsecond(code);
		else
			fragment->handler = (PLtsql_stmt *) makeEmptyBlockStmt(getLineNo(ctx->catch_block()));

		popContainer(ctx);

	}

	void enterTry_block(TSqlParser::Try_blockContext *ctx) override
	{
		pushContainer(ctx);
	}

	void exitTry_block(TSqlParser::Try_blockContext *ctx) override
	{
		PLtsql_stmt_block *result = (PLtsql_stmt_block *) makeBlockStmt(ctx, *this);
		result->body = getCode(ctx);
		popContainer(ctx);
		graft((PLtsql_stmt *) result, peekContainer());
	}

	void enterCatch_block(TSqlParser::Catch_blockContext *ctx) override
	{
		pushContainer(ctx);
	}

	void exitCatch_block(TSqlParser::Catch_blockContext *ctx) override
	{
		PLtsql_stmt_block *result = (PLtsql_stmt_block *) makeBlockStmt(ctx, *this);
		result->body = getCode(ctx);
		popContainer(ctx);
		graft((PLtsql_stmt *) result, peekContainer());
	}
	
	void enterCreate_or_alter_procedure(TSqlParser::Create_or_alter_procedureContext *ctx) override
	{
		pushContainer(ctx);
	}

	void exitCreate_or_alter_procedure(TSqlParser::Create_or_alter_procedureContext *ctx) override
	{
		// just throw away all PLtsql_stmt in the container.
		// procedure body is a sequence of sql_clauses. In create-procedure, we don't need to generate PLtsql_stmt.
		//
		// TODO: Ideally, we may stop visiting or disable vistior logic inside the procedure body. It will save the resoruce.

		popContainer(ctx);
	}

	void enterCreate_or_alter_function(TSqlParser::Create_or_alter_functionContext *ctx) override
	{
		pushContainer(ctx);
	}

	void exitCreate_or_alter_function(TSqlParser::Create_or_alter_functionContext *ctx) override
	{
		// just throw away all PLtsql_stmts in the container. Please see the comment in exitCreate_or_alter_procedure()
		popContainer(ctx);
	}

	void enterCreate_or_alter_trigger(TSqlParser::Create_or_alter_triggerContext *ctx) override
	{
		pushContainer(ctx);
	}

	void exitCreate_or_alter_trigger(TSqlParser::Create_or_alter_triggerContext *ctx) override
	{
		// just throw away all PLtsql_stmts in the container. Please see the comment in exitCreate_or_alter_procedure()
		popContainer(ctx);
	}

	void exitAlter_table(TSqlParser::Alter_tableContext *ctx) override
	{
		if (ctx->TRIGGER() && ctx->id().size() > 1)	/* condition to filter alter table statements which contains TRIGGER keyword and multiple trigger names */
		{
			/*
			 * When we come across a alter table query which enable/disable trigger with multiple trigger name, 
			 * we will replace it with list of alter table statements, a statement for each trigger.
			 * As Postgres only support enabling/disabling of only one trigger using alter table syntax, so a call like:
			 * 
			 * 	ALTER TABLE Employees { ENABLE | DISABLE } TRIGGER trigger_a, trigger_b
			 *	GO
			 * 
			 * will be re-written as:
			 * 
			 * 	ALTER TABLE Employees { ENABLE | DISABLE } TRIGGER trigger_a; 
			 *  ALTER TABLE Employees { ENABLE | DISABLE } TRIGGER trigger_b;
			 */

			std::vector<TSqlParser::IdContext *> list_id = ctx->id();
			TSqlParser::Table_nameContext *table_name = ctx->tabname;

			std::string str = std::string("");
			std::string action_type;
			if (ctx->ENABLE() != nullptr)
			{
				action_type = std::string(" ENABLE");
			}
			else
			{
				action_type = std::string(" DISABLE");
			}

			for (TSqlParser::IdContext *id : list_id) {
				str += std::string("ALTER TABLE ") + ::getFullText(table_name) + action_type + std::string(" TRIGGER ") + ::getFullText(id) + "; ";
			}

			rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(::getFullText(ctx), str)));
		}
	}

	void exitEnable_trigger(TSqlParser::Enable_triggerContext *ctx) override
	{
		if(ctx->SERVER() || ctx->DATABASE())
		{
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "'DDL trigger' is not currently supported in Babelfish.", 0, 0);
		}
	}

	void exitDisable_trigger(TSqlParser::Disable_triggerContext *ctx) override
	{
		if(ctx->SERVER() || ctx->DATABASE())
		{
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "'DDL trigger' is not currently supported in Babelfish.", 0, 0);
		}
	}
	
	//////////////////////////////////////////////////////////////////////////////
	// Non-container statement management
	//////////////////////////////////////////////////////////////////////////////

   	void enterDml_statement(TSqlParser::Dml_statementContext *ctx) override
	{
		// We ran into a DML clause while walking down the ANTLR parse
		// tree - we create a PLtsql_stmt_execsql statement to handle
		// this clause and graft it into the list of PLtsql_stmts kept
		// in the top-most container.
		//
		// execsql statements are used to handle non-control-of-flow
		// statements (aka SQL statements) - we just make a copy of
		// the string that makes up the statement, store that string
		// inside of the PLtsql_stmt_execsql, and send that string
		// to the main SQL parser when we execute the statement.

        if (ctx->bulk_insert_statement())
        {
            graft(makeInsertBulkStatement(ctx), peekContainer());
        }
        else
        {
            graft(makeSQL(ctx), peekContainer());
        }

		// prepare rewriting
		clear_rewritten_query_fragment();
		PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) getPLtsql_fragment(ctx);
		Assert(stmt);
		statementMutator = std::make_unique<PLtsql_expr_query_mutator>(stmt->sqlstmt, ctx);
	}

	void exitDml_statement(TSqlParser::Dml_statementContext *ctx) override
	{
        if (ctx->bulk_insert_statement())
        {
            clear_rewritten_query_fragment();
            return;
        }
		PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) getPLtsql_fragment(ctx);
		Assert(stmt);
		Assert(stmt->sqlstmt = statementMutator->expr);
		try
		{
			process_execsql_destination(ctx, stmt);
		}
		catch (PGErrorWrapperException &e)
		{
			clear_rewritten_query_fragment();
			throw;
		}

		process_execsql_remove_unsupported_tokens(ctx, statementMutator.get());

		// record whether the stmt is an INSERT-EXEC stmt
		stmt->insert_exec =
			ctx->insert_statement() &&
			ctx->insert_statement()->insert_statement_value() &&
			ctx->insert_statement()->insert_statement_value()->execute_statement();

		if (stmt->insert_exec)
		{
			TSqlParser::Func_proc_name_server_database_schemaContext *ctx_name = nullptr;
			TSqlParser::Execute_bodyContext *body = nullptr;

			TSqlParser::Execute_statementContext *ctxES = ctx->insert_statement()->insert_statement_value()->execute_statement();
			body = ctxES->execute_body();
			Assert(body);
			
			ctx_name       = body->func_proc_name_server_database_schema();
			if (ctx_name) 
			{				
				if (ctx_name->database)
				{
					db_name = stripQuoteFromId(ctx_name->database);
					if (!string_matches(db_name.c_str(), get_cur_db_name()))
					{
						is_cross_db = true;
					}
				}
			}
		}

		// record whether stmt is cross-db
		if (is_cross_db)
			stmt->is_cross_db = true;
		// record that the stmt is dml
	 	stmt->is_dml = true;
		// record if a function call
		if (is_function)
			stmt->func_call = true;

		if (!schema_name.empty())
			stmt->schema_name = pstrdup(downcase_truncate_identifier(schema_name.c_str(), schema_name.length(), true));
		// record db name for the cross db query
		if (!db_name.empty())
			stmt->db_name = pstrdup(downcase_truncate_identifier(db_name.c_str(), db_name.length(), true));
		// record if the SQL object is schema qualified
		if (is_schema_specified)
			stmt->is_schema_specified = true;

		if (is_compiling_create_function())
		{
			/* select without destination should be blocked. We can use already information about desitnation, which is already processed. */
			if (ctx->select_statement_standalone() && stmt->need_to_push_result)
				throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "SELECT statement returning result to a client cannot be used in a function", getLineAndPos(ctx->select_statement_standalone()));

			/* T-SQL doens't allow side-effecting operations in CREATE FUNCTION */
			if (ctx->insert_statement())
			{
				auto ddl_object = ctx->insert_statement()->ddl_object();
				if (stmt->insert_exec && ddl_object && !ddl_object->local_id()) /* insert into non-local object */
					throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "'INSERT EXEC' cannot be used within a function", getLineAndPos(ddl_object));
				else if (ddl_object && !ddl_object->local_id()) /* insert into non-local object */
					throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "'INSERT' cannot be used within a function", getLineAndPos(ddl_object));
			}
			else if (ctx->update_statement() && ctx->update_statement()->ddl_object() && !ctx->update_statement()->ddl_object()->local_id() && 
					(ctx->update_statement()->table_sources() ? ::getFullText(ctx->update_statement()->table_sources()).c_str()[0] != '@' : true)) /* update non-local object, table variables are allowed */
				throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "'UPDATE' cannot be used within a function", getLineAndPos(ctx->update_statement()->ddl_object()));
			else if (ctx->delete_statement() && ctx->delete_statement()->delete_statement_from()->ddl_object() && !ctx->delete_statement()->delete_statement_from()->ddl_object()->local_id()  &&
					(ctx->delete_statement()->table_sources() ? ::getFullText(ctx->delete_statement()->table_sources()).c_str()[0] != '@' : true)) /* delete non-local object, table variables are allowed */
				throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "'DELETE' cannot be used within a function", getLineAndPos(ctx->delete_statement()->delete_statement_from()->ddl_object()));

			/*
			 * Reject if OUTPUT clause is missing INTO (returning to client) or OUTPUT INTO non local object
			 */

			if (ctx->insert_statement() && ctx->insert_statement()->output_clause() && (!ctx->insert_statement()->output_clause()->INTO() || !ctx->insert_statement()->output_clause()->LOCAL_ID()))
			{
				throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "Invalid use of a side-effecting operator 'INSERT' within a function.", getLineAndPos(ctx->insert_statement()->output_clause()));
			}
			else if (ctx->update_statement() && ctx->update_statement()->output_clause() && (!ctx->update_statement()->output_clause()->INTO() || !ctx->update_statement()->output_clause()->LOCAL_ID()))
			{
				throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "Invalid use of a side-effecting operator 'UPDATE' within a function.", getLineAndPos(ctx->update_statement()->output_clause()));
			}
			else if (ctx->delete_statement() && ctx->delete_statement()->output_clause() && (!ctx->delete_statement()->output_clause()->INTO() || !ctx->delete_statement()->output_clause()->LOCAL_ID()))
			{
				throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "Invalid use of a side-effecting operator 'DELETE' within a function.", getLineAndPos(ctx->delete_statement()->output_clause()));
			}
		}

		/* we must add previous rewrite at first. */
		add_rewritten_query_fragment_to_mutator(statementMutator.get());

		// post-processing of execsql stmt query
		for (auto &entry : local_id_positions)
		{
			// Adding quote to tsql local_id (starting with '@') because backend parser is expecting that.
			std::string quoted_local_id = std::string("\"") + entry.second + "\"";
			statementMutator->add(entry.first, entry.second, quoted_local_id);
		}

		/* Add query hints */
		if (query_hints.size() && enable_hint_mapping)
		{
			add_query_hints(statementMutator.get(), ctx->start->getStartIndex());
			clear_query_hints();
		}

		statementMutator->run();
		statementMutator = nullptr;
		clear_rewritten_query_fragment();
		clear_tables_info();
	}

	void exitSelect_statement(TSqlParser::Select_statementContext *selectCtx) override
	{
		if (statementMutator)
			process_select_statement(selectCtx, statementMutator.get());
	}

	void enterBatch_level_statement(TSqlParser::Batch_level_statementContext *ctx) override
	{
		// See the comments in enterDml_statement() for an explanation of this code
		graft(makeSQL(ctx), peekContainer());
	}
	
	void enterDdl_statement(TSqlParser::Ddl_statementContext *ctx) override
	{
		// See the comments in enterDml_statement() for an explanation of this code
		PLtsql_stmt *stmt;
		if (ctx->alter_authorization())
		{
			stmt = makeChangeDbOwnerStatement(ctx->alter_authorization());
		}
		else if (ctx->create_fulltext_index())
		{
			stmt = makeCreateFulltextIndexStmt(ctx->create_fulltext_index());
		}
		else if (ctx->drop_fulltext_index())
		{
			stmt = makeDropFulltextIndexStmt(ctx->drop_fulltext_index());
		}
		else
		{
			stmt = makeSQL(ctx);
		}
		graft(stmt, peekContainer());
		clear_rewritten_query_fragment();
	}

	void exitDdl_statement(TSqlParser::Ddl_statementContext *ctx) override
	{
		if (ctx->alter_authorization()) 
		{
			// Exit in case of Change DB owner
			return;
		}
		
		if (ctx->create_fulltext_index())
		{
			clear_rewritten_query_fragment();
			return;
		}
		if (ctx->drop_fulltext_index())
		{
			clear_rewritten_query_fragment();
			return;
		}
		PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) getPLtsql_fragment(ctx);
		Assert(stmt);
		// record that the stmt is ddl
	 	stmt->is_ddl = true;

		if (is_compiling_create_function())
		{
			/* T-SQL doesn't allow side-effecting operations in CREATE FUNCTION */
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "DDL cannot be used within a function", getLineAndPos(ctx));
		}


		bool nop = false;
		if (ctx->create_table())
			nop = post_process_create_table(ctx->create_table(), stmt, ctx);
		else if (ctx->alter_table())
			nop = post_process_alter_table(ctx->alter_table(), stmt, ctx);
		else if (ctx->create_index())
			nop = post_process_create_index(ctx->create_index(), stmt, ctx);
		else if (ctx->create_database())
			nop = post_process_create_database(ctx->create_database(), stmt, ctx);
		else if (ctx->create_type())
			nop = post_process_create_type(ctx->create_type(), stmt, ctx);
		else if (ctx->alter_fulltext_index())
		{
			ereport(WARNING,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("ALTER FULLTEXT INDEX statement will be ignored.")));
			nop = true;
		}

		if (nop)
		{
			make_nop((PLtsql_stmt *) stmt, peekContainer());
			return;
		}
		else
		{
			// post-processing of execsql stmt query
			PLtsql_expr_query_mutator mutator(stmt->sqlstmt, ctx);
			add_rewritten_query_fragment_to_mutator(&mutator);
			mutator.run();
		}
		clear_rewritten_query_fragment();
	}

    void exitCfl_statement(TSqlParser::Cfl_statementContext *ctx) override
    {
		PLtsql_expr *expr = nullptr;
		if (ctx->print_statement())
		{
			PLtsql_stmt_print *stmt = (PLtsql_stmt_print *) getPLtsql_fragment(ctx);
			expr = (PLtsql_expr *) linitial(stmt->exprs);
		}
		else if (ctx->raiseerror_statement() && ctx->raiseerror_statement()->raiseerror_msg() && ctx->raiseerror_statement()->raiseerror_msg()->char_string())
		{
			PLtsql_stmt_raiserror *stmt = (PLtsql_stmt_raiserror *) getPLtsql_fragment(ctx);
			expr = (PLtsql_expr *) linitial(stmt->params);
		}
		else if (ctx->return_statement())
		{
			if (pltsql_curr_compile && pltsql_curr_compile->fn_prokind != PROKIND_PROCEDURE)
			{
				PLtsql_stmt_return *stmt = (PLtsql_stmt_return *) getPLtsql_fragment(ctx);
				expr = (PLtsql_expr *) stmt->expr;
			}
		}
		if (expr) 
		{
			PLtsql_expr_query_mutator mutator(expr, ctx);
			mutator.markSelectFragment(ctx);
			add_rewritten_query_fragment_to_mutator(&mutator);
			mutator.run();

			// remove the offsets for processed fragments
			selectFragmentOffsets.clear();
					
			clear_rewritten_query_fragment();
		}
	}
	
	void exitSecurity_statement(TSqlParser::Security_statementContext *ctx) override
	{
		if (ctx->grant_statement())
		{
			auto grant = ctx->grant_statement();
			if (!grant->permission_object() && grant->permissions())
			{
				for (auto perm : grant->permissions()->permission())
				{
					auto single_perm = perm->single_permission();
					if (single_perm->CONNECT())
					{
						clear_rewritten_query_fragment();
						return;
					}
				}
			}
			else if (grant->ON() && grant->permission_object() && grant->permission_object()->permission_object_type() && grant->permission_object()->permission_object_type()->SCHEMA())
			{
				if (grant->principals() && grant->permissions())
				{
					for (auto perm: grant->permissions()->permission())
					{
						auto single_perm = perm->single_permission();
						if (single_perm->EXECUTE()
							|| single_perm->EXEC()
							|| single_perm->SELECT()
							|| single_perm->INSERT()
							|| single_perm->UPDATE()
							|| single_perm->DELETE()
							|| single_perm->REFERENCES())
						{
							return;
						}
					}
				}
			}
		}
		else if (ctx->revoke_statement())
		{
			auto revoke = ctx->revoke_statement();
			if (!revoke->permission_object() && revoke->permissions())
			{
				for (auto perm : revoke->permissions()->permission())
				{
					auto single_perm = perm->single_permission();
					if (single_perm->CONNECT())
					{
						clear_rewritten_query_fragment();
						return;
					}
				}
			}

			else if (revoke->ON() && revoke->permission_object() && revoke->permission_object()->permission_object_type() && revoke->permission_object()->permission_object_type()->SCHEMA())
			{
				if (revoke->principals() && revoke->permissions())
				{
					for (auto perm: revoke->permissions()->permission())
					{
						auto single_perm = perm->single_permission();
						if (single_perm->EXECUTE()
							|| single_perm->EXEC()
							|| single_perm->SELECT()
							|| single_perm->INSERT()
							|| single_perm->UPDATE()
							|| single_perm->DELETE()
							|| single_perm->REFERENCES())
						{
							return;
						}
					}
				}
			}
		}

		PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) getPLtsql_fragment(ctx);
		Assert(stmt);

		PLtsql_expr_query_mutator mutator(stmt->sqlstmt, ctx);
		add_rewritten_query_fragment_to_mutator(&mutator);
		mutator.run();
		clear_rewritten_query_fragment();
	}

	void enterAnother_statement(TSqlParser::Another_statementContext *ctx) override
	{
		// We've encountered an "another_statement" while descending the ANTLR
		// parse tree. "another_statement" is a grammar rule that matches DECLARE,
		// EXECUTE, cursor-related statements, conversation statements, and several
		// others (basically, statements that don't belong in some other category).
		//
		// Most of these statements will end up as PLtsql_stmt_execsql statements,
		// but a few (such as DECLARE and SET) require special handling.
		//
		// Please note that one "another_statement" may return a list of PLtsql_stmt
		// in case of DECLARE multiple variable with initializers at a time.
		std::vector<PLtsql_stmt *> result = makeAnother(ctx, *this);
		for (PLtsql_stmt *stmt : result)
			graft(stmt, peekContainer());

		clear_rewritten_query_fragment();
	}
	
	void exitAnother_statement(TSqlParser::Another_statementContext *ctx) override
	{	
		// currently, declare_cursor only need rewriting because it contains select statement
		if (ctx->cursor_statement() && ctx->cursor_statement()->declare_cursor())
		{
			PLtsql_stmt_decl_cursor *decl_cursor_stmt = (PLtsql_stmt_decl_cursor *) getPLtsql_fragment(ctx);
			post_process_declare_cursor_statement(decl_cursor_stmt, ctx->cursor_statement()->declare_cursor(), *this);
		}

		// Declare table type statement might need rewriting in column definition list.
		else if (ctx->declare_statement() && ctx->declare_statement()->table_type_definition())
		{
			PLtsql_stmt_decl_table *decl_table_stmt = (PLtsql_stmt_decl_table *) getPLtsql_fragment(ctx);
			post_process_declare_table_statement(decl_table_stmt, ctx->declare_statement()->table_type_definition());
		}

		else if (ctx->execute_statement())
		{
			PLtsql_stmt_exec *stmt = (PLtsql_stmt_exec *) getPLtsql_fragment(ctx);
			if (stmt->cmd_type == PLTSQL_STMT_EXEC)
			{
				PLtsql_expr_query_mutator mutator(stmt->expr, ctx);
				add_rewritten_query_fragment_to_mutator(&mutator); // move information of rewritten_query_fragment to mutator.
				mutator.run(); // expr->query will be rewitten here
			}
		}

		else if (ctx->set_statement() && ctx->set_statement()->expression())
		{
			// There should always be offsets for SET expressions
			Assert(selectFragmentOffsets.find(ctx->set_statement()) != selectFragmentOffsets.end());			
															
			PLtsql_stmt_assign *stmt = (PLtsql_stmt_assign *) getPLtsql_fragment(ctx->set_statement());
			PLtsql_expr_query_mutator mutator(stmt->expr, ctx->set_statement());
			mutator.markSelectFragment(ctx->set_statement());
			add_rewritten_query_fragment_to_mutator(&mutator); 
			mutator.run();
		}
		
		else if (ctx->declare_statement()) 
		{			
			if (ctx->declare_statement()->declare_local().size() > 0) 
			{
				// For each assignment to a @variable, a fragment was created (via makeInitializer).
				// There can be multiple declarations and assignments in a single DECLARE, and these are processed below.
				int i = 0;
				for (TSqlParser::Declare_localContext *d : ctx->declare_statement()->declare_local() ) 
				{
					i++;
					if (d->expression())
					{  
						ParserRuleContext *ctx_fragment = (ParserRuleContext *) ctx;			
						if (selectFragmentOffsets.find(d->expression()) != selectFragmentOffsets.end()) 
						{ 
							ctx_fragment = d->expression();
						}
								
						PLtsql_stmt_assign *stmt = (PLtsql_stmt_assign *) getPLtsql_fragment(ctx_fragment);
						PLtsql_expr_query_mutator mutator(stmt->expr, ctx_fragment);
						mutator.markSelectFragment(ctx_fragment);
						add_rewritten_query_fragment_to_mutator(&mutator);
						mutator.run(); 
					}
				}				
			}
		}

		// remove the offsets for processed fragments
		selectFragmentOffsets.clear();		
				
		clear_rewritten_query_fragment();
	}

	// NB: similar code is in tsqlMutator
	void exitChar_string(TSqlParser::Char_stringContext *ctx) override
	{
		std::string str = getFullText(ctx);			

		if (str.front() == 'N')
		{
			// Temporarily remove the leading 'N' only locally here, to make the assertion on str.front() easy (below)
			str.erase(0, 1);	
		}

		if (str.front() == '"')
		{	
			Assert(str.back() == '"');
			
			// Change double-quoted string to single-quoted string:
			str = rewriteDoubleQuotedString(str);	
			size_t startPosition = ctx->start->getStartIndex();
			if (in_execute_body_batch_parameter) startPosition += fragment_EXEC_prefix.length(); // add length of prefix prepended internally for execute_body_batch  
			rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(::getFullText(ctx), str)));
		}
		else
		{
			// This is a single-quoted string, no further action needed
			Assert(str.front() == '\'');
			Assert(str.back() == '\'');		    						
		}
	}

	void enterExecute_parameter(TSqlParser::Execute_parameterContext *ctx) override
	{
		if (in_execute_body_batch) in_execute_body_batch_parameter = true;
	}

	void exitExecute_parameter(TSqlParser::Execute_parameterContext *ctx) override
	{
		if (ctx->id())
		{
			// A stored procedure parameter which is parsed as a column name (= identifier)
			// is either an unquoted string, a double-quoted string, or a bracketed string.
			// For a procedure call parameter, a double-quoted string is interpreted 
			// as a string even with QUOTED_IDENTIFIER=ON.			
			std::string str = getFullText(ctx->id());
			size_t startPosition = ctx->id()->start->getStartIndex();		
			if (in_execute_body_batch_parameter) startPosition += fragment_EXEC_prefix.length(); // add length of prefix prepended internally for execute_body_batch			

			if (str.front() == '"')
			{
				Assert(str.back() == '"');
								
				// Change double-quoted string to single-quoted string
				str = rewriteDoubleQuotedString(str);		    	  	
				rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(getFullText(ctx->id()), str)));										
			}		
			else if (str.front() == '\'')
			{
				// This is a single-quoted string, no further action needed	
				Assert(str.back() == '\'');		    						
			}
			else if (str.front() == '[') 
			{
				// When it's a bracketed identifier, remove the delimiters as T-SQL treats it as a string								
				Assert(str.back() == ']');

				// Temporarily turn this into a double-quoted string so that we can handle embedded quotes.
				// Since embedded double quotes inside a bracketed identifier are not escaped (as they would be in a 
				// double-quoted string), escape them first. We cannot just call rewriteDoubeQuotedString() since if we'd
				// have two adjacent double quotes, i.e. [a""b], this would then become [a"b] so we'd lose one quote.
				str = escapeDoubleQuotes(str);
				str = '"' + str.substr(1,str.length()-2) + '"';
				str = rewriteDoubleQuotedString(str);	
				rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(getFullText(ctx->id()), str)));					
			}
			else 
			{
				// This is an unquoted string parameter which has been parsed as an identifier(column name).
				// Put quotes around it: even though it is an identifier in the ANTLR parse tree, it will be 
				// parsed as a string by the backend parser
				str = "'" + str + "'";
				rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(getFullText(ctx->id()), str)));
			}
		}		
		if (in_execute_body_batch_parameter) in_execute_body_batch_parameter = false;
	}

    void enterCfl_statement(TSqlParser::Cfl_statementContext *ctx) override
    {
		// We ran into a control-of-flow (CFL) statement while descending the
		// ANTLR parse tree. CFL statements are things like BREAK, GOTO, IF,
		// WHILE, and others.
		//
		// In general, each CFL statement requires custom handling.  So we call
		// makeCfl() to create the appropriate PLtsql_stmt and then graft that
		// into the topmost container.
		graft(makeCfl(ctx, *this), peekContainer());

		clear_rewritten_query_fragment();
	}

	void enterDbcc_statement(TSqlParser::Dbcc_statementContext *ctx) override
	{
		if (ctx->CHECKIDENT())
        		graft(makeDbccCheckidentStatement(ctx), peekContainer());

		clear_rewritten_query_fragment();
	}

	void exitDbcc_statement(TSqlParser::Dbcc_statementContext *ctx) override
	{
		// TO-DO
	}

	void exitExecute_statement_arg_named(TSqlParser::Execute_statement_arg_namedContext *ctx) override
	{
		// Look for named arguments with an @@variable with no preceding whitespace, i.e. 'exec myproc @p=@@spid'
		Assert(ctx->EQUAL());
		Assert(ctx->execute_parameter());
		size_t startPosition = ctx->execute_parameter()->start->getStartIndex();
		if ((startPosition - ctx->EQUAL()->getSymbol()->getStopIndex()) == 1)
		{
			std::string var = getFullText(ctx->execute_parameter());
				
			// The subsequent expression must be a variable starting with '@@'
			if (var.front() == '@') 
			{
				if (var.at(1) == '@') 
				{
					// Insert a space before the variable name
					if (in_execute_body_batch) startPosition += fragment_EXEC_prefix.length(); // add length of prefix prepended internally for execute_body_batch
					rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(var, " "+var)));
				}
			}
		}
	}
	
	void exitOrder_by_clause(TSqlParser::Order_by_clauseContext *ctx) override
	{
		handleOrderByOffsetFetch(ctx);
	}

	void exitTRIM(TSqlParser::TRIMContext *ctx) override
	{
		rewrite_function_trim_to_sys_trim(ctx);
	}
  
	// NB: the following are copied in tsqlMutator
	void exitColumn_def_table_constraints(TSqlParser::Column_def_table_constraintsContext *ctx)
	{
		handleTableConstraintWithoutComma(ctx);
	}
	void exitConstant(TSqlParser::ConstantContext *ctx) override
	{	
		// Check for floating-point number without exponent
		handleFloatWithoutExponent(ctx);
	}
	void exitPredicate(TSqlParser::PredicateContext *ctx) override
	{
		// Check for comparison operators directly followed by an '@@' variable, like =@@
		handleAtAtVarInPredicate(ctx);
	}		
	void exitUnary_op_expr(TSqlParser::Unary_op_exprContext *ctx) override
	{
		handleBitNotOperator(ctx);
	}
	void exitPlus_minus_bit_expr(TSqlParser::Plus_minus_bit_exprContext *ctx) override
	{
		handleBitOperators(ctx);
	}
	void exitMult_div_percent_expr(TSqlParser::Mult_div_percent_exprContext *ctx) override
	{
		handleModuloOperator(ctx);
	}

	//////////////////////////////////////////////////////////////////////////////
	// Special handling of non-statement context
	//////////////////////////////////////////////////////////////////////////////
	void enterLocal_id(TSqlParser::Local_idContext *ctx) override
	{
		std::string local_id_str = ::getFullText(ctx);
		if (local_id_str.length() > 2 && local_id_str[0] == '@' && local_id_str[1] == '@')
		{
			// starting with "@@" is a global variable (or internal function). skip adding.
			return;
		}

		// keep <position, local_id string> to add quote later
		if (ctx->start)
		{
			local_id_positions.emplace(std::make_pair(ctx->start->getStartIndex(), local_id_str));
		}
	}

	void exitFull_object_name(TSqlParser::Full_object_nameContext *ctx) override
	{
		if (ctx && (ctx->DOT().size() <= 2) && ctx->schema)
		{
			schema_name = stripQuoteFromId(ctx->schema);
			is_schema_specified = true;
		}
		else
			is_schema_specified = false;
		tsqlCommonMutator::exitFull_object_name(ctx);
		if (ctx && (ctx->DOT().size() <= 2) && ctx->database)
		{
			db_name = stripQuoteFromId(ctx->database);

			if (!string_matches(db_name.c_str(), get_cur_db_name()))
				is_cross_db = true;
		}
	}

	void exitTable_name(TSqlParser::Table_nameContext *ctx) override
	{
		tsqlCommonMutator::exitTable_name(ctx);
		if (ctx && ctx->database)
		{
			db_name = stripQuoteFromId(ctx->database);

			if (!string_matches(db_name.c_str(), get_cur_db_name()))
				is_cross_db = true;
		}
	}

	void exitFull_column_name(TSqlParser::Full_column_nameContext *ctx) override
	{
		handleFullColumnNameCtx(ctx);
	}

	/* We are adding handling for CLR_UDT Types in:
	 * tsqlBuilder: for cases other than inside CREATE/ALTER View, Procedure, Function
	 */
	void exitClr_udt_func_call(TSqlParser::Clr_udt_func_callContext *ctx) override
	{
		handleClrUdtFuncCall(ctx);
	}

	//////////////////////////////////////////////////////////////////////////////
	// function/procedure call analysis
	//////////////////////////////////////////////////////////////////////////////

	void exitFunction_call(TSqlParser::Function_callContext *ctx) override
	{
		is_function = true;
		if (ctx->NEXT() && ctx->full_object_name())
		{
			TSqlParser::Full_object_nameContext *fctx = (TSqlParser::Full_object_nameContext *) ctx->full_object_name();
			std::string seq_name = ::getFullText(fctx);
			std::string nextval_string = "nextval('" + seq_name + "')";
			if (fctx->schema)
			{
				TSqlParser::IdContext *dctx = fctx->database;
				TSqlParser::IdContext *sctx = fctx->schema;
				TSqlParser::IdContext *octx = fctx->object_name;
				char *database;
				char *schema;

				if(dctx)
					database = pstrdup(stripQuoteFromId(dctx).c_str());
				else
					database = get_cur_db_name();

				schema = get_physical_schema_name(database, stripQuoteFromId(sctx).c_str());

				if(strcmp(schema, "") == 0)
					nextval_string = "nextval('" + ::stripQuoteFromId(octx) + "')";
				else
					// Need to directly use the backend schema name since nextval is a postgres function
					nextval_string = "nextval('" + std::string(schema) + '.' + ::stripQuoteFromId(octx) + "')";

				pfree(database);
			}

			rewritten_query_fragment.emplace(std::make_pair(ctx->NEXT()->getSymbol()->getStartIndex(), std::make_pair(::getFullText(ctx->NEXT()), "")));
			rewritten_query_fragment.emplace(std::make_pair(ctx->VALUE()->getSymbol()->getStartIndex(), std::make_pair(::getFullText(ctx->VALUE()), "")));
			rewritten_query_fragment.emplace(std::make_pair(ctx->FOR()->getSymbol()->getStartIndex(), std::make_pair(::getFullText(ctx->FOR()), "")));
			rewritten_query_fragment.emplace(std::make_pair(ctx->full_object_name()->start->getStartIndex(), std::make_pair(::getFullText(ctx->full_object_name()), nextval_string)));
		}
		if (ctx->analytic_windowed_function())
		{
			auto actx = ctx->analytic_windowed_function();
			Assert(actx);

			if (actx->PERCENTILE_CONT() || actx->PERCENTILE_DISC())
			{
				if (actx->over_clause())
				{
					std::string funcName = actx->PERCENTILE_CONT() ? ::getFullText(actx->PERCENTILE_CONT()) : ::getFullText(actx->PERCENTILE_DISC());

					if (actx->over_clause()->row_or_range_clause())
						throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s cannot have a window frame", funcName.c_str()), getLineAndPos(actx->over_clause()->row_or_range_clause()));
					else if (actx->over_clause()->order_by_clause())
						throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s cannot have ORDER BY in OVER clause", funcName.c_str()), getLineAndPos(actx->over_clause()->order_by_clause()));
				}
			}
		}

		if (ctx->built_in_functions())
		{
			auto bctx = ctx->built_in_functions();

			/* Re-write system_user to sys.system_user(). */
			if (bctx->bif_no_brackets && bctx->SYSTEM_USER())
				rewritten_query_fragment.emplace(std::make_pair(bctx->bif_no_brackets->getStartIndex(), std::make_pair(::getFullText(bctx->SYSTEM_USER()), "sys.system_user()")));

			/* Re-write session_user to sys.session_user(). */
			if (bctx->bif_no_brackets && bctx->SESSION_USER())
				rewritten_query_fragment.emplace(std::make_pair(bctx->bif_no_brackets->getStartIndex(), std::make_pair(::getFullText(bctx->SESSION_USER()), "sys.session_user()")));
		}

		tsqlCommonMutator::exitFunction_call(ctx);
	}

	//////////////////////////////////////////////////////////////////////////////
	// statement analysis
	//////////////////////////////////////////////////////////////////////////////

	void enterQuery_specification(TSqlParser::Query_specificationContext *ctx) override
	{
		has_identity_function = false;
	}

	void exitOrder_by_expression(TSqlParser::Order_by_expressionContext *ctx) override
	{
		/*
		 * If there are multiple Order by clauses then we do not need to append
		 * NULLS LAST since cummulative order bys do not choose an index scan.
		 */
		if (!(ctx->parent && ((TSqlParser::Order_by_clauseContext *)ctx->parent)->order_bys.size() == 1))
			return;
		/*
		 * If the order by clause expression has a vector operator then we need to append
		 * NULLS LAST as the sort option such that vector index types can be chosen. This
		 * is done because the TSQL ordering is NULLS FIRST but for PG it's the opposite
		 * and the order does not matter for bit indexes.
		 */
		if (statementMutator && ctx->expression() && ((TSqlParser::Vector_exprContext *) ctx->expression())->vector_operator())
		{
			PLtsql_expr_query_mutator *mutator = statementMutator.get();
			if (ctx->ASC())
			{
				mutator->add(ctx->ASC()->getSymbol()->getStopIndex()+1, "", " NULLS LAST");
			}
			else if (ctx->DESC())
			{
				mutator->add(ctx->DESC()->getSymbol()->getStopIndex()+1, "", " NULLS LAST");
			}
			else
			{
				mutator->add(ctx->expression()->stop->getStopIndex()+1, "", " NULLS LAST");
			}
		}
	}

	void exitQuery_specification(TSqlParser::Query_specificationContext *ctx) override
	{
		// if select doesnt contains into but it contains identity we should throw error
		if(has_identity_function && !ctx->INTO()){
			throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "The IDENTITY function can only be used when the SELECT statement has an INTO clause.", getLineAndPos(ctx));
		}
		has_identity_function = false;
		if (statementMutator)
			process_query_specification(ctx, statementMutator.get());
	}

	void exitDrop_relational_or_xml_or_spatial_index(TSqlParser::Drop_relational_or_xml_or_spatial_indexContext *ctx) override
	{
		/* 
		 * Rewrite 'DROP INDEX index_name ON schema.table' as 'DROP INDEX index_name ON table SCHEMA schema'
		 * Note that using a 3-part or 4-part table name is not currently supported and has already been intercepted at this point.
		 */
		Assert(ctx->full_object_name());
		if (ctx->full_object_name()->schema)
		{
			std::string str = getFullText(ctx->full_object_name());				
			size_t startPosition = ctx->full_object_name()->start->getStartIndex();
			std::string tbName = getFullText(ctx->full_object_name()->object_name);	
			std::string schemaName = " SCHEMA " +getFullText(ctx->full_object_name()->schema);	
			rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(str, tbName+schemaName)));		
		}
	}

	void exitDrop_backward_compatible_index(TSqlParser::Drop_backward_compatible_indexContext *ctx) override
	{
		/*
		 * Rewrite 'DROP INDEX [schema.]table.index_name' as 'DROP INDEX index_name ON table [ SCHEMA schema ]'
		 */
		std::string str = getFullText(ctx);
		size_t startPosition = ctx->start->getStartIndex();
		std::string ixName = getFullText(ctx->index_name);
		std::string tbName = getFullText(ctx->table_or_view_name);
		std::string schemaName = "";
		if (ctx->owner_name) {
			schemaName = " SCHEMA " +getFullText(ctx->owner_name);
		}
		rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(str, ixName+" ON "+tbName+schemaName)));
	}

	//////////////////////////////////////////////////////////////////////////////
	// Special handling of ITVF
	//////////////////////////////////////////////////////////////////////////////
	void enterFunc_body_return_select_body(TSqlParser::Func_body_return_select_bodyContext *ctx) override
	{
		// prepare rewriting
		clear_rewritten_query_fragment();
	}

	void exitFunc_body_return_select_body(TSqlParser::Func_body_return_select_bodyContext *ctx) override
	{
		handleITVFBody(ctx);
		clear_rewritten_query_fragment();
	}

	void enterExecute_body_batch(TSqlParser::Execute_body_batchContext *ctx) override
	{
		in_execute_body_batch = true;							
		PLtsql_stmt *stmt = makeExecBodyBatch(ctx);
		attachPLtsql_fragment(ctx, stmt);
		graft(stmt, peekContainer());
		clear_rewritten_query_fragment();		
	}
		
	void exitExecute_body_batch(TSqlParser::Execute_body_batchContext *ctx) override
	{
		in_execute_body_batch = false;	
		PLtsql_stmt_exec *stmt = (PLtsql_stmt_exec *) getPLtsql_fragment(ctx);
		PLtsql_expr_query_mutator mutator(stmt->expr, ctx);
		add_rewritten_query_fragment_to_mutator(&mutator); 
		mutator.run();
		clear_rewritten_query_fragment();		
	}

	PLtsql_expr *rewrite_if_condition(TSqlParser::Search_conditionContext *ctx)
	{
		PLtsql_expr *expr = makeTsqlExpr(ctx, false);
		PLtsql_expr_query_mutator mutator(expr, ctx);
		add_rewritten_query_fragment_to_mutator(&mutator);
		mutator.run();
		clear_rewritten_query_fragment();

		/* Now we can prepend SELECT to rewritten search_condition */
		expr->query = strdup((std::string("SELECT ") + std::string(expr->query)).c_str());
		return expr;
	}

	void exitSearch_condition(TSqlParser::Search_conditionContext *ctx) override
	{
		if (!ctx->parent || !ctx->parent->parent)
			return;

		if (((TSqlParser::Cfl_statementContext *) ctx->parent->parent)->if_statement())
		{

			PLtsql_stmt_if *fragment = (PLtsql_stmt_if *) getPLtsql_fragment(ctx->parent->parent);
			fragment->cond = rewrite_if_condition(ctx);
		}
		else if (((TSqlParser::Cfl_statementContext *) ctx->parent->parent)->while_statement())
		{
			PLtsql_stmt_while *fragment = (PLtsql_stmt_while *) getPLtsql_fragment(ctx->parent->parent);
			fragment->cond = rewrite_if_condition(ctx);
		}
	}	
};

////////////////////////////////////////////////////////////////////////////////
// tsqlMutator
//
//  This listener class can mutate the parse tree (or input stream) before
//  the tsqlBuilder gets a chance to traverse the tree.  We use this class
//  to, for example, change the name of a function that appears in the given
//  source code.


class tsqlMutator : public TSqlParserBaseListener
{
public:		
	const std::vector<std::string> &ruleNames;	   		
	MyInputStream &stream; 
	bool in_procedure_parameter = false;    
	bool in_procedure_parameter_id = false;    

	std::vector<int> double_quota_places;

    explicit tsqlMutator(const std::vector<std::string> &rules, MyInputStream &s)
        : ruleNames(rules), stream(s)
    {
    }

public:
    void enterFunc_proc_name_schema(TSqlParser::Func_proc_name_schemaContext *ctx) override
    {	
	// We are looking at a function name; it may be a function call, or a
	// DROP function statement, or some other reference.
	//
	// If the function is named "char", change it to " chr" since 
	// "char" is a data type name in PostgreSQL

	TSqlParser::IdContext *proc = ctx->procedure;

	//  According to the grammar, an id can be any of the following:
	//
    //  id
	//	: ID
	//	| DOUBLE_QUOTE_ID
	//	| SQUARE_BRACKET_ID
	//	| keyword
	//	| id colon_colon id
	//
	//  We only translate CHAR to CHR for ID, DOUBLE_QUOTE_ID, or SQUARE_BRACKET_ID
	//  tokens.  CHAR is not a keyword so we just ignore that token type.  The last
	//  rule (id colon_colon id) looks like it might be a call to a type method; we
	//  ignore those as well.
	
	if (proc->keyword() || proc->colon_colon())
	    return;
	
	// FIXME: handle the schema here too
	std::string procNameStr = getIDName(proc->DOUBLE_QUOTE_ID(), proc->SQUARE_BRACKET_ID(), proc->ID());

	if (pg_strcasecmp(procNameStr.c_str(), "char") ==  0)
	{
	    if (proc->DOUBLE_QUOTE_ID())
		stream.setText(ctx->start->getStartIndex(), "\"chr\" ");
	    else if (proc->SQUARE_BRACKET_ID())
		stream.setText(ctx->start->getStartIndex(), "[chr] ");		
	    else
		stream.setText(ctx->start->getStartIndex(), " chr");
	}
    }	
    
	std::string
	getNodeDesc(ParseTree *t)
	{
		std::string result = Trees::getNodeText(t, this->ruleNames);
		return result;
	}

	void enterComparison_operator(TSqlParser::Comparison_operatorContext *ctx) override
	{
		// Handle multiple cases:
		// - 2-char comparison operators containing whitespace, i.e. '! =', '< >', etc.
		// - operators !< and !> (which may also contains whitespace), convert to >= and <= 
		std::string str = getFullText(ctx);
		std::string operator_final = "";			
		int fill = 0;

		if (str.length() > 2)
		{
			// This operator contains whitespace, remove it	        
			for(size_t i = 0; i < str.length(); i++) 
			{
			    if (!isspace(str[i])) 
			    	operator_final += str[i];
			}	   
			fill = str.length() - operator_final.length();			
		}

		// Handle !> and !< operators by converting to <= and >=
		if      (pg_strncasecmp(str.c_str(),            "!<", 2) == 0) operator_final = ">=";
		else if (pg_strncasecmp(operator_final.c_str(), "!<", 2) == 0) operator_final = ">=";
		else if (pg_strncasecmp(str.c_str(),            "!>", 2) == 0) operator_final = "<=";
		else if (pg_strncasecmp(operator_final.c_str(), "!>", 2) == 0) operator_final = "<=";
						
		// Fill with spaces until original length 
		operator_final.append(fill, ' ');  
			
		if (operator_final.length() > 0)
		{
			stream.setText(ctx->start->getStartIndex(), operator_final.c_str());
		}
	}

	// Tree listener overrides		
	void enterEveryRule(ParserRuleContext *ctx) override
	{
		std::string desc{getNodeDesc(ctx)};

		if (pltsql_enable_antlr_detailed_log)
			std::cout << "+entering (tsqlMutator)" << (void *) ctx << "[" << desc << "]" << std::endl;
	}

	void exitEveryRule(ParserRuleContext *ctx) override
	{
		std::string desc{getNodeDesc(ctx)};

		if (pltsql_enable_antlr_detailed_log)
			std::cout << "-leaving (tsqlMutator)" << (void *) ctx << "[" << desc << "]" << std::endl;
	}    
	
  void enterFunc_proc_name_server_database_schema(TSqlParser::Func_proc_name_server_database_schemaContext *ctx) override
  {
	// We are looking at a function name; it may be a function call, or a
	// DROP function statement, or some other reference.
	//
	// If the function is named "char", change it to " chr" since 
	// "char" is a data type name in PostgreSQL

	TSqlParser::IdContext *proc = ctx->procedure;

	#ifdef ENABLE_SPATIAL_TYPES
	if(!ctx->id().empty() && ctx->id()[0]->id().size() == 2)
	{
		TSqlParser::IdContext *idctx = ctx->id()[0];
		if(idctx->id()[0] && idctx->colon_colon() && idctx->id()[1])
		{
			std::string idText = idctx->id()[0]->getText();
			transform(idText.begin(), idText.end(), idText.begin(), ::tolower);
			size_t start = idText.find_first_not_of(" \n\r\t\f\v");
    		idText = (start == std::string::npos) ? "" : idText.substr(start);
			size_t end = idText.find_last_not_of(" \n\r\t\f\v");
    		idText = (end == std::string::npos) ? "" : idText.substr(0, end + 1);
			if(idText == "geography" || idText == "geometry"){
				// Replace colon_colon with underscores of the same length
				std::string colonText = idctx->colon_colon()->getText();
				std::string underScores(colonText.size(), '_');

				stream.setText(idctx->colon_colon()->start->getStartIndex(), underScores.c_str());
			}
		}
	}
	#endif
	
	// if the func name contains colon_colon, it must begin with it. see grammar
    if (ctx->colon_colon())
    {
        // Treat ::func() as func()
        stream.setText(ctx->start->getStartIndex(), "  ");
    }

	// See the commment in enterFunc_proc_name_schema() for an explanation of this code
	
	if (proc->keyword() || proc->colon_colon())
	    return;
	
	// FIXME: handle the schema here too
	std::string procNameStr = getIDName(proc->DOUBLE_QUOTE_ID(), proc->SQUARE_BRACKET_ID(), proc->ID());

	if (pg_strcasecmp(procNameStr.c_str(), "char") ==  0)
	{
	    if (proc->DOUBLE_QUOTE_ID())
		stream.setText(ctx->start->getStartIndex(), "\"chr\" ");
	    else if (proc->SQUARE_BRACKET_ID())
		stream.setText(ctx->start->getStartIndex(), "[chr] ");		
	    else
		stream.setText(ctx->start->getStartIndex(), " chr");
	}
    }

    // When a user exports an MSSQL application using a tool such as SSMS,
    // all type names are delimited by square brackets ([INT]). That forces
    // Postgres to compare the type name in a case-sensitive manner. Since
    // we don't have a type named INT (or Int, or iNT, ...), we throw a
    // "type name unknown" error when trying to use those delimited identifier.
    //
    // We know that no standard type names require delimited identifiers so
    // we strip off the delimiters here. This transforms [INT] to INT, which
    // is no longer delimited and will perform as a case-insensitive identifier.

    void enterData_type(TSqlParser::Data_typeContext *ctx) override
    {
	TSqlParser::Simple_nameContext *nameContext;

	// Make sure that we only adjust type names that match
	// the ext_type and unscaled_type parser rules
	
	if (ctx->ext_type)
	    nameContext = ctx->ext_type;
	else if (ctx->unscaled_type)
	    nameContext = ctx->unscaled_type;
	else
	    return;

	TSqlParser::IdContext *name = nameContext->name;

	if (name)
	{
	    tree::TerminalNode *terminal;

	    // And then remove the delimiters for double-quoted
	    // and square-bracketed names
	    
	    if (name->DOUBLE_QUOTE_ID())
		terminal = name->DOUBLE_QUOTE_ID();
	    else if (name->SQUARE_BRACKET_ID())
		terminal = name->SQUARE_BRACKET_ID();
	    else
		return;
	    
	    std::string str = terminal->getSymbol()->getText();

	    Assert(str.front() == '[' || str.front() == '"');
	    Assert(str.back() == ']' || str.back() == '"');
	    
	    str.front() = ' ';
	    str.back() = ' ';

	    stream.setText(name->start->getStartIndex(), str.c_str());
	}
    }

	void exitFunction_call(TSqlParser::Function_callContext *ctx) override
	{
		if (ctx->func_proc_name_server_database_schema())
		{
			auto fpnsds = ctx->func_proc_name_server_database_schema();

			if (fpnsds->DOT().empty() && fpnsds->id().back()->keyword()) /* built-in functions */
			{
				auto id = fpnsds->id().back();

				if (id->keyword()->SUBSTRING()) /* SUBSTRING */
				{
					if (ctx->function_arg_list() && !ctx->function_arg_list()->expression().empty())
					{
						auto first_arg = ctx->function_arg_list()->expression().front();
						if (dynamic_cast<TSqlParser::Constant_exprContext*>(first_arg) && static_cast<TSqlParser::Constant_exprContext*>(first_arg)->constant()->NULL_P())
							ereport(ERROR, (errcode(ERRCODE_SUBSTRING_ERROR), errmsg("Argument data type NULL is invalid for argument 1 of substring function")));
					}
				}
			}
		}
	}	

	void enterProcedure_param(TSqlParser::Procedure_paramContext *ctx) override
	{
		if (ctx->expression()) {
			in_procedure_parameter = true;
		}
	}
	
	void enterFull_column_name(TSqlParser::Full_column_nameContext *ctx) override
	{
		if (in_procedure_parameter) {
			in_procedure_parameter_id = true;
		}		
	}

	void exitFunc_body_returns_scalar(TSqlParser::Func_body_returns_scalarContext *ctx) override
	{	
		// If no AS keyword is specified, insert it prior to the BEGIN keyword.
		// This only applies to scalar functions; for other function types, the optional AS keyword 
		// is already supported.
		// Formally, this fix is required only for all Babelfish-defined function result datatypes such as
		// TINYINT, but for simplicity it's done for all data types.
		if (!ctx->AS() && ctx->BEGIN())
		{	
			std::string b = getFullText(ctx->BEGIN());
			size_t startPosition = ctx->BEGIN()->getSymbol()->getStartIndex();
			rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(b, "AS "+b)));	
		}
	}

	void exitProcedure_param(TSqlParser::Procedure_paramContext *ctx) override
	{
		in_procedure_parameter = false;
		in_procedure_parameter_id = false;

		// Look for parameter defaults that use an @@variable with no preceding whitespace
		if (ctx->EQUAL())
		{
			// The '=' char must be followed immediately by the variable without any character in between
			Assert(ctx->expression());			
			size_t startPosition = ctx->expression()->start->getStartIndex();
			if ((startPosition - ctx->EQUAL()->getSymbol()->getStopIndex()) == 1)
			{
				std::string var = getFullText(ctx->expression());
				// The subsequent default expression must be a variable starting with '@@'
				if (var.front() == '@') 
				{
					if (var.at(1) == '@') 
					{
						// Insert a space before the default variable name
						rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(var, " "+var)));
					}
				}
			}
		}
	}

	void exitId(TSqlParser::IdContext *ctx) override
	{
		if (in_procedure_parameter_id)
		{
			// This is a string parameter default which has been parsed as an identifier.
			// Put quotes around it: even though it is an identifier in the ANTLR parse tree, it will then be 
			// parsed as a string by the backend parser
			std::string str = getFullText(ctx);
				
			// When it's a bracketed identifier, remove the delimiters as T-SQL treats it as a string
			// When it's a quoted identifier, T-SQL also treats it as a string independent of the QUOTED_IDENTIFIER setting
			// (as we get here, it means QUOTED_IDENTIFIER=ON)
			// When it none of the above, it is an unquoted string 
			if (str.front() == '[') {
				Assert(str.back() == ']');

				// Temporarily turn this into a double-quoted string so that we can handle embedded quotes.
				// Since embedded double quotes inside a bracketed identifier are not escaped (as they would be in a 
				// double-quoted string), escape them first. We cannot just call rewriteDoubeQuotedString() since if we'd
				// have two adjacent double quotes, i.e. [a""b], this would then become [a"b] so we'd lose one quote.
				str = escapeDoubleQuotes(str);
				str = '"' + str.substr(1,str.length()-2) + '"';
				str = rewriteDoubleQuotedString(str);
			}
			else if (str.front() == '"') {
				Assert(str.back() == '"');
				str = rewriteDoubleQuotedString(str);
			}
			else {
				// Unquoted string, add quotes: there cannot be any quotes in the string otherwise it would 
				// not have been parsed as an identifier
				str = "'" + str + "'";
			}

			rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(getFullText(ctx), str)));
		}
	}

	// NB: similar code is in tsqlBuilder
	void exitChar_string(TSqlParser::Char_stringContext *ctx) override
	{
		if (in_procedure_parameter)
		{
			std::string str = getFullText(ctx);
			if (str.front() == 'N')
			{
				// This is only to make the assertion on str.front() easy (below)
				str.erase(0, 1);	
			}
						
			if (str.front() == '\'') 
			{
				// This is a single-quoted string used as parameter default: no further action needed
				Assert(str.back() == '\'');
			}
			else
			{
				// This is a double-quoted string used as parameter default.
				// (as we get here, it means QUOTED_IDENTIFIER=OFF)	
				
				Assert(str.front() == '"');
				Assert(str.back() == '"');
				
				// Change to PG-compatible single-quoted string
				str = rewriteDoubleQuotedString(str);
				rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(getFullText(ctx), str)));
			}
		}
	}

	// NB: the following are copied in tsqlBuilder
	void exitColumn_def_table_constraints(TSqlParser::Column_def_table_constraintsContext *ctx)
	{
		handleTableConstraintWithoutComma(ctx);
  }
	void exitConstant(TSqlParser::ConstantContext *ctx) override
	{
		// Check for floating-point number without exponent
		handleFloatWithoutExponent(ctx);
	}
	void exitPredicate(TSqlParser::PredicateContext *ctx) override
	{
		// Check for comparison operators directly followed by an '@@' variable, like =@@
		handleAtAtVarInPredicate(ctx);
	}	
	void exitUnary_op_expr(TSqlParser::Unary_op_exprContext *ctx) override
	{
		handleBitNotOperator(ctx);
	}
	void exitPlus_minus_bit_expr(TSqlParser::Plus_minus_bit_exprContext *ctx) override
	{
		handleBitOperators(ctx);
	}
	void exitMult_div_percent_expr(TSqlParser::Mult_div_percent_exprContext *ctx) override
	{
		handleModuloOperator(ctx);
	}

};

////////////////////////////////////////////////////////////////////////////////
// Error listener
////////////////////////////////////////////////////////////////////////////////

class MyParserErrorListener: public antlr4::BaseErrorListener
{
	virtual void syntaxError(antlr4::Recognizer *recognizer, antlr4::Token *offendingSymbol, size_t line, size_t charPositionInLine, const std::string &msg, std::exception_ptr e) override
	{
		/*
		 * ErrorData->cursorpos indicates character position from the beginning of query.
		 * This a character position not a byte-offset meaning multi-byte character is counted as 1.
		 * antlr4::Token::startIndex() returns the similar thing but it does not count '\n'. add (line#-1) here to adjust the index accordingly.
		 *
		 * TODO: from the connection of Windows, the query string may contain '\r'. We need more investigation here.
		 */
		int errorpos = offendingSymbol->getStartIndex() + line - 1;

		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("syntax error near %s at line %lu and character position %lu", recognizer->getTokenErrorDisplay(offendingSymbol).c_str(), line, charPositionInLine), line, errorpos);
	}
};

/*
 * Necessary checks and mutations for query_specification
 */
static void process_query_specification(
	TSqlParser::Query_specificationContext *qctx,
	PLtsql_expr_query_mutator *mutator)
{
	Assert(qctx->select_list());
	std::vector<TSqlParser::Select_list_elemContext *> select_elems = qctx->select_list()->select_list_elem();
	for (size_t i=0; i<select_elems.size(); ++i)
	{
		TSqlParser::Select_list_elemContext *elem = select_elems[i];

		if (elem->EQUAL() || elem->assignment_operator())
		{
			/* check if assignment is used in top-level select */
			if (!is_top_level_query_specification(qctx))
				throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "variable assignment can be used only in top-level SELECT", getLineAndPos(elem));

			/* check if assignment is involved with sql_union */
			auto pctx = qctx->parent;
			while (pctx)
			{
				if (dynamic_cast<TSqlParser::Query_expressionContext *>(pctx))
				{
					TSqlParser::Query_expressionContext *qectx = static_cast<TSqlParser::Query_expressionContext *>(pctx);
					if (!qectx->sql_union().empty())
						throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "variable assignment cannot be used with UNION, EXCEPT or INTERSECT", getLineAndPos(elem));
				}
				else if (dynamic_cast<TSqlParser::Sql_unionContext *>(pctx))
				{
					throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "variable assignment cannot be used in UNION, EXCEPT or INTERSECT", getLineAndPos(elem));
				}

				else
					break; /* no interest */

				pctx = pctx->parent;
			}
		}
	}

	bool is_freetext_predicate = false;
	if(qctx->where)
		is_freetext_predicate = check_freetext_predicate(qctx->where);

	PLtsql_expr *expr = mutator->expr;
	ParserRuleContext* baseCtx = mutator->ctx;

	/* remove unsupported_tokens */
	if (qctx->table_sources())
	{
		for (auto tctx : qctx->table_sources()->table_source_item()) // from-clause (to remove hints)
			post_process_table_source(tctx, expr, baseCtx, is_freetext_predicate);
	}

	/* handle special alias syntax and quote alias */
	for (size_t i=0; i<select_elems.size(); ++i)
	{
		TSqlParser::Select_list_elemContext *elem = select_elems[i];
		if (elem->expression_elem() && elem->expression_elem()->EQUAL())
		{
			/* rewrite "SELECT COL=expr" to "SELECT expr as "COL"" */
			auto expr_elem = elem->expression_elem();

			/* 1. remove "COL=" */
			std::string orig_text = ::getFullText(expr_elem->column_alias());
			mutator->add(expr_elem->column_alias()->start->getStartIndex(), orig_text, "");

			orig_text = ::getFullText(elem->expression_elem()->EQUAL());
			mutator->add(elem->expression_elem()->EQUAL()->getSymbol()->getStartIndex(), orig_text, "");

			/* 2. append "AS COL" to the end of expr */
			std::string repl_text(" AS ");
			if (is_quotation_needed_for_column_alias(expr_elem->column_alias()))
				repl_text += "\"" + ::getFullText(expr_elem->column_alias()) + "\"";
			else
				repl_text += ::getFullText(expr_elem->column_alias());
			mutator->add(expr_elem->expression()->stop->getStopIndex()+1, "", repl_text);
		}
		else if (elem->expression_elem() && elem->expression_elem()->as_column_alias())
		{
			/* if AS is missing, add it. */
			auto column_alias_as = elem->expression_elem()->as_column_alias();
			if (!column_alias_as->AS())
			{
				if (is_quotation_needed_for_column_alias(column_alias_as->column_alias()))
				{
					mutator->add(column_alias_as->start->getStartIndex(), "", " AS \"");
					mutator->add(column_alias_as->stop->getStopIndex() + 1, "", "\"");
				}
				else
					mutator->add(column_alias_as->start->getStartIndex(), "", " AS ");
			}
		}
	}
}

/*
 * Necessary mutations for select_statement_standalone which cannot be covered by tsqlBuilder
 */
static void process_select_statement_standalone(
	TSqlParser::Select_statement_standaloneContext *standaloneCtx,
	PLtsql_expr_query_mutator *mutator, tsqlBuilder &builder)
{
	Assert(mutator);
	auto ssm = std::make_unique<tsqlSelectStatementMutator>();
	ssm->mutator = mutator;
	antlr4::tree::ParseTreeWalker walker;
	walker.walk(ssm.get(), standaloneCtx);
}

/*
 * Necessary mutations for select_statement
 */
static void process_select_statement(
	TSqlParser::Select_statementContext *selectCtx,
	PLtsql_expr_query_mutator *mutator)
{
	/* remove unsupported_tokens */
	if (selectCtx->for_clause()) 
	{
		Assert(selectCtx->for_clause()->XML() || selectCtx->for_clause()->JSON());
		if (selectCtx->for_clause()->XML()) // FOR XML
		{
			Assert(selectCtx->for_clause()->RAW() || selectCtx->for_clause()->PATH());
		}
		else // for JSON
		{
			Assert(selectCtx->for_clause()->PATH() || selectCtx->for_clause()->AUTO());
		}
	}

	Assert(mutator);
	PLtsql_expr *expr = mutator->expr;
	ParserRuleContext* baseCtx = mutator->ctx;
	for (auto octx : selectCtx->option_clause()) // query hint
	{
		extractQueryHintsFromOptionClause(octx);
		removeCtxStringFromQuery(expr, octx, baseCtx);
	}
}

////////////////////////////////////////////////////////////////////////////////
// Entry point for ANTLR parser
////////////////////////////////////////////////////////////////////////////////
ANTLR_result
antlr_parser_cpp(const char *sourceText)
{
	ANTLR_result result = {
		false,	/* success */
		false,	/* parseTreeCreated */
		0,	/* errpos */
		0,	/* errcod */
		NULL,	/* errfmt */
		0,	/* n_errargs */
		{}	/* errargs */
	};
	instr_time	parseStart;
	instr_time	parseEnd;
	INSTR_TIME_SET_CURRENT(parseStart);
	INSTR_TIME_SET_ZERO(antlr_parse_time);

	// special handling for empty sourceText
	if (strlen(sourceText) == 0)
	{
		pltsql_parse_result = makeEmptyBlockStmt(0);
		result.success = true;
		result.parseTreeCreated = false;
		result.errpos = 0;
		result.errcod = 0;
		result.errfmt = NULL;
		result.n_errargs = 0;

		return result;
	}

	if (pltsql_enable_antlr_detailed_log)
	{
		std::string sep(120, '=');

		std::cout << sep << std::endl;
		std::cout << sourceText << std::endl;
		std::cout << sep << std::endl;
	}

	result = antlr_parse_query(sourceText, pltsql_enable_sll_parse_mode);

	/* 
	 * Only try to reparse if creation of the parse tree failed.  If parse tree is created, parsing mode will make no difference
	 * Generally the mutator steps are non-reentrant, if parsetree is created and mutators are run, subsequent parsing may produce
	 * incorrect error messages
	*/
	if (!result.success && !result.parseTreeCreated && pltsql_enable_sll_parse_mode)
	{
		elog(DEBUG1, "Query failed using SLL parser mode, retrying with LL parser mode query_text: %s", sourceText);
		result = antlr_parse_query(sourceText, false);
		if (result.parseTreeCreated)
			elog(WARNING, "Query parsing failed using SLL parser mode but succeeded with LL mode: %s", sourceText);
	}
	INSTR_TIME_SET_CURRENT(parseEnd);
	INSTR_TIME_SUBTRACT(parseEnd, parseStart);
	elog(DEBUG1, "ANTLR Query Parse Time for query: %s | %f ms", sourceText, 1000.0 * INSTR_TIME_GET_DOUBLE(parseEnd));

	/* And store time spent in ANTLR parsing so that we can emit it for EXPLAIN info if required */
	antlr_parse_time = parseEnd;

	return result;
}

ANTLR_result
antlr_parse_query(const char *sourceText, bool useSLLParsing) {
	ANTLR_result result = {
		false,	/* success */
		false,	/* parseTreeCreated */
		0,	/* errpos */
		0,	/* errcod */
		NULL,	/* errfmt */
		0,	/* n_errargs */
		{}	/* errargs */
	};
	MyInputStream sourceStream(sourceText);

	TSqlLexer lexer(&sourceStream);
	CommonTokenStream tokens(&lexer);

	MyParserErrorListener errorListner;

	TSqlParser parser(&tokens);
	volatile bool parseTreeCreated = false;

	if (useSLLParsing)
		parser.getInterpreter<atn::ParserATNSimulator>()->setPredictionMode(atn::PredictionMode::SLL);
	parser.removeErrorListeners();
	parser.addErrorListener(&errorListner);

	/* initialize line number. Correspoding to location_lineno_init() in non-antlr path */
	CurrentLineNumber = 1;

	try
	{
		// TSqlParser::Tsql_fileContext *tree = parser.tsql_file();
		tree::ParseTree *tree = nullptr;

		/*
		 * The semantic of "RETURN SELECT ..." depends on whether it is used in Inlined Table Value Function or not.
		 * In ITVF, they should be interpeted as return a result tuple of SELECT statement.
		 * but in the other case (i.e. procedure or SQL batch), it should be interpreted as two separate statements like "RETURN; SELECT ..."
		 *
		 * Currently, we have only proc_body in input so accessing pltsql_curr_compile to check this is a body of ITVF or not.
		 * If it is ITVF, we parsed it with func_body_return_select_body grammar.
		 */
		if (pltsql_curr_compile && pltsql_curr_compile->is_itvf) /* special path to itvf */
			tree = parser.func_body_return_select_body();
		else /* normal path */
			tree = parser.tsql_file();
		parseTreeCreated = true;
		if (pltsql_enable_antlr_detailed_log)
			std::cout << tree->toStringTree(&parser, true) << std::endl;

		/* visit all the node and publish instrumentation for unsupported feature */
		std::unique_ptr<TsqlUnsupportedFeatureHandler> unsupportedFeatureHandler = TsqlUnsupportedFeatureHandler::create();
		unsupportedFeatureHandler->setPublishInstr(true);
		unsupportedFeatureHandler->visit(tree);

		if (unsupportedFeatureHandler->hasUnsupportedFeature())
		{
			/* revisit the parsed tree and throw an error when we meet the first unsupported feature */
			unsupportedFeatureHandler->setPublishInstr(false);
			unsupportedFeatureHandler->setThrowError(true);
			unsupportedFeatureHandler->visit(tree);
		}

		std::unique_ptr<tsqlMutator> mutator = std::make_unique<tsqlMutator>(parser.getRuleNames(), sourceStream);
		antlr4::tree::ParseTreeWalker firstPass;
		firstPass.walk(mutator.get(), tree);

		// for batch-level statement (i.e. create procedure), we don't need to create actual PLtsql_stmt* by tsqlBuilder.
		// We can just relay the query string to backend parser via one PLtsql_stmt_execsql.
		TSqlParser::Tsql_fileContext *tsql_file = dynamic_cast<TSqlParser::Tsql_fileContext *>(tree);
		if (tsql_file && tsql_file->batch_level_statement())
		{
			/* By tsql grammar, batch-level statement can exist in tsql_file only
			 * and there should be exactly one batch_level_statement there
			 */
			auto ssm = std::make_unique<tsqlSelectStatementMutator>();
			handleBatchLevelStatement(tsql_file->batch_level_statement(), ssm.get());

			/* If PARSEONLY is enabled, replace with empty statement */
			if (pltsql_parseonly)
				pltsql_parse_result = makeEmptyBlockStmt(0);

			result.success = true;
			return result;
		}
		else
		{
			if (pltsql_curr_compile && pltsql_curr_compile->fn_oid == InvalidOid) /* new batch */
			{
				pltsql_curr_compile_body_position = 0;
				pltsql_curr_compile_body_lineno = 0;
			}
		}

		std::unique_ptr<tsqlBuilder> builder = std::make_unique<tsqlBuilder>(tree, parser.getRuleNames(), 
			sourceStream, mutator.get()->double_quota_places);
		antlr4::tree::ParseTreeWalker secondPass;
		secondPass.walk(builder.get(), tree);

		if (pltsql_dump_antlr_query_graph)
			toDotRecursive(tree, parser.getRuleNames(), sourceText);

		if (pltsql_parseonly)
			pltsql_parse_result = makeEmptyBlockStmt(0);

		result.parseTreeCreated = parseTreeCreated;
		result.success = true;
		return result;
	}
	catch (PGErrorWrapperException &e)
	{
		result.success = false;
		result.parseTreeCreated = parseTreeCreated;
		result.errcod = e.get_errcode();
		result.errpos = e.get_errpos();
		result.errfmt = e.get_errmsg();
		result.n_errargs = (e.get_errargs().size() < 5) ? e.get_errargs().size() : 5;
		for (size_t i=0; i<e.get_errargs().size(); ++i)
			result.errargs[i] = e.get_errargs()[i];

		CurrentLineNumber = e.get_errorline();

		return result; /* to avoid compiler warning. should not reach */
	}
	catch (std::exception &e) /* not to cause a crash just in case */
	{
		result.success = false;
		result.parseTreeCreated = parseTreeCreated;
		result.errcod = ERRCODE_SYNTAX_ERROR;
		result.errpos = 0;
		result.errfmt = pstrdup(e.what());
		result.n_errargs = 0;

		return result;
	}
	catch (...) /* not to cause a crash just in case. consume all exception before C-layer */
	{
		result.success = false;
		result.parseTreeCreated = parseTreeCreated;
		result.errcod = ERRCODE_SYNTAX_ERROR;
		result.errpos = 0;
		result.errfmt = "unknown error";
		result.n_errargs = 0;

		return result;
	}
}

extern "C"
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat-security"

void report_antlr_error(ANTLR_result r)
{
	Assert(r.n_errargs <= 5);
	switch (r.n_errargs)
	{
		case 0:
			ereport(ERROR, (errcode(r.errcod), errmsg(r.errfmt), errposition(r.errpos)));
			break;
		case 1:
			ereport(ERROR, (errcode(r.errcod), errmsg(r.errfmt, r.errargs[0]), errposition(r.errpos)));
			break;
		case 2:
			ereport(ERROR, (errcode(r.errcod), errmsg(r.errfmt, r.errargs[0], r.errargs[1]), errposition(r.errpos)));
			break;
		case 3:
			ereport(ERROR, (errcode(r.errcod), errmsg(r.errfmt, r.errargs[0], r.errargs[1], r.errargs[2]), errposition(r.errpos)));
			break;
		case 4:
			ereport(ERROR, (errcode(r.errcod), errmsg(r.errfmt, r.errargs[0], r.errargs[1], r.errargs[2], r.errargs[3]), errposition(r.errpos)));
			break;
		case 5:
			ereport(ERROR, (errcode(r.errcod), errmsg(r.errfmt, r.errargs[0], r.errargs[1], r.errargs[2], r.errargs[3], r.errargs[4]), errposition(r.errpos)));
			break;
		default:
			break;
	}
}

#pragma GCC diagnostic pop
} // extern "C"

template <class T>
bool
removeTokenFromOptionList(PLtsql_expr *expr, std::vector<T>& options, std::vector<antlr4::tree::TerminalNode *>& commas, antlr4::ParserRuleContext *ctx, GetTokenFunc<T> getTokenFunc)
{
	Assert(options.size() -1 == commas.size());

	bool all_removed = true;
	bool comma_carry_over = false;

	for (size_t i=0; i<options.size(); ++i)
	{
		if (getTokenFunc(options[i]))
		{
			removeCtxStringFromQuery(expr, options[i], ctx);

			// Concetually we have to remove any nearest COMMA.
			// But code is little bit dirty to handle some corner cases (the first few elems are removed or the last few elems are removed)
			if ((i==0 || comma_carry_over) && i<commas.size())
			{
				/* we have to remove next COMMA because it is the first elem or the prev COMMA is already removed */
				removeTokenStringFromQuery(expr, commas[i], ctx); // remove COMMA as well
				comma_carry_over = true;
			}
			else if (i-1<commas.size())
			{
				/* remove prev COMMA by default */
				removeTokenStringFromQuery(expr, commas[i-1], ctx);
			}
		}
		else
		{
			all_removed = false; /* there is a token not removed. don't remove WITH */
			comma_carry_over = false;
		}
	}

	return all_removed;
}

void
rewriteBatchLevelStatement(
	TSqlParser::Batch_level_statementContext *ctx, tsqlSelectStatementMutator *ssm, PLtsql_expr *expr)
{
	// rewrite batch-level stmt query
	PLtsql_expr_query_mutator mutator(expr, ctx);
	/* cppcheck-suppress autoVariables */
	ssm->mutator = &mutator;

	/*
	 * remove unnecessary create-options such as SCHEMABINDING, EXECUTE_AS_CALLER.
	 * basically, we check SCHEMABINDING,EXECUTE_AS_CALLER is specified of each kind of statement
	 * each code is very similar the grammar can be little bit different
	 * so handle them by one by one
	 */
	if (ctx->create_or_alter_function())
	{
		if (ctx->create_or_alter_function()->func_body_returns_select()) /* CREATE FUNCTION ... RETURNS TABLE RETURN SELECT ... */
		{
			auto cctx = ctx->create_or_alter_function()->func_body_returns_select();
			if (cctx->WITH())
			{
				auto options = cctx->function_option();
				auto commas = cctx->COMMA();
				GetTokenFunc<TSqlParser::Function_optionContext*> getToken = [](TSqlParser::Function_optionContext* o) {
					if (o->execute_as_clause())
						return o->execute_as_clause()->CALLER();
					return o->SCHEMABINDING();
				};
				bool all_removed = removeTokenFromOptionList(expr, options, commas, ctx, getToken);
				if (all_removed)
					removeTokenStringFromQuery(expr, cctx->WITH(), ctx);
			}
		}
		else if (ctx->create_or_alter_function()->func_body_returns_table()) /* CREATE FUNCTION ... RETURNS TABLE(COLUMN_DEFINITION) AS BEGIN ... END */
		{
			auto cctx = ctx->create_or_alter_function()->func_body_returns_table();
			if (cctx->WITH())
			{
				auto options = cctx->function_option();
				auto commas = cctx->COMMA();
				GetTokenFunc<TSqlParser::Function_optionContext*> getToken = [](TSqlParser::Function_optionContext* o) {
					if (o->execute_as_clause())
						return o->execute_as_clause()->CALLER();
					return o->SCHEMABINDING();
				};
				bool all_removed = removeTokenFromOptionList(expr, options, commas, ctx, getToken);
				if (all_removed)
					removeTokenStringFromQuery(expr, cctx->WITH(), ctx);
			}

			if (cctx->table_type_definition() && cctx->table_type_definition()->column_def_table_constraints())
			{
				for (auto cdtctx : cctx->table_type_definition()->column_def_table_constraints()->column_def_table_constraint())
				{
					if (cdtctx->table_constraint() && cdtctx->table_constraint()->UNIQUE())
						rewritten_query_fragment.emplace(std::make_pair(cdtctx->table_constraint()->UNIQUE()->getSymbol()->getStopIndex()+1 , std::make_pair("", " NULLS NOT DISTINCT")));

					if (cdtctx->column_definition() && !cdtctx->column_definition()->column_constraint().empty())
					{
						for (auto actx: cdtctx->column_definition()->column_constraint())
						{
							if (actx->UNIQUE())
								rewritten_query_fragment.emplace(std::make_pair(actx->UNIQUE()->getSymbol()->getStopIndex()+1 , std::make_pair("", " NULLS NOT DISTINCT")));
						}
					}

				}
			}
		}
		else if (ctx->create_or_alter_function()->func_body_returns_scalar()) /* CREATE FUNCTON ... RETURNS INT RETURN ... */
		{
			auto cctx = ctx->create_or_alter_function()->func_body_returns_scalar();
			if (cctx->WITH())
			{
				auto options = cctx->function_option();
				auto commas = cctx->COMMA();
				GetTokenFunc<TSqlParser::Function_optionContext*> getToken = [](TSqlParser::Function_optionContext* o) {
					if (o->execute_as_clause())
						return o->execute_as_clause()->CALLER();
					return o->SCHEMABINDING();
				};
				bool all_removed = removeTokenFromOptionList(expr, options, commas, ctx, getToken);
				if (all_removed)
					removeTokenStringFromQuery(expr, cctx->WITH(), ctx);
			}
		}
		else if (ctx->create_or_alter_function()->func_body_returns_table_clr())
		{
			auto cctx = ctx->create_or_alter_function()->func_body_returns_table_clr();
			if (cctx->WITH())
			{
				auto options = cctx->function_option();
				auto commas = cctx->COMMA();
				GetTokenFunc<TSqlParser::Function_optionContext*> getToken = [](TSqlParser::Function_optionContext* o) {
					if (o->execute_as_clause())
						return o->execute_as_clause()->CALLER();
					return o->SCHEMABINDING();
				};
				bool all_removed = removeTokenFromOptionList(expr, options, commas, ctx, getToken);
				if (all_removed)
					removeTokenStringFromQuery(expr, cctx->WITH(), ctx);
			}
		}
		else
			Assert(0);

		for (auto param : ctx->create_or_alter_function()->procedure_param())
			if (param->VARYING())
				throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "Cannot use the VARYING option in a CREATE FUNCTION statement.", getLineAndPos(param->VARYING()));
	}
	else if (ctx->create_or_alter_procedure())
	{
		auto cctx = ctx->create_or_alter_procedure();
		if (cctx->WITH())
		{
			size_t num_commas_in_procedure_param = cctx->COMMA().size();
			auto options = cctx->procedure_option();
			/* COMMA is shared between procedure-param and WITH-clause. calculate the number of COMMA so that it can be removed properly */
			num_commas_in_procedure_param -= (cctx->procedure_option().size() - 1);
			auto commas = cctx->COMMA();
			std::vector<antlr4::tree::TerminalNode *> commas_in_with_clause;
			commas_in_with_clause.insert(commas_in_with_clause.begin(), commas.begin() + num_commas_in_procedure_param, commas.end());
			GetTokenFunc<TSqlParser::Procedure_optionContext*> getToken = [](TSqlParser::Procedure_optionContext* o) {
				if (o->execute_as_clause())
					return o->execute_as_clause()->CALLER();
				return o->SCHEMABINDING();
			};
			bool all_removed = removeTokenFromOptionList(expr, options, commas_in_with_clause, ctx, getToken);
			if (all_removed)
				removeTokenStringFromQuery(expr, cctx->WITH(), ctx);
		}

		for (auto param : ctx->create_or_alter_procedure()->procedure_param())
			if (param->VARYING())
					removeTokenStringFromQuery(expr, param->VARYING(), ctx);
	}
	else if (ctx->create_or_alter_trigger() && ctx->create_or_alter_trigger()->create_or_alter_dml_trigger())
	{
		auto cctx = ctx->create_or_alter_trigger()->create_or_alter_dml_trigger();
		/* DML trigger can have two WITH. one for trigger options and the other for WITH APPEND */
		if (cctx->WITH().size() > 1 || (cctx->WITH().size() == 1 && !cctx->APPEND()))
		{
			size_t num_commas_in_dml_trigger_operation = cctx->COMMA().size();
			auto options = cctx->trigger_option();
			/* COMMA is shared between dml_trigger_operation and WITH-clause. calculate the number of COMMA so that it can be removed properly */
			num_commas_in_dml_trigger_operation -= (cctx->trigger_option().size() - 1);
			auto commas = cctx->COMMA();
			std::vector<antlr4::tree::TerminalNode *> commas_in_with_clause;
			commas_in_with_clause.insert(commas_in_with_clause.begin(), commas.begin() , commas.end() - num_commas_in_dml_trigger_operation);
			GetTokenFunc<TSqlParser::Trigger_optionContext*> getToken = [](TSqlParser::Trigger_optionContext* o) {
				if (o->execute_as_clause())
					return o->execute_as_clause()->CALLER();
				return o->SCHEMABINDING();
			};
			bool all_removed = removeTokenFromOptionList(expr, options, commas_in_with_clause, ctx, getToken);
			if (all_removed)
				removeTokenStringFromQuery(expr, cctx->WITH(0), ctx);
		}
	}
	else if (ctx->create_or_alter_trigger() && ctx->create_or_alter_trigger()->create_or_alter_ddl_trigger())
	{
		auto cctx = ctx->create_or_alter_trigger()->create_or_alter_ddl_trigger();
		if (cctx->WITH())
		{
			size_t num_commas_in_ddl_trigger_operaion = cctx->COMMA().size();
			auto options = cctx->trigger_option();
			/* COMMA is shared between ddl_trigger_operation and WITH-clause. calculate the number of COMMA so that it can be removed properly */
			num_commas_in_ddl_trigger_operaion -= (cctx->trigger_option().size() - 1);
			auto commas = cctx->COMMA();
			std::vector<antlr4::tree::TerminalNode *> commas_in_with_clause;
			commas_in_with_clause.insert(commas_in_with_clause.begin(), commas.begin() , commas.end() - num_commas_in_ddl_trigger_operaion);
			GetTokenFunc<TSqlParser::Trigger_optionContext*> getToken = [](TSqlParser::Trigger_optionContext* o) {
				if (o->execute_as_clause())
					return o->execute_as_clause()->CALLER();
				return o->SCHEMABINDING();
			};
			bool all_removed = removeTokenFromOptionList(expr, options, commas_in_with_clause, ctx, getToken);
			if (all_removed)
				removeTokenStringFromQuery(expr, cctx->WITH(), ctx);
		}
	}
	else if (ctx->create_or_alter_view())
	{
		auto cctx = ctx->create_or_alter_view();
		/* view can have two WITH. one for view attribute and the other for WITH CHECK OPTION */
		if (cctx->WITH().size() > 1 || (cctx->WITH().size() == 1 && !cctx->CHECK()))
		{
			auto options = cctx->view_attribute();
			auto commas = cctx->COMMA();
			GetTokenFunc<TSqlParser::View_attributeContext*> getToken = [](TSqlParser::View_attributeContext* o) { return o->SCHEMABINDING(); };
			bool all_removed = removeTokenFromOptionList(expr, options, commas, ctx, getToken);
			if (all_removed)
				removeTokenStringFromQuery(expr, cctx->WITH(0), ctx);
		}
	}

	/* for_replication */
	if (ctx->create_or_alter_procedure())
		if (ctx->create_or_alter_procedure()->for_replication())
			removeCtxStringFromQuery(expr, ctx->create_or_alter_procedure()->for_replication(), ctx);
	if (ctx->create_or_alter_trigger() && ctx->create_or_alter_trigger()->create_or_alter_dml_trigger())
		if (ctx->create_or_alter_trigger()->create_or_alter_dml_trigger()->for_replication())
			removeCtxStringFromQuery(expr, ctx->create_or_alter_trigger()->create_or_alter_dml_trigger()->for_replication(), ctx);

	// Run common mutator
	tsqlCommonMutator cm;
	antlr4::tree::ParseTreeWalker cmwalker;
	cmwalker.walk(&cm, ctx);
	add_rewritten_query_fragment_to_mutator(&mutator);

	// Run select statement mutator
	antlr4::tree::ParseTreeWalker walker;
	walker.walk(ssm, ctx);
	add_rewritten_query_fragment_to_mutator(&mutator);

	mutator.run();
	ssm->mutator = nullptr;
	clear_rewritten_query_fragment();
}

static Token *
get_start_token_of_batch_level_stmt_body(TSqlParser::Batch_level_statementContext *ctx)
{
	if (ctx->create_or_alter_function())
	{
		auto fctx = ctx->create_or_alter_function();
		if (fctx->func_body_returns_select())
			return fctx->func_body_returns_select()->func_body_return_select_body()->getStart();
		else if (fctx->func_body_returns_table() && !fctx->func_body_returns_table()->sql_clauses().empty())
			return fctx->func_body_returns_table()->sql_clauses()[0]->getStart();
		else if (fctx->func_body_returns_scalar() && !fctx->func_body_returns_scalar()->sql_clauses().empty())
			return fctx->func_body_returns_scalar()->sql_clauses()[0]->getStart();
	}
	else if (ctx->create_or_alter_procedure())
	{
		auto pctx = ctx->create_or_alter_procedure();
		if (!pctx->sql_clauses().empty())
			return pctx->sql_clauses()[0]->getStart();
	}
	else if (ctx->create_or_alter_trigger() && ctx->create_or_alter_trigger()->create_or_alter_dml_trigger())
	{
		auto tctx = ctx->create_or_alter_trigger()->create_or_alter_dml_trigger();
		if (!tctx->sql_clauses().empty())
			return tctx->sql_clauses()[0]->getStart();
	}
	else if (ctx->create_or_alter_trigger() && ctx->create_or_alter_trigger()->create_or_alter_ddl_trigger())
	{
		auto tctx = ctx->create_or_alter_trigger()->create_or_alter_ddl_trigger();
		if (!tctx->sql_clauses().empty())
			return tctx->sql_clauses()[0]->getStart();
	}
	else if (ctx->create_or_alter_view())
	{
		auto vctx = ctx->create_or_alter_view();
		return vctx->select_statement_standalone()->getStart();
	}

	return nullptr;
}

void
handleBatchLevelStatement(TSqlParser::Batch_level_statementContext *ctx, tsqlSelectStatementMutator *ssm)
{
	// batch-level statment can be inputted in SQL batch only (by inline_handler) or has empty body. getLineNo() will not be affected by uninitialized pltsql_curr_compile_body_lineno.
	Assert(pltsql_curr_compile->fn_oid == InvalidOid || ctx->SEMI());

	PLtsql_stmt_block *result = (PLtsql_stmt_block *) palloc0(sizeof(*result));
	result->cmd_type = PLTSQL_STMT_BLOCK;
	result->lineno = getLineNo(ctx);
	result->label = NULL;
	result->body = NIL;
	result->n_initvars = 0;
	result->initvarnos = nullptr;
	result->exceptions = nullptr;

	PLtsql_stmt_init *init = (PLtsql_stmt_init *) palloc0(sizeof(*init));
	init->cmd_type = PLTSQL_STMT_INIT;
	init->lineno = getLineNo(ctx);
	init->label = NULL;
	init->inits = rootInitializers;

	result->body = list_make1(init);
	// create PLtsql_stmt_execsql to wrap all query string
	PLtsql_stmt_execsql *execsql = (PLtsql_stmt_execsql *) makeSQL(ctx);
	execsql->original_query = pstrdup((makeTsqlExpr(ctx, false))->query);

	rewriteBatchLevelStatement(ctx, ssm, execsql->sqlstmt);
	result->body = lappend(result->body, execsql);

	// check if it is a CREATE VIEW statement
	if (ctx->create_or_alter_view())
	{
		execsql->is_create_view = true;
		if (ctx->create_or_alter_view()->simple_name() && ctx->create_or_alter_view()->simple_name()->schema)
		{
			std::string schema_name = stripQuoteFromId(ctx->create_or_alter_view()->simple_name()->schema);
			if (!schema_name.empty())
				execsql->schema_name = pstrdup(downcase_truncate_identifier(schema_name.c_str(), schema_name.length(), true));
		}
	}

	Token* start_body_token = get_start_token_of_batch_level_stmt_body(ctx);

	pltsql_curr_compile_body_position = (start_body_token ? start_body_token->getStartIndex() : 0);
	pltsql_curr_compile_body_lineno = (start_body_token ? start_body_token->getLine() : 0);
	pltsql_parse_result = result;
}

bool
handleITVFBody(TSqlParser::Func_body_return_select_bodyContext *ctx)
{
	PLtsql_stmt_block *result = (PLtsql_stmt_block *) palloc0(sizeof(*result));
	result->cmd_type = PLTSQL_STMT_BLOCK;
	result->lineno = getLineNo(ctx);
	result->label = NULL;
	result->body = NIL;
	result->n_initvars = 0;
	result->initvarnos = nullptr;
	result->exceptions = nullptr;
	result->body = list_make1(makeReturnQueryStmt(ctx->select_statement_standalone(), true/*itvf*/));

	pltsql_parse_result = result;

	return true;
}

////////////////////////////////////////////////////////////////////////////////
// Diagrammer for PLtsql_stmt-based parse tree
////////////////////////////////////////////////////////////////////////////////

class tsqlGrapher
{
public:
	tsqlGrapher(const char *fileName)
		: out{fileName},
		  nodeID{1},
		  separator{""}
	{
	}
	
	int graphBlock(PLtsql_stmt_block *stmt, int parent, const char *parentField);
	int graphWhile(PLtsql_stmt_while *stmt, int parent, const char *parentField);
	int graphIf(PLtsql_stmt_if *stmt, int parent, const char *parentField);
	int graphGoto(PLtsql_stmt_goto *stmt, int parent, const char *parentField);
	int graphStmt(PLtsql_stmt *stmt, int parent, const char *parentField);
	int graphOther(PLtsql_stmt *stmt, int parent, const char *parentField);
	int graphPrint(PLtsql_stmt_print *stmt, int parent, const char *parentField);
	void graphLink(int from, int to, const char *fromField, const char *toField, int linkNo = -1);
	void graphStmtBeg(void *stmtPtr, int nodeID, const char *verb);
	void graphStmtEnd(int from, int to, const char *fromField, const char *toField);
	void graphAddField(const char *field, const std::string &payload);

	std::string quote(const std::string &src, const char *justify = "\\n");

	std::ofstream	out;
	

private:

	int				nodeID;
	const char *	separator;
	
};

extern "C"
{
	void toDotTSql(PLtsql_stmt *tree, const char *source, const char *fileName)
	{
		if (!pltsql_dump_antlr_query_graph)
			return;

		tsqlGrapher grapher(fileName);

		grapher.out << "digraph parsetree {" << std::endl;
		grapher.out << "   node [shape=record, fontname=\"Courier New\"];" << std::endl;
		grapher.out << "   graph [ " << std::endl;
		grapher.out << "     fontname = \"Courier New\"" << std::endl;
		grapher.out << "     label = \"" << grapher.quote(source, "\\l") << "\"" << std::endl;
		grapher.out << "   ];" << std::endl;

		grapher.graphStmt(tree, 0, nullptr);

		grapher.out << "}" << std::endl;
	}
}

void
tsqlGrapher::graphStmtBeg(void *stmtPtr, int nodeID, const char *verb)
{
	PLtsql_stmt *stmt = (PLtsql_stmt *) stmtPtr;

	out << "  node_" << nodeID << " ";
	out << "  [label = \"<f0> " << nodeID << "| <f1> " << (verb ? verb : pltsql_stmt_typename(stmt)) << "|{";

	// out << " [label = \"<next>|line:" << stmt->lineno << " " << "|" << (verb ? verb : pltsql_stmt_typename(stmt)) << "|{";

	separator = "";
}

int
tsqlGrapher::graphStmt(PLtsql_stmt *stmt, int parent, const char *parentField)
{

	if (stmt == 0)
		return 0;
	
	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_IF:
			return graphIf((PLtsql_stmt_if *) stmt, parent, parentField);
			
		case PLTSQL_STMT_BLOCK:
			return graphBlock((PLtsql_stmt_block *) stmt, parent, parentField);

		case PLTSQL_STMT_WHILE:
			return graphWhile((PLtsql_stmt_while *) stmt, parent, parentField);

		case PLTSQL_STMT_GOTO:
			return graphGoto((PLtsql_stmt_goto *) stmt, parent, parentField);

		case PLTSQL_STMT_PRINT:
			return graphPrint((PLtsql_stmt_print *) stmt, parent, parentField);
			
		default:
			return graphOther(stmt, parent, parentField);
	}
}

int
tsqlGrapher::graphWhile(PLtsql_stmt_while *stmt, int parent, const char *parentField)
{
	int myNodeID = ++nodeID;

	std::string cond{quote(stmt->cond->query)};

	this->graphStmtBeg(stmt, myNodeID, nullptr);
	this->graphAddField("cond", cond);
	this->graphAddField("body", "body");
	this->graphStmtEnd(parent, myNodeID, parentField, nullptr);

	ListCell *s;
	
	foreach(s, stmt->body)
	{
		nodeID = graphStmt((PLtsql_stmt *) lfirst(s), nodeID, nullptr);
	}

	return myNodeID;
}

int tsqlGrapher::graphGoto(PLtsql_stmt_goto *stmt, int parent, const char *parentField)
{
	int myNodeID = ++nodeID;

	this->graphStmtBeg(stmt, myNodeID, nullptr);
	this->graphAddField("targetLabel", std::string(stmt->target_label));
	this->graphStmtEnd(parent, myNodeID, parentField, nullptr);

	return myNodeID;
}

int tsqlGrapher::graphPrint(PLtsql_stmt_print *stmt, int parent, const char *parentField)
{
	int myNodeID = ++nodeID;
	PLtsql_expr *expr = (PLtsql_expr *) linitial(stmt->exprs);
	std::string predicate{quote(expr->query)};

	graphStmtBeg(stmt, myNodeID, nullptr);
	graphAddField("expr", std::string(quote(expr->query)));
	graphStmtEnd(parent, myNodeID, parentField, nullptr);

	return myNodeID;
}

int
tsqlGrapher::graphIf(PLtsql_stmt_if *stmt, int parent, const char *parentField)
{
	int myNodeID = ++nodeID;

	std::string predicate{quote(stmt->cond->query)};

	this->graphStmtBeg(stmt, myNodeID, nullptr);
	this->graphAddField("predicate", predicate);
	this->graphAddField("then_body", "true");
	this->graphAddField("else_body", "false");
	this->graphStmtEnd(parent, myNodeID, parentField, nullptr);

	graphStmt((PLtsql_stmt *) stmt->then_body, myNodeID, "then_body");
	graphStmt((PLtsql_stmt *) stmt->else_body, myNodeID, "else_body");

	return myNodeID;
}

int
tsqlGrapher::graphOther(PLtsql_stmt *stmt, int parent, const char *parentField)
{
	int myNodeID = ++nodeID;

	graphStmtBeg(stmt, myNodeID, nullptr);
	graphStmtEnd(parent, myNodeID, parentField, nullptr);

	return myNodeID;
}

void
tsqlGrapher::graphStmtEnd(int from, int to, const char *fromField, const char *toField)
{
	out << "}\"];" << std::endl;

	graphLink(from, to, fromField, toField);
}

void
tsqlGrapher::graphAddField(const char *field, const std::string &payload)
{
	out << separator;

	if (field)
		out << "<" << field << ">";
							   
	out << payload;

    separator = "|";
}

int
tsqlGrapher::graphBlock(PLtsql_stmt_block *stmt, int parent, const char *parentField)
{
	int myNodeID = ++nodeID;

	if (stmt->exceptions)
	{
		this->graphStmtBeg(stmt, myNodeID, "try/catch");
		this->graphAddField("body", "try");
		this->graphAddField("handler", "catch");
		this->graphStmtEnd(parent, myNodeID, parentField, nullptr);
	}
	else
	{
		this->graphStmtBeg(stmt, myNodeID, "block");
		this->graphAddField("body", "body");
		this->graphStmtEnd(parent, myNodeID, parentField, nullptr);
	}

	//int			 node	= myNodeID;
	const char	*fieldName = "body";

	ListCell	*s;
	
	foreach(s, stmt->body)
	{
		//node = graphStmt((PLtsql_stmt *) lfirst(s), myNodeID, fieldName);
		graphStmt((PLtsql_stmt *) lfirst(s), myNodeID, fieldName);
	}
	
#if 0
	foreach(s, stmt->exceptions->action)
	{
		node = graphStmt((PLtsql_stmt *) lfirst(s), nodeID, fieldName);
		fieldName = ":next";
	}
#endif
	return myNodeID;
}

void
tsqlGrapher::graphLink(int from, int to, const char *fromField, const char *toField, int linkNo)
{
	if (from == 0 || to == 0)
		return;

	out << "    node_" << from;
	if (fromField)
		out << ":" << fromField;

	out << " -> ";

	out << "node_" << to;
	if(toField)
		out << ":" << toField;

	if (linkNo != -1)
		out << " [label=" << linkNo << "]";
	
	out << ";" << std::endl;
}

std::string
tsqlGrapher::quote(const std::string &src, const char *justify)
{
	std::string dst;
	
	for (auto i : src)
	{
		switch (i)
		{
			case '<':
			case '>':
			case '\"':
			case '\\':
			case '|':
			case '\'':
				dst += '\\';
				dst += i;
				break;

			case '\n':
				dst += justify;
				break;

			default:
				dst += i;
				break;
		}
	}

	return dst;
}

////////////////////////////////////////////////////////////////////////////////
// Diagrammer for ANTLR-generated parse tree
////////////////////////////////////////////////////////////////////////////////

class grapher
{
	
public:
	grapher(const char *fileName, const std::vector<std::string> &ruleNames)
		: out(fileName),
		  nodeID(1),
		  ruleNames(ruleNames)
	{
	}

	std::ofstream					 out;
	int								 nodeID;
	const std::vector<std::string>	&ruleNames;	

	void toDotAddNode(ParseTree *t, int parentNodeId);

	std::string quote(const std::string &src);
	
private:

};

void
grapher::toDotAddNode(ParseTree *t, int parentNodeId)
{
	int myNodeID = this->nodeID++;

    std::string nodeDesc = this->quote(antlrcpp::escapeWhitespace(Trees::getNodeText(t, this->ruleNames), false));
	PLtsql_stmt *fragment = getPLtsql_fragment(t);
	std::string fragmentDesc;
	
	if (fragment == nullptr)
		fragmentDesc = "";
	else
		fragmentDesc = std::string("| <f3> ") + pltsql_stmt_typename(fragment);
																					
	out << "  node_" << myNodeID << " ";
	out << "  [label = \"" << "{<f0> " << myNodeID << "| <f1> " << nodeDesc << "| <f2> " << (void *) t << fragmentDesc << "} \"];" << std::endl;

    if (parentNodeId)
		out << "node_" << parentNodeId << " -> node_" << myNodeID << ";" << std::endl;
							  
	for (size_t c = 0; c < t->children.size(); c++)
		toDotAddNode(t->children[c], myNodeID);

}

std::string
grapher::quote(const std::string &src)
{
	std::string dst;
	
	for (auto i : src)
	{
		switch (i)
		{
			case '<':
			case '>':
			case '\"':
			case '\\':
			case '|':
			case '\'':
				dst += '\\';
				dst += i;
				break;

			case '\n':
				dst += "\\n";
				break;

			default:
				dst += i;
				break;
		}
	}

	return dst;
}

static void
toDotRecursive(ParseTree *t, const std::vector<std::string> &ruleNames, const std::string &sourceText)
{
	grapher ctx("/tmp/antlr.dot", ruleNames);

	ctx.out << "digraph parsetree {" << std::endl;
	ctx.out << "   node [shape=record, fontname=\"Courier New\"];" << std::endl;
	ctx.out << "   graph [ " << std::endl;
	ctx.out << "     fontname = \"Courier New\"" << std::endl;
	ctx.out << "     label = \"" << ctx.quote(sourceText) << "\"" << std::endl;
	ctx.out << "   ];" << std::endl;
	
	ctx.toDotAddNode(t, 0);

	ctx.out << "}" << std::endl;
}

////////////////////////////////////////////////////////////////////////////////
// Node construction code
////////////////////////////////////////////////////////////////////////////////

PLtsql_stmt *
makeExecSql(ParserRuleContext *ctx)
{
	PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) palloc0(sizeof(*stmt));

	stmt->cmd_type = PLTSQL_STMT_EXECSQL;
	stmt->lineno = getLineNo(ctx);
	stmt->sqlstmt = makeTsqlExpr(ctx, false);
	stmt->into = false;
	stmt->strict = false;
	stmt->target = NULL;
	stmt->need_to_push_result = false;
	stmt->is_tsql_select_assign_stmt = false;
	stmt->insert_exec = false;

	return (PLtsql_stmt *) stmt;
}

PLtsql_expr *
makeTsqlExpr(const std::string &fragment, bool addSelect)
{
    PLtsql_expr *result = (PLtsql_expr *) palloc0(sizeof(*result));

	if (addSelect)
		result->query = pstrdup((fragment_SELECT_prefix + fragment).c_str());
	else
		result->query = pstrdup(fragment.c_str());
	
    result->plan     = NULL;
    result->paramnos = NULL;
    result->rwparam  = -1;
    result->ns	     = pltsql_ns_top();
    
    return result;
}

PLtsql_expr *
makeTsqlExpr(ParserRuleContext *ctx, bool addSelect)
{
	return makeTsqlExpr(::getFullText(ctx), addSelect);
}

// Helper function to remove/replace token from the query string in PLtsql_expr.
// Please make sure to pass correct baseCtx which generates PLtsql_expr
// because we'll figure out internal indices to be replaced based on relative indices
// Also, we support in-place replacement only. 'repl' string should not be longer than original one
void replaceTokenStringFromQuery(PLtsql_expr* expr, Token* startToken, Token* endToken, const char *repl, ParserRuleContext *baseCtx)
{
	size_t startIdx = startToken->getStartIndex();
	if (startIdx == INVALID_INDEX)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "can't generate an internal query", getLineAndPos(baseCtx));

	size_t endIdx = endToken->getStopIndex();
	if (endIdx == INVALID_INDEX)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "can't generate an internal query", getLineAndPos(baseCtx));

	size_t baseIdx = baseCtx->getStart()->getStartIndex();
	if (baseIdx == INVALID_INDEX)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "can't generate an internal query", getLineAndPos(baseCtx));

	// repl string is too long. we cannot replace with it in place.
	if (repl && strlen(repl) > endIdx - startIdx + 1)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "can't generate an internal query", getLineAndPos(baseCtx));

	Assert(expr->query);

	/* store and rewrite instead of in-place rewrite */
	rewritten_query_fragment.emplace(std::make_pair(startIdx, std::make_pair(startToken->getInputStream()->getText(misc::Interval(startIdx, endIdx)), repl ? std::string(repl) : std::string(endIdx - startIdx + 1, ' '))));
}

void replaceTokenStringFromQuery(PLtsql_expr* expr, TerminalNode* tokenNode, const char * repl, ParserRuleContext *baseCtx)
{
	replaceTokenStringFromQuery(expr, tokenNode->getSymbol(), tokenNode->getSymbol(), repl, baseCtx);
}

void replaceCtxStringFromQuery(PLtsql_expr* expr, ParserRuleContext *ctx, const char *repl, ParserRuleContext *baseCtx)
{
	replaceTokenStringFromQuery(expr, ctx->getStart(), ctx->getStop(), repl, baseCtx);
}

void removeTokenStringFromQuery(PLtsql_expr* expr, TerminalNode* tokenNode, ParserRuleContext *baseCtx)
{
	replaceTokenStringFromQuery(expr, tokenNode->getSymbol(), tokenNode->getSymbol(), NULL, baseCtx);
}

void removeCtxStringFromQuery(PLtsql_expr* expr, ParserRuleContext *ctx, ParserRuleContext *baseCtx)
{
	replaceTokenStringFromQuery(expr, ctx->getStart(), ctx->getStop(), NULL, baseCtx);
}

void extractQueryHintsFromOptionClause(TSqlParser::Option_clauseContext *octx)
{
	if (!enable_hint_mapping)
		return; // do nothing

	for (auto option: octx->option())
	{
		if (option->TABLE())
		{
			std::string table_name = ::getFullText(option->table_name()->table);
			if (!table_name.empty())
			{
				for (auto table_hint: option->table_hint())
				{
					extractTableHint(table_hint, table_name);
				}
			}
		}
		else if (option->JOIN())
			extractJoinHintFromOption(option);
		else if (option->FORCE() && option->ORDER())
			query_hints.push_back("Set(join_collapse_limit 1)");
		else if (option->MAXDOP() && option->DECIMAL())
		{
			std::string value = ::getFullText(option->DECIMAL());
			if (!value.empty())
			{
				/* 
				 * The MAXDOP hint should be handled specially the hint value is 0
				 * This is because in T-SQL, setting MAXDOP to 0 allows SQL Server to use all the available processors up to 64 processors
 				 * However, if we set the GUC max_parallel_workers_per_gather to 0, it disables parallelism in P-SQL
 				 * Thus, we need to set the GUC value to 64 instead.
 				 */
				if (stoi(value) == 0)
					value = "64";
				query_hints.push_back("Set(max_parallel_workers_per_gather " + value + ")");
			}
		}
	}

	if (isJoinHintInOptionClause)
	{
		if (!join_hints_info[LOOP_QUERY_HINT])
			query_hints.push_back("Set(enable_nestloop off)");
		if (!join_hints_info[HASH_QUERY_HINT])
			query_hints.push_back("Set(enable_hashjoin off)");
		if (!join_hints_info[MERGE_QUERY_HINT])
			query_hints.push_back("Set(enable_mergejoin off)");
	}
}

void extractTableHints(TSqlParser::With_table_hintsContext *tctx, std::string table_name)
{
	if (enable_hint_mapping && !table_name.empty())
	{
		for (auto table_hint: tctx->table_hint())
			extractTableHint(table_hint, table_name);
	}
}

std::string extractSchemaName(TSqlParser::Ddl_objectContext *dctx, TSqlParser::Table_source_itemContext *tctx)
{
	std::string schema_name = "";
	if (dctx == nullptr)
	{
		if (tctx && tctx->full_object_name() && tctx->full_object_name()->schema)
			schema_name = stripQuoteFromId(tctx->full_object_name()->schema);
	}
	else
	{
		if (dctx->full_object_name() && dctx->full_object_name()->schema)
			schema_name = stripQuoteFromId(dctx->full_object_name()->schema);
	}
	return schema_name;
}

std::string extractTableName(TSqlParser::Ddl_objectContext *dctx, TSqlParser::Table_source_itemContext *tctx)
{
	std::string table_name;
	if (dctx == nullptr && tctx != nullptr)
	{
		if (tctx->full_object_name())
			table_name = stripQuoteFromId(tctx->full_object_name()->object_name);
		else if (tctx->local_id())
			table_name = ::getFullText(tctx->local_id());
	}
	else if(dctx != nullptr)
	{
		if (dctx->full_object_name())
			table_name = stripQuoteFromId(dctx->full_object_name()->object_name);
		else if (dctx->local_id())
			table_name = ::getFullText(dctx->local_id());
	}
	return table_name;
}

void extractTableHint(TSqlParser::Table_hintContext *table_hint, std::string table_name)
{
	if (table_hint->INDEX())
	{
		std::string index_values = extractIndexValues(table_hint->index_value(), table_name);
		if (!index_values.empty())
			query_hints.push_back("IndexScan(" + table_name + " " + index_values + ")");
	}
}

void extractJoinHint(TSqlParser::Join_hintContext *join_hint, std::string table_names)
{
	if (join_hint->LOOP())
	{
		join_hints_info[LOOP_JOIN_HINT] = true;
		query_hints.push_back("NestLoop(" + table_names + ")");
	}
	else if (join_hint->HASH())
	{
		join_hints_info[HASH_JOIN_HINT] = true;
		query_hints.push_back("HashJoin(" + table_names + ")");
	}
	else if (join_hint->MERGE())
	{
		join_hints_info[MERGE_JOIN_HINT] = true;
		query_hints.push_back("MergeJoin(" + table_names + ")");
	}
}

void extractJoinHintFromOption(TSqlParser::OptionContext *option) {
	isJoinHintInOptionClause = true;
	if (option->LOOP())
		join_hints_info[LOOP_QUERY_HINT] = true;
	else if (option->HASH())
		join_hints_info[HASH_QUERY_HINT] = true;
	else if (option->MERGE())
		join_hints_info[MERGE_QUERY_HINT] = true;
}

std::string extractIndexValues(std::vector<TSqlParser::Index_valueContext *> index_valuesCtx, std::string table_name)
{
	if (alias_to_table_mapping.find(table_name) != alias_to_table_mapping.end())
		table_name = alias_to_table_mapping[table_name];

	//lowercase table names and later index names since they are lowercase in pg when hashed
	transform(table_name.begin(), table_name.end(), table_name.begin(), ::tolower);

	std::string index_values;
	for (auto ictx: index_valuesCtx)
	{
		if (ictx->id())
		{
			if (index_values.size())
				index_values += " ";
			std::string indexName = ::getFullText(ictx->id());

			transform(indexName.begin(), indexName.end(), indexName.begin(), ::tolower);
			char * index_value = construct_unique_index_name(const_cast <char *>(indexName.c_str()), const_cast <char *>(table_name.c_str()));
			index_values += std::string(index_value);
		}
	}
	return index_values;
}


#if 0
static void *
makeBatch(TSqlParser::Block_statementContext *ctx, tsqlBuilder &tsql)
{
	breakHere();
	
	PLtsql_stmt_block *result = (PLtsql_stmt_block *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_BLOCK;
	result->lineno = getLineNo(ctx);
	result->label = NULL;
	result->body = NIL;

	PLtsql_stmt_init *init = (PLtsql_stmt_init *) palloc0(sizeof(*init));

	init->cmd_type = PLTSQL_STMT_INIT;
	init->lineno = getLineNo(ctx);
	init->label = NULL;
	init->inits = rootInitializers;

	result->body = list_make1(init);

	for (auto clause : ctx->sql_clauses())
	{
		void *ptr = (void *) getPLtsql_fragment(clause->cfl_statement());
		
		result->body = lappend(result->body, ptr);
	}

	result->n_initvars = 0;
	result->initvarnos = nullptr;
	result->exceptions = nullptr;

	attachPLtsql_fragment(ctx, (PLtsql_stmt *) result);
	
	return result;
}
#endif

static void *
makeBatch(TSqlParser::Tsql_fileContext *ctx, tsqlBuilder &builder)
{
	breakHere();
	
	PLtsql_stmt_block *result = (PLtsql_stmt_block *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_BLOCK;
	result->lineno = getLineNo(ctx);
	result->label = NULL;
	result->body = NIL;

    PLtsql_stmt_init *init = (PLtsql_stmt_init *) palloc0(sizeof(*init));

	init->cmd_type = PLTSQL_STMT_INIT;
	init->lineno = getLineNo(ctx);
	init->label = NULL;
	init->inits = rootInitializers;

	result->body = list_make1(init);

	List *code = builder.getCode(ctx);
	ListCell *s;

	foreach(s, code)
	{
		result->body = lappend(result->body, lfirst(s));
	}
#if 0	
	for (auto x : ctx->children)
	{
		void *ptr = (void *) x;
		PLtsql_stmt *stmt = getPLtsql_fragment(x);
		
		ptr = nullptr;
	}
	
	for (auto clause : ctx->sql_clauses())
	{
		PLtsql_stmt *ptr = getPLtsql_fragment(clause->cfl_statement());

		if (ptr)
			result->body = lappend(result->body, (void *) ptr);
	}
#endif
	
	result->n_initvars = 0;
	result->initvarnos = nullptr;
	result->exceptions = nullptr;

	attachPLtsql_fragment(ctx, (PLtsql_stmt *) result);
	
	return result;
}

void *
makeBlockStmt(ParserRuleContext *ctx, tsqlBuilder &builder)
{
	PLtsql_stmt_block *result = (PLtsql_stmt_block *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_BLOCK;
	result->lineno = getLineNo(ctx);
	result->label = NULL;
	result->body = NIL;
	result->n_initvars = 0;
	result->initvarnos = nullptr;
	result->exceptions = nullptr;

	return result;
}

PLtsql_stmt_block *
makeEmptyBlockStmt(int lineno)
{
	PLtsql_stmt_block *result = (PLtsql_stmt_block *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_BLOCK;
	result->lineno = lineno;
	result->label = NULL;
	result->body = NIL;
	result->n_initvars = 0;
	result->initvarnos = nullptr;
	result->exceptions = nullptr;

	return result;
}

PLtsql_stmt *
makeBreakStmt(TSqlParser::Break_statementContext *ctx)
{
	PLtsql_stmt_exit	*result;

	result = (PLtsql_stmt_exit *) palloc0(sizeof(*result));
	
	result->cmd_type = PLTSQL_STMT_EXIT;
	result->is_exit  = true;
	result->lineno = getLineNo(ctx);
	result->label	 = NULL;
	result->cond	 = NULL;

	return (PLtsql_stmt *) result;
}

void *
makeContinueStmt(TSqlParser::Continue_statementContext *ctx)
{
	PLtsql_stmt_exit	*result;

	result = (PLtsql_stmt_exit *) palloc0(sizeof(*result));
	
	result->cmd_type = PLTSQL_STMT_EXIT;
	result->is_exit  = false;
	result->lineno = getLineNo(ctx);
	result->label	 = NULL;
	result->cond	 = NULL;

	return (PLtsql_stmt *) result;

}

PLtsql_stmt *
makeGotoStmt(TSqlParser::Goto_statementContext *ctx)
{
	// The grammar uses a single rule (goto_statement) to parse a
	// GOTO statement and to parse a label.
	//
	// If we have a GOTO statement, ctx->GOTO() will return non-null
	// If we are parsing a label, ctx->GOTO() will return null
	//
	// In either case, ctx->id() will return the name of the label

	if (ctx->GOTO() == nullptr)
	{
		// This is a statement label
		PLtsql_stmt_label *result = (PLtsql_stmt_label *) palloc0(sizeof(*result));

		result->cmd_type = PLTSQL_STMT_LABEL;
		result->lineno = getLineNo(ctx);
		std::string label_str = ::getFullText(ctx->id());
		result->label = pstrdup(downcase_truncate_identifier(label_str.c_str(), label_str.length(), true));

		return (PLtsql_stmt *) result;
	}
	else
	{
		// This is a GOTO statement
		PLtsql_stmt_goto *result = (PLtsql_stmt_goto *) palloc0(sizeof(*result));
	
		result->cmd_type = PLTSQL_STMT_GOTO;
		result->lineno = getLineNo(ctx);
		result->cond = NULL;
		result->target_pc = -1;
		std::string label_str = ::getFullText(ctx->id());
		result->target_label = pstrdup(downcase_truncate_identifier(label_str.c_str(), label_str.length(), true));
	
		return (PLtsql_stmt *) result;
	}
}

void *
makeIfStmt(TSqlParser::If_statementContext *ctx)
{
	// IF search_condition sql_clauses (ELSE sql_clauses)? ';'?
	
	PLtsql_stmt_if	*result = (PLtsql_stmt_if *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_IF;
	result->lineno = getLineNo(ctx);

	/*
	 * Note that 
	 * 1/ We fill in result->cond during exitIf_statement so that search_condition would have
	 *    been rewritten at that point. 
	 * 2/ We record the then_body and the else_body in exitIf_statement().
	 */

	return result;
}

void *
makeReturnStmt(TSqlParser::Return_statementContext *ctx)
{
	PLtsql_stmt_return *result = (PLtsql_stmt_return *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_RETURN;
	result->lineno = getLineNo(ctx);
	result->retvarno = -1;
	if (ctx->expression())
	{
		if (pltsql_curr_compile && pltsql_curr_compile->fn_prokind == PROKIND_PROCEDURE)
		{
			// create "CAST(%s AS INT)" expression to force int used for return-datatype. PG Optimizer can remove casting if unnecessary.
			std::string expr = std::string("CAST( ") + ::getFullText(ctx->expression()) + " AS INT)";
			result->expr = makeTsqlExpr(expr, true);
		}
		else 
		{
			result->expr = makeTsqlExpr(ctx->expression(), true);
			recordSelectFragmentOffsets(ctx->parent, ctx->expression());	
		}
	}
	else
		result->expr = NULL;

	if (pltsql_curr_compile->fn_prokind == PROKIND_PROCEDURE)
	{
		/*
		 * If we have any OUT parameters, remember which variable
		 * will hold the output tuple.
		 */
		if (pltsql_curr_compile->out_param_varno >= 0)
			result->retvarno = pltsql_curr_compile->out_param_varno;
	}

	return result;
}

void *
makeReturnQueryStmt(TSqlParser::Select_statement_standaloneContext *ctx, bool itvf)
{
	PLtsql_stmt_return_query *result = (PLtsql_stmt_return_query *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_RETURN_QUERY;
	result->lineno =getLineNo(ctx);

	auto *expr = makeTsqlExpr(ctx, false);
	result->query = expr;
	if (itvf)
	{
		auto *itvf_expr = makeTsqlExpr(ctx, false);
		PLtsql_expr_query_mutator itvf_mutator(itvf_expr, ctx);

		/*
		 * For inline table-valued function, we need to save another version of the query
		 * statement that we can call SPI_prepare to generate a plan, in order to figure
		 * out the column definition list. So, we replace all variable references by
		 * "CAST(NULL AS <type>)" in order to get the correct columnn list from
		 * planning.
		 */
		size_t base_index = ctx->getStart()->getStartIndex();
		if (base_index == INVALID_INDEX)
			throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "can't generate an internal query", getLineAndPos(ctx));

		/* we must add previous rewrite at first. */
		add_rewritten_query_fragment_to_mutator(&itvf_mutator);

		std::u32string query = utf8_to_utf32(itvf_expr->query);
		for (const auto &entry : local_id_positions)
		{
			const std::string& local_id = entry.second;
			const std::u32string& local_id_u32 = utf8_to_utf32(local_id.c_str());
			size_t offset = entry.first - base_index;
			if (query.substr(offset, local_id_u32.length()) == local_id_u32) // local_id maybe already deleted in some cases such as select-assignment. check here if it still exists)
			{
				int dno;
				PLtsql_nsitem *nse = pltsql_ns_lookup(pltsql_ns_top(), false, local_id.c_str(), nullptr, nullptr, nullptr);
				if (nse)
					dno = nse->itemno;
				else
					throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("\"%s\" is not a known variable", local_id.c_str()), getLineAndPos(ctx));

				PLtsql_var *var = (PLtsql_var *) pltsql_Datums[dno];
				std::string repl_text = std::string("CAST(NULL AS ") + std::string(var->datatype->typname) + std::string(")");
				itvf_mutator.add(entry.first, entry.second, repl_text);
			}
		}
		itvf_mutator.run();
		result->query->itvf_query = itvf_expr->query;
	}
	return result;
}

void *
makeThrowStmt(TSqlParser::Throw_statementContext *ctx)
{
	PLtsql_stmt_throw *result = (PLtsql_stmt_throw *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_THROW;
	result->lineno = getLineNo(ctx);
	result->params = NIL;

	if (ctx->throw_error_number())
	{
		result->params = lappend(result->params, makeTsqlExpr(ctx->throw_error_number(), true));
		result->params = lappend(result->params, makeTsqlExpr(ctx->throw_message(), true));
		result->params = lappend(result->params, makeTsqlExpr(ctx->throw_state(), true));
	}
	
	return result;
}

void *
makeTryCatchStmt(TSqlParser::Try_catch_statementContext *ctx)
{
	PLtsql_stmt_try_catch *result = (PLtsql_stmt_try_catch *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_TRY_CATCH;
	result->lineno = getLineNo(ctx);

	// Note that we record the then_body and the else_body
	// in exitIf_statement()

	return result;
}

void *
makeWaitForStmt(TSqlParser::Waitfor_statementContext *ctx)
{
	return nullptr;
}

void *
makeWhileStmt(TSqlParser::While_statementContext *ctx)
{
	PLtsql_stmt_while *result = (PLtsql_stmt_while *) palloc0(sizeof(*result));
	result->cmd_type = PLTSQL_STMT_WHILE;

	/* We will populate result->cond during exitSearch_condition() */

	return result;
}

void *
makePrintStmt(TSqlParser::Print_statementContext *ctx)
{
	PLtsql_stmt_print *result = (PLtsql_stmt_print *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_PRINT;
	result->exprs = list_make1(makeTsqlExpr(ctx->expression(), true));
	recordSelectFragmentOffsets(ctx->parent, ctx->expression());

	return result;
}

void *
makeRaiseErrorStmt(TSqlParser::Raiseerror_statementContext *ctx)
{
	PLtsql_stmt_raiserror *result = (PLtsql_stmt_raiserror *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_RAISERROR;
	result->lineno   = getLineNo(ctx);
	result->params   = NIL;
	result->paramno  = 3;
	result->log      = false;
	result->nowait   = false;
	result->seterror = false;

	// msg, severity, state
	result->params = lappend(result->params, makeTsqlExpr(ctx->msg->getText(), true));
	recordSelectFragmentOffsets(ctx->parent, ctx->raiseerror_msg());
		
	result->params = lappend(result->params, makeTsqlExpr(ctx->severity, true));
	result->params = lappend(result->params, makeTsqlExpr(ctx->state, true));
	
	// additional arguments
	if (ctx->argument.size() > 20)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "Too many substitution parameters for RAISERROR. Cannot exceed 20 substitution parameters.", getLineAndPos(ctx));
	
	if(does_msg_exceeds_params_limit(ctx->msg->getText()))
	{
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "Message text expects more than the maximum number of arguments (20).", getLineAndPos(ctx));
	}

	for (auto arg : ctx->argument)
	{
		result->params = lappend(result->params, makeTsqlExpr(arg->getText(), true));
		result->paramno++;
	}

	// WITH ...
	if (ctx->WITH())
	{
		for (auto raiseerror_option : ctx->raiseerror_option())
		{
			if (pg_strcasecmp(raiseerror_option->getText().c_str(), "LOG") == 0)
			{
				result->log = true;
				ereport(NOTICE,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("The LOG option is currently ignored.")));
			}
			else if (pg_strcasecmp(raiseerror_option->getText().c_str(), "NOWAIT") == 0)
				result->nowait = true;
			else if (pg_strcasecmp(raiseerror_option->getText().c_str(), "SETERROR") == 0)
				result->seterror = true;
			else
				Assert(0);
		}
	}

	return result;
}

PLtsql_stmt *
makeInitializer(int varno, int lineno, TSqlParser::ExpressionContext *val)
{
	PLtsql_stmt_assign *result = (PLtsql_stmt_assign *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_ASSIGN;
	result->lineno   = lineno;
	result->varno    = varno;
	result->expr     = makeTsqlExpr(val, true);

	// We've created an assignment statement out of the
	// initializer.  Now we want to attach that to the
	// initializer list for the function/procedure/batch.
	//
	// Note that for TSQL, we don't attach this initializer
	// the nearest enclosing block - variables are scoped
	// to the function/procedure/batch.

	return (PLtsql_stmt *) result;
}

std::vector<PLtsql_stmt *>
makeDeclareStmt(TSqlParser::Declare_statementContext *ctx, std::map<PLtsql_stmt *, ParseTree *> *declare_local_expr)
{
	std::vector<PLtsql_stmt *> result;

	// NOTE: This function returns nullptr if no initializer.
	//       otherwise, it will return assign_stmt for each
	//       declared variables as a vector.
	//
	//       Please note that we should keep the order of
	//       statement because initializer can be a function or
	//       global variable so they can be affected by
	//       preceeding statements. That's the reason why
	//       we don't use rootInitializer any more.

	if (ctx->LOCAL_ID() && ctx->table_type_definition())
	{
		std::string nameStr = ::getFullText(ctx->LOCAL_ID());
		std::string typeStr = ::getFullText(ctx->table_type_definition());
		const char *name = downcase_truncate_identifier(nameStr.c_str(), nameStr.length(), true);
		check_dup_declare(name);
		PLtsql_type *type = parse_datatype(typeStr.c_str(), 0);

		PLtsql_variable *var = pltsql_build_variable(name, 0, type, true);

		result.push_back(makeDeclTableStmt(var, type, getLineNo(ctx)));
	}
	else
	{
		for (TSqlParser::Declare_localContext *local : ctx->loc)
		{
			// FIXME: handle collation associated with data type

			std::string nameStr = ::getFullText(local->LOCAL_ID());
			const char *name = downcase_truncate_identifier(nameStr.c_str(), nameStr.length(), true);
			check_dup_declare(name);

			PLtsql_variable *var = nullptr;

			if (local->data_type()->CURSOR())
			{
				// cursor datatype needs a special build process
				var = (PLtsql_variable *) build_cursor_variable(name, getLineNo(local));
			}
			else
			{
				std::string typeStr = ::getFullText(local->data_type());
				PLtsql_type *type = parse_datatype(typeStr.c_str(), 0);  // FIXME: the second arg should be 'location'
				
				if (is_tsql_text_ntext_or_image_datatype(type->typoid))
				{
					throw PGErrorWrapperException(ERROR, ERRCODE_DATATYPE_MISMATCH, "The text, ntext, and image data types are invalid for local variables.", getLineAndPos(local->data_type()));
				}

				var = pltsql_build_variable(name, 0, type, true);

				if (var->dtype == PLTSQL_DTYPE_TBL)
					result.push_back(makeDeclTableStmt(var, type, getLineNo(ctx)));
				else if (local->expression()) 
				{
					PLtsql_stmt *e = makeInitializer(var->dno, getLineNo(ctx), local->expression());
					result.push_back(e);
					
					// DECLARE is different from other stmts under Another_statement, in that multiple fragments may be created.
					// By associating these with the expression() node, they can be stored without issues (otherwise, exitAnother_statement 
					// would use the context of the Another_statement rule for all fragments and all but the last would be lost).
					(*declare_local_expr).emplace(std::make_pair(e, local->expression()));
					
					// Each variable assignment in DECLARE becomes a fragment, for which rewriting may be required. Since all rewrite actions
					// will be accumulated by the time the rewriting happens (in exitAnother_statement), we need to keep track of where 
					// the assignment is located (start-end of range) so that we can apply the rewrites correctly.
					recordSelectFragmentOffsets(local->expression(), local->expression());
				}
			}
		}
	}

	return result;
}

static PLtsql_stmt *
makeDeclTableStmt(PLtsql_variable *var, PLtsql_type *type, int lineno)
{
	Assert(var->dtype == PLTSQL_DTYPE_TBL);

	PLtsql_stmt_decl_table *result = (PLtsql_stmt_decl_table *) palloc0(sizeof(*result));
	result->cmd_type = PLTSQL_STMT_DECL_TABLE;
	result->lineno = lineno;
	result->dno = var->dno;
	result->tbltypname = NULL;
	result->coldef = NULL;

	if (type->origtypname && type->origtypname->names)
		result->tbltypname = pstrdup(NameListToQuotedString(type->origtypname->names));

	if (type->coldef)
		result->coldef = pstrdup(type->coldef);

	return (PLtsql_stmt *) result;
}

// The following node types contain a vector of statements
//
//	* Tsql_fileContext
//	* Block_statementContext
//  * If_statementContext
//	* Try_catch_statementContext
//	Create_or_alter_procedureContext
/// Create_or_alter_triggerContext
//  Create_or_alter_dml_triggerContext
//  Create_or_alter_ddl_triggerContext
//	Func_body_returns_tableContext
//	Func_body_returns_scalarContext


PLtsql_stmt *
makeCfl(TSqlParser::Cfl_statementContext *ctx, tsqlBuilder &builder)
{
	void *result = nullptr;
	
	if (ctx->block_statement())
		result = makeBlockStmt(ctx->block_statement(), builder);
	else if (ctx->break_statement())
		result = makeBreakStmt(ctx->break_statement());
	else if (ctx->continue_statement())
		result = makeContinueStmt(ctx->continue_statement());
	else if (ctx->goto_statement())
		result = makeGotoStmt(ctx->goto_statement());
	else if (ctx->if_statement())
		result = makeIfStmt(ctx->if_statement());
	else if (ctx->return_statement())
		result = makeReturnStmt(ctx->return_statement());
	else if (ctx->throw_statement())
		result = makeThrowStmt(ctx->throw_statement());
	else if (ctx->try_catch_statement())
		result = makeTryCatchStmt(ctx->try_catch_statement());
	else if (ctx->waitfor_statement())
		result = makeWaitForStmt(ctx->waitfor_statement());
	else if (ctx->while_statement())
		result = makeWhileStmt(ctx->while_statement());
	else if (ctx->print_statement())
		result = makePrintStmt(ctx->print_statement());
	else if (ctx->raiseerror_statement())
		result = makeRaiseErrorStmt(ctx->raiseerror_statement());

	attachPLtsql_fragment(ctx, (PLtsql_stmt *) result);
	
	return (PLtsql_stmt *) result;
}

PLtsql_stmt *
makeSQL(ParserRuleContext *ctx)
{
	PLtsql_stmt *result;
	result = makeExecSql(ctx);

	attachPLtsql_fragment(ctx, result);
	
	return result;
}

static bool is_valid_set_option(std::string val)
{
	/* ON/OFF option and other special options (i.e. TRANSACTION ISOLATION LEVEL) are not incldued in this function because they are handled by grammar */
	return (pg_strcasecmp("DATEFIRST", val.c_str()) == 0) ||
		(pg_strcasecmp("DATEFORMAT", val.c_str()) == 0) ||
		(pg_strcasecmp("DEADLOCK_PRIORITY", val.c_str()) == 0) ||
		(pg_strcasecmp("LOCK_TIMEOUT", val.c_str()) == 0) ||
		(pg_strcasecmp("CONTEXT_INFO", val.c_str()) == 0) ||
		(pg_strcasecmp("LANGUAGE", val.c_str()) == 0) ||
		(pg_strcasecmp("QUERY_GOVERNOR_COST_LIMIT", val.c_str()) == 0);
}

static PLtsql_var * build_babelfish_guc_variable(TSqlParser::Special_variableContext *guc_ctx)
{
	PLtsql_var *var;
	int type;
	std::string command = ::getFullText(guc_ctx);
	std::transform(command.begin(), command.end(), command.begin(), ::tolower);

	if (guc_ctx->ROWCOUNT() || guc_ctx->DATEFIRST())
		type = INT4OID;
	else 
		type = TEXTOID;

	var = (PLtsql_var *) pltsql_build_variable(command.c_str(), 
						  0, 
						  pltsql_build_datatype(type, -1, InvalidOid, NULL), 
						  false);
	var->is_babelfish_guc = true;
	return var;
}

PLtsql_stmt *
makeSetStatement(TSqlParser::Set_statementContext *ctx, tsqlBuilder &builder)
{

	auto *expr = ctx->expression();
	auto *localID = ctx->LOCAL_ID();
	
	if (expr && localID)
	{
		auto targetText = ::getFullText(localID);
		int dno = check_assignable(localID);

		PLwdatum wdatum;
		PLword word;

		char *target = pstrdup(targetText.c_str());
		pltsql_parse_word(target, target, &wdatum, &word);
		
		PLtsql_stmt_assign *result =  (PLtsql_stmt_assign *) makeInitializer(dno, getLineNo(ctx), expr);	
		
		int posStart = expr->getStart()->getStartIndex();
		int posEnd   = expr->getStop()->getStopIndex() ;
		int posBracket = 0; // assigned below

		if (ctx->assignment_operator())
		{
			tree::TerminalNode *anode = nullptr;
			if (ctx->assignment_operator()->PLUS_ASSIGN())
				anode = ctx->assignment_operator()->PLUS_ASSIGN();
			else if (ctx->assignment_operator()->MINUS_ASSIGN())
				anode = ctx->assignment_operator()->MINUS_ASSIGN();
			else if (ctx->assignment_operator()->MULT_ASSIGN())
				anode = ctx->assignment_operator()->MULT_ASSIGN();
			else if (ctx->assignment_operator()->DIV_ASSIGN())
				anode = ctx->assignment_operator()->DIV_ASSIGN();
			else if (ctx->assignment_operator()->MOD_ASSIGN())
				anode = ctx->assignment_operator()->MOD_ASSIGN();
			else if (ctx->assignment_operator()->AND_ASSIGN())
				anode = ctx->assignment_operator()->AND_ASSIGN();
			else if (ctx->assignment_operator()->XOR_ASSIGN())
				anode = ctx->assignment_operator()->XOR_ASSIGN();
			else if (ctx->assignment_operator()->OR_ASSIGN())
				anode = ctx->assignment_operator()->OR_ASSIGN();
			else
				Assert(0);

			/*
			 * Now replace the query (new->expr->query) with a new
			 * form that eliminates the complex assignment operator.
			 *
			 * In other words, change the query from:
			 *    SET @var ^= 5 - 1
			 * to
			 *    SET @var = "@var" ^ (5 -1)
			 */
						 
			StringInfoData new_query;
			initStringInfo(&new_query);			
			appendStringInfo(&new_query, "SELECT \"%s\" %s (%s)", 
			                 target, 
			                 rewrite_assign_operator(anode), 
			                 result->expr->query + strlen("SELECT "));  // Pointer arithmetic: skip over the string  
			                                                            // preceding the expression, prior to the rewrite
			result->expr->query = new_query.data;
			
			// Record how many chars are added prior to the expression
			// "SELECT " : preceding chars before this reformatting the expression
			// +1 : the opening bracket
			posBracket = strcspn(new_query.data, "(") - strlen("SELECT ") + 1;
			                                                                 		
		}

		// Each variable assignment becomes a fragment, for which rewriting may be required. We need to keep track of where 
		// the assignment is located (start-end of range) so that we can apply the rewrites correctly
		recordSelectFragmentOffsets(ctx, posStart, posEnd, posBracket);
			
		return (PLtsql_stmt *) result;
	}
	else if (ctx->CURSOR())
	{
		PLtsql_stmt_assign *result = (PLtsql_stmt_assign *) palloc0(sizeof(*result));
		result->cmd_type = PLTSQL_STMT_ASSIGN;
		result->lineno = getLineNo(ctx);

		auto targetText = ::getFullText(localID);
		result->varno = lookup_cursor_variable(targetText.c_str())->dno;

		/* Generate cursor name based on pointer of PLtsql_stmt_assign since it is unique until procedure is dropped */
		StringInfoData ds;
		initStringInfo(&ds);
		appendStringInfo(&ds, "%s##sys_gen##%p", targetText.c_str(), (void *) result);
		PLtsql_var *curvar = build_cursor_variable(ds.data, getLineNo(ctx));

		int cursor_option = 0;
		for (auto pctx : ctx->declare_cursor_options())
			cursor_option = read_extended_cursor_option(pctx, cursor_option);

		TSqlParser::Select_statement_standaloneContext *sctx = ctx->select_statement_standalone();
		Assert(sctx);

		auto expr = makeTsqlExpr(sctx, false);

		PLtsql_expr_query_mutator mutator(expr, sctx);
		process_select_statement_standalone(sctx, &mutator, builder);
		add_rewritten_query_fragment_to_mutator(&mutator);
		mutator.run();

		curvar->cursor_explicit_expr = expr;
		curvar->cursor_explicit_argrow = -1;
		curvar->cursor_options = CURSOR_OPT_FAST_PLAN | cursor_option | PGTSQL_CURSOR_ANONYMOUS;
		curvar->isconst = true;

		resetStringInfo(&ds);
		appendStringInfo(&ds, "\"%s\"", curvar->refname);
		PLtsql_expr *new_curvar_expr = makeTsqlExpr(ds.data, true);
		new_curvar_expr->query = pstrdup(curvar->default_val->query);
		new_curvar_expr->ns = pltsql_ns_top();

		result->expr = new_curvar_expr;

		return (PLtsql_stmt *) result;
	}
	else if (ctx->set_special())
	{
		// Relaying set statement to main parser by default.
		// Please note that, internally backend parser adds a prefix "babelfish_pgsql.".
		// If the invalid set-option is used, as it is a qualifed SET-option, SET statement will not fail and add a placeholder variable. (please see find_option())
		TSqlParser::Set_specialContext *set_special_ctx = static_cast<TSqlParser::Set_specialContext*> (ctx->set_special());

		if (set_special_ctx->set_on_off_option().size() > 1)
		{
			PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) palloc0(sizeof(PLtsql_stmt_execsql));
			std::string query;
			for (auto option : set_special_ctx->set_on_off_option())
			{
				query += "SET ";
				query += getFullText(option);
				query += " ";
				query += getFullText(set_special_ctx->on_off());
				query += "; ";

				if (option->PARSEONLY())
				{
					if (pg_strcasecmp("on", getFullText(set_special_ctx->on_off()).c_str()) == 0)
					{
						pltsql_parseonly = true;
					}
					else if (pg_strcasecmp("off", getFullText(set_special_ctx->on_off()).c_str()) == 0)
					{
						pltsql_parseonly = false;
					}
				}
			}

			if (query.empty())
				return nullptr;

			stmt->cmd_type = PLTSQL_STMT_EXECSQL;
			stmt->lineno = getLineNo(ctx);
			stmt->sqlstmt = makeTsqlExpr(query, false);
			stmt->into = false;
			stmt->strict = false;
			stmt->target = NULL;
			stmt->need_to_push_result = false;
			stmt->is_tsql_select_assign_stmt = false;
			stmt->insert_exec = false;

			attachPLtsql_fragment(ctx, (PLtsql_stmt *) stmt);
			return (PLtsql_stmt *) stmt;
		}
		else if (set_special_ctx->set_on_off_option().size() == 1)
		{
			auto option = set_special_ctx->set_on_off_option().front();
			if (option->BABELFISH_SHOWPLAN_ALL() || (option->SHOWPLAN_ALL() && escape_hatch_showplan_all == EH_IGNORE))
				return makeSetExplainModeStatement(ctx, true);
			// PARSEONLY is handled at parse time.
			if (option->PARSEONLY())
			{
				if (pg_strcasecmp("on", getFullText(set_special_ctx->on_off()).c_str()) == 0)
				{
					pltsql_parseonly = true;
				}
				else if (pg_strcasecmp("off", getFullText(set_special_ctx->on_off()).c_str()) == 0)
				{
					pltsql_parseonly = false;
				}
			}

			return makeSQL(ctx);
		}
		else if (!set_special_ctx->id().empty())
		{
			// invalid SET-option will be ignored in backend. We have to figure out it is a valid SET-option or not here.
			// we don't have a detaield grammar for valid set option. check it with string comparison.
			std::string val = getFullText(set_special_ctx->id().front());
			if (!is_valid_set_option(val))
			{
				throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("unrecognized configuration parameter: %s", val.c_str()), getLineAndPos(set_special_ctx->id().front()));
			}
			if (pg_strcasecmp("CONTEXT_INFO", val.c_str()) == 0)
			{
				std::string param = getFullText(set_special_ctx->constant_LOCAL_ID());
				if (pg_strncasecmp(param.c_str(), "NULL", 4) == 0 || param.length() == 0 || (pg_strncasecmp(param.c_str(), "0x", 2) == 0 && param.length() - 2 > 256))
					throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, "SET CONTEXT_INFO option requires varbinary (128) NOT NULL parameter.", getLineAndPos(set_special_ctx->constant_LOCAL_ID()));

				PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) palloc0(sizeof(PLtsql_stmt_execsql));
				std::string query;
				query += "CALL bbf_set_context_info(convert(varbinary(128), ";
				query += param;
				query += "));";

				stmt->cmd_type = PLTSQL_STMT_EXECSQL;
				stmt->lineno = getLineNo(ctx);
				stmt->sqlstmt = makeTsqlExpr(query, false);
				stmt->into = false;
				stmt->strict = false;
				stmt->target = NULL;
				stmt->need_to_push_result = false;
				stmt->is_tsql_select_assign_stmt = false;
				stmt->insert_exec = false;

				attachPLtsql_fragment(ctx, (PLtsql_stmt *) stmt);
				return (PLtsql_stmt *) stmt;
			}
			else
				return makeSQL(ctx);
		}
		else if (set_special_ctx->OFFSETS())
			return nullptr;
		else if (set_special_ctx->STATISTICS())
		{
			for (auto kw : set_special_ctx->set_statistics_keyword())
			{
				if (kw->PROFILE() && escape_hatch_showplan_all == EH_IGNORE)
					return makeSetExplainModeStatement(ctx, false);
			}
			return nullptr;
		}
		else if (set_special_ctx->BABELFISH_STATISTICS() && set_special_ctx->PROFILE())
			return makeSetExplainModeStatement(ctx, false);
		else if(set_special_ctx->ISOLATION())
		{
			PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) makeSQL(ctx);
			stmt->is_set_tran_isolation = true;
			return (PLtsql_stmt *) stmt;
		}			
		else if(set_special_ctx->special_variable())
		{
			TSqlParser::Special_variableContext *guc_ctx = static_cast<TSqlParser::Special_variableContext*> (set_special_ctx->special_variable());
			/* build expression with the input variable */
			PLtsql_expr* input_expr = makeTsqlExpr(getFullText(set_special_ctx->LOCAL_ID()), true);
			/* build target variable for this GUC, so that in backend we can identify that target is GUC */
			PLtsql_var *target_var = build_babelfish_guc_variable(guc_ctx);
			/* assign expression to target */
			PLtsql_stmt_assign *result = (PLtsql_stmt_assign *) palloc0(sizeof(*result));
			result->cmd_type = PLTSQL_STMT_ASSIGN;
			result->lineno   = getLineNo(ctx);
			result->varno    = target_var->dno;
			result->expr     = input_expr;
			return (PLtsql_stmt *) result;
		}
		else
			return makeSQL(ctx);
	}
	else
		return nullptr;
}

PLtsql_stmt *
makeSetExplainModeStatement(TSqlParser::Set_statementContext *ctx, bool is_explain_only)
{
	TSqlParser::Set_specialContext *set_special_ctx;
	PLtsql_stmt_set_explain_mode *stmt;
	std::string on_off;
	size_t len;

	set_special_ctx = static_cast<TSqlParser::Set_specialContext*> (ctx->set_special());
	if (!set_special_ctx)
		return nullptr;

	stmt = (PLtsql_stmt_set_explain_mode *) palloc0(sizeof(PLtsql_stmt_set_explain_mode));
	on_off = getFullText(set_special_ctx->on_off());
	len = on_off.length();

	stmt->cmd_type = PLTSQL_STMT_SET_EXPLAIN_MODE;
	stmt->lineno = getLineNo(ctx);
	stmt->query = pstrdup(getFullText(ctx).c_str());
	if (is_explain_only)
	{
		stmt->is_explain_only = true;
		stmt->is_explain_analyze = false;
	}
	else
	{
		stmt->is_explain_only = false;
		stmt->is_explain_analyze = true;
	}

	if (pg_strncasecmp(on_off.c_str(), "on", len) == 0)
		stmt->val = true;
	else if (pg_strncasecmp(on_off.c_str(), "off", len) == 0)
		stmt->val = false;
	else
		return nullptr;

	attachPLtsql_fragment(ctx, (PLtsql_stmt *) stmt);
	return (PLtsql_stmt *) stmt;
}

PLtsql_stmt *
makeInsertBulkStatement(TSqlParser::Dml_statementContext *ctx)
{
	PLtsql_stmt_insert_bulk *stmt = (PLtsql_stmt_insert_bulk *) palloc0(sizeof(*stmt));
	TSqlParser::Bulk_insert_statementContext *bulk_ctx = ctx->bulk_insert_statement();
	std::vector<TSqlParser::Insert_bulk_column_definitionContext *> column_list = bulk_ctx->insert_bulk_column_definition();
	std::vector<TSqlParser::Bulk_insert_optionContext *> option_list = bulk_ctx->bulk_insert_option();

	std::string table_name;
	std::string schema_name;
	std::string db_name;
	stmt->column_refs = NIL;

	if (!bulk_ctx)
	{
		return nullptr;
	}

	stmt->cmd_type = PLTSQL_STMT_INSERT_BULK;
	if (bulk_ctx->ddl_object())
	{
		if (bulk_ctx->ddl_object()->local_id())
		{
			table_name = ::getFullText(bulk_ctx->ddl_object()->local_id()).c_str();
		}
		else if (bulk_ctx->ddl_object()->full_object_name())
		{
			if (bulk_ctx->ddl_object()->full_object_name()->object_name)
				table_name = stripQuoteFromId(bulk_ctx->ddl_object()->full_object_name()->object_name);
			if (bulk_ctx->ddl_object()->full_object_name()->schema)
				schema_name = stripQuoteFromId(bulk_ctx->ddl_object()->full_object_name()->schema);
			if (bulk_ctx->ddl_object()->full_object_name()->database)
				db_name = stripQuoteFromId(bulk_ctx->ddl_object()->full_object_name()->database);
		}
		if (!table_name.empty())
		{
			stmt->table_name = pstrdup(downcase_truncate_identifier(table_name.c_str(), table_name.length(), true));
		}
		if (!schema_name.empty())
		{
			stmt->schema_name = pstrdup(downcase_truncate_identifier(schema_name.c_str(), schema_name.length(), true));
		}
		if (!db_name.empty())
		{
			stmt->db_name = pstrdup(downcase_truncate_identifier(db_name.c_str(), db_name.length(), true));
		}

		/* create a list of columns to insert into */
		if (!column_list.empty())
		{
			for (size_t i = 0; i < column_list.size(); i++)
			{
				std::string column_refs;
				column_refs = ::stripQuoteFromId(column_list[i]->simple_column_name()->id());
				if (!column_refs.empty())
					stmt->column_refs = lappend(stmt->column_refs , pstrdup(downcase_truncate_identifier(column_refs.c_str(), column_refs.length(), true)));
			}
		}

		if (!option_list.empty())
		{
			for (size_t i = 0; i < option_list.size(); i++)
			{
				if (option_list[i]->ORDER())
					throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "insert bulk option order is not yet supported in babelfish", getLineAndPos(bulk_ctx->WITH()));

				else if (pg_strcasecmp("ROWS_PER_BATCH", ::getFullText(option_list[i]->id()).c_str()) == 0)
				{
					if (option_list[i]->expression())
						stmt->rows_per_batch = pstrdup(::getFullText(option_list[i]->expression()).c_str());
					else
						throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("incorrect syntax near %s",
													::getFullText(option_list[i]->id()).c_str()),
													getLineAndPos(option_list[i]->expression()));
				}
				else if (pg_strcasecmp("KILOBYTES_PER_BATCH", ::getFullText(option_list[i]->id()).c_str()) == 0)
				{
					if (option_list[i]->expression())
						stmt->kilobytes_per_batch = pstrdup(::getFullText(option_list[i]->expression()).c_str());
					else
						throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("incorrect syntax near %s",
													::getFullText(option_list[i]->id()).c_str()),
													getLineAndPos(option_list[i]->expression()));
				}
				else if (pg_strcasecmp("KEEP_NULLS", ::getFullText(option_list[i]->id()).c_str()) == 0)
					stmt->keep_nulls = true;

				else if (pg_strcasecmp("CHECK_CONSTRAINTS", ::getFullText(option_list[i]->id()).c_str()) == 0)
				{
					stmt->check_constraints = true;
				}
				else if (pg_strcasecmp("FIRE_TRIGGERS", ::getFullText(option_list[i]->id()).c_str()) == 0)
					throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "insert bulk option fire_triggers is not yet supported in babelfish", getLineAndPos(bulk_ctx->WITH()));

				else if (pg_strcasecmp("TABLOCK", ::getFullText(option_list[i]->id()).c_str()) == 0)
					throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "insert bulk option tablock is not yet supported in babelfish", getLineAndPos(bulk_ctx->WITH()));

				else
					throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("invalid insert bulk option %s", ::getFullText(option_list[i]->id()).c_str()), getLineAndPos(bulk_ctx->WITH()));
			}
		}
	}
	attachPLtsql_fragment(ctx, (PLtsql_stmt *) stmt);
	return (PLtsql_stmt *) stmt;
}

PLtsql_stmt *
makeExecuteStatement(TSqlParser::Execute_statementContext *ctx)
{
	TSqlParser::Execute_bodyContext *body = ctx->execute_body();
	Assert(body);

	if (body->LR_BRACKET()) /* execute a character string */
	{
		PLtsql_stmt_exec_batch *result = (PLtsql_stmt_exec_batch *) palloc0(sizeof(*result));
		result->cmd_type = PLTSQL_STMT_EXEC_BATCH;
		result->lineno = getLineNo(ctx);

		std::vector<TSqlParser::Execute_var_stringContext *> exec_strings = body->execute_var_string();
		std::stringstream ss;
		if (!exec_strings.empty())
		{
			ss << ::getFullText(exec_strings[0]);
			for (size_t i = 1; i < exec_strings.size(); i++)
			{
				ss << " + " << ::getFullText(exec_strings[i]);
			}
		}
		std::string expr_query = ss.str();
		result->expr = makeTsqlExpr(expr_query, true);
		
		return (PLtsql_stmt *) result;
	}
	else /* execute a stored procedure or function */
	{			
		return makeExecuteProcedure(ctx, "execute_statement");
	}
}

PLtsql_stmt *
makeDeclareCursorStatement(TSqlParser::Declare_cursorContext *ctx)
{
	Assert(ctx->cursor_name());
	std::string cursor_name = ::getFullText(ctx->cursor_name());

	PLtsql_var *curvar = nullptr;
	PLtsql_nsitem *nse = pltsql_ns_lookup(pltsql_ns_top(), false, cursor_name.c_str(), nullptr, nullptr, nullptr);
	if (nse)
	{
		// Unlike other variable, cursor variable can be declared multiple times in a batch.
		// In compilation time, we should make them refer to the same variable so that in runtime, duplicate declaration will be judged to whether valid or not.
		curvar = (PLtsql_var *) pltsql_Datums[nse->itemno];
	}
	else
	{
		curvar = build_cursor_variable(cursor_name.c_str(), getLineNo(ctx));
	}

	int cursor_option = 0;
	for (auto pctx : ctx->declare_cursor_options())
			cursor_option = read_extended_cursor_option(pctx, cursor_option);

	/* ANSI grammar */
	if (ctx->SCROLL())
	{
		if (cursor_option != 0)
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "mixture of ISO syntax and T-SQL extended syntax", getLineAndPos(ctx->SCROLL()));
		else
			cursor_option |= CURSOR_OPT_SCROLL;
	}

	if (ctx->READ() && ctx->ONLY())
	{
		if (cursor_option & TSQL_CURSOR_OPT_READ_ONLY)
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "both READ_ONLY and FOR READ ONLY cannot be specified on a cursor declaration", getLineAndPos(ctx->READ()));

		// note: SCROLL_LOCKS and OPTIMISTIC is not supported. so unsupported-feature error should be thrown already.
		if (cursor_option & TSQL_CURSOR_OPT_SCROLL_LOCKS)
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "both SCROLL_LOCKS and FOR READ ONLY cannot be specified on a cursor declaration", getLineAndPos(ctx->READ()));
		if (cursor_option & TSQL_CURSOR_OPT_OPTIMISTIC)
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "both OPTIMISTIC and FOR READ ONLY cannot be specified on a cursor declaration", getLineAndPos(ctx->READ()));
	}

	/*
	 * Other than pl/pgsql, T-SQL can distinguish a constant cursor (DECLARE CURSOR FOR QUERY)
	 * from a cursor variable (DECLARE @curvar CURSOR; SET @curvar = CURSOR FOR query).
	 * if query is given at declaration, mark it as constant.
	 * It is not assignable and it will affect cursor system function such as CURSOR_STATUS
	 */
	TSqlParser::Select_statement_standaloneContext *sctx = ctx->select_statement_standalone();
	if (sctx)
	{
		auto expr = makeTsqlExpr(sctx, false);
		curvar->cursor_explicit_expr = expr;
		curvar->cursor_explicit_argrow = -1;
		curvar->isconst = true;
	}

	PLtsql_stmt_decl_cursor *result = (PLtsql_stmt_decl_cursor *) palloc0(sizeof(PLtsql_stmt_decl_cursor));
	result->cmd_type = PLTSQL_STMT_DECL_CURSOR;
	result->lineno = getLineNo(ctx);
	result->curvar = curvar->dno;
	result->cursor_explicit_expr = curvar->cursor_explicit_expr;
	result->cursor_options = CURSOR_OPT_FAST_PLAN | cursor_option;

	return (PLtsql_stmt *) result;
}

PLtsql_stmt *
makeOpenCursorStatement(TSqlParser::Cursor_statementContext *ctx)
{
	Assert(ctx->OPEN());

	if (ctx->GLOBAL())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "GLOBAL CURSOR is not supported yet", getLineAndPos(ctx->GLOBAL()));

	PLtsql_stmt_open *result = (PLtsql_stmt_open *) palloc0(sizeof(PLtsql_stmt_open));
	result->cmd_type = PLTSQL_STMT_OPEN;
	result->lineno = getLineNo(ctx);
	result->curvar = -1;
	result->cursor_options = CURSOR_OPT_FAST_PLAN;

	auto targetText = ::getFullText(ctx->cursor_name());
	result->curvar = lookup_cursor_variable(targetText.c_str())->dno;

	return (PLtsql_stmt *) result;
}

PLtsql_stmt *
makeFetchCursorStatement(TSqlParser::Fetch_cursorContext *ctx)
{
	PLtsql_stmt_fetch *result = (PLtsql_stmt_fetch *) palloc(sizeof(PLtsql_stmt_fetch));
	result->cmd_type = PLTSQL_STMT_FETCH;
	result->lineno = getLineNo(ctx);
	result->target = NULL;
	result->is_move = false;
	/* set direction defaults: */
	result->direction = FETCH_FORWARD;
	result->how_many = 1;
	result->expr = NULL;
	result->returns_multiple_rows = false;

	/* cursor_name */
	auto targetText = ::getFullText(ctx->cursor_name());
	result->curvar = lookup_cursor_variable(targetText.c_str())->dno;

	/* FETCH CURSOR without destination should be blocked inside a function. */

	if (is_compiling_create_function() && !ctx->INTO())
	{
		throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_FUNCTION_DEFINITION, "SELECT statements included within a function cannot return data to a client.", getLineAndPos(ctx));
	}
	/* fetch option */
	if (ctx->NEXT()) {
		result->direction = FETCH_FORWARD;
	} else if (ctx->PRIOR()) {
		result->direction = FETCH_BACKWARD;
	} else if (ctx->FIRST()) {
		result->direction = FETCH_ABSOLUTE;
	} else if (ctx->LAST()) {
		result->direction = FETCH_ABSOLUTE;
		result->how_many = -1;
	} else if (ctx->ABSOLUTE()) {
		result->direction = FETCH_ABSOLUTE;
		result->expr = makeTsqlExpr(ctx->expression(), true);
	} else if (ctx->RELATIVE()) {
		result->direction = FETCH_RELATIVE;
		result->expr = makeTsqlExpr(ctx->expression(), true);
	} else {
		/* use default */
	}


	/* target handling: we'll do similar thing with read_into_scalar_list() */

	auto localIDs = ctx->LOCAL_ID();
	if (localIDs.empty()) /* no target */
		return (PLtsql_stmt *) result;

	if (localIDs.size() > 1024)
		throw PGErrorWrapperException(ERROR, ERRCODE_PROGRAM_LIMIT_EXCEEDED, "too many INTO variables specified", getLineAndPos(ctx->LOCAL_ID()[0]));

	PLtsql_row *row = (PLtsql_row *) palloc(sizeof(PLtsql_row));
	row->dtype = PLTSQL_DTYPE_ROW;
	row->refname = pstrdup("*internal*");
	row->lineno = getLineNo(ctx);
	row->rowtupdesc = NULL;
	row->nfields = localIDs.size();
	row->fieldnames = (char **) palloc(sizeof(char *) * row->nfields);
	row->varnos = (int *) palloc(sizeof(int) * row->nfields);

	for (size_t i=0; i<localIDs.size(); ++i)
	{
		targetText = ::getFullText(localIDs[i]);
		PLtsql_nsitem *nse = pltsql_ns_lookup(pltsql_ns_top(), false, targetText.c_str(), nullptr, nullptr, nullptr);
		if (nse)
		{
			if (nse->itemtype == PLTSQL_NSTYPE_REC ||
			    nse->itemtype == PLTSQL_NSTYPE_TBL)
			{
				throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "FETCH into non-scalar type is not supported yet", getLineAndPos(localIDs[i]));
			}
			else if (nse->itemtype == PLTSQL_NSTYPE_VAR)
			{
				PLtsql_var *var = (PLtsql_var *) pltsql_Datums[nse->itemno];
				if (is_tsql_text_ntext_or_image_datatype(var->datatype->typoid))
					throw PGErrorWrapperException(ERROR, ERRCODE_DATATYPE_MISMATCH, "Cannot fetch into text, ntext, and image variables.", getLineAndPos(localIDs[i]));
			}
			/* please refer to read_into_scalar_list */
			row->fieldnames[i] = pstrdup(targetText.c_str());
			row->varnos[i] = nse->itemno;
		}
		else
			throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("\"%s\" is not a known variable", targetText.c_str()), getLineAndPos(localIDs[i]));
	}

	pltsql_adddatum((PLtsql_datum *)row);
	result->target = (PLtsql_variable *) row;

	return (PLtsql_stmt *) result;
}

PLtsql_stmt *
makeCloseCursorStatement(TSqlParser::Cursor_statementContext *ctx)
{
	Assert(ctx->CLOSE());

	if (ctx->GLOBAL())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "GLOBAL CURSOR is not supported yet", getLineAndPos(ctx->GLOBAL()));

	PLtsql_stmt_close *result = (PLtsql_stmt_close *) palloc0(sizeof(PLtsql_stmt_close));
	result->cmd_type = PLTSQL_STMT_CLOSE;
	result->lineno = getLineNo(ctx);
	result->curvar = -1;

	auto targetText = ::getFullText(ctx->cursor_name());
	result->curvar = lookup_cursor_variable(targetText.c_str())->dno;

	return (PLtsql_stmt *) result;
}

PLtsql_stmt *
makeDeallocateCursorStatement(TSqlParser::Cursor_statementContext *ctx)
{
	if (ctx->GLOBAL())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "GLOBAL CURSOR is not supported yet", getLineAndPos(ctx->GLOBAL()));

	PLtsql_stmt_deallocate *result = (PLtsql_stmt_deallocate *) palloc0(sizeof(PLtsql_stmt_deallocate));
	result->cmd_type = PLTSQL_STMT_DEALLOCATE;
	result->lineno = getLineNo(ctx);;
	result->curvar = -1;

	auto targetText = ::getFullText(ctx->cursor_name());
	result->curvar = lookup_cursor_variable(targetText.c_str())->dno;

	return (PLtsql_stmt *) result;
}

PLtsql_stmt *
makeCursorStatement(TSqlParser::Cursor_statementContext *ctx)
{
	if (ctx->declare_cursor())
		return makeDeclareCursorStatement(ctx->declare_cursor());
	else if (ctx->OPEN())
		return makeOpenCursorStatement(ctx);
	else if (ctx->fetch_cursor())
		return makeFetchCursorStatement(ctx->fetch_cursor());
	else if (ctx->CLOSE())
		return makeCloseCursorStatement(ctx);
	else if (ctx->DEALLOCATE())
		return makeDeallocateCursorStatement(ctx);
	else
		Assert(0);
	return nullptr; /* not reachable. to bypass compilation warning */
}

PLtsql_stmt *
makeUseStatement(TSqlParser::Use_statementContext *ctx)
{
	PLtsql_stmt_usedb *result = (PLtsql_stmt_usedb *) palloc0(sizeof(PLtsql_stmt_usedb));
	result->cmd_type = PLTSQL_STMT_USEDB;
	result->lineno = getLineNo(ctx);

	Assert(ctx->id());
	std::string id_str = ::getFullText(ctx->id());
	if (ctx->id()->SQUARE_BRACKET_ID() || ctx->id()->DOUBLE_QUOTE_ID())
	{
		// remove [] or "" from the identifier
		id_str.erase(id_str.begin());
		id_str.erase(id_str.end() -1);
	}

	result->db_name = pstrdup(downcase_truncate_identifier(id_str.c_str(), id_str.length(), true));
	return (PLtsql_stmt *) result;
}

PLtsql_stmt *
makeKillStatement(TSqlParser::Kill_statementContext *ctx)
{
	PLtsql_stmt_kill *result = (PLtsql_stmt_kill *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_KILL;
	result->lineno = getLineNo(ctx);

	/* 
	 * Only supporting numeric argument for the spid,
	 * other flavours of KILL are intercepted in the parser.
	 */
	if (ctx->kill_process()) {
		char *strtol_endptr;
		std::string spidStr = ::getFullText(ctx->kill_process());
		result->spid = (int) strtol(spidStr.c_str(), &strtol_endptr, 10);
	}

	return (PLtsql_stmt *) result;
}

PLtsql_stmt *
makeGrantdbStatement(TSqlParser::Security_statementContext *ctx)
{
	if (ctx->grant_statement())
	{
		auto grant = ctx->grant_statement();
		if (!grant->permission_object() && grant->permissions())
		{
			for (auto perm : grant->permissions()->permission())
			{
				auto single_perm = perm->single_permission();
				if (single_perm->CONNECT())
				{
					PLtsql_stmt_grantdb *result = (PLtsql_stmt_grantdb *) palloc0(sizeof(PLtsql_stmt_grantdb));
					result->cmd_type = PLTSQL_STMT_GRANTDB;
					result->lineno = getLineNo(grant);
					result->is_grant = true;
					List *grantee_list = NIL;
					for (auto prin : grant->principals()->principal_id())
					{
						if (prin->id())
						{
							std::string id_str = ::getFullText(prin->id());
							char *grantee_name = pstrdup(downcase_truncate_identifier(id_str.c_str(), id_str.length(), true));
							grantee_list = lappend(grantee_list, grantee_name);
						}
						if (prin->PUBLIC())
						{
							char *grantee_name = pstrdup(PUBLIC_ROLE_NAME);
							grantee_list = lappend(grantee_list, grantee_name);
						}
					}
					result->grantees = grantee_list;
					return (PLtsql_stmt *) result;
				}
			}
		}
		else if (grant->ON() && grant->permission_object() && grant->permission_object()->permission_object_type() && grant->permission_object()->permission_object_type()->SCHEMA())
		{
			if (grant->principals() && grant->permissions())
			{
				PLtsql_stmt_grantschema *result = (PLtsql_stmt_grantschema *) palloc0(sizeof(PLtsql_stmt_grantschema));
				result->cmd_type = PLTSQL_STMT_GRANTSCHEMA;
				result->lineno = getLineNo(grant);
				result->is_grant = true;
				std::string schema_name;
				if (grant->permission_object()->full_object_name()->object_name)
				{
					schema_name = stripQuoteFromId(grant->permission_object()->full_object_name()->object_name);
					if (string_matches(schema_name.c_str(), "information_schema"))
						schema_name = "information_schema_tsql";
					result->schema_name = pstrdup(downcase_truncate_identifier(schema_name.c_str(), schema_name.length(), true));
				}
				List *grantee_list = NIL;
				for (auto prin : grant->principals()->principal_id())
				{
					if (prin->id())
					{
						std::string id_str = stripQuoteFromId(prin->id());
						char *grantee_name = pstrdup(downcase_truncate_identifier(id_str.c_str(), id_str.length(), true));
						grantee_list = lappend(grantee_list, grantee_name);
					}
					if (prin->PUBLIC())
					{
						char *grantee_name = pstrdup(PUBLIC_ROLE_NAME);
						grantee_list = lappend(grantee_list, grantee_name);
					}
				}
				int privileges = 0;
				for (auto perm: grant->permissions()->permission())
				{
					auto single_perm = perm->single_permission();
					if (single_perm->EXECUTE())
						privileges |= ACL_EXECUTE;
					if (single_perm->EXEC())
						privileges |= ACL_EXECUTE;
					if (single_perm->SELECT())
						privileges |= ACL_SELECT;
					if (single_perm->INSERT())
						privileges |= ACL_INSERT;
					if (single_perm->UPDATE())
						privileges |= ACL_UPDATE;
					if (single_perm->DELETE())
						privileges |= ACL_DELETE;
					if (single_perm->REFERENCES())
						privileges |= ACL_REFERENCES;
				}
				result->privileges = privileges;
				if (grant->WITH())
					result->with_grant_option = true;
				result->grantees = grantee_list;
				return (PLtsql_stmt *) result;
			}
		}
	}

	else if (ctx->revoke_statement())
	{
		auto revoke = ctx->revoke_statement();
		if (!revoke->permission_object() && revoke->permissions())
		{
			for (auto perm : revoke->permissions()->permission())
			{
				auto single_perm = perm->single_permission();
				if (single_perm->CONNECT())
				{
					PLtsql_stmt_grantdb *result = (PLtsql_stmt_grantdb *) palloc0(sizeof(PLtsql_stmt_grantdb));
					result->cmd_type = PLTSQL_STMT_GRANTDB;
					result->lineno = getLineNo(revoke);
					result->is_grant = false;
					List *grantee_list = NIL;

					for (auto prin : revoke->principals()->principal_id())
					{
						if (prin->id())
						{
							std::string id_str = ::getFullText(prin->id());
							char *grantee_name = pstrdup(downcase_truncate_identifier(id_str.c_str(), id_str.length(), true));
							grantee_list = lappend(grantee_list, grantee_name);
						}
						if (prin->PUBLIC())
						{
							char *grantee_name = pstrdup(PUBLIC_ROLE_NAME);
							grantee_list = lappend(grantee_list, grantee_name);
						}
					}
					result->grantees = grantee_list;
					return (PLtsql_stmt *) result;
				}
			}
		}

		else if (revoke->ON() && revoke->permission_object() && revoke->permission_object()->permission_object_type() && revoke->permission_object()->permission_object_type()->SCHEMA())
		{
			if (revoke->principals() && revoke->permissions())
			{
				PLtsql_stmt_grantschema *result = (PLtsql_stmt_grantschema *) palloc0(sizeof(PLtsql_stmt_grantschema));
				result->cmd_type = PLTSQL_STMT_GRANTSCHEMA;
				result->lineno = getLineNo(revoke);
				result->is_grant = false;
				std::string schema_name;
				if (revoke->permission_object()->full_object_name()->object_name)
				{
					schema_name = stripQuoteFromId(revoke->permission_object()->full_object_name()->object_name);
					result->schema_name = pstrdup(downcase_truncate_identifier(schema_name.c_str(), schema_name.length(), true));
				}
				List *grantee_list = NIL;
				for (auto prin : revoke->principals()->principal_id())
				{
					if (prin->id())
					{
						std::string id_str = stripQuoteFromId(prin->id());
						char *grantee_name = pstrdup(downcase_truncate_identifier(id_str.c_str(), id_str.length(), true));
						grantee_list = lappend(grantee_list, grantee_name);
					}
					if (prin->PUBLIC())
					{
						char *grantee_name = pstrdup(PUBLIC_ROLE_NAME);
						grantee_list = lappend(grantee_list, grantee_name);
					}
				}
				int privileges = 0;
				for (auto perm: revoke->permissions()->permission())
				{
					auto single_perm = perm->single_permission();
					if (single_perm->EXECUTE())
						privileges |= ACL_EXECUTE;
					if (single_perm->EXEC())
						privileges |= ACL_EXECUTE;
					if (single_perm->SELECT())
						privileges |= ACL_SELECT;
					if (single_perm->INSERT())
						privileges |= ACL_INSERT;
					if (single_perm->UPDATE())
						privileges |= ACL_UPDATE;
					if (single_perm->DELETE())
						privileges |= ACL_DELETE;
					if (single_perm->REFERENCES())
						privileges |= ACL_REFERENCES;
				}
				result->privileges = privileges;
				result->grantees = grantee_list;
				return (PLtsql_stmt *) result;
			}
		}
	}

	PLtsql_stmt *result;
	result = makeExecSql(ctx);
	attachPLtsql_fragment(ctx, result);
	return result;
}

PLtsql_stmt *
makeTransactionStatement(TSqlParser::Transaction_statementContext *ctx)
{
	PLtsql_stmt *result;

	result = makeExecSql(ctx);

	PLtsql_stmt_execsql *stmt = (PLtsql_stmt_execsql *) result;

	stmt->txn_data = (PLtsql_txn_data *) palloc0(sizeof(PLtsql_txn_data));
	auto *localID = ctx->LOCAL_ID();
	if (localID)
	{
		stmt->txn_data->txn_name_expr = makeTsqlExpr(::getFullText(localID), true);
	}
	else if(ctx->id())
	{
		std::string name = stripQuoteFromId(ctx->id());
		stmt->txn_data->txn_name = pstrdup(name.c_str());
	}

	return result;
}

std::vector<PLtsql_stmt *>
makeAnother(TSqlParser::Another_statementContext *ctx, tsqlBuilder &builder)
{
	std::vector<PLtsql_stmt *> result;
	std::map<PLtsql_stmt *, ParseTree *> declare_local_expr;

	if (ctx->declare_statement())
	{
		std::vector<PLtsql_stmt *> decl_result = makeDeclareStmt(ctx->declare_statement(), &declare_local_expr);
		result.insert(result.end(), decl_result.begin(), decl_result.end());
	}
	else if (ctx->set_statement())
		result.push_back(makeSetStatement(ctx->set_statement(), builder));
	else if (ctx->execute_statement())
		result.push_back(makeExecuteStatement(ctx->execute_statement()));
	else if (ctx->cursor_statement())
		result.push_back(makeCursorStatement(ctx->cursor_statement()));
	else if (ctx->security_statement() && (ctx->security_statement()->grant_statement() || ctx->security_statement()->revoke_statement()))
		result.push_back(makeGrantdbStatement(ctx->security_statement()));
	else if (ctx->security_statement())
		result.push_back(makeSQL(ctx->security_statement())); /* relaying security statement to main parser */
	else if (ctx->transaction_statement())
		result.push_back(makeTransactionStatement(ctx->transaction_statement())); /* relaying transaction statement to main parser */
	else if (ctx->use_statement())
		result.push_back(makeUseStatement(ctx->use_statement()));
	else if (ctx->kill_statement())
		result.push_back(makeKillStatement(ctx->kill_statement()));

	// FIXME: handle remaining statement types

	for (PLtsql_stmt *stmt : result) 
	{
		// Associate each fragement with a tree node
		if (!declare_local_expr.empty() && declare_local_expr.find(stmt) != declare_local_expr.end()) 
		{
			attachPLtsql_fragment(declare_local_expr.at(stmt), stmt);	
		}
		else if (ctx->set_statement()) 
		{
			attachPLtsql_fragment(ctx->set_statement(), stmt);	
		}
		else 
		{
			attachPLtsql_fragment(ctx, stmt);
		}
	}

	return result;
}
	
// For stored procedure calls without EXECUTE keyword, with the procedure name as first thing in the batch:
PLtsql_stmt *
makeExecBodyBatch(TSqlParser::Execute_body_batchContext *ctx)
{
	return makeExecuteProcedure(ctx, "execute_body_batch");
}

// For stored procedure calls, or functions called with EXECUTE:
PLtsql_stmt *
makeExecuteProcedure(ParserRuleContext *ctx, std::string call_type) 
{	
	Assert(string_matches(call_type.c_str(), "execute_statement") || string_matches(call_type.c_str(), "execute_body_batch"));
	Assert(ctx);	
	
	TSqlParser::Func_proc_name_server_database_schemaContext *ctx_name = nullptr;
	TSqlParser::Execute_statement_argContext *func_proc_args = nullptr;
	TSqlParser::Execute_bodyContext *body = nullptr;
		
	std::string schema_name;
	std::string proc_name;
	std::string db_name;
	std::string name;		
	bool is_cross_db = false;		
	int lineno = getLineNo(ctx);
	int return_code_dno = -1;	
	std::string execKeywd = "EXEC"; // DO NOT CHANGE!
	int name_length = 0;
		
	// Use a boolean vor convenience
	bool execute_statement = string_matches(call_type.c_str(), "execute_statement") ? true : false;
		
	size_t startPos = ctx->start->getStartIndex(); // start position of statement
	size_t namePos = -1;   // start position of procedure name
	size_t argPos = -1;	// start position of first argument	

	// Set up calltype-dependent values
	if (execute_statement) 
	{
		TSqlParser::Execute_statementContext *ctxES = (TSqlParser::Execute_statementContext *) ctx;
			
		if (ctxES->EXECUTE()) execKeywd = "EXEC   ";  // same length as EXECUTE. DO NOT CHANGE!						
		body = ctxES->execute_body();
		Assert(body);
		
		ctx_name       = body->func_proc_name_server_database_schema();
		func_proc_args = body->execute_statement_arg();		
	}
	else // execute_body_batch
	{
		TSqlParser::Execute_body_batchContext *ctxEBB = (TSqlParser::Execute_body_batchContext *) ctx;
		ctx_name       = ctxEBB->func_proc_name_server_database_schema();		
		func_proc_args = ctxEBB->execute_statement_arg();		
		Assert(ctx_name);
	}		
	

	if (ctx_name) 
	{
		// Get the name of procedure being executed, and split up in parts
		name = ::getFullText(ctx_name);
		name_length = ctx_name->stop->getStopIndex() - ctx_name->start->getStartIndex() + 1;
		Assert(!name.empty());
		
		// Original position of the name
		namePos = ctx_name->start->getStartIndex();		
		
		if (ctx_name->database)
		{
			db_name = stripQuoteFromId(ctx_name->database);
			if (!string_matches(db_name.c_str(), get_cur_db_name()))
			{
				is_cross_db = true;
			}
		}
		
		if (ctx_name->schema)
		{
			schema_name = stripQuoteFromId(ctx_name->schema);
		}
		
		if (ctx_name->procedure)
		{
			proc_name = stripQuoteFromId(ctx_name->procedure);
		}
		
		// Note: previous code performed rewriting here for procedure names with leading dots (EXEC ..proc1)
		// This is now performed in exitFunc_proc_name_server_database_schema() which is called via the mutator (previously, it wasn't).
		
		// For sp_* procs, truncate proc name to sp_* if the schema is "dbo" or "sys" or has leading dots
		// ToDo: handle 'EXEC mydb..sp_proc' where sp_proc gets executed in the context of 'mydb', even when the current DB is not 'mydb'	
		if ((pg_strncasecmp(name.c_str(), "..dbo.sp_", 9) == 0) || (pg_strncasecmp(name.c_str(), "..sys.sp_", 9) == 0))
		{
			name.erase(name.begin() + 0, name.begin() + 6);
		}
		else if ((pg_strncasecmp(name.c_str(), ".dbo.sp_", 8) == 0) || (pg_strncasecmp(name.c_str(), ".sys.sp_", 8) == 0))
		{
			name.erase(name.begin() + 0, name.begin() + 5);
		}
		else if ((pg_strncasecmp(name.c_str(), "dbo.sp_", 7) == 0) || (pg_strncasecmp(name.c_str(), "sys.sp_", 7) == 0))
		{
			name.erase(name.begin() + 0, name.begin() + 4);
		}
		else if (pg_strncasecmp(name.c_str(), ".sp_", 4) == 0)
		{
			name.erase(name.begin() + 0, name.begin() + 1);
		}
		else if (pg_strncasecmp(name.c_str(), "..sp_", 5) == 0)
		{
			name.erase(name.begin() + 0, name.begin() + 2);
		}
		else if (pg_strncasecmp(name.c_str(), "...sp_", 6) == 0)
		{
			name.erase(name.begin() + 0, name.begin() + 3);
		}
	}	
			
	if (!ctx_name && execute_statement) 
	{
		// LOCAL_ID can be placed on return_status and/or proc_var. choose the corresponding index, depending on whether return_status exists or not
		Assert(body->proc_var);
		name = ::getFullText(body->return_status ? body->LOCAL_ID()[1] : body->LOCAL_ID()[0]);
		Assert(!name.empty());	
		
		namePos = body->proc_var->getStartIndex();		
	}

	if (execute_statement) 
	{
		// Check for return status variable: EXEC @var = proc
		auto *localID = body->return_status ? body->LOCAL_ID()[0] : nullptr;
		if (localID)
		{
			return_code_dno = getVarno(localID);	
		}
	}
			
	if (is_sp_proc(name))
	{
		// If this is one of the special stored procs, exit here
		return makeSpStatement(name, func_proc_args, lineno, return_code_dno);
	}
	
	// Build the statement
	PLtsql_stmt_exec *result = (PLtsql_stmt_exec *) palloc0(sizeof(*result));
	result->cmd_type = PLTSQL_STMT_EXEC;
	result->lineno = lineno;
	result->is_call = true;
	result->return_code_dno = return_code_dno;
	result->paramno = 0;
	result->params = NIL;
	result->is_cross_db = is_cross_db;  // Record whether this is a cross-db call

	// Handle name parts
	if (!proc_name.empty())
	{
		result->proc_name = pstrdup(downcase_truncate_identifier(proc_name.c_str(), proc_name.length(), true));
	}
	if (!schema_name.empty())
	{
		result->schema_name = pstrdup(downcase_truncate_identifier(schema_name.c_str(), schema_name.length(), true));
	}
	if (!db_name.empty())
 	{
		result->db_name = pstrdup(downcase_truncate_identifier(db_name.c_str(), db_name.length(), true));
 	}

	// Handle arguments
	if (func_proc_args)
	{
		argPos = func_proc_args->start->getStartIndex();
		std::vector<tsql_exec_param *> params;
		makeSpParams(func_proc_args, params);
		for (size_t i = 0; i < params.size(); i++) 
		{
			result->params = lappend(result->params, params[i]);
			result->paramno++;
		}
	}

	// For execute_body_batch, there was no EXEC[UTE] keyword, so 'EXEC ' will be prepended; 
	// must account for the resulting offset
	if (!execute_statement) 
	{
		namePos += fragment_EXEC_prefix.length();
		argPos  += fragment_EXEC_prefix.length();
	}
	
	// If there is a comment preceding the statement, startPos will be > 0
	namePos -= startPos;
	Assert(namePos >= 0);

	// Build the statement text
	std::stringstream ss;	
	if (execute_statement) 
	{
		// In order for rewriting of the arguments to work correctly, they should be at the same position as in the original
		// SQL text. 
		ss << execKeywd;
	}
	else 
	{
		// For proc execution without EXECUTE, prepend 'EXEC '
		ss << fragment_EXEC_prefix;
	}
	int ssPos = ss.str().length();
	
	// Because whitespace and comments will be ignored by the logic below, spaces are added as needed 
	// to keep the tokens at the same offsets as originally; this is required for rewriting	
	int spacesNeeded = (namePos - ssPos);	
	
	ss << std::string(spacesNeeded, ' ');
	ssPos += spacesNeeded;
			
	ss << name;
	ssPos += name_length;
	
	if (func_proc_args) 
	{
		argPos -= startPos;
		spacesNeeded = (argPos - ssPos);
		Assert(spacesNeeded >= 0);
		
		ss << std::string(spacesNeeded, ' ');
		ssPos += spacesNeeded;
		
		ss << ::getFullText(func_proc_args);		
	}
	std::string expr_query = ss.str();
	result->expr = makeTsqlExpr(expr_query, false);

	return (PLtsql_stmt *) result;
}

PLtsql_stmt*
makeDbccCheckidentStatement(TSqlParser::Dbcc_statementContext *ctx)
{
	PLtsql_stmt_dbcc *stmt = (PLtsql_stmt_dbcc *) palloc0(sizeof(*stmt));

	std::string	new_reseed_value;
	std::string	input_str;
	int	i;
	char	*db_name = NULL;
	char	*schema_name = NULL;
	char	*table_name = NULL;
	char	*input_str_to_split;
	char	**splited_object_name;
	bool	is_reseed = true;
	bool	no_infomsgs = false;

	stmt->cmd_type = PLTSQL_STMT_DBCC;
	stmt->dbcc_stmt_type = PLTSQL_DBCC_CHECKIDENT;

	if (ctx->table_name_string())
	{
		if(ctx->table_name_string()->table)
		{
			input_str = stripQuoteFromId(ctx->table_name_string()->table);
		}
		if (ctx->table_name_string()->char_string())
		{
			input_str = ctx->table_name_string()->char_string()->STRING()->getSymbol()->getText();
			if (input_str.length() <= 2)
				throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE,
					       	"Parameter 1 is incorrect for this DBCC statement",
					       	getLineAndPos(ctx->table_name_string()));
			input_str = input_str.substr(1, input_str.length()-2);
		}
		if (ctx->RESEED())
		{
			if (ctx->new_value)
			{
				if(ctx->MINUS())
					stmt->dbcc_stmt_data.dbcc_checkident.new_reseed_value = pstrdup((ctx->new_value->getText().insert(0,"-")).c_str());
				else
					stmt->dbcc_stmt_data.dbcc_checkident.new_reseed_value = pstrdup((ctx->new_value->getText()).c_str());
			}
		}
		else if (ctx->NORESEED())
		{
			is_reseed = false;
		}

		if(ctx->dbcc_options())
		{
			if (pg_strcasecmp(::getFullText(ctx->dbcc_options()).c_str(), "NO_INFOMSGS") == 0)
			{
				no_infomsgs = true;
			}
			else
			{
				throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR,
					format_errmsg("\'%s\' is not a recognized option",
						::getFullText(ctx->dbcc_options()).c_str()),
							getLineAndPos(ctx->dbcc_options()));
			}
		}
	}

	input_str_to_split = pstrdup(input_str.c_str());

	/* strip trailing whitespace from input string */
	i = strlen(input_str_to_split);
	while (i > 0 && isspace((unsigned char) input_str_to_split[i - 1]))
		input_str_to_split[--i] = '\0';

	splited_object_name = split_object_name(input_str_to_split);
	db_name = !strcmp(splited_object_name[1], "")? NULL : splited_object_name[1];
	schema_name = !strcmp(splited_object_name[2], "")? NULL : splited_object_name[2];
	table_name = !strcmp(splited_object_name[3], "")? NULL : splited_object_name[3];

	if(db_name)
	{
		stmt->dbcc_stmt_data.dbcc_checkident.db_name = pstrdup(downcase_truncate_identifier(db_name, strlen(db_name), true));
		pfree(db_name);
	}
	if(schema_name)
	{
		stmt->dbcc_stmt_data.dbcc_checkident.schema_name = pstrdup(downcase_truncate_identifier(schema_name, strlen(schema_name), true));
		pfree(schema_name);
	}
	if(table_name)
	{
		stmt->dbcc_stmt_data.dbcc_checkident.table_name = pstrdup(downcase_truncate_identifier(table_name, strlen(table_name), true));
		pfree(table_name);
	}
	stmt->dbcc_stmt_data.dbcc_checkident.is_reseed = is_reseed;
	stmt->dbcc_stmt_data.dbcc_checkident.no_infomsgs = no_infomsgs;

	pfree(splited_object_name);
	pfree(input_str_to_split);
	
	attachPLtsql_fragment(ctx, (PLtsql_stmt *) stmt);
	return (PLtsql_stmt *) stmt;
}

// helper function to create target row
PLtsql_row *
create_select_target_row(const char *refname, size_t nfields, int lineno)
{
	/* prepare target if it is not ready */
	PLtsql_row *target = (PLtsql_row *) palloc0(sizeof(*target));
	target->dtype = PLTSQL_DTYPE_ROW;
	target->refname = (char *) refname;
	target->lineno = lineno;
	target->rowtupdesc = NULL;
	target->nfields = nfields;
	target->fieldnames = (char **) palloc(sizeof(char *) * target->nfields);
	target->varnos = (int *) palloc(sizeof(int) * target->nfields);
	return target;
}

// Add target column to target row for assignment
void add_assignment_target_field(PLtsql_row *target, antlr4::tree::TerminalNode *localId, size_t idx)
{
	auto targetText = ::getFullText(localId);
	PLtsql_nsitem *nse = pltsql_ns_lookup(pltsql_ns_top(), false, targetText.c_str(), nullptr, nullptr, nullptr);
	if (!nse)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("\"%s\" is not a known variable", targetText.c_str()), getLineAndPos(localId));

	target->varnos[idx] = nse->itemno;
	if (nse->itemno >= 0 && nse->itemno < pltsql_nDatums)
	{
		PLtsql_var *var = (PLtsql_var *) pltsql_Datums[nse->itemno];
		target->fieldnames[idx] = var->refname;
	}
	else
		target->fieldnames[idx] = NULL;

	// DECLARE @v=0; SELECT @v+=1, @v+=2;
	// In tsql, @v will have 3 because @v+=1 and @v+=2 is executed sequentially. We cannot support this case.
	for (size_t i=0; i<idx; ++i)
		if (target->varnos[i] == nse->itemno)
			throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("Babelfish does not support assignment to the same variable in SELECT. variable name: \"%s\"", targetText.c_str()), getLineAndPos(localId));
}

void process_execsql_destination_select(TSqlParser::Select_statement_standaloneContext* ctx, PLtsql_stmt_execsql *stmt)
{
	TSqlParser::Query_specificationContext *qctx = get_query_specification(ctx->select_statement());
	Assert(qctx);

	/* check select stmt has INTO-clause */
	if (qctx->INTO()) {
		// FIXME: we need a special handling for INTO-clause.
		return;
	}

	/* check select elem has assingment */
	PLtsql_row *target = NULL;

	Assert(qctx->select_list());
	std::vector<TSqlParser::Select_list_elemContext *> select_elems = qctx->select_list()->select_list_elem();
	for (size_t i=0; i<select_elems.size(); ++i)
	{
		TSqlParser::Select_list_elemContext *elem = select_elems[i];

		if (elem->EQUAL() || elem->assignment_operator())
		{
			if (i>0 && !target) /* one of preceeding elems doesn't have destination */
				throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "A SELECT statement that assigns a value to a variable must not be combined with data-retrieval operations", getLineAndPos(elem));

			if (!target)
				target = create_select_target_row("(select target)", select_elems.size(), getLineNo(elem));

			add_assignment_target_field(target, elem->LOCAL_ID(), i);

			if (elem->EQUAL())
			{
				// in PG main parser, '@a=1' will be treated as a boolean expression to compare @a and 1. This is different T-SQL expected.
				// We'll remove '@a=' from the query string so that main parser will return the expected result.
				removeTokenStringFromQuery(stmt->sqlstmt, elem->LOCAL_ID(), ctx);
				removeTokenStringFromQuery(stmt->sqlstmt, elem->EQUAL(), ctx);
			}
			else
			{
				Assert(elem->assignment_operator());

				/* We'll rewrite the query similar with EQUAL() but we'll just remove '=' character from token */
				tree::TerminalNode *anode = nullptr;
				if (elem->assignment_operator()->PLUS_ASSIGN())
					anode = elem->assignment_operator()->PLUS_ASSIGN();
				else if (elem->assignment_operator()->MINUS_ASSIGN())
					anode = elem->assignment_operator()->MINUS_ASSIGN();
				else if (elem->assignment_operator()->MULT_ASSIGN())
					anode = elem->assignment_operator()->MULT_ASSIGN();
				else if (elem->assignment_operator()->DIV_ASSIGN())
					anode = elem->assignment_operator()->DIV_ASSIGN();
				else if (elem->assignment_operator()->MOD_ASSIGN())
					anode = elem->assignment_operator()->MOD_ASSIGN();
				else if (elem->assignment_operator()->AND_ASSIGN())
					anode = elem->assignment_operator()->AND_ASSIGN();
				else if (elem->assignment_operator()->XOR_ASSIGN())
					anode = elem->assignment_operator()->XOR_ASSIGN();
				else if (elem->assignment_operator()->OR_ASSIGN())
					anode = elem->assignment_operator()->OR_ASSIGN();
				else
					Assert(0);

				replaceTokenStringFromQuery(stmt->sqlstmt, anode, rewrite_assign_operator(anode), ctx);
			}
		}
		else
		{
			if (target) /* one of preceeding elems has a destination */
				throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "A SELECT statement that assigns a value to a variable must not be combined with data-retrieval operations", getLineAndPos(elem));
		}
	}

	if (target)
	{
		pltsql_adddatum((PLtsql_datum *) target);

		stmt->target = (PLtsql_variable *)target;
		stmt->is_tsql_select_assign_stmt = true;
	}
	else
		stmt->need_to_push_result = true;
}

void process_execsql_destination_update(TSqlParser::Update_statementContext *uctx, PLtsql_stmt_execsql *stmt)
{
	/*
	 * If UPDATE statement has SET to local varialbe, we will rewrite a query with RETURNING and set destination
	 * i.e. "UPDATE t SET col=1, @var=2" => "UPDATE t SET col=1 RETURNING 2" and the result will be assigned to @var.
	 */
	size_t target_row_size = 0;
	bool has_combined_variable_and_column_update = false;
	for (auto elem : uctx->update_elem())
	{
		if (elem->LOCAL_ID())
		{
			++target_row_size;
			if (elem->full_column_name())
				has_combined_variable_and_column_update = true;
		}
	}

	if (target_row_size == uctx->update_elem().size() && !has_combined_variable_and_column_update)
	{
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "UPDATE statement with variables without table update is not yet supported", getLineAndPos(uctx));
	}

	if (target_row_size > 0)
	{
		PLtsql_row *target = create_select_target_row("(select target)", target_row_size, getLineNo(uctx->SET()));
		StringInfoData ds;
		initStringInfo(&ds);
		appendStringInfo(&ds, "RETURNING ");
		size_t returning_col_cnt = 0;
		bool comma_carry_over = false; /* true if the prev comma is already removed */

		std::vector<TSqlParser::Update_elemContext *> elems = uctx->update_elem();
		for (size_t i=0; i<elems.size(); ++i)
		{
			auto elem = elems[i];
			if (elem->LOCAL_ID())
			{
				add_assignment_target_field(target, elem->LOCAL_ID(), returning_col_cnt);

				if (returning_col_cnt > 0)
					appendStringInfo(&ds, ", ");
				++returning_col_cnt;

				if (elem->full_column_name())
				{
					/* "SET @a=col=expr" => "SET col=expr ... RETURNING col" */
					appendStringInfo(&ds, "%s", ::getFullText(elem->full_column_name()).c_str());

					removeTokenStringFromQuery(stmt->sqlstmt, elem->LOCAL_ID(), uctx);
					removeTokenStringFromQuery(stmt->sqlstmt, elem->EQUAL(0), uctx);
				}
				else
				{
					/* "SET @a=expr, col=expr2" => "SET col=expr2 ... RETURNING expr" */
					appendStringInfo(&ds, "%s", ::getFullText(elem->expression()).c_str());

					removeTokenStringFromQuery(stmt->sqlstmt, elem->LOCAL_ID(), uctx);
					removeTokenStringFromQuery(stmt->sqlstmt, elem->EQUAL(0), uctx);
					removeCtxStringFromQuery(stmt->sqlstmt, elem->expression(), uctx);
				}

				// Conceptually we have to remove any nearest COMMA.
				// But code is little bit dirty to handle some corner cases (the first few elems are removed or the last few elems are removed)
				if ((i==0 || comma_carry_over) && i<uctx->COMMA().size())
				{
					/* we have to remove next COMMA because it is the first elem or the prev COMMA is already removed */
					removeTokenStringFromQuery(stmt->sqlstmt, uctx->COMMA(i), uctx);
					comma_carry_over = true;
				}
				else if (i-1<uctx->COMMA().size())
				{
					/* remove prev COMMA by default */
					removeTokenStringFromQuery(stmt->sqlstmt, uctx->COMMA(i-1), uctx);
				}
			}
			else
				comma_carry_over = false;
		}

		pltsql_adddatum((PLtsql_datum *) target);

		stmt->target = (PLtsql_variable *)target;
		stmt->is_tsql_select_assign_stmt = true;

		StringInfoData ds2;
		initStringInfo(&ds2);
		appendStringInfo(&ds2, "%s %s", stmt->sqlstmt->query, ds.data);
		stmt->sqlstmt->query = pstrdup(ds2.data);
	}
}

void process_execsql_destination(TSqlParser::Dml_statementContext *ctx, PLtsql_stmt_execsql *stmt)
{
	Assert(ctx);
	Assert(stmt);

	if (ctx->select_statement_standalone())
	{
		process_execsql_destination_select(ctx->select_statement_standalone(), stmt);
	}
	else if (ctx->update_statement())
	{
		process_execsql_destination_update(ctx->update_statement(), stmt);
	}
}

static bool check_freetext_predicate(TSqlParser::Search_conditionContext *ctx)
{
    if (ctx && ctx->predicate_br().size() > 0)
	{
        for (auto pred : ctx->predicate_br())
		{
            if (pred && pred->predicate() && pred->predicate()->freetext_predicate())
                return true;
            if (pred && pred->search_condition()) {
                if (check_freetext_predicate(pred->search_condition()))
                    return true;
            }
        }
    }
    return false;
}

static void post_process_table_source(TSqlParser::Table_source_itemContext *ctx, PLtsql_expr *expr, ParserRuleContext *baseCtx, bool is_freetext_predicate)
{
	for (auto cctx : ctx->table_source_item())
		post_process_table_source(cctx, expr, baseCtx, is_freetext_predicate);

	std::string table_name = extractTableName(nullptr, ctx);

	for (auto wctx : ctx->with_table_hints())
	{
		if (!wctx->sample_clause())
			extractTableHints(wctx, table_name);
		removeCtxStringFromQuery(expr, wctx, baseCtx);
	}

	for (auto actx : ctx->as_table_alias())
	{
		std::string alias_name = ::getFullText(actx->table_alias()->id());
		if (!table_name.empty() && !alias_name.empty())
		{
			alias_to_table_mapping[alias_name] = table_name;
			table_to_alias_mapping[table_name] = alias_name;
		}
		if (actx->table_alias()->with_table_hints())
		{
			if (!actx->table_alias()->with_table_hints()->sample_clause())
				extractTableHints(actx->table_alias()->with_table_hints(), alias_name);
			removeCtxStringFromQuery(expr, actx->table_alias()->with_table_hints(), baseCtx);
		}
	}

	if (!table_name.empty())
	{
		if (table_to_alias_mapping.find(table_name) != table_to_alias_mapping.end())
			table_name = table_to_alias_mapping[table_name];
		num_of_tables++;
		if (!table_names.empty())
			table_names += " ";
		table_names += table_name;
	}

	if (ctx->join_hint())
	{
		if (enable_hint_mapping && num_of_tables > 1)
		{
			leading_hint = "Leading(" + table_names + ")";
			extractJoinHint(ctx->join_hint(), table_names);
		}
		removeCtxStringFromQuery(expr, ctx->join_hint(), baseCtx);
	}

	// check for freetext predicate CONTAINS()
	if(is_freetext_predicate)
	{
		std::string schema_name = extractSchemaName(nullptr, ctx);
		
		const char * t_name = downcase_truncate_identifier(table_name.c_str(), table_name.length(), true);
		const char * s_name = downcase_truncate_identifier(schema_name.c_str(), schema_name.length(), true);
		
		// check if full-text index exist for the table, if not throw error
		if(!check_fulltext_exist(const_cast <char *>(s_name), const_cast <char *>(t_name)))
			throw PGErrorWrapperException(ERROR, ERRCODE_RAISE_EXCEPTION, format_errmsg("Cannot use a CONTAINS or FREETEXT predicate on table or indexed view '%s' because it is not full-text indexed.", table_name.c_str()), getLineAndPos(ctx));
	}
}

void process_execsql_remove_unsupported_tokens(TSqlParser::Dml_statementContext *ctx, PLtsql_expr_query_mutator *exprMutator)
{
	PLtsql_expr * sqlstmt = exprMutator->expr;
	if (ctx->insert_statement())
	{
		auto ictx = ctx->insert_statement();
		if (ictx->with_table_hints() && ictx->with_table_hints()->WITH()) // table hints
		{
			if (!ictx->with_table_hints()->sample_clause() && ictx->ddl_object())
			{
				std::string table_name = extractTableName(ictx->ddl_object(), nullptr);
				extractTableHints(ictx->with_table_hints(), table_name);
			}
			removeCtxStringFromQuery(sqlstmt, ictx->with_table_hints(), exprMutator->ctx);
		}
		if (ictx->option_clause()) // query hints
		{
			removeCtxStringFromQuery(sqlstmt, ictx->option_clause(), exprMutator->ctx);
			extractQueryHintsFromOptionClause(ictx->option_clause());
		}
	}
	else if (ctx->update_statement())
	{
		auto uctx = ctx->update_statement();
		if (uctx->table_sources())
			for (auto tctx : uctx->table_sources()->table_source_item()) // from-clause (to remove hints)
				post_process_table_source(tctx, sqlstmt, exprMutator->ctx);
		if (uctx->with_table_hints()) // table hints
		{
			if (!uctx->with_table_hints()->sample_clause() && uctx->ddl_object())
			{
				std::string table_name = extractTableName(uctx->ddl_object(), nullptr);
				extractTableHints(uctx->with_table_hints(), table_name);
			}
			removeCtxStringFromQuery(sqlstmt, uctx->with_table_hints(), exprMutator->ctx);
		}
		if (uctx->option_clause()) // query hints
		{
			removeCtxStringFromQuery(sqlstmt, uctx->option_clause(), exprMutator->ctx);
			extractQueryHintsFromOptionClause(uctx->option_clause());
		}
	}
	else if (ctx->delete_statement())
	{
		auto dctx = ctx->delete_statement();
		if (dctx->table_sources())
		{
			for (auto tctx : dctx->table_sources()->table_source_item()) // from-clause (to remove hints)
				post_process_table_source(tctx, sqlstmt, exprMutator->ctx);
		}
		if (dctx->delete_statement_from()->table_alias() && dctx->delete_statement_from()->table_alias()->with_table_hints())
		{
			if (!dctx->delete_statement_from()->table_alias()->with_table_hints()->sample_clause()) 
			{
				std::string table_name = ::getFullText(dctx->delete_statement_from()->table_alias()->id());
				extractTableHints(dctx->delete_statement_from()->table_alias()->with_table_hints(), table_name);
			}
			removeCtxStringFromQuery(sqlstmt, dctx->delete_statement_from()->table_alias()->with_table_hints(), exprMutator->ctx);
		}
		if (dctx->with_table_hints()) // table hints
		{
			if (!dctx->with_table_hints()->sample_clause() && dctx->delete_statement_from()->ddl_object()) 
			{
				std::string table_name = extractTableName(dctx->delete_statement_from()->ddl_object(), nullptr);
				extractTableHints(dctx->with_table_hints(), table_name);
			}
			removeCtxStringFromQuery(sqlstmt, dctx->with_table_hints(), exprMutator->ctx);
		}
		if (dctx->option_clause()) // query hints
		{
			removeCtxStringFromQuery(sqlstmt, dctx->option_clause(), exprMutator->ctx);
			extractQueryHintsFromOptionClause(dctx->option_clause());
		}
	}
}

static void
post_process_column_constraint(TSqlParser::Column_constraintContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	if (ctx->UNIQUE())
		rewritten_query_fragment.emplace(std::make_pair(ctx->UNIQUE()->getSymbol()->getStopIndex()+1 , std::make_pair("", " NULLS NOT DISTINCT")));
	if (ctx && ctx->clustered() && ctx->clustered()->CLUSTERED())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->clustered()->CLUSTERED(), baseCtx);
	if (ctx && ctx->clustered() && ctx->clustered()->NONCLUSTERED())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->clustered()->NONCLUSTERED(), baseCtx);
	if (ctx->with_index_options())
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->with_index_options(), baseCtx);

	if (ctx && ctx->for_replication())
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->for_replication(), baseCtx);
}

static void
post_process_inline_index(TSqlParser::Inline_indexContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	if (ctx->ON())
	{
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->ON(), baseCtx);
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->storage_partition_clause()[0], baseCtx);
	}

	if (ctx->FILESTREAM_ON())
	{
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->FILESTREAM_ON(), baseCtx);
		size_t idx = ctx->ON() ? 1 : 0; // if ON() exists, the second storage_partition_clause belongs to filestream
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->storage_partition_clause()[idx], baseCtx);
	}

	if (ctx->clustered() && ctx->clustered()->CLUSTERED())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->clustered()->CLUSTERED(), baseCtx);
	if (ctx->clustered() && ctx->clustered()->NONCLUSTERED())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->clustered()->NONCLUSTERED(), baseCtx);
	if (ctx->with_index_options())
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->with_index_options(), baseCtx);
}

static void
post_process_special_column_option(TSqlParser::Special_column_optionContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	if (ctx->for_replication())
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->for_replication(), baseCtx);
	if (ctx->SPARSE())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->SPARSE(), baseCtx);
	if (ctx->FILESTREAM())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->FILESTREAM(), baseCtx);
	if (ctx->ROWGUIDCOL())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->ROWGUIDCOL(), baseCtx);
}

static void
post_process_column_definition(TSqlParser::Column_definitionContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	/*
	 * T-SQL allows TIMESTAMP datatype without column name in create/alter table/type
	 * statement and internally assumes "timestamp" as column name. So here if
	 * we find TIMESTAMP token then we will prepend "timestamp" as a column name
	 * in the column definition.
	 */
	if (ctx->TIMESTAMP())
		rewritten_query_fragment.emplace(std::make_pair(ctx->TIMESTAMP()->getSymbol()->getStartIndex(), std::make_pair(::getFullText(ctx->TIMESTAMP()), "timestamp " + ::getFullText(ctx->TIMESTAMP()))));

 	/*
	* PG doesn't allow for TIME/DATETIME2/DATETIMEOFFSET to be declared with precision 7, but this is permitted in TSQL.
	* In order to get around this, remove the scale factor so that the typmod is set to -1 (default). Luckily,
	* in TSQL the default scale is also 7, so we can re-add the decimal digits to meet the scale factor on the return side.
	*/
	if (pg_strncasecmp(::getFullText(ctx->data_type()).c_str(), "TIME(7)", 7) == 0)
		rewritten_query_fragment.emplace(std::make_pair(ctx->data_type()->start->getStartIndex(), std::make_pair(::getFullText(ctx->data_type()), "TIME")));
	if (pg_strncasecmp(::getFullText(ctx->data_type()).c_str(), "DATETIME2(7)", 12) == 0)
		rewritten_query_fragment.emplace(std::make_pair(ctx->data_type()->start->getStartIndex(), std::make_pair(::getFullText(ctx->data_type()), "DATETIME2")));
	if (pg_strncasecmp(::getFullText(ctx->data_type()).c_str(), "DATETIMEOFFSET(7)", 17) == 0)
		rewritten_query_fragment.emplace(std::make_pair(ctx->data_type()->start->getStartIndex(), std::make_pair(::getFullText(ctx->data_type()), "DATETIMEOFFSET")));
	 
	if (ctx->inline_index())
		post_process_inline_index(ctx->inline_index(), stmt, baseCtx);

	for (auto cctx : ctx->column_constraint())
		post_process_column_constraint(cctx, stmt, baseCtx);

	for (auto sctx : ctx->special_column_option())
		post_process_special_column_option(sctx, stmt, baseCtx);

	if (ctx->for_replication())
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->for_replication(), baseCtx);

	if (ctx->ROWGUIDCOL())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->ROWGUIDCOL(), baseCtx);
}

static void
post_process_table_constraint(TSqlParser::Table_constraintContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	if (ctx->UNIQUE())
		rewritten_query_fragment.emplace(std::make_pair(ctx->UNIQUE()->getSymbol()->getStopIndex()+1 , std::make_pair("", " NULLS NOT DISTINCT")));
	if (ctx->clustered() && ctx->clustered()->CLUSTERED())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->clustered()->CLUSTERED(), baseCtx);
	if (ctx->clustered() && ctx->clustered()->NONCLUSTERED())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->clustered()->NONCLUSTERED(), baseCtx);
	if (ctx->with_index_options())
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->with_index_options(), baseCtx);

	for (auto frctx : ctx->for_replication())
		removeCtxStringFromQuery(stmt->sqlstmt, frctx, baseCtx);

	if (ctx->ON())
	{
		Assert(ctx->storage_partition_clause());
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->ON(), baseCtx);
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->storage_partition_clause(), baseCtx);
	}
}

static bool
post_process_create_table(TSqlParser::Create_tableContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	/*
	 * visit subclauses and remove unsupported options by backend (assuming corresponding error is already thrown for bbf unsupported error.
	 * we need to handle following keyword options in CREATE-TABLE
	 *  1. filegroup, partitioning scheme, filestream (ON/TEXTIMAGE_ON/FILESTREAM_ON clause)
	 *  2. CLUSTERED/NONCLUSTERED index
	 */

	if (ctx->column_def_table_constraints())
	{
		for (auto cdtctx : ctx->column_def_table_constraints()->column_def_table_constraint())
		{
			if (cdtctx->column_definition())
				post_process_column_definition(cdtctx->column_definition(), stmt, baseCtx);

			if (cdtctx->table_constraint())
				post_process_table_constraint(cdtctx->table_constraint(), stmt, baseCtx);
		}
	}

	// remove storage_partition from query string
	for (auto cctx : ctx->create_table_options())
	{
		if (cctx->ON())
		{
			Assert(cctx->storage_partition_clause());
			removeTokenStringFromQuery(stmt->sqlstmt, cctx->ON(), baseCtx);
			removeCtxStringFromQuery(stmt->sqlstmt, cctx->storage_partition_clause(), baseCtx);
		}
		else if (cctx->TEXTIMAGE_ON())
		{
			Assert(cctx->storage_partition_clause());
			removeTokenStringFromQuery(stmt->sqlstmt, cctx->TEXTIMAGE_ON(), baseCtx);
			removeCtxStringFromQuery(stmt->sqlstmt, cctx->storage_partition_clause(), baseCtx);
		}
		else if (cctx->FILESTREAM_ON())
		{
			Assert(cctx->storage_partition_clause());
			removeTokenStringFromQuery(stmt->sqlstmt, cctx->FILESTREAM_ON(), baseCtx);
			removeCtxStringFromQuery(stmt->sqlstmt, cctx->storage_partition_clause(), baseCtx);
		}
	}

	// visit options in column definition
	for (auto cdctx : ctx->column_definition())
		post_process_column_definition(cdctx, stmt, baseCtx);

	// viist options in index specification
	for (auto ictx : ctx->inline_index())
	{
		post_process_inline_index(ictx, stmt, baseCtx);
	}

	for (auto ictx : ctx->table_constraint())
	{
		post_process_table_constraint(ictx, stmt, baseCtx);
	}
	return false;
}

static bool
post_process_alter_table(TSqlParser::Alter_tableContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	if (ctx->column_def_table_constraints())
	{
		for (auto cdtctx : ctx->column_def_table_constraints()->column_def_table_constraint())
		{
			if (cdtctx->column_definition())
				post_process_column_definition(cdtctx->column_definition(), stmt, baseCtx);

			if (cdtctx->table_constraint())
				post_process_table_constraint(cdtctx->table_constraint(), stmt, baseCtx);
		}
	}

	// visit options in column definition
	if (ctx->column_definition())
		post_process_column_definition(ctx->column_definition(), stmt, baseCtx);

	if (ctx->special_column_option())
		post_process_special_column_option(ctx->special_column_option(), stmt, baseCtx);

	if (ctx->FILESTREAM_ON())
	{
		return true; // not an effective stmt. make this stmt NOP
	}

	if (ctx->ADD())
	{
		if (ctx->WITH())
		{
			Assert(ctx->CHECK().size() == 1 || ctx->NOCHECK().size() == 1);
			removeTokenStringFromQuery(stmt->sqlstmt, ctx->WITH(), baseCtx);
			for (auto node : ctx->CHECK())
				removeTokenStringFromQuery(stmt->sqlstmt, node, baseCtx);
			for (auto node : ctx->NOCHECK())
				removeTokenStringFromQuery(stmt->sqlstmt, node, baseCtx);
		}
	}

	if (ctx->CONSTRAINT())
	{
		return true; // not an effective stmt. make this stmt NOP
	}

	return false;
}

std::pair<std::string, std::string> 
getTableNameAndSchemaName(TSqlParser::Table_nameContext* ctx)
{
    std::string table_info = ::getFullText(ctx);
    std::string table_name = "";
    std::string schema_name = "";
    size_t pos = table_info.find(".");
    if (pos != std::string::npos) {
        // Extract the schema name before the "."
        schema_name = table_info.substr(0, pos);
        // Extract the table name after the "."
        table_name = table_info.substr(pos + 1);
    } else {
        // No "." character found, set first to the entire string
        table_name = table_info;
    }
    return std::make_pair(downcase_truncate_identifier(table_name.c_str(), table_name.length(), true),
                           downcase_truncate_identifier(schema_name.c_str(), schema_name.length(), true));
}

PLtsql_stmt *
makeCreateFulltextIndexStmt(TSqlParser::Create_fulltext_indexContext *ctx)
{
	PLtsql_stmt_fulltextindex *stmt = (PLtsql_stmt_fulltextindex *) palloc0(sizeof(PLtsql_stmt_fulltextindex));
	stmt->cmd_type = PLTSQL_STMT_FULLTEXTINDEX;
	stmt->lineno = getLineNo(ctx);
	stmt->is_create = true;

	if (ctx->table_name())
	{ 
		auto table_info = getTableNameAndSchemaName(ctx->table_name());
        stmt->table_name = pstrdup(table_info.first.c_str());
        stmt->schema_name = pstrdup(table_info.second.c_str());
	}
	List *column_name_list = NIL;
    if (ctx->fulltext_index_column().size() > 0)
    {
        for (auto column : ctx->fulltext_index_column())
        {
			if (column->TYPE() && column->COLUMN())
				throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "'TYPE COLUMN' option is not currently supported in Babelfish", getLineAndPos(column->TYPE()));
			else if (column->LANGUAGE())
				throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "'LANGUAGE' option is not currently supported in Babelfish", getLineAndPos(column->LANGUAGE()));
			else if (column->STATISTICAL_SEMANTICS())
				throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "'STATISTICAL_SEMANTICS' option is not currently supported in Babelfish", getLineAndPos(column->STATISTICAL_SEMANTICS()));
			else
			{
				std::string column_name_str = ::getFullText(column->full_column_name());
				char *column_name = pstrdup(downcase_truncate_identifier(column_name_str.c_str(), column_name_str.length(), true));
				column_name_list = lappend(column_name_list, column_name);
			}

        }
		stmt->column_name = column_name_list;
    }
	if (ctx->catalog_filegroup_option())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "'CATALOG FILEGROUP OPTION' is not currently supported in Babelfish", getLineAndPos(ctx));
	if (ctx->fulltext_with_option().size() > 0)
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "'WITH OPTION' is not currently supported in Babelfish", getLineAndPos(ctx));
	if (ctx->id())
	{
		std::string index_name = ::getFullText(ctx->id());
		stmt->index_name = pstrdup(downcase_truncate_identifier(index_name.c_str(), index_name.length(), true));
	}
	attachPLtsql_fragment(ctx, (PLtsql_stmt *) stmt);
    return (PLtsql_stmt *) stmt;
}

PLtsql_stmt *
makeDropFulltextIndexStmt(TSqlParser::Drop_fulltext_indexContext *ctx)
{
	PLtsql_stmt_fulltextindex *stmt = (PLtsql_stmt_fulltextindex *) palloc0(sizeof(PLtsql_stmt_fulltextindex));
	stmt->cmd_type = PLTSQL_STMT_FULLTEXTINDEX;
	stmt->lineno = getLineNo(ctx);
	stmt->is_create = false;
	if (ctx->table_name())
	{
		auto table_info = getTableNameAndSchemaName(ctx->table_name());
        stmt->table_name = pstrdup(table_info.first.c_str());
        stmt->schema_name = pstrdup(table_info.second.c_str());
	}
	attachPLtsql_fragment(ctx, (PLtsql_stmt *) stmt);
	return (PLtsql_stmt *) stmt;
}

static bool
post_process_create_index(TSqlParser::Create_indexContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	if (ctx->storage_partition_clause())
	{
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->ON().back(), baseCtx); /* remove last ON */
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->storage_partition_clause(), baseCtx);
	}

	if (ctx->clustered() && ctx->clustered()->CLUSTERED())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->clustered()->CLUSTERED(), baseCtx);
	if (ctx->clustered() && ctx->clustered()->NONCLUSTERED())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->clustered()->NONCLUSTERED(), baseCtx);
	if (ctx->COLUMNSTORE())
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->COLUMNSTORE(), baseCtx);
	if (ctx->with_index_options() && !ctx->vector_index_method()) /* Vector indexes can have With clause. */
		removeCtxStringFromQuery(stmt->sqlstmt, ctx->with_index_options(), baseCtx);

	return false;
}

static antlr4::tree::TerminalNode *
getCreateDatabaseOptionTobeRemoved(TSqlParser::Create_database_optionContext* o)
{
	// remove token needs to be removed
	if (o->FILESTREAM())
		return o->FILESTREAM();
	if (o->DEFAULT_LANGUAGE())
		return o->DEFAULT_LANGUAGE();
	if (o->DEFAULT_FULLTEXT_LANGUAGE())
		return o->DEFAULT_FULLTEXT_LANGUAGE();
	if (o->DB_CHAINING())
		return o->DB_CHAINING();
	if (o->TRUSTWORTHY())
		return o->TRUSTWORTHY();
	if (o->CATALOG_COLLATION())
		return o->CATALOG_COLLATION();
	if (o->PERSISTENT_LOG_BUFFER())
		return o->PERSISTENT_LOG_BUFFER();
	return nullptr;
}

static bool
post_process_create_database(TSqlParser::Create_databaseContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	if (ctx->CONTAINMENT())
	{
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->CONTAINMENT(), baseCtx);
		removeTokenStringFromQuery(stmt->sqlstmt, ctx->EQUAL(), baseCtx);
		if (ctx->NONE())
			removeTokenStringFromQuery(stmt->sqlstmt, ctx->NONE(), baseCtx);
		if (ctx->PARTIAL())
			removeTokenStringFromQuery(stmt->sqlstmt, ctx->PARTIAL(), baseCtx);
	}

	size_t num_commas_in_on_clause = ctx->COMMA().size();

	if (ctx->WITH())
	{
		/* COMMA is shared between ON-clause and WITH-clause. calculate the number of COMMA so that it can be removed properly */
		num_commas_in_on_clause -= (ctx->create_database_option().size() - 1);

		auto options = ctx->create_database_option();
		auto commas = ctx->COMMA();
		std::vector<antlr4::tree::TerminalNode *> commas_in_with_clause;
		commas_in_with_clause.insert(commas_in_with_clause.begin(), commas.begin() + num_commas_in_on_clause, commas.end());

		GetTokenFunc<TSqlParser::Create_database_optionContext*> getToken = getCreateDatabaseOptionTobeRemoved;
		bool all_removed = removeTokenFromOptionList(stmt->sqlstmt, options, commas_in_with_clause, ctx, getToken);
		if (all_removed)
			removeTokenStringFromQuery(stmt->sqlstmt, ctx->WITH(), ctx);
	}

	if (!ctx->ON().empty())
	{
		auto specs = ctx->database_file_spec();
		for (auto sctx : specs)
			removeCtxStringFromQuery(stmt->sqlstmt, sctx, ctx);

		for (size_t i=0; i<num_commas_in_on_clause; ++i)
			removeTokenStringFromQuery(stmt->sqlstmt, ctx->COMMA()[i], ctx);

		for (size_t i=0; i<ctx->ON().size(); ++i)
			removeTokenStringFromQuery(stmt->sqlstmt, ctx->ON()[i], ctx);

		if (ctx->PRIMARY())
			removeTokenStringFromQuery(stmt->sqlstmt, ctx->PRIMARY(), ctx);
		if (ctx->LOG())
			removeTokenStringFromQuery(stmt->sqlstmt, ctx->LOG(), ctx);
	}

	return false;
}

static bool
post_process_create_type(TSqlParser::Create_typeContext *ctx, PLtsql_stmt_execsql *stmt, TSqlParser::Ddl_statementContext *baseCtx)
{
	if (ctx->column_def_table_constraints())
	{
		for (auto cdtctx : ctx->column_def_table_constraints()->column_def_table_constraint())
		{
			if (cdtctx->column_definition())
				post_process_column_definition(cdtctx->column_definition(), stmt, baseCtx);

			if (cdtctx->table_constraint())
				post_process_table_constraint(cdtctx->table_constraint(), stmt, baseCtx);
		}
	}

	return false;
}

static void
post_process_declare_table_statement(PLtsql_stmt_decl_table *stmt, TSqlParser::Table_type_definitionContext *ctx)
{
	if (ctx->column_def_table_constraints())
	{
		for (auto cdtctx : ctx->column_def_table_constraints()->column_def_table_constraint())
		{
			/*
			 * T-SQL allows TIMESTAMP datatype without column name in declare table type
			 * statement and internally assumes "timestamp" as column name. So here if
			 * we find TIMESTAMP token then we will prepend "timestamp" as a column name
			 * in the column definition.
			 */
			if (cdtctx->column_definition() && cdtctx->column_definition()->TIMESTAMP())
			{
				auto tctx = cdtctx->column_definition()->TIMESTAMP();
				std::string rewritten_text = "timestamp " + ::getFullText(tctx);
				rewritten_query_fragment.emplace(std::make_pair(tctx->getSymbol()->getStartIndex(), std::make_pair(::getFullText(tctx), rewritten_text)));
			}

			if (cdtctx->table_constraint() && cdtctx->table_constraint()->UNIQUE())
				rewritten_query_fragment.emplace(std::make_pair(cdtctx->table_constraint()->UNIQUE()->getSymbol()->getStopIndex()+1 , std::make_pair("", " NULLS NOT DISTINCT")));

			if (cdtctx->column_definition() && !cdtctx->column_definition()->column_constraint().empty())
			{
				for (auto actx: cdtctx->column_definition()->column_constraint())
				{
					if (actx->UNIQUE())
						rewritten_query_fragment.emplace(std::make_pair(actx->UNIQUE()->getSymbol()->getStopIndex()+1 , std::make_pair("", " NULLS NOT DISTINCT")));
				}
			}

		}

		/*
		 * Need to run the mutator to perform rewriting not only when items were added above,
		 * but also if rewrite items were added earlier - for example, in exitColumn_def_table_constraints()
		 * in case a table constraint was specified without a separator comma.
		 */
		if (rewritten_query_fragment.size() > 0)
		{
			PLtsql_expr *expr = makeTsqlExpr(ctx, false);
			PLtsql_expr_query_mutator mutator(expr, ctx);
			add_rewritten_query_fragment_to_mutator(&mutator);
			mutator.run();
			char *rewritten_query = expr->query;
			
			// Save the rewritten column definition list
			stmt->coldef = pstrdup(&rewritten_query[5]);
		}
	}
}

static void
post_process_declare_cursor_statement(PLtsql_stmt_decl_cursor *stmt, TSqlParser::Declare_cursorContext *ctx, tsqlBuilder &builder)
{
	if (stmt->cursor_explicit_expr)
	{
		PLtsql_expr *expr = stmt->cursor_explicit_expr;

		auto sctx = ctx->select_statement_standalone();
		Assert(sctx);

		PLtsql_expr_query_mutator mutator(expr, sctx);
		process_select_statement_standalone(sctx, &mutator, builder);
		add_rewritten_query_fragment_to_mutator(&mutator);
		mutator.run();
	}
}

static PLtsql_var *
lookup_cursor_variable(const char *varname)
{
	PLtsql_nsitem *nse = pltsql_ns_lookup(pltsql_ns_top(), false, varname, nullptr, nullptr, nullptr);
	if (!nse)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("\"%s\" is not a known variable", varname), 0, 0);

	PLtsql_datum* datum = pltsql_Datums[nse->itemno];
	if (datum->dtype != PLTSQL_DTYPE_VAR)
		throw PGErrorWrapperException(ERROR, ERRCODE_DATATYPE_MISMATCH, "cursor variable must be a simple variable", 0, 0);

	PLtsql_var *var = (PLtsql_var *) datum;
	if (!is_cursor_datatype(var->datatype->typoid))
		throw PGErrorWrapperException(ERROR, ERRCODE_DATATYPE_MISMATCH, format_errmsg("variable \"%s\" must be of type cursor or refcursor", var->refname), 0, 0);

	return var;
}

static PLtsql_var *
build_cursor_variable(const char *curname, int lineno)
{
	PLtsql_var *curvar = (PLtsql_var *) pltsql_build_variable(pstrdup(curname), lineno,
		pltsql_build_datatype(REFCURSOROID, -1, InvalidOid, NULL), true);

	StringInfoData ds;
	initStringInfo(&ds);
	char		*cp1;
	PLtsql_expr *curname_def = (PLtsql_expr *) palloc0(sizeof(PLtsql_expr));
	appendStringInfo(&ds, "SELECT ");
	cp1 = curvar->refname;
	/*
	 * Don't trust standard_conforming_strings here;
	 * it might change before we use the string.
	 */
	if (strchr(cp1, '\\') != NULL)
		appendStringInfo(&ds, "%c", ESCAPE_STRING_SYNTAX);
	appendStringInfo(&ds, "%c", '\'');
	while (*cp1)
	{
		if (SQL_STR_DOUBLE(*cp1, true))
			appendStringInfo(&ds, "%c", *cp1);
		appendStringInfo(&ds, "%c", *cp1++);
	}
	appendStringInfo(&ds, "'::pg_catalog.refcursor");
	curname_def->query = pstrdup(ds.data);

	curvar->default_val = curname_def;

	return curvar;
}

static int
read_extended_cursor_option(TSqlParser::Declare_cursor_optionsContext *ctx, int option)
{
	if (ctx->GLOBAL())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "GLOBAL CURSOR is not supported yet", getLineAndPos(ctx->GLOBAL()));
	if (ctx->LOCAL())
		option |= TSQL_CURSOR_OPT_LOCAL;

	if (ctx->FORWARD_ONLY())
	{
		if ((option & TSQL_CURSOR_OPT_SCROLL) != 0)
			throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "cannot specify both FORWARD_ONLY and SCROLL", getLineAndPos(ctx->FORWARD_ONLY()));
		option |= (CURSOR_OPT_NO_SCROLL | TSQL_CURSOR_OPT_FORWARD_ONLY);
	}
	if (ctx->SCROLL())
	{
		if ((option & TSQL_CURSOR_OPT_FORWARD_ONLY) != 0)
			throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "cannot specify both FORWARD_ONLY and SCROLL", getLineAndPos(ctx->SCROLL()));
		option |= (CURSOR_OPT_SCROLL | TSQL_CURSOR_OPT_SCROLL);
	}

	if (ctx->STATIC())
		option |= TSQL_CURSOR_OPT_STATIC;
	if (ctx->KEYSET())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "KEYSET CURSOR is not supported", getLineAndPos(ctx->KEYSET()));
	if (ctx->DYNAMIC())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "DYNAMIC CURSOR is not supported", getLineAndPos(ctx->DYNAMIC()));
	if (ctx->FAST_FORWARD())
	{
		if ((option & TSQL_CURSOR_OPT_SCROLL) != 0)
			throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "cannot specify both FAST_FORWARD and SCROLL", getLineAndPos(ctx->FAST_FORWARD()));

		/* FAST_FORWARD specifies FORWARD_ONLY and READ_ONLY) */
		option |= (CURSOR_OPT_NO_SCROLL | TSQL_CURSOR_OPT_FORWARD_ONLY | TSQL_CURSOR_OPT_READ_ONLY);
	}

	if (ctx->READ_ONLY())
	{
		/*
		 * TODO:
		 * All the PG cursor is updatable. As READ_ONLY is one of commonly used options,
		 * let babelfish allow and ignore it. We may need to throw an error if the update/delete
		 * statement is running with 'where current of' clause.
		 */
		option |= TSQL_CURSOR_OPT_READ_ONLY;
	}
	if (ctx->SCROLL_LOCKS())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "SCROLL LOCKS is not supported", getLineAndPos(ctx->SCROLL_LOCKS()));
	if (ctx->OPTIMISTIC())
		throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "OPTIMISTIC is not supported", getLineAndPos(ctx->OPTIMISTIC()));

	return option;
}

static PLtsql_stmt *
makeSpStatement(const std::string& name_str, TSqlParser::Execute_statement_argContext *sp_args, int lineno, int return_code_dno)
{
	Assert(!name_str.empty());

	if (!sp_args)
		throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

	std::vector<tsql_exec_param *> params;

	PLtsql_stmt_exec_sp *result = (PLtsql_stmt_exec_sp *) palloc0(sizeof(*result));
	result->cmd_type = PLTSQL_STMT_EXEC_SP;
	result->lineno = lineno;
	result->return_code_dno = return_code_dno;
	result->paramno = 0;
	result->params = NIL;

	makeSpParams(sp_args, params);
	size_t paramno = params.size();

	if (string_matches(name_str.c_str(), "sp_cursor"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSOR;
		if (paramno < 4)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		result->handle = getNthParamExpr(params, 1);
		result->opt1 = getNthParamExpr(params, 2);
		result->opt2 = getNthParamExpr(params, 3);
		result->opt3 = getNthParamExpr(params, 4);

		for (size_t i = 4; i < paramno; i++)
		{
			result->params = lappend(result->params, params[i]);
			result->paramno++;
		}
	}
	else if (string_matches(name_str.c_str(), "sp_cursorclose"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSORCLOSE;
		if (paramno != 1)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		result->handle = getNthParamExpr(params, 1);
	}
	else if (string_matches(name_str.c_str(), "sp_cursorexecute"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSOREXECUTE;
		if (paramno < 2)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		result->handle = getNthParamExpr(params, 1);
		check_param_type(params[1], true, INT4OID, "cursor");
		result->cursor_handleno = params[1]->varno;
		result->opt1 = getNthParamExpr(params, 3);
		result->opt2 = getNthParamExpr(params, 4);
		result->opt3 = getNthParamExpr(params, 5);
		for (size_t i = 5; i < paramno; i++)
		{
			result->params = lappend(result->params, params[i]);
			result->paramno++;
		}
	}
	else if (string_matches(name_str.c_str(), "sp_cursorfetch"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSORFETCH;
		if (paramno < 1 || paramno > 4)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		result->handle = getNthParamExpr(params, 1);
		result->opt1 = getNthParamExpr(params, 2);
		result->opt2 = getNthParamExpr(params, 3);
		result->opt3 = getNthParamExpr(params, 4);
	}
	else if (string_matches(name_str.c_str(), "sp_cursoropen"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSOROPEN;
		if (paramno < 2)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		check_param_type(params[0], true, INT4OID, "cursor");
		result->cursor_handleno = params[0]->varno;
		result->query = getNthParamExpr(params, 2);
		result->opt1 = getNthParamExpr(params, 3);
		result->opt2 = getNthParamExpr(params, 4);
		result->opt3 = getNthParamExpr(params, 5);
		result->param_def = getNthParamExpr(params, 6);
		for (size_t i = 6; i < paramno; i++)
		{
			result->params = lappend(result->params, params[i]);
			result->paramno++;
		}
	}
	else if (string_matches(name_str.c_str(), "sp_cursoroption"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSOROPTION;
		if (paramno != 3)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		result->handle = getNthParamExpr(params, 1);
		result->opt1 = getNthParamExpr(params, 2);
		result->opt2 = getNthParamExpr(params, 3);
	}
	else if (string_matches(name_str.c_str(), "sp_cursorprepare"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSORPREPARE;
		if (paramno < 4 || paramno > 6)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		check_param_type(params[0], true, INT4OID, "prepared_handle");
		result->prepared_handleno = params[0]->varno;
		result->param_def = getNthParamExpr(params, 2);
		result->query = getNthParamExpr(params, 3);
		result->opt3 = getNthParamExpr(params, 4);
		result->opt1 = getNthParamExpr(params, 5);
		result->opt2 = getNthParamExpr(params, 6);
	}
	else if (string_matches(name_str.c_str(), "sp_cursorprepexec"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSORPREPEXEC;
		if (paramno < 5)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		check_param_type(params[0], true, INT4OID, "prepared_handle");
		result->prepared_handleno = params[0]->varno;
		check_param_type(params[1], true, INT4OID, "cursor");
		result->cursor_handleno = params[1]->varno;
		result->param_def = getNthParamExpr(params, 3);
		result->query = getNthParamExpr(params, 4);
		result->opt1 = getNthParamExpr(params, 5);
		result->opt2 = getNthParamExpr(params, 6);
		result->opt3 = getNthParamExpr(params, 7);
		for (size_t i = 7; i < paramno; i++)
		{
			result->params = lappend(result->params, params[i]);
			result->paramno++;
		}
	}
	else if (string_matches(name_str.c_str(), "sp_cursorunprepare"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_CURSORUNPREPARE;
		if (paramno != 1)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		result->handle = getNthParamExpr(params, 1);
	}
	else if (string_matches(name_str.c_str(), "sp_execute"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_EXECUTE;
		if (paramno < 1)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		result->handle = getNthParamExpr(params, 1);

		for (size_t i = 1; i < paramno; i++)
		{
			result->params = lappend(result->params, params[i]);
			result->paramno++;
		}
	}
	else if (string_matches(name_str.c_str(), "sp_executesql"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_EXECUTESQL;
		if (paramno < 1)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		result->query = getNthParamExpr(params, 1);
		result->param_def = getNthParamExpr(params, 2);

		for (size_t i = 2; i < paramno; i++)
		{
			result->params = lappend(result->params, params[i]);
			result->paramno++;
		}
	}
	else if (string_matches(name_str.c_str(), "sp_prepexec"))
	{
		result->sp_type_code = PLTSQL_EXEC_SP_PREPEXEC;
		if (paramno < 3)
			throw PGErrorWrapperException(ERROR, ERRCODE_INVALID_PARAMETER_VALUE, format_errmsg("%s procedure was called with an incorrect number of parameters", name_str.c_str()), getLineAndPos(sp_args));

		check_param_type(params[0], true, INT4OID, "prepared_handle");
		result->prepared_handleno = params[0]->varno;
		result->param_def = getNthParamExpr(params, 2);
		result->query = getNthParamExpr(params, 3);

		for (size_t i = 3; i < paramno; i++)
		{
			result->params = lappend(result->params, params[i]);
			result->paramno++;
		}
	}
	else
		Assert(0);

	return (PLtsql_stmt *) result;
}

static void
makeSpParams(TSqlParser::Execute_statement_argContext *ctx, std::vector<tsql_exec_param *> &params)
{
	tsql_exec_param *p;
	if (ctx->execute_statement_arg_unnamed())
	{
		p = makeSpParam(ctx->execute_statement_arg_unnamed());
		params.push_back(p);
		if (ctx->execute_statement_arg())
			makeSpParams(ctx->execute_statement_arg(), params);
	}
	else
	{
		for (auto arg : ctx->execute_statement_arg_named())
		{
			p = makeSpParam(arg);
			params.push_back(p);
		}
	}
}

static tsql_exec_param *
makeSpParam(TSqlParser::Execute_statement_arg_namedContext *ctx)
{
	TSqlParser::Execute_parameterContext *exec_param = ctx->execute_parameter();
	Assert(exec_param && ctx->LOCAL_ID());

	tsql_exec_param *p = (tsql_exec_param *) palloc0(sizeof(*p));
	auto targetText = ::getFullText(ctx->LOCAL_ID());
	p->name = pstrdup(targetText.c_str());
	p->varno = -1;
	p->mode = FUNC_PARAM_IN;

	if (exec_param->LOCAL_ID() && (exec_param->OUTPUT() || exec_param->OUT()))
	{
		auto *localID = exec_param->LOCAL_ID();
		p->varno = getVarno(localID);
		p->expr = makeTsqlExpr(::getFullText(localID), true);
		p->mode = FUNC_PARAM_INOUT;
	}
	else
		p->expr = makeTsqlExpr(exec_param, true);

	return p;
}

static tsql_exec_param *
makeSpParam(TSqlParser::Execute_statement_arg_unnamedContext *ctx)
{
	TSqlParser::Execute_parameterContext *exec_param = ctx->execute_parameter();
	Assert(exec_param);

	tsql_exec_param *p = (tsql_exec_param *) palloc0(sizeof(*p));
	p->name = NULL;
	p->varno = -1;
	p->mode = FUNC_PARAM_IN;

	if (exec_param->LOCAL_ID() && (exec_param->OUTPUT() || exec_param->OUT()))
	{
		auto *localID = exec_param->LOCAL_ID();
		p->varno = getVarno(localID);
		p->expr = makeTsqlExpr(::getFullText(localID), true);
		p->mode = FUNC_PARAM_INOUT;
	}
	else
		p->expr = makeTsqlExpr(exec_param, true);

	return p;
}

static int
getVarno(tree::TerminalNode *localID)
{
	int dno = -1;
	auto targetText = ::getFullText(localID);

	PLtsql_nsitem *nse = pltsql_ns_lookup(pltsql_ns_top(), false, targetText.c_str(), nullptr, nullptr, nullptr);

	if (nse)
		dno = nse->itemno;
	else
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("\"%s\" is not a known variable", targetText.c_str()), getLineAndPos(localID));

	return dno;
}

static int
check_assignable(tree::TerminalNode *localID)
{
	int dno = getVarno(localID);

	PLtsql_datum *datum = pltsql_Datums[dno];
	// FIXME: may need to check other datum types
	if (datum->dtype == PLTSQL_DTYPE_TBL)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("unrecognized dtype: %d", datum->dtype), getLineAndPos(localID));
	return dno;
}

static void
check_dup_declare(const char *name)
{
	if (pltsql_ns_lookup(pltsql_ns_top(), true, name, NULL, NULL, NULL) != NULL) 
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, "duplicate declaration", 0, 0);
}

static bool
is_sp_proc(const std::string& func_proc_name)
{
	const char *name_str = func_proc_name.c_str();
	return string_matches(name_str, "sp_cursor") ||
		string_matches(name_str, "sp_cursoropen") ||
		string_matches(name_str, "sp_cursorprepare") ||
		string_matches(name_str, "sp_cursorexecute") ||
		string_matches(name_str, "sp_cursorprepexec") ||
		string_matches(name_str, "sp_cursorunprepare") ||
		string_matches(name_str, "sp_cursorfetch") ||
		string_matches(name_str, "sp_cursoroption") ||
		string_matches(name_str, "sp_cursorclose") ||
		string_matches(name_str, "sp_executesql") ||
		string_matches(name_str, "sp_execute") ||
		string_matches(name_str, "sp_prepexec");
}

static bool
string_matches(const char *str, const char *pattern)
{
	if (pg_strcasecmp(str, pattern) == 0)
		return true;
	else
		return false;
}

static void
check_param_type(tsql_exec_param *param, bool is_output, Oid typoid, const char *param_str)
{
	if (is_output && param->mode != FUNC_PARAM_INOUT)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("%s param is not specified as OUTPUT", param_str), 0, 0);
	PLtsql_datum *datum = pltsql_Datums[param->varno];
	if (typoid != InvalidOid && datum->dtype != PLTSQL_DTYPE_VAR)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("invalid %s param", param_str), 0, 0);
	PLtsql_var *var = (PLtsql_var *) datum;
	if (typoid != InvalidOid && var->datatype->typoid != typoid)
		throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("invalid %s param datatype", param_str), 0, 0);
}

static PLtsql_expr*
getNthParamExpr(std::vector<tsql_exec_param *> &params, size_t n)
{
	if (n <= params.size())
		return params[n - 1]->expr;
	else
		return NULL;
}

static const char*
rewrite_assign_operator(tree::TerminalNode *aop)
{
	/* rewrite assign-operator to normal operator. simply remove '='. */
	std::string aop_str = ::getFullText(aop);
	Assert(aop_str.length() == 2);
	Assert(aop_str[1] == '=');

	switch (aop_str[0])
	{
		case '+': return "+";   /* addition */
		case '-': return "-";   /* subtraction */
		case '/': return "/";   /* division */
		case '*': return "*";   /* multiplication */
		case '%': return "%";   /* modulus */
		case '|': return "|";   /* bitwise OR */
		case '&': return "&";   /* bitwise AND */
		case '^': return "^";   /* bitwise XOR - we don't need to replace with PG '#' since we override it to XOR in tsql-dialect is ON */
		default: Assert(0);
	}
	return NULL; /* to avoid compiler warning */
}

TSqlParser::Query_specificationContext *
get_query_specification(TSqlParser::Select_statementContext* sctx)
{
	Assert(sctx);
	Assert(sctx->query_expression());
	TSqlParser::Query_expressionContext *qectx = sctx->query_expression();
	TSqlParser::Query_specificationContext *qctx = qectx->query_specification();
	while (!qctx)
	{
		/* query expression should be surrounded by bracket */
		Assert(qectx->LR_BRACKET());
		qectx = qectx->query_expression();
		Assert(qectx);

		if (qectx->query_specification())
			qctx = qectx->query_specification();
	}
	return qctx;
}

bool
is_top_level_query_specification(TSqlParser::Query_specificationContext *ctx)
{
	/*
	 * In ANTLR T-SQL grammar, top-level SELECT statement is represented as select_statement_standalone.
	 * subquery, derived table, CTE can contain query specification via SELECT statement but it is just a select_statement not via select_statement_standalone.
	 * To figure out the query-specification is corresponding to top-level SELECT statement,
	 * iterate its ancestors and check if encountering subquery, derived_table or common_table_expression.
	 * if it is query specification in top-level statement, it will never meet those grammar element.
	 */
	Assert(ctx);

	auto pctx = ctx->parent;
	while (pctx)
	{
		if (dynamic_cast<TSqlParser::Derived_tableContext *>(pctx) ||
		    dynamic_cast<TSqlParser::SubqueryContext *>(pctx) ||
		    dynamic_cast<TSqlParser::Common_table_expressionContext *>(pctx) ||
		    dynamic_cast<TSqlParser::Declare_xmlnamespaces_statementContext *>(pctx)) // not supported in BBF. excluding it from top-level select statement just in case.
			return false;

		pctx = pctx->parent;
	}
	return true;
}

static bool
is_quotation_needed_for_column_alias(TSqlParser::Column_aliasContext *ctx)
{
	if (ctx->id())
	{
		if (ctx->id()->DOUBLE_QUOTE_ID())
			return false;
		else if (ctx->id()->SQUARE_BRACKET_ID())
			return false;
		return true;
	}
	else // string literal
		return false;
}

static bool
is_compiling_create_function()
{
	if (!pltsql_curr_compile)
		return false;
	if (pltsql_curr_compile->fn_oid == InvalidOid)
		return false;
	if (pltsql_curr_compile->fn_prokind != PROKIND_FUNCTION)
		return false;
	if (pltsql_curr_compile->fn_is_trigger != PLTSQL_NOT_TRIGGER) /* except trigger */
		return false;
	return true;
}

/* if no rewriting necessary, return empty string */
template<class T>
std::string
rewrite_information_schema_to_information_schema_tsql(T ctx, GetCtxFunc<T> getSchema)
{
	auto schema = getSchema(ctx);
	if (!schema)
		return "";
	else if (string_matches(stripQuoteFromId(ctx->schema).c_str(), "information_schema"))
		return "information_schema_tsql";
	else
		return "";
}

/* if no rewriting necessary, return empty string */
template<class T>
std::string
rewrite_object_name_with_omitted_db_and_schema_name(T ctx, GetCtxFunc<T> getDatabase, GetCtxFunc<T> getSchema)
{
	if (ctx->DOT().size() == 1)
	{
		auto schema = getSchema(ctx);

		// .object -> dbo.object
		if (!schema)
			return "dbo" + ::getFullText(ctx);
		else
			return "";
	}
	if (ctx->DOT().size() >= 2)
	{
		std::string name = ::getFullText(ctx);
		if (ctx->DOT().size() == 3)
		{
			// we can assume servername is null because unsupported-feature error should be thrown
			// so we can remove the first leading dot. the remaining name should be handled with the same with two dots case
			name = name.substr(1);
		}

		auto database = getDatabase(ctx);
		auto schema = getSchema(ctx);

		// ..object -> object
		if (!database && !schema)
			return name.substr(2);
		// db..object -> db.dbo.object
		else if (database && !schema)
		{
			size_t first_dot_index = name.find('.');
			Assert(first_dot_index != std::string::npos);
			Assert(name[first_dot_index+1] == '.'); /* next character should be also '.' */
			return name.substr(0,first_dot_index + 1) + "dbo" + name.substr(first_dot_index + 1);
		}
		// .schema.object -> schema.object
		else if (!database && schema)
			return name.substr(1);
		else
			return "";
	}
	return "";
}

/* if no rewriting necessary, return empty string */
template<class T>
std::string
rewrite_column_name_with_omitted_schema_name(T ctx, GetCtxFunc<T> getSchema, GetCtxFunc<T> getTableName)
{
	// Other than object name, the following cases are not valid.
	// 1) .column
	// 1) ..column
	// 2) schema..column
	// Let them as it is so that backend parser will throw a syntax error

	if (ctx->DOT().size() >= 2)
	{
		std::string name = ::getFullText(ctx);
		if (ctx->DOT().size() == 3)
		{
			// we can assume servername is null because unsupported-feature error should be thrown
			// so we can remove the first leading dot. the remaining name should be handled with the same with two dots case
			name = name.substr(1);
		}

		auto schema = getSchema(ctx);
		auto tablename = getTableName(ctx);

		if (!schema && tablename)
			return name.substr(1);
	}
	return "";
}

/*
 * In this function we Rewrite the Query for Trim function as follows
 * TRIM '(' expression from expression ')' -> sys.TRIM '(' expression , expression ')'
 */
static void
rewrite_function_trim_to_sys_trim(TSqlParser::TRIMContext *ctx)
{
	if (ctx->trim_from())
	{	
		rewritten_query_fragment.emplace(std::make_pair(ctx->trim_from()->start->getStartIndex(), std::make_pair(::getFullText(ctx->trim_from()), " , ")));
	}
	rewritten_query_fragment.emplace(std::make_pair(ctx->TRIM()->getSymbol()->getStartIndex(), std::make_pair(::getFullText(ctx->TRIM()), "sys.trim")));
}

///////////////////////////////////////////////////////////////////////////////
// Spatial Query Helper
////////////////////////////////////////////////////////////////////////////////

/*
 * In this helper function we Rewrite the Query for Geospatial Handling
 * For Col_Ref Functions (such as STX, STY, Lat, Long) : ColRef.Func_name  ->  (ColRef).Func_name
 */
template<class T>
void
rewrite_geospatial_col_ref_query_helper(T ctx, TSqlParser::Method_callContext *method, size_t geospatial_start_index)
{
	std::vector<size_t> keysToRemove;
	std::string ctx_str = ::getFullText(ctx);
	ctx_str = ctx_str.substr(0, method->stop->getStopIndex() - ctx->start->getStartIndex() + 1);
	int func_call_len = (int)geospatial_start_index - ctx->start->getStartIndex();
	int method_len = (int)method->stop->getStopIndex() - method->start->getStartIndex();
	std::string expr = "";
	int index = 0;
	int offset1 = 0;
	
	/* writting the previously rewritten Geospatial context */
	for (auto &entry : rewritten_query_fragment)
	{
		if(entry.first >= ctx->start->getStartIndex() && entry.first <= method->stop->getStopIndex())
		{
			expr += ctx_str.substr(index, (int)entry.first - ctx->start->getStartIndex() - index) + entry.second.second;
			index = (int)entry.first - ctx->start->getStartIndex() + entry.second.first.size();
			keysToRemove.push_back(entry.first);
			if(entry.first <= geospatial_start_index) offset1 += (int)entry.second.second.size() - entry.second.first.size();
		}
	}
	for (const auto &key : keysToRemove) rewritten_query_fragment.erase(key);
	keysToRemove.clear();
	expr += ctx_str.substr(index);
	
	handleLocalIdQuotingFuncRefNoArg(ctx, geospatial_start_index, offset1, expr, keysToRemove);

	std::string rewritten_exp = "(" + expr.substr(0, func_call_len + offset1 + 1) + ")." + expr.substr((int)method->start->getStartIndex() - ctx->start->getStartIndex() + offset1, method_len + 1);
	rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(ctx_str.c_str(), rewritten_exp.c_str())));
}

/*
 * In this helper function we Rewrite the Query for Geospatial Handling
 * For Func_Ref Functions with no args (such as STAsText(), STAsBinary()) : ColRef.Func_name()  ->  Func_name(ColRef)
 */
template<class T>
void
rewrite_geospatial_func_ref_no_arg_query_helper(T ctx, TSqlParser::Method_callContext *method, size_t geospatial_start_index)
{
	std::vector<size_t> keysToRemove;
	std::string ctx_str = ::getFullText(ctx);
	ctx_str = ctx_str.substr(0, method->stop->getStopIndex() - ctx->start->getStartIndex() + 1);
	int func_call_len = (int)geospatial_start_index - ctx->start->getStartIndex();
	int method_len = (int)method->stop->getStopIndex() - method->start->getStartIndex();
	std::string expr = "";
	int index = 0;
	int offset1 = 0;
	
	/* writting the previously rewritten Geospatial context */
	for (auto &entry : rewritten_query_fragment)
	{
		if(entry.first >= ctx->start->getStartIndex() && entry.first <= method->stop->getStopIndex())
		{
			expr += ctx_str.substr(index, (int)entry.first - ctx->start->getStartIndex() - index) + entry.second.second;
			index = (int)entry.first - ctx->start->getStartIndex() + entry.second.first.size();
			keysToRemove.push_back(entry.first);
			if(entry.first <= geospatial_start_index) offset1 += (int)entry.second.second.size() - entry.second.first.size();
		}
	}
	for (const auto &key : keysToRemove) rewritten_query_fragment.erase(key);
	keysToRemove.clear();
	expr += ctx_str.substr(index);
	
	handleLocalIdQuotingFuncRefNoArg(ctx, geospatial_start_index, offset1, expr, keysToRemove);
	
	std::string rewritten_exp = expr.substr((int)method->start->getStartIndex() - ctx->start->getStartIndex() + offset1, method_len) + expr.substr(0, func_call_len + offset1 + 1) + ")";
	rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(ctx_str.c_str(), rewritten_exp.c_str())));
}

/*
 * In this helper function we Rewrite the Query for Geospatial Handling
 * For Func_Ref Functions with args (such as STDistance(arg)) : ColRef.Func_name(arg_list)  ->  Func_name(arg_list, ColRef)
 */
template<class T>
void
rewrite_geospatial_func_ref_args_query_helper(T ctx, TSqlParser::Method_callContext *method, size_t geospatial_start_index)
{
	std::vector<size_t> keysToRemove;
	std::string ctx_str = ::getFullText(ctx);
	ctx_str = ctx_str.substr(0, method->stop->getStopIndex() - ctx->start->getStartIndex() + 1);
	int func_call_len = (int)geospatial_start_index - ctx->start->getStartIndex();
	int method_len = (int)method->stop->getStopIndex() - method->start->getStartIndex();
	std::string expr = "";
	int index = 0;
	int offset1 = 0;
	int offset2 = 0;
	std::vector<std::pair<int, int>> arg_offset_list;
	int local_id_end_offset = 0;
	
	/* writting the previously rewritten Geospatial context */
	for (auto &entry : rewritten_query_fragment)
	{
		if(entry.first >= ctx->start->getStartIndex() && entry.first <= method->stop->getStopIndex())
		{
			expr += ctx_str.substr(index, (int)entry.first - ctx->start->getStartIndex() - index) + entry.second.second;
			index = (int)entry.first - ctx->start->getStartIndex() + entry.second.first.size();
			keysToRemove.push_back(entry.first);
			if(entry.first <= geospatial_start_index) offset1 += (int)entry.second.second.size() - entry.second.first.size();
			else if(entry.first > geospatial_start_index && entry.first <= method->stop->getStopIndex())
			{
				offset2 += (int)entry.second.second.size() - entry.second.first.size();
				/* storing these values in a list so that we could correctly calculate the offset for local_id argument rewrites */
				arg_offset_list.push_back(std::make_pair((int)entry.first, (int)entry.second.second.size() - entry.second.first.size()));
			}
		}
	}
	for (const auto &key : keysToRemove) rewritten_query_fragment.erase(key);
	keysToRemove.clear();
	expr += ctx_str.substr(index);
	
	/* quoting local_id here so as to remove possibility of multiple rewrites in a single context */
	for (auto &entry : local_id_positions)
	{
		if(entry.first >= ctx->start->getStartIndex() && entry.first <= geospatial_start_index)
		{
			/* Here we are quoting local_id which are before the function name */
			int local_index = (int)entry.first - ctx->start->getStartIndex() + offset1;
			if(expr.substr(local_index, entry.second.size()) ==  entry.second)
			{
				keysToRemove.push_back(entry.first);
				expr = expr.substr(0, local_index) + "\"" + entry.second + "\"" + expr.substr(local_index + entry.second.size());
				offset1 += 2;
			}
		}
		else if(entry.first >= method->spatial_methods()->expression_list()->start->getStartIndex() && entry.first <= method->spatial_methods()->expression_list()->stop->getStopIndex())
		{
			/* Here we are quoting local_id which are within the argument list of the function */
			int local_index = (int)entry.first - ctx->start->getStartIndex() + offset1 + local_id_end_offset;
			for (size_t i = 0; i < arg_offset_list.size(); i++)
			{
				if((size_t)arg_offset_list[i].first < entry.first) local_index += arg_offset_list[i].second;
			}
			if(expr.substr(local_index, entry.second.size()) ==  entry.second)
			{
				keysToRemove.push_back(entry.first);
				expr = expr.substr(0, local_index) + "\"" + entry.second + "\"" + expr.substr(local_index + entry.second.size());
				offset2 += 2;
				local_id_end_offset += 2;
			}
		}
	}
	for (const auto &key : keysToRemove) local_id_positions.erase(key);
	keysToRemove.clear();
	std::string rewritten_exp = expr.substr((int)method->start->getStartIndex() - ctx->start->getStartIndex() + offset1, method_len + offset2) + "," + expr.substr(0, func_call_len + offset1 + 1) + ")";
	rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(ctx_str.c_str(), rewritten_exp.c_str())));
}

/*
 * In this helper function we Rewrite the Query for Geospatial Handling
 * For Col_Ref Functions (such as STX, STY, Lat, Long) : ColRef.Func_name  ->  (ColRef).Func_name
 * For Func_Ref Functions (such as STAsText, STAsBinary, STDistance) : ColRef.Func_name (arg_list)  ->  Func_name (arg_list, ColRef)
 */
template<class T>
void
rewrite_geospatial_query_helper(T ctx, TSqlParser::Method_callContext *method, size_t geospatial_start_index)
{	
	/* Check whether it is a Col_Ref Function or a Func_Ref Function */
	if(method->spatial_methods()->geospatial_col() && !method->spatial_methods()->LR_BRACKET() ) 
		rewrite_geospatial_col_ref_query_helper(ctx, method, geospatial_start_index);
	else if(method->spatial_methods()->geospatial_func_no_arg() && !method->spatial_methods()->expression_list() ) 
		rewrite_geospatial_func_ref_no_arg_query_helper(ctx, method, geospatial_start_index);
	else if(method->spatial_methods()->geospatial_func_arg() && method->spatial_methods()->expression_list() ) 
		rewrite_geospatial_func_ref_args_query_helper(ctx, method, geospatial_start_index);
}

///////////////////////////////////////////////////////////////////////////////
// End of Spatial Query Helper
////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Spatial Query Helper for Function Calls
////////////////////////////////////////////////////////////////////////////////

/*
 * In this helper function we Rewrite the Query for Geospatial Handling
 * This implementation is different for Function_Call Rule
 * For Func_Ref Functions with no args (such as STAsText(), STAsBinary()) : ColRef.Func_name()  ->  Func_name(ColRef)
 */
template<class T>
void
rewrite_function_call_geospatial_func_ref_no_arg(T ctx)
{
	std::vector<size_t> keysToRemove;
	std::string func_ctx = ::getFullText(ctx);

	std::string arg_ctx = "";
	int index = (int) ctx->spatial_proc_name_server_database_schema()->stop->getStopIndex() - ctx->spatial_proc_name_server_database_schema()->start->getStartIndex() + 1; 
	int length = (int) ctx->stop->getStopIndex() - ctx->spatial_proc_name_server_database_schema()->stop->getStopIndex() - 1; 
	
	/* rewriting the query as: table.col.STAsText() -> STAsText(table.col) */
	if (ctx->spatial_proc_name_server_database_schema()->table) arg_ctx += stripQuoteFromId(ctx->spatial_proc_name_server_database_schema()->table) + ".";
	arg_ctx += stripQuoteFromId(ctx->spatial_proc_name_server_database_schema()->column);
	std::string rewritten_func = ::getFullText(ctx->spatial_proc_name_server_database_schema()->geospatial_func_no_arg()) + func_ctx.substr(index, length) + arg_ctx + ")";
	rewritten_query_fragment.emplace(std::make_pair(ctx->spatial_proc_name_server_database_schema()->start->getStartIndex(), std::make_pair(::getFullText(ctx), rewritten_func.c_str())));
}

/*
 * In this helper function we Rewrite the Query for Geospatial Handling
 * This implementation is different for Function_Call Rule
 * For Func_Ref Functions with args (such as STDistance(arg)) : ColRef.Func_name(arg_list)  ->  Func_name(arg_list, ColRef)
 */
template<class T>
void
rewrite_function_call_geospatial_func_ref_args(T ctx)
{
	std::vector<size_t> keysToRemove;
	std::string func_ctx = ::getFullText(ctx);
	int col_len = (int)ctx->spatial_proc_name_server_database_schema()->column->stop->getStopIndex() - ctx->start->getStartIndex();
	int method_len = (int)ctx->stop->getStopIndex() - ctx->spatial_proc_name_server_database_schema()->geospatial_func_arg()->start->getStartIndex();
	std::string expr = "";
	int index = 0;
	int offset1 = 0;
	int offset2 = 0;
	std::vector<std::pair<int, int>> arg_offset_list;
	int local_id_end_offset = 0;
	
	/* writting the previously rewritten Geospatial context */
	for (auto &entry : rewritten_query_fragment)
	{
		if(entry.first >= ctx->start->getStartIndex() && entry.first <= ctx->stop->getStopIndex())
		{
			expr += func_ctx.substr(index, (int)entry.first - ctx->start->getStartIndex() - index) + entry.second.second;
			index = (int)entry.first - ctx->start->getStartIndex() + entry.second.first.size();
			keysToRemove.push_back(entry.first);
			if(entry.first <= ctx->spatial_proc_name_server_database_schema()->column->stop->getStopIndex()) offset1 += (int)entry.second.second.size() - entry.second.first.size();
			else
			{
				offset2 += (int)entry.second.second.size() - entry.second.first.size();
				/* storing these values in a list so that we could correctly calculate the offset for local_id argument rewrites */
				arg_offset_list.push_back(std::make_pair((int)entry.first, (int)entry.second.second.size() - entry.second.first.size()));
			}
		}
	}
	for (const auto &key : keysToRemove) rewritten_query_fragment.erase(key);
	keysToRemove.clear();
	expr += func_ctx.substr(index);
	
	/* quoting local_id here so as to remove possibility of multiple rewrites in a single context */
	for (auto &entry : local_id_positions)
	{
		if(entry.first >= ctx->function_arg_list()->start->getStartIndex() && entry.first <= ctx->function_arg_list()->stop->getStopIndex())
		{
			/* Here we are quoting local_id which are within the argument list of the function */
			int local_index = (int)entry.first - ctx->start->getStartIndex() + offset1 + local_id_end_offset;
			for (size_t i = 0; i < arg_offset_list.size(); i++)
			{
				if((size_t)arg_offset_list[i].first < entry.first) local_index += arg_offset_list[i].second;
			}
			if(expr.substr(local_index, entry.second.size()) ==  entry.second)
			{
				keysToRemove.push_back(entry.first);
				expr = expr.substr(0, local_index) + "\"" + entry.second + "\"" + expr.substr(local_index + entry.second.size());
				offset2 += 2;
				local_id_end_offset += 2;
			}
		}
	}
	for (const auto &key : keysToRemove) local_id_positions.erase(key);
	keysToRemove.clear();

	/*
	 * Rewriting the query as: table.col.STDistance(arg) -> STDistance(arg, table.col)
	 */
	std::string rewritten_func = expr.substr((int)ctx->spatial_proc_name_server_database_schema()->geospatial_func_arg()->start->getStartIndex() - ctx->start->getStartIndex() + offset1, method_len + offset2) + "," + expr.substr(0, col_len + offset1 + 1) + ")";
	rewritten_query_fragment.emplace(std::make_pair(ctx->spatial_proc_name_server_database_schema()->start->getStartIndex(), std::make_pair(::getFullText(ctx), rewritten_func.c_str())));
}

///////////////////////////////////////////////////////////////////////////////
// End of Spatial Query Helper for Function Calls 
////////////////////////////////////////////////////////////////////////////////

template <class T>
static void 
handleLocalIdQuotingFuncRefNoArg(T ctx, size_t geospatial_start_index, int &offset1, std::string &expr, std::vector<size_t> keysToRemove)
{
	/* quoting local_id here so as to remove possibility of multiple rewrites in a single context */
	for (auto &entry : local_id_positions)
	{
		if(entry.first >= ctx->start->getStartIndex() && entry.first <= geospatial_start_index)
		{
			/* Here we are quoting local_id which are before the function name */
			int local_index = (int)entry.first - ctx->start->getStartIndex() + offset1;
			if(expr.substr(local_index, entry.second.size()) ==  entry.second)
			{
				keysToRemove.push_back(entry.first);
				expr = expr.substr(0, local_index) + "\"" + entry.second + "\"" + expr.substr(local_index + entry.second.size());
				offset1 += 2;
			}
		}
	}
	for (const auto &key : keysToRemove) local_id_positions.erase(key);
	keysToRemove.clear();
}

static void
handleGeospatialFunctionsInFunctionCall(TSqlParser::Function_callContext *ctx)
{
	/* Handles rewrite of geospatial function calls */
	if (ctx->spatial_proc_name_server_database_schema())
	{
		if (ctx->spatial_proc_name_server_database_schema()->schema) throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, "Remote procedure/function reference with 4-part object name is not currently supported in Babelfish", getLineAndPos(ctx));

		/* This if-elseIf clause rewrites the query in case of geospatial function calls */
		if (ctx->spatial_proc_name_server_database_schema()->geospatial_func_arg() && ctx->function_arg_list())
			rewrite_function_call_geospatial_func_ref_args(ctx);
		else if (ctx->spatial_proc_name_server_database_schema()->geospatial_func_no_arg() && !ctx->function_arg_list())
			rewrite_function_call_geospatial_func_ref_no_arg(ctx);
	}
}

static void 
handleClrUdtFuncCall(TSqlParser::Clr_udt_func_callContext *ctx)
{
	/* checking if CLR_UDT types */
	if(ctx != NULL && !ctx->DOT().empty())
	{
		std::vector<TSqlParser::Method_callContext *> method_calls = ctx->method_call();
		for (size_t i = 0; i < method_calls.size(); ++i)
		{
			TSqlParser::Method_callContext *method = method_calls[i];
			/* rewriting the query in case of geospatial function calls */
			if(method->spatial_methods())
			{
				size_t ind = -1;
				if (i == 0)
				{
					if(ctx->local_id()) ind = ctx->local_id()->stop->getStopIndex();
					else if(ctx->subquery()) ind = ctx->subquery()->stop->getStopIndex();
					else if(ctx->function_call()) ind = ctx->function_call()->stop->getStopIndex();
					else if(ctx->RR_BRACKET()) ind = ctx->RR_BRACKET()->getSymbol()->getStartIndex();
				}
				else ind = method_calls[i-1]->stop->getStopIndex();
				rewrite_geospatial_query_helper(ctx, method, ind);
			}
		}
	}
}

static void
handleFullColumnNameCtx(TSqlParser::Full_column_nameContext *ctx)
{
	GetCtxFunc<TSqlParser::Full_column_nameContext *> getSchema = [](TSqlParser::Full_column_nameContext *o) { return o->schema; };
	GetCtxFunc<TSqlParser::Full_column_nameContext *> getTablename = [](TSqlParser::Full_column_nameContext *o) { return o->tablename; };
	
	std::string func_name;
	/* Handles rewrite of geospatial query */
	if(ctx->column_name) func_name = stripQuoteFromId(ctx->column_name);
	else if (ctx->geospatial_col())
	{
		/* Throwing error similar to TSQL as we do not allow 4-Part name for geospatial function calls */
		if(ctx->schema) throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("The multi-part identifier \"%s\" could not be bound.", ::getFullText(ctx).c_str()), getLineAndPos(ctx));
		
		/* Rewriting the query as: table.col.STX -> (table.col).STX */
		std::string ctx_str = ::getFullText(ctx);
		std::string rewritten_func_name = "(" + ctx_str.substr(0, ctx->column->stop->getStopIndex() - ctx->start->getStartIndex() + 1) + ")." + ctx_str.substr(ctx->geospatial_col()->start->getStartIndex() - ctx->start->getStartIndex());
		rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(ctx_str, rewritten_func_name.c_str())));
	}
	
	std::string rewritten_name = rewrite_column_name_with_omitted_schema_name(ctx, getSchema, getTablename);
	std::string rewritten_schema_name = rewrite_information_schema_to_information_schema_tsql(ctx, getSchema);
	if (!rewritten_name.empty())
		rewritten_query_fragment.emplace(std::make_pair(ctx->start->getStartIndex(), std::make_pair(::getFullText(ctx), rewritten_name)));
	if (pltsql_enable_tsql_information_schema && !rewritten_schema_name.empty())
		rewritten_query_fragment.emplace(std::make_pair(ctx->schema->start->getStartIndex(), std::make_pair(::getFullText(ctx->schema), rewritten_schema_name)));

	if (does_object_name_need_delimiter(ctx->tablename))
		rewritten_query_fragment.emplace(std::make_pair(ctx->tablename->start->getStartIndex(), std::make_pair(::getFullText(ctx->tablename), delimit_identifier(ctx->tablename))));

	// qualified identifier doesn't need delimiter
	if (ctx->DOT().empty() && does_object_name_need_delimiter(ctx->column_name))
		rewritten_query_fragment.emplace(std::make_pair(ctx->column_name->start->getStartIndex(), std::make_pair(::getFullText(ctx->column_name), delimit_identifier(ctx->column_name))));
}

static bool
does_object_name_need_delimiter(TSqlParser::IdContext *id)
{
	if (!id)
		return false;

	if (!id->ID() && !id->keyword())
		return false; // already delimited

	std::string id_str = ::getFullText(id);
	for (size_t i=0; i<get_num_column_names_to_be_delimited(); ++i)
	{
		const char *keyword = column_names_to_be_delimited[i];
		if (pg_strcasecmp(keyword, id_str.c_str()) == 0)
			return true;
	}
	for (size_t i=0; i<get_num_pg_reserved_keywords_to_be_delimited(); ++i)
	{
		const char *keyword = pg_reserved_keywords_to_be_delimited[i];
		if (pg_strcasecmp(keyword, id_str.c_str()) == 0)
			return true;
	}
	return false;
}

static std::string
delimit_identifier(TSqlParser::IdContext *id)
{
	return std::string("[") + ::getFullText(id) + "]";
}

/**
 * Checks if the number of format specifiers in the message
 * is exceeding the limit i.e 20
 * The logic to check number of format specifier is based on 
 * the prepare_format_string function in string.c file
 **/
static bool 
does_msg_exceeds_params_limit(const std::string& msg)
{
	//end is at msg.length() - 1 since we dont count '%' as a param if it is the last character
	int paramCount = 0, end = msg.length() - 1, idx = 0;
	
	while(idx < end)
	{
		if(msg[idx++] == '%'){
			paramCount++;
		}
	}

	return paramCount > RAISE_ERROR_PARAMS_LIMIT;
}

// getIDName() - returns the name found in one of the given TerminalNodes
//
//	We expect one non-null pointer and two null pointers.  The first (dq)
//  will be non-null if we are working with a DOUBLE_QUOTE_ID() - we
//  strip off the double-quotes and return the result.  The second (sb)
//  will be non-null if we are working with a SQUARE_BRACKET_ID() - we
//  strip off the square brackets and return the result.  The last (id)
//  will be non-null if we are working on an ID() - we just return the
//  name itself.
static std::string
getIDName(TerminalNode *dq, TerminalNode *sb, TerminalNode *id)
{
	Assert(dq || sb || id);

	if (dq)
	{
		std::string name{dq->getSymbol()->getText()};
		Assert(name.front() == '"');
		Assert(name.back() == '"');

		name = name.substr(1, name.size() - 2);

		return name;
	}
	else if (sb)
	{
		std::string name{sb->getSymbol()->getText()};
		Assert(name.front() == '[');
		Assert(name.back() == ']');

		name = name.substr(1, name.size() - 2);

		return name;
	}
	else
	{
		return std::string(id->getSymbol()->getText());
	}
}

// rewriteDoubleQuotedString() - change double-quoted string to single-quoted
// A double-quoted string must be changed to a single-quoted string
// since PG accepts only single quotes as string delimiters. This requires:
// - change the enclosing quotes to single quotes
// - escape any single quotes in the string by doubling them
// - unescape any double quotes
std::string 
rewriteDoubleQuotedString(const std::string strDoubleQuoted)
{
	std::string str = strDoubleQuoted;

	Assert(str.front() == '"');
	Assert(str.back() == '"');

	// For any embedded single-quotes, these must be escaped by doubling them
	for (size_t i = str.find("\'", 1);  // start at pos 1: char 0 has the enclosing quote
		i != std::string::npos;   
		i = str.find("\'", i + 2) )
	{
		str.replace(i, 1, "''");	    // Change single quote to 2 single-quotes					
	}

	// Now change the enclosing quotes, i.e. from "foo" to 'foo'
	// Must do this after embedded single-quote handling above
	str.front() = '\'';
	str.back() = '\'';

	// For any embedded double-quotes, these must be un-escaped by removing one of the two
	for (size_t i = str.find("\"\"", 1);  // Start at pos 1: char 0 has the enclosing quote
		i != std::string::npos; 
		i = str.find("\"\"", i + 1) )
	{
		str.replace(i, 2, "\"");	     // Remove one of the double quotes
	}

	return str;
}

// Escape double quotes by doubling them
std::string 
escapeDoubleQuotes(const std::string strWithDoubleQuote)
{
	std::string quote = "\"";
	std::string str = strWithDoubleQuote;

	// If the string contains embedded quotes, these must be escaped by doubling them
	for (size_t i = str.find(quote, 1);  // Start at pos 1: char 0 has the enclosing delimiter
		i != std::string::npos;   
		i = str.find(quote, i + 2) )
	{
		str.replace(i, 1, quote+quote);	 // Change quote to 2 quotes					
	}

	return str;
}

PLtsql_stmt *
makeChangeDbOwnerStatement(TSqlParser::Alter_authorizationContext *ctx)
{
	PLtsql_stmt_change_dbowner *result = (PLtsql_stmt_change_dbowner *) palloc0(sizeof(*result));

	result->cmd_type = PLTSQL_STMT_CHANGE_DBOWNER;
	result->lineno = getLineNo(ctx);
	
	// 'table' represents the actual database name in the grammar
	std::string db_name_str = stripQuoteFromId(ctx->entity_name()->table);
	result->db_name = pstrdup(downcase_truncate_identifier(db_name_str.c_str(), db_name_str.length(), true));
	
	// Login name for the new owner
	std::string new_owner_name_str = stripQuoteFromId(ctx->authorization_grantee()->id());
	result->new_owner_name = pstrdup(downcase_truncate_identifier(new_owner_name_str.c_str(), new_owner_name_str.length(), true));

	return (PLtsql_stmt *) result;
}

// Look for '<number>E' : T-SQL allows the exponent to be omitted (defaults to 0), but PG raises an error 
// The REAL token is generated by the lexer; check the actual string to see if this is REAL notation	
// Notes: 
//  * the mantissa may also start with a '.', i.e. '.5e'
//  * the exponent may just be a + or - sign (means '0'; 1e+ ==> 1e0 )
void
handleFloatWithoutExponent(TSqlParser::ConstantContext *ctx) 
{
	std::string str = getFullText(ctx);

	// Check for case where exponent is only a sign: 2E+ , 2E-
	if ((str.back() == '+') || (str.back() == '-'))
	{
		// remove terminating sign	
		str.pop_back();

		if ((str.back() == 'E') || (str.back() == 'e'))
		{
			// ends in 'E+' or 'E-', continue below
		}
		else 
		{
			// Whatever it is, it's not the notation we're looking for 
			return;
		}
	}

	if ((str.back() == 'E') || (str.back() == 'e'))
	{
		// remove terminating E
		str.pop_back();

		if ((str.front() == '+') || (str.front() == '-'))
		{
			 // remove leading sign
			 str.erase(0,1);
		}

		// Now check if this is a valid number. Note that it may start or end with '.' 
		// but in both cases it must have at least one digit as well.  
		size_t dot = str.find(".");
		if (dot != std::string::npos)
		{
			 // remove the dot
			 str.erase(dot,1);
		}
    
		// What we have left now should be all digits
		bool is_number = true;
		if (str.length() == 0) 
		{
			is_number = false;
		}
		else
    	{
			for(size_t i = 0; i < str.length(); i++) 
			{
			    if (!isdigit(str[i])) 
			    {
			    	is_number = false;
			    	break;
			    }
			}
		}
	
		if (is_number)
		{
			// Rewrite the exponent by adding a '0'
			std::string str = getFullText(ctx);
			size_t startPosition = ctx->start->getStartIndex();
			if (in_execute_body_batch_parameter) startPosition += fragment_EXEC_prefix.length(); // add length of prefix prepended internally for execute_body_batch
			rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(str, str+"0")));
		}
	}
	return;
}

static void
handleBitNotOperator(TSqlParser::Unary_op_exprContext *ctx)
{
	// For the bit negation unary operator ('~') always add a space ahead of it as there may be a '+' or '-' preceding it (but we cannot immediately tell from
	// the current context). Also add a space behind it, depending on whether specific characters follow directly without an intervening space.
	if (ctx->BIT_NOT())
	{
		std::string op   = getFullText(ctx->BIT_NOT()); // this is a bit redundant since it can only be '~', but keeping the same style as other rewrites
		std::string expr = getFullText(ctx->expression());
		std::string endSpace = "";
		if ((expr.front() == '+') || (expr.front() == '-') || (expr.front() == '@')) endSpace = " ";
		size_t startPosition = ctx->BIT_NOT()->getSymbol()->getStartIndex();
		rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(op, " "+op+endSpace)));
	}
	return;
}

static void 
handleTableConstraintWithoutComma(TSqlParser::Column_def_table_constraintsContext *ctx)
{
	/*
	 * It is not documented but it seems T-SQL allows that column-definition is followed by table-constraint without COMMA.
	 * PG backend parser will throw a syntax error when this kind of query is inputted.
	 * It is not easy to add a rule accepting this syntax to backend parser because of many shift/reduce conflicts.
	 * To handle this case, add a compensation COMMA between column-definition and table-constraint here.
	 *
	 * This handling should be only applied to table-constraint following column-definition. Other cases (such as two column definitions without comma) should still throw a syntax error.
	 */
	ParseTree* prev_child = nullptr;
	for (ParseTree* child : ctx->children)
	{
		TSqlParser::Column_def_table_constraintContext* cdtctx = dynamic_cast<TSqlParser::Column_def_table_constraintContext*>(child);
		if (cdtctx && cdtctx->table_constraint())
		{
			TSqlParser::Column_def_table_constraintContext* prev_cdtctx = (prev_child ? dynamic_cast<TSqlParser::Column_def_table_constraintContext*>(prev_child) : nullptr);
			if (prev_cdtctx && prev_cdtctx->column_definition())
			{
				rewritten_query_fragment.emplace(std::make_pair(cdtctx->start->getStartIndex(), std::make_pair("", ","))); // add comma
			}
		}
		prev_child = child;
	}
	return;
}

static void
handleBitOperators(TSqlParser::Plus_minus_bit_exprContext *ctx)
{
	// For the bit operators AND, OR , XOR ('&', '|', '^') add a space behind it, depending on whether specific characters follow directly without an intervening space.
	if (ctx->BIT_AND() || ctx->BIT_OR() || ctx->BIT_XOR())
	{
		Assert(ctx->expression(1));
		std::string expr = getFullText(ctx->expression(1));
		if ((expr.front() = '+') || (expr.front() = '-') || (expr.front() = '@')) 
		{
			std::string op = getFullText(ctx->op);
			size_t startPosition = ctx->op->getStartIndex();
			rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(op, op+" ")));
		}
	}
	return;
}

static void
handleModuloOperator(TSqlParser::Mult_div_percent_exprContext *ctx)
{
	// For the modulo operator ('%') add a space behind it, depending on whether specific characters follow directly without an intervening space.
	if (ctx->PERCENT_SIGN())
	{
		Assert(ctx->expression(1));	
		std::string expr = getFullText(ctx->expression(1));
		if ((expr.front() == '+') || (expr.front() == '-') || (expr.front() == '@')) 
		{
			std::string op = getFullText(ctx->PERCENT_SIGN()); // this is a bit redundant since it can only be '%', but keeping the same style as other rewrites
			size_t startPosition = ctx->PERCENT_SIGN()->getSymbol()->getStartIndex();
			rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(op, op+" ")));
		}
	}
	return;
}

void handleAtAtVarInPredicate(TSqlParser::PredicateContext *ctx)
{	
	// For comparison operators directly followed by an '@@' variable, insert a space 
	// to avoid these being parsed incorrectly by PG; this applies to these following 
	// character sequences: =@@, >@@, <@@ as well as !=@ (single-@ variable)
	// Note: this issue does occur for assignments like 'SET @v=@@spid' or column aliases like 'SELECT a=@@spid'
	// Note: parameter defaults and named parameters are handled separately

	if ((ctx->comparison_operator()) && (ctx->expression().size() > 1))
	{
		std::string op = getFullText(ctx->comparison_operator());		
		if ((op.back() == '=') || 
		    (op.back() == '>') || 
		    (op.back() == '<'))
		{
			// The operator must be followed immediately by the variable without any character in between
			Assert(ctx->expression(1));
			size_t startPosition = ctx->expression(1)->start->getStartIndex();
			if ((startPosition - ctx->comparison_operator()->stop->getStopIndex()) == 1)
			{
				std::string var = getFullText(ctx->expression(1));
				// The subsequent expression must be a variable starting with '@@'
				if (var.front() == '@') 
				{
					if ((var.at(1) == '@') || (pg_strncasecmp(op.c_str(), "!=", 2) == 0))
					{
						// Insert a space before the variable name
						rewritten_query_fragment.emplace(std::make_pair(startPosition, std::make_pair(var, " "+var)));
					}
				}
			}
		}
	}
	return;
}	

static void
handleOrderByOffsetFetch(TSqlParser::Order_by_clauseContext *ctx)
{
	// Add brackets around the expressions for OFFSET..ROWS and FETCH..ROWS
	
	if (ctx->offset_exp) 
	{
		// Do not rewrite the entire expression since that will break the logic in the mutator when there is something inside the
		// expression that also needs rewriting (like a local variable @p which needs to be rewritten as "@p").
		// Instead, insert an opening and closing bracket in the right places.
		// Also, do not add a rewrite at the start position of the expression since there may be an '@' for a local var 
		// at that position and the rewrite to double-quote the variable will be lost as a result.
		rewritten_query_fragment.emplace(std::make_pair((ctx->offset_exp->start->getStartIndex() - 1), std::make_pair("", " (")));
		rewritten_query_fragment.emplace(std::make_pair((ctx->offset_exp->stop->getStopIndex() + 1), std::make_pair("", ") ")));
	}
	
	if (ctx->fetch_exp) 
	{
		// See comment for offset_exp above.
		rewritten_query_fragment.emplace(std::make_pair((ctx->fetch_exp->start->getStartIndex() - 1), std::make_pair("", " (")));
		rewritten_query_fragment.emplace(std::make_pair((ctx->fetch_exp->stop->getStopIndex() + 1), std::make_pair("", ") ")));
	}

	return;
}

