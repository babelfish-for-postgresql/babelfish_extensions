-- Test 1 : Brackets around datatype for procedure
SELECT ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'storeOriginalQuery_procedure';
go
-- Test 2 : Single Line comment for procedure
ALTER PROCEDURE storeOriginalQuery_procedure AS BEGIN DECLARE @storeOriginalQuery_var [varchar] (6000) END
go
SELECT ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'storeOriginalQuery_procedure';
go
-- Test 3 : Multi Line comment for procedure

-- multiline comment line 1
-- multiline comment line 2
ALTER PROCEDURE storeOriginalQuery_procedure AS BEGIN DECLARE @storeOriginalQuery_var [varchar] (6000) END
go
SELECT ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'storeOriginalQuery_procedure';
go
-- Test 4 : Revise test 1,2,3 with functions
SELECT ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'storeOriginalQuery_function';
go
-- Test 5 : Single Line comment for function
ALTER function storeOriginalQuery_function() RETURNS [VARCHAR](6000) AS BEGIN DECLARE @storeOriginalQuery_var [varchar] (6000) RETURN @storeOriginalQuery_var END
go
SELECT ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'storeOriginalQuery_function';
go
-- Test 6 : Multi Line comment for function

-- multiline comment line 1
-- multiline comment line 2
ALTER function storeOriginalQuery_function() RETURNS [VARCHAR](6000) AS BEGIN DECLARE @storeOriginalQuery_var [varchar] (6000) RETURN @storeOriginalQuery_var END
go
SELECT ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'storeOriginalQuery_function';
go