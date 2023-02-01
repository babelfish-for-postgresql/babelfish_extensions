%expect 1

%debug
%verbose

%initial-action
{
	yydebug = false;

	YYDPRINTF((stderr, "starting base SQL parser\n"));

	YYDPRINTF((stderr, "  %s\n", pg_yyget_extra(yyscanner)->core_yy_extra.scanbuf));
}

%type <node> tsql_stmt

%type <node> tsql_CreateFunctionStmt tsql_VariableSetStmt tsql_CreateTrigStmt tsql_TransactionStmt tsql_UpdateStmt tsql_DeleteStmt tsql_IndexStmt
%type <node> tsql_DropIndexStmt tsql_InsertStmt
%type <node> tsql_CreateLoginStmt tsql_AlterLoginStmt tsql_DropLoginStmt
%type <node> tsql_CreateUserStmt tsql_DropRoleStmt tsql_AlterUserStmt
%type <node> tsql_CreateRoleStmt
%type <node> tsql_nchar
%type <list> tsql_login_option_list1 tsql_login_option_list2
%type <list> tsql_alter_login_option_list
%type <defelt> tsql_login_option_elem tsql_alter_login_option_elem
%type <boolean> tsql_enable_disable
%type <defelt> tsql_create_user_options tsql_alter_user_options
%type <str> tsql_create_user_login
%type <list> tsql_createfunc_options tsql_createfunc_opt_list tsql_IsolationLevel
%type <list> tsql_func_name
%type <defelt> tsql_func_opt_item

%type <list> tsql_qualified_func_name

%type <node> openjson_expr
%type <node> openjson_col_def
%type <list> openjson_col_defs
%type <str> optional_path
%type <boolean> optional_asJson

%type <node> tsql_opt_arg_dflt
%type <node> tsql_opt_null_keyword
%type <fun_param> tsql_proc_arg tsql_func_arg
%type <list> tsql_proc_args_list tsql_func_args_list

%type <node> tsql_ExecStmt tsql_output_ExecStmt
%type <list> tsql_actual_args
%type <node> tsql_actual_arg
%type <boolean> tsql_opt_output tsql_opt_readonly

%type <str> tsql_OptTranName tsql_IsolationLevelStr

%type <node> tsql_alter_table_cmd

%type <ival> tsql_TriggerActionTime
%type <list> tsql_TriggerEvents tsql_TriggerOneEvent

%type <list> tsql_stmtmulti
%type <list> columnListWithOptAscDesc

%type <boolean> tsql_cluster tsql_opt_cluster

%type <list> tsql_OptParenthesizedIdentList tsql_IdentList

%type <node> TSQL_computed_column
%type <node> columnElemWithOptAscDesc

%type <node> tsql_ColConstraint tsql_ColConstraintElem

%type <typnam> TSQL_Typename TSQL_SimpleTypename TSQL_GenericType

%type <str> datepart_arg datediff_arg dateadd_arg
%type <str> tsql_type_function_name
%type <list> tsql_createproc_args tsql_createfunc_args
%type <list> tsql_triggername

%type <node> tsql_top_clause opt_top_clause

%type <str> tokens_remaining
%type <str> tsql_table_hint_kw_no_with
%type <list> tsql_table_hint_expr tsql_opt_table_hint_expr tsql_table_hint_list
%type <node> tsql_table_hint
%type <node> tsql_for_xml_clause tsql_xml_common_directive
%type <list> tsql_xml_common_directives

%type <node> tsql_for_json_clause tsql_for_json_common_directive
%type <list> tsql_for_json_common_directives

%type <istmt> tsql_output_insert_rest tsql_output_insert_rest_no_paren

%type <node> tsql_output_simple_select tsql_values_clause
%type <list> tsql_output_clause tsql_output_target_list tsql_output_into_target_columns
%type <target> tsql_output_target_el
%type <node> tsql_alter_server_role

%token <keyword> TSQL_ATAT TSQL_ALLOW_SNAPSHOT_ISOLATION
	TSQL_CALLER TSQL_CHOOSE TSQL_CLUSTERED TSQL_COLUMNSTORE TSQL_CONVERT
	TSQL_DATENAME TSQL_DATEPART TSQL_DATEDIFF TSQL_DATEADD TSQL_DEFAULT_SCHEMA TSQL_ISNULL
	TSQL_D TSQL_DAYOFYEAR TSQL_DD TSQL_DW TSQL_DY TSQL_HH TSQL_ISO_WEEK TSQL_ISOWK
	TSQL_ISOWW TSQL_LOGIN TSQL_M TSQL_MCS TSQL_MI TSQL_MICROSECOND TSQL_MILLISECOND TSQL_MM TSQL_MS
	TSQL_N TSQL_NANOSECOND TSQL_NONCLUSTERED TSQL_NS TSQL_OUTPUT TSQL_OUT TSQL_PARSE TSQL_Q
	TSQL_QQ TSQL_QUARTER TSQL_READONLY TSQL_ROWGUIDCOL TSQL_S
	TSQL_SAVE TSQL_SS TSQL_TRAN TSQL_TRY_CAST TSQL_TRY_CONVERT TSQL_TRY_PARSE
	TSQL_TEXTIMAGE_ON TSQL_TZ TSQL_TZOFFSET TSQL_W TSQL_WEEK TSQL_WEEKDAY TSQL_WK TSQL_WW TSQL_Y TSQL_YY TSQL_YYYY
	TSQL_SCHEMABINDING TSQL_IDENTITY_INSERT
	TSQL_EXEC TSQL_PROC TSQL_IIF TSQL_REPLICATION TSQL_SUBSTRING TSQL_PERSISTED
	TSQL_NOCHECK TSQL_NOLOCK TSQL_READUNCOMMITTED TSQL_UPDLOCK TSQL_REPEATABLEREAD
	TSQL_READCOMMITTED TSQL_TABLOCK TSQL_TABLOCKX TSQL_PAGLOCK TSQL_ROWLOCK
	TSQL_TOP TSQL_PERCENT
	TSQL_AUTO TSQL_EXPLICIT TSQL_RAW TSQL_PATH TSQL_FOR TSQL_BASE64 TSQL_ROOT TSQL_READPAST TSQL_XLOCK TSQL_NOEXPAND OPENJSON
	TSQL_JSON TSQL_INCLUDE_NULL_VALUES TSQL_WITHOUT_ARRAY_WRAPPER
	TSQL_MEMBER TSQL_SERVER
	TSQL_WINDOWS TSQL_CERTIFICATE TSQL_DEFAULT_DATABASE TSQL_DEFAULT_LANGUAGE TSQL_HASHED
	TSQL_MUST_CHANGE TSQL_CHECK_EXPIRATION TSQL_CHECK_POLICY TSQL_CREDENTIAL TSQL_SID TSQL_OLD_PASSWORD
	TSQL_UNLOCK TSQL_VALUES
	TSQL_NVARCHAR
	TSQL_CROSS TSQL_OUTER TSQL_APPLY

/*
 * WITH_paren is added to support table hints syntax WITH (<table_hint> [[,]...n]),
 * otherwise the parser cannot tell between 'WITH' and 'WITH (' and thus
 * lead to a shift/reduce conflict.
 */
%token	WITH_paren TSQL_HINT_START_BRACKET UPDATE_paren

%left TSQL_CROSS TSQL_OUTER
