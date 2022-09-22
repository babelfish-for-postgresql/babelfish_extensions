CREATE PROCEDURE sys_all_parameters_vu_prepare_addTwo @num1 int, @num2 int
AS
SELECT (@num1 + @num2)
GO

CREATE PROCEDURE sys_all_parameters_vu_prepare_complexProc
@dec decimal(23,3), 
@num numeric(22, 8), 
@var varchar(30), 
@nvar nvarchar(5),
@varmax varchar(max),
@nvarmax nvarchar(max)
AS
SELECT 1
GO

CREATE SCHEMA sys_all_parameters_schema_vu_prepare
GO

CREATE PROCEDURE sys_all_parameters_schema_vu_prepare.sys_all_parameters_vu_prepare_complexProc
@dec_schema decimal(23,3), 
@num_schema numeric(22, 8), 
@var_schema varchar(30), 
@nvar_schema nvarchar(5),
@varmax_schema varchar(max),
@nvarmax_schema nvarchar(max)
AS
SELECT 1
GO

CREATE FUNCTION sys_all_parameters_vu_prepare_scalFunc(@a int)
RETURNS INT
AS
BEGIN
RETURN @a;
END
GO

CREATE FUNCTION sys_all_parameters_vu_prepare_tableFunc(@c1 int, @c2 int)
RETURNS @t TABLE (
    c1 int,
    c2 int
)
AS
BEGIN
    INSERT INTO @t
    SELECT @c1 as c1, @c2 as c2;
    RETURN;
END
GO

CREATE FUNCTION sys_all_parameters_vu_prepare_InlineTableFunc(@t1 int, @t2 int)
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE TYPE sys_all_parameters_vu_prepare_myTableParam
    AS TABLE
        ( a int,
          b int)
GO

CREATE FUNCTION sys_all_parameters_vu_prepare_tableFunc2(@c1 sys_all_parameters_vu_prepare_myTableParam READONLY,
    @c2 sys_all_parameters_vu_prepare_myTableParam READONLY)
RETURNS @t TABLE (
    c1 int,
    c2 int
)
AS
BEGIN
    INSERT INTO @t
    SELECT @c1 as c1, @c2 as c2;
    RETURN;
END
GO

CREATE FUNCTION sys_all_parameters_vu_prepare_InlineTableFunc2(@t1 sys_all_parameters_vu_prepare_myTableParam READONLY, 
    @t2 sys_all_parameters_vu_prepare_myTableParam READONLY)
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE PROCEDURE sys_all_parameters_vu_prepare_tvpProc @tvp sys_all_parameters_vu_prepare_myTableParam READONLY
AS
SELECT * FROM @tvp
GO

CREATE TYPE sys_all_parameters_vu_prepare_myDec FROM DECIMAL(23, 5);
GO

CREATE FUNCTION sys_all_parameters_vu_prepare_myDecFunc (@a sys_all_parameters_vu_prepare_myDec)
RETURNS sys_all_parameters_vu_prepare_myDec
AS
BEGIN
    RETURN @a;
END
GO

CREATE PROCEDURE sys_all_parameters_vu_prepare_typeModifier
@var4000 varchar(8000),
@varmax varchar(max),
@nvar4000 nvarchar(4000),
@nvarmax nvarchar(max),
@char char(8000),
@nchar nchar(4000),
@binary BINARY(8000),
@varbinary varbinary(8000),
@varbinaryMax varbinary(max),
@sysname sysname
AS
SELECT 1
GO

CREATE PROCEDURE sys_all_parameters_vu_prepare_DataTypeExamples
@dt_bigint BIGINT = 4242
, @dt_binary_9 BINARY(9) = 0x42
, @dt_bit BIT = 1
, @dt_char_42 CHAR(42) = 'SELECT * FROM hg2g'
, @dt_date DATE OUT
, @dt_datetime DATETIME
, @dt_datetime2_5 DATETIME2(5)
, @dt_datetimeoffset_3 DATETIMEOFFSET(3)
, @dt_decimal10_3 DECIMAL(10,3)
, @dt_float FLOAT
, @dt_image IMAGE
, @dt_int INT
, @dt_money MONEY
, @dt_nchar_10 NCHAR(10)
, @dt_ntext NTEXT
, @dt_time_4 TIME(4)
, @dt_tinyint TINYINT
, @dt_uniqueidentifier UNIQUEIDENTIFIER
, @dt_varbinary_max VARBINARY(max)
, @dt_varchar_128 VARCHAR(128)
, @dt_smalldatetime SMALLDATETIME
, @dt_smallint SMALLINT
, @dt_smallmoney SMALLMONEY
, @dt_sql_variant SQL_VARIANT
, @dt_xml XML
AS
BEGIN
SELECT 'OK'
RETURN 0
END;
GO
