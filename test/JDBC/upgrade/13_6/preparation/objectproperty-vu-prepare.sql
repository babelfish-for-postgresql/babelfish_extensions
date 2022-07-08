-- Global setup for tests
CREATE DATABASE db1
GO
USE db1
GO

-- =============== OwnerId ===============

-- Setup
CREATE SCHEMA ownerid_schema
GO

CREATE TABLE ownerid_schema.ownerid_table(a int) 
GO

-- =============== IsDefaultCnst ===============

-- Setup
CREATE TABLE isdefaultcnst_table(a int DEFAULT 10)
GO

CREATE TABLE isdefaultcnst_table2(a int DEFAULT 10, b int DEFAULT 20)
GO

-- =============== ExecIsQuotedIdentOn ===============

-- Does not function properly due to sys.sql_modules not recording the correct settings

-- Setup
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC execisquotedident_proc_off
AS
RETURN 1
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC execisquotedident_proc_on
AS
RETURN 1
GO

CREATE TABLE execisquotedident_table(a int)
GO

-- =============== IsMSShipped ===============

-- Setup
CREATE TABLE is_ms_shipped_table(a int)
GO

-- =============== TableFullTextPopulateStatus ===============

-- Setup
CREATE TABLE tablefulltextpopulatestatus_table(a int)
GO

CREATE PROC tablefulltextpopulatestatus_proc
AS
RETURN 1
GO


-- =============== TableHasVarDecimalStorageFormat ===============

-- Setup
CREATE TABLE TableHasVarDecimalStorageFormat_table(a int)
GO

CREATE proc TableHasVarDecimalStorageFormat_proc
AS
RETURN 1
GO

-- =============== IsSchemaBound ===============

-- Currently does not work due to hardcoded value in sys.sql_modules
-- Setup
CREATE FUNCTION IsSchemaBound_function_false()
RETURNS int
BEGIN
    return 1
END
GO

CREATE FUNCTION IsSchemaBound_function_true()
RETURNS int
WITH SCHEMABINDING
BEGIN
    return 1
END
GO

CREATE TABLE IsSchemaBound_table(a int)
GO


-- =============== ExecIsAnsiNullsOn ===============

-- Currently does not work due to hardcoded value in sys.sql_modules
-- Setup
SET ANSI_NULLS OFF
GO

CREATE PROC ansi_nulls_off_proc
AS
SELECT CASE WHEN NULL = NULL then 1 else 0 end
GO

SET ANSI_NULLS ON
GO

CREATE PROC ansi_nulls_on_proc
AS
SELECT CASE WHEN NULL = NULL then 1 else 0 end
GO

CREATE TABLE ansi_nulls_on_table(a int)
GO

-- =============== IsDeterministic ===============

-- Currently does not work since INFORMATION_SCHEMA.ROUTINES does not evaluate if a function is deterministic
-- Setup
CREATE FUNCTION IsDeterministic_function_yes()
RETURNS int
WITH SCHEMABINDING
BEGIN
    return 1;
END
GO

CREATE FUNCTION IsDeterministic_function_no()
RETURNS sys.datetime
WITH SCHEMABINDING
BEGIN
    return GETDATE();
END
GO

CREATE TABLE IsDeterministic_table(a int)
GO

-- =============== IsProcedure ===============
-- Setup
CREATE PROC IsProcedure_proc AS
SELECT 1
GO

CREATE TABLE IsProcedure_table(a int)
GO

-- =============== IsTable ===============
-- Setup
CREATE TABLE IsTable_table(a int)
GO

CREATE PROC IsTable_proc AS
SELECT 1
GO

-- =============== IsView ===============
-- Setup
CREATE VIEW IsView_view AS
SELECT 1
GO

CREATE TABLE IsView_table(a int)
GO

-- =============== IsUserTable ===============
-- Setup
CREATE TABLE IsUserTable_table(a int)
GO

CREATE VIEW IsUserTable_view AS
SELECT 1
GO

-- =============== IsTableFunction ===============
-- NOTE: Currently will return 0 since sys.all_objects does not identify objects of type TF (BABELFISH-483)

-- Setup
CREATE FUNCTION IsTableFunction_tablefunction()
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

CREATE FUNCTION IsTableFunction_inlinetablefunction()
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE FUNCTION IsTableFunction_function()
RETURNS INT
AS
BEGIN
RETURN 1
END
GO

-- =============== IsInlineFunction ===============
-- NOTE: Currently will return 0 since BBF cannot currently identify if a function is inline or not

-- Setup
CREATE FUNCTION IsInlineFunction_tablefunction()
RETURNS INT
AS
BEGIN
    RETURN 1
END
GO

CREATE FUNCTION IsInlineFunction_function()
RETURNS INT
AS
BEGIN
RETURN 1
END
GO


-- =============== IsScalarFunction ===============

-- Setup
CREATE FUNCTION IsScalarFunction_function()
RETURNS INT
AS
BEGIN
    RETURN 1
END
GO

CREATE TABLE IsScalarFunction_table(a int)
GO

-- =============== IsPrimaryKey ===============
-- Setup
CREATE TABLE IsPrimaryKey_table(a int, CONSTRAINT pk_isprimarykey PRIMARY KEY(a))
GO

-- =============== IsIndexed ===============
-- Setup
CREATE TABLE IsIndexed_table(a int, CONSTRAINT PK_isprimarykey PRIMARY KEY(a))
GO

CREATE TABLE IsIndexed_nonindexed_table(a int)
GO

-- =============== IsDefault ===============
-- NOTE: Defaults are currently not supported so will return 0

-- Setup
CREATE TABLE IsDefault_table(a int)
GO

-- =============== IsRule ===============
-- NOTE: Rules are currently not supported so will return 0

-- Setup
CREATE TABLE IsRule_table(a int)
GO

-- =============== IsTrigger ===============

-- Setup
CREATE TABLE IsTrigger_table(a int)
GO

CREATE TRIGGER IsTrigger_trigger ON IsTrigger_table INSTEAD OF INSERT
AS
BEGIN
    SELECT * FROM IsTrigger_table
END
GO