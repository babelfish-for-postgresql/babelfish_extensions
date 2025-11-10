-- Drop function first
DROP FUNCTION IF EXISTS jira_babel_update_with_var_assign.custom_function;
GO

-- Drop all tables
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_int;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_str;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_multi;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_where;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_null;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_empty;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_single;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_numeric;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_math;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_col_assign;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_main;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_lookup;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_large;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_str_complex;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_case;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_counter;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_init;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_self;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_datetime;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_tran;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_top;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_convert;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_nested;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_other;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_dynamic;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_mixed_types;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_coalesce;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_output;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_running_max;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_cross_db;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_target;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_source;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_udf;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_concurrent;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_overflow;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_unicode;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_computed;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_recursive;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_division;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_truncation;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_identity;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_large_string;
GO
DROP TABLE IF EXISTS jira_babel_update_with_var_assign.test_complex_expr;
GO

-- Drop schema
DROP SCHEMA IF EXISTS jira_babel_update_with_var_assign;
GO