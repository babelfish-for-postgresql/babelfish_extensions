-- sla 600000
select SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_DEFINITION from information_schema.routines where SPECIFIC_NAME LIKE 'xp_%' ORDER BY ROUTINE_NAME;
go

use db_routines_vu_prepare;
go

select SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, COLLATION_NAME, CHARACTER_SET_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, ROUTINE_BODY, ROUTINE_DEFINITION, IS_DETERMINISTIC, SQL_DATA_ACCESS, IS_NULL_CALL, SCHEMA_LEVEL_ROUTINE, MAX_DYNAMIC_RESULT_SETS, IS_USER_DEFINED_CAST, IS_IMPLICITLY_INVOCABLE from information_schema.routines where SPECIFIC_NAME LIKE 'routines_vu_prepare%' ORDER BY ROUTINE_NAME;
go

-- Test cross DB reference to ISC view routines
select ROUTINE_NAME from db_routines_vu_prepare.information_schema.routines ORDER BY ROUTINE_NAME;
go

use master;
go

select SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, CHARACTER_OCTET_LENGTH, COLLATION_NAME, CHARACTER_SET_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION, ROUTINE_BODY, ROUTINE_DEFINITION, IS_DETERMINISTIC, SQL_DATA_ACCESS, IS_NULL_CALL, SCHEMA_LEVEL_ROUTINE, MAX_DYNAMIC_RESULT_SETS, IS_USER_DEFINED_CAST, IS_IMPLICITLY_INVOCABLE from information_schema.routines where SPECIFIC_NAME LIKE 'routines_vu_prepare%' ORDER BY ROUTINE_DEFINITION;
go

-- Verify cross DB reference to ISC view routines
select ROUTINE_NAME from db_routines_vu_prepare.information_schema.routines ORDER BY ROUTINE_NAME;
go

use db_routines_vu_prepare;
go

drop procedure routines_vu_prepare_test_nvar;
go

drop FUNCTION routines_vu_prepare_sc1.routines_vu_prepare_test_dec;
go

drop schema routines_vu_prepare_sc1;
go

drop function routines_vu_prepare_fc1;
go

drop FUNCTION routines_vu_prepare_test_func_opt;
go

drop FUNCTION routines_vu_prepare_test_func_tvf;
go

drop FUNCTION routines_vu_prepare_test_func_itvf;
go

use master;
go

drop database db_routines_vu_prepare;
go
