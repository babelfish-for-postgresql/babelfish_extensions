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
#include "common/md5.h"

#include "src/backend_parser/gramparse.h"
#include "src/pltsql_instr.h"
#include "src/multidb.h"

#define MD5_HASH_LEN 32

static void pgtsql_base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner, const char *msg);

List *TsqlSystemFuncName(char *name);
List *TsqlSystemFuncName2(char *name);

/* Private struct for the result of tsql_for_clause production */
typedef struct TSQL_ForClause
{
	int mode;
	char *elementName;
	List *commonDirectives;
	int location;		/* token location of FOR, or -1 if unknown */
} TSQL_ForClause;

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
static Node *TsqlFunctionChoose(Node *int_expr, List *choosable, int location);
static void tsql_check_param_readonly(const char* paramname, TypeName *typename, bool readonly);
static ResTarget *TsqlForXMLMakeFuncCall(TSQL_ForClause *forclause, char *src_query, size_t start_location, core_yyscan_t yyscanner);
static ResTarget *TsqlForJSONMakeFuncCall(TSQL_ForClause *forclause, char *src_query, size_t start_location, core_yyscan_t yyscanner);
static Node* tsql_get_transformed_query(StringInfo format_query, char *end_param, char *query, List *params);

char * construct_unique_index_name(char *index_name, char *relation_name);

static Node *tsql_update_delete_stmt_with_join(Node *n, List* from_clause, Node*
				where_clause, Node *top_clause, RangeVar *relation,
				core_yyscan_t yyscanner);
static Node *tsql_update_delete_stmt_with_top(Node *top_clause, RangeVar
				*relation, Node *where_clause, core_yyscan_t yyscanner);
static void tsql_update_delete_stmt_from_clause_alias(RangeVar *relation, List *from_clause);
static Node *tsql_insert_output_into_cte_transformation(WithClause *opt_with_clause, RangeVar *insert_target, 
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
