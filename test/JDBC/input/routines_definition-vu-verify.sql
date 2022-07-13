select SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, COLLATION_NAME, CHARACTER_SET_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, ROUTINE_BODY, ROUTINE_DEFINITION, IS_DETERMINISTIC, SQL_DATA_ACCESS, IS_NULL_CALL, SCHEMA_LEVEL_ROUTINE, MAX_DYNAMIC_RESULT_SETS, IS_USER_DEFINED_CAST, IS_IMPLICITLY_INVOCABLE from information_schema.routines where SPECIFIC_NAME NOT LIKE 'xp%' ORDER BY ROUTINE_DEFINITION;
go

use db1;
go

select SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, COLLATION_NAME, CHARACTER_SET_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, ROUTINE_BODY, ROUTINE_DEFINITION, IS_DETERMINISTIC, SQL_DATA_ACCESS, IS_NULL_CALL, SCHEMA_LEVEL_ROUTINE, MAX_DYNAMIC_RESULT_SETS, IS_USER_DEFINED_CAST, IS_IMPLICITLY_INVOCABLE from information_schema.routines where SPECIFIC_NAME NOT LIKE 'xp%' ORDER BY ROUTINE_DEFINITION;
go

use master;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_uid';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b1';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b2';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b3';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b4';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b5';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b6';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_bd7';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_bb';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b8';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_bd9';
go

select tsql_get_functiondef(oid) from pg_proc where proname='func_nvar';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b10';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b11';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_func_opt';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_s';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_arg';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_con';
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_t';
go

select tsql_get_functiondef(oid) from pg_proc where proname='cur_var';
go
