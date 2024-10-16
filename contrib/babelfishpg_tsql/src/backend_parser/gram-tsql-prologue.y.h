/*****************************************************************************
 *
 * Start of T-SQL specific prologue (will be moved to separate file)
 *
 *****************************************************************************/

#include "access/htup_details.h"
#include "catalog/pg_type.h"
#include "parser/parse_type.h"
#include "parser/scansup.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "common/md5.h"

#include "src/backend_parser/gramparse.h"
#include "src/pltsql_instr.h"
#include "src/catalog.h"
#include "src/multidb.h"
#include "src/tsql_for/tsql_for.h"

#define MD5_HASH_LEN 32

static void pgtsql_base_yyerror(YYLTYPE * yylloc, core_yyscan_t yyscanner, const char *msg);

List	   *TsqlSystemFuncName(char *name);
List	   *TsqlSystemFuncName2(char *name);

typedef struct OpenJson_Col_Def
{
	char	   *elemName;
	TypeName   *elemType;
	char	   *elemPath;
	bool		asJson;
} OpenJson_Col_Def;

extern bool output_update_transformation;
extern bool output_into_insert_transformation;
extern char *update_delete_target_alias;
extern PLtsql_execstate *get_current_tsql_estate(void);

static Node *makeTSQLHexStringConst(char *str, int location);
static RangeVar *makeRangeVarFromAnyNameForTableType(List *names, int position, core_yyscan_t yyscanner);

static Node *TsqlFunctionTryCast(Node *arg, TypeName *typename, int location);
static Node *TsqlFunctionConvert(TypeName *typename, Node *arg, Node *style, bool try, int location);
static Node *TsqlFunctionParse(Node *arg, TypeName *typename, Node *culture, bool try, int location);

static Node *TsqlFunctionIIF(Node *bool_expr, Node *arg1, Node *arg2, int location);
static Node *TsqlFunctionIdentityInto(TypeName *typename, Node *seed, Node *increment, int location);
static Node *TsqlFunctionChoose(Node *int_expr, List *choosable, int location);
static void tsql_check_param_readonly(const char *paramname, TypeName *typename, bool readonly);
static ResTarget *TsqlForXMLMakeFuncCall(TSQL_ForClause *forclause);
static ResTarget *TsqlForJSONMakeFuncCall(TSQL_ForClause *forclause);
static RangeSubselect *TsqlForClauseSubselect(Node *selectstmt);
static Node * buildTsqlMultiLineTvfNode(int create_loc, bool replace, List *func_name, int func_name_loc, 
										List *tsql_createfunc_args, char *param_name, int table_loc, List *table_elts, 
										char *tokens_remaining, int tokens_loc, bool alter, core_yyscan_t yyscanner);
static Node *tsql_pivot_select_transformation(List *target_list, List *from_clause, List *pivot_clause, Alias *alias_clause, SelectStmt *pivot_sl);

static Node *TsqlOpenJSONSimpleMakeFuncCall(Node *jsonExpr, Node *path);
static Node *TsqlOpenJSONWithMakeFuncCall(Node *jsonExpr, Node *path, List *cols, Alias *alias);
static Node *createOpenJsonWithColDef(char *elemName, TypeName *elemType);
static int	getElemTypMod(TypeName *t);
static TypeName *setCharTypmodForOpenjson(TypeName *t);
static bool isCharType(char *typenameStr);
static bool isNVarCharType(char *typenameStr);

static Node *TsqlJsonModifyMakeFuncCall(Node *expr, Node *path, Node *newValue);
static bool is_json_query(List *name);

static Node *TsqlExpressionContains(char *colId, Node *search_expr, core_yyscan_t yyscanner);
static Node *makeToTSVectorFuncCall(char *colId, core_yyscan_t yyscanner, Node *pgconfig);
static Node *makeToTSQueryFuncCall(Node *search_expr, Node *pgconfig);

char	   *construct_unique_index_name(char *index_name, char *relation_name);

static Node *tsql_update_delete_stmt_with_join(Node *n, List *from_clause, Node *where_clause, Node *top_clause, RangeVar *relation,
											   core_yyscan_t yyscanner);
static void tsql_reset_update_delete_globals(void);
static void tsql_update_delete_stmt_from_clause_alias(RangeVar *relation, List *from_clause);
static Node *tsql_insert_output_into_cte_transformation(WithClause *opt_with_clause, Node *opt_top_clause, RangeVar *insert_target,
														List *insert_column_list, List *tsql_output_clause, RangeVar *output_target, List *tsql_output_into_target_columns,
														InsertStmt *tsql_output_insert_rest, int select_location);
static Node *tsql_delete_output_into_cte_transformation(WithClause *opt_with_clause, Node *opt_top_clause,
														RangeVar *relation_expr_opt_alias, List *tsql_output_clause, RangeVar *insert_target,
														List *tsql_output_into_target_columns, List *from_clause, Node *where_or_current_clause,
														core_yyscan_t yyscanner);
static void tsql_check_update_output_transformation(List *tsql_output_clause);
static Node *tsql_update_output_into_cte_transformation(WithClause *opt_with_clause, Node *opt_top_clause,
														RangeVar *relation_expr_opt_alias, List *set_clause_list,
														List *tsql_output_clause, RangeVar *insert_target, List *tsql_output_into_target_columns,
														List *from_clause, Node *where_or_current_clause, core_yyscan_t yyscanner);
static List *get_transformed_output_list(List *tsql_output_clause);
static bool returning_list_has_column_name(List *existing_colnames, char *current_colname);
static void tsql_index_nulls_order(List *indexParams, const char *accessMethod);
static void check_server_role_and_throw_if_unsupported(const char* serverrole, int position, core_yyscan_t yyscanner);
