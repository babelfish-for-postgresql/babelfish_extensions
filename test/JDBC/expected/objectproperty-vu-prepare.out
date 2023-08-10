-- Used to test when user does not have permission on the object
CREATE LOGIN objectproperty_login_1 WITH PASSWORD = '12345678'
go

create user objectproperty_login_1
go

-- =============== OwnerId ===============
-- Setup
CREATE SCHEMA objectproperty_vu_prepare_ownerid_schema
GO

CREATE TABLE objectproperty_vu_prepare_ownerid_schema.objectproperty_vu_prepare_ownerid_table(a int) 
GO

-- =============== IsDefaultCnst ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_isdefaultcnst_table(a int DEFAULT 10)
GO

CREATE TABLE objectproperty_vu_prepare_isdefaultcnst_table2(a int DEFAULT 10, b int DEFAULT 20)
GO

-- =============== ExecIsQuotedIdentOn ===============
-- Setup
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC objectproperty_vu_prepare_execisquotedident_proc_off
AS
RETURN 1
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC objectproperty_vu_prepare_execisquotedident_proc_on
AS
RETURN 1
GO

CREATE TABLE objectproperty_vu_prepare_execisquotedident_table(a int)
GO

-- =============== IsMSShipped ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_is_ms_shipped_table(a int)
GO

-- =============== TableFullTextPopulateStatus ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_tablefulltextpopulatestatus_table(a int)
GO

CREATE PROC objectproperty_vu_prepare_tablefulltextpopulatestatus_proc
AS
RETURN 1
GO

-- =============== TableHasVarDecimalStorageFormat ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_table(a int)
GO

CREATE proc objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_proc
AS
RETURN 1
GO

-- =============== IsSchemaBound ===============
-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsSchemaBound_function_false()
RETURNS int
BEGIN
    return 1
END
GO

CREATE FUNCTION objectproperty_vu_prepare_IsSchemaBound_function_true()
RETURNS int
WITH SCHEMABINDING
BEGIN
    return 1
END
GO

CREATE TABLE objectproperty_vu_prepare_IsSchemaBound_table(a int)
GO

-- =============== ExecIsAnsiNullsOn ===============
-- Setup
SET ANSI_NULLS OFF
GO

CREATE PROC objectproperty_vu_prepare_ansi_nulls_off_proc
AS
SELECT CASE WHEN NULL = NULL then 1 else 0 end
GO

SET ANSI_NULLS ON
GO

CREATE PROC objectproperty_vu_prepare_ansi_nulls_on_proc
AS
SELECT CASE WHEN NULL = NULL then 1 else 0 end
GO

CREATE TABLE objectproperty_vu_prepare_ansi_nulls_on_table(a int)
GO

-- =============== IsDeterministic ===============
-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsDeterministic_function_yes()
RETURNS int
WITH SCHEMABINDING
BEGIN
    return 1;
END
GO

CREATE FUNCTION objectproperty_vu_prepare_IsDeterministic_function_no()
RETURNS sys.datetime
WITH SCHEMABINDING
BEGIN
    return GETDATE();
END
GO

CREATE TABLE objectproperty_vu_prepare_IsDeterministic_table(a int)
GO

-- =============== IsProcedure ===============
-- Setup
CREATE PROC objectproperty_vu_prepare_IsProcedure_proc AS
SELECT 1
GO

CREATE TABLE objectproperty_vu_prepare_IsProcedure_table(a int)
GO

-- =============== IsTable ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsTable_table(a int)
GO

CREATE PROC objectproperty_vu_prepare_IsTable_proc AS
SELECT 1
GO

-- =============== IsView ===============
-- Setup
CREATE VIEW objectproperty_vu_prepare_IsView_view AS
SELECT 1
GO

CREATE TABLE objectproperty_vu_prepare_IsView_table(a int)
GO

-- =============== IsUserTable ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsUserTable_table(a int)
GO

CREATE VIEW objectproperty_vu_prepare_IsUserTable_view AS
SELECT 1
GO

-- =============== IsTableFunction ===============
-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsTableFunction_tablefunction()
RETURNS @t TABLE (
    c1 int,
    c2 int
)
AS
BEGIN
    INSERT INTO @t
    SELECT 1 as c1, 2 as c2;
    RETURN;
END
GO

CREATE FUNCTION objectproperty_vu_prepare_IsTableFunction_inlinetablefunction()
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE FUNCTION objectproperty_vu_prepare_IsTableFunction_function()
RETURNS INT
AS
BEGIN
RETURN 1
END
GO

-- =============== IsInlineFunction ===============
-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsInlineFunction_tablefunction()
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE FUNCTION objectproperty_vu_prepare_IsInlineFunction_function()
RETURNS INT
AS
BEGIN
RETURN 1
END
GO

-- =============== IsScalarFunction ===============
-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsScalarFunction_function()
RETURNS INT
AS
BEGIN
    RETURN 1
END
GO

CREATE TABLE objectproperty_vu_prepare_IsScalarFunction_table(a int)
GO

-- =============== IsPrimaryKey ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsPrimaryKey_table(a int, CONSTRAINT objectproperty_vu_prepare_pk PRIMARY KEY(a))
GO

-- =============== IsIndexed ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsIndexed_table(a int, CONSTRAINT PK_isprimarykey PRIMARY KEY(a))
GO

CREATE TABLE objectproperty_vu_prepare_IsIndexed_nonindexed_table(a int)
GO

-- =============== IsDefault ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsDefault_table(a int)
GO

-- =============== IsRule ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsRule_table(a int)
GO

-- =============== IsTrigger ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsTrigger_table(a int)
GO

CREATE TRIGGER objectproperty_vu_prepare_IsTrigger_trigger ON objectproperty_vu_prepare_IsTrigger_table INSTEAD OF INSERT
AS
BEGIN
    SELECT * FROM objectproperty_vu_prepare_IsTrigger_table
END
GO
