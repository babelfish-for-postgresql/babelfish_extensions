DROP FUNCTION IF EXISTS babel_sp_sproc_columns_vu_prepare_net
GO
CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_net(
    @quantity INT,
    @list_price DEC(10,2),
    @discount DEC(4,2)
)
RETURNS DEC(10,2)
AS 
BEGIN
    RETURN @quantity * @list_price * (1 - @discount);
END
GO

DROP DATABASE IF EXISTS babel_sp_sproc_columns_vu_prepare_db1
GO
CREATE DATABASE babel_sp_sproc_columns_vu_prepare_db1
GO
USE babel_sp_sproc_columns_vu_prepare_db1
GO

DROP TABLE IF EXISTS babel_sp_sproc_columns_vu_prepare_t1
GO
CREATE TABLE babel_sp_sproc_columns_vu_prepare_t1(a INT)
GO

DROP PROCEDURE IF EXISTS babel_sp_sproc_columns_vu_prepare_select_all
GO
CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_select_all
AS
SELECT * FROM babel_sp_sproc_columns_vu_prepare_t1
GO

DROP PROCEDURE IF EXISTS babel_sp_sproc_columns_vu_prepare_select_all_with_parameter
GO
CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_select_all_with_parameter @id int
AS
BEGIN
SELECT * FROM babel_sp_sproc_columns_vu_prepare_t1 WHERE a = @id
END
GO

DROP PROCEDURE IF EXISTS babel_sp_sproc_columns_vu_prepare_mp_select_all
GO
CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_mp_select_all @id int, @MyVarChar varchar(256)
AS
BEGIN
SELECT * FROM babel_sp_sproc_columns_vu_prepare_t1 WHERE a = @id
END
GO

CREATE SCHEMA babel_sp_sproc_columns_vu_prepare_s1
GO

DROP FUNCTION IF EXISTS babel_sp_sproc_columns_vu_prepare_s1.positive_or_negative
GO

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_s1.positive_or_negative (
@long DECIMAL(9,6)
)
RETURNS CHAR(4) AS
BEGIN
DECLARE @return_value CHAR(10);
SET @return_value = 'zero';
    IF (@long > 0.00) SET @return_value = 'positive';
    IF (@long < 0.00) SET @return_value = 'negative';

    RETURN @return_value
END;
GO

DROP FUNCTION IF EXISTS babel_sp_sproc_columns_vu_prepare_net
GO
CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_net(
    @quantity INT,
    @list_price DEC(10,2),
    @discount DEC(4,2)
)
RETURNS DEC(10,2)
AS 
BEGIN
    RETURN @quantity * @list_price * (1 - @discount);
END
GO

DROP FUNCTION IF EXISTS babel_sp_sproc_columns_vu_prepare_no_param_name
GO
CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_no_param_name(
    @ INT
)
RETURNS INT
AS 
BEGIN
    RETURN @
END
GO

DROP FUNCTION IF EXISTS babel_sp_sproc_columns_vu_prepare_table_value_func
GO
CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_table_value_func (
    @num INT
)
RETURNS TABLE
AS 
RETURN
SELECT a as b FROM babel_sp_sproc_columns_vu_prepare_t1 WHERE a > @num
GO

CREATE TYPE babel_sp_sproc_columns_vu_prepare_eyedees FROM int not NULL
go
CREATE TYPE babel_sp_sproc_columns_vu_prepare_Phone_Num FROM varchar(11) NOT NULL
go

CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_eyedees_proc @id babel_sp_sproc_columns_vu_prepare_eyedees
AS
SELECT  1
GO

CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_Phone_Num_proc @num babel_sp_sproc_columns_vu_prepare_Phone_Num
AS
SELECT  1
GO

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_eyedees_func (
    @id babel_sp_sproc_columns_vu_prepare_eyedees
)
RETURNS babel_sp_sproc_columns_vu_prepare_eyedees AS
BEGIN
return @id
END
GO

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_PhoneNum_func (
    @Pn babel_sp_sproc_columns_vu_prepare_Phone_Num
)
RETURNS babel_sp_sproc_columns_vu_prepare_Phone_Num AS
BEGIN
return @Pn
END
GO

CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_addTwo @num1 int, @num2 int
AS
SELECT (@num1 + @num2)
GO

CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_complexProc
@dec decimal(23,3), 
@num numeric(22, 8), 
@var varchar(30), 
@nvar nvarchar(5),
@varmax varchar(max),
@nvarmax nvarchar(max)
AS
SELECT 1
GO

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_scalFunc(@a int)
RETURNS INT
AS
BEGIN
RETURN @a;
END
GO

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_tableFunc(@c1 int, @c2 int)
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

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_InlineTableFunc(@t1 int, @t2 int)
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE TYPE babel_sp_sproc_columns_vu_prepare_myTableParam
    AS TABLE
        ( a int,
          b int)
GO

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_tableFunc2(@c1 babel_sp_sproc_columns_vu_prepare_myTableParam READONLY,
    @c2 babel_sp_sproc_columns_vu_prepare_myTableParam READONLY)
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

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_InlineTableFunc2(@t1 babel_sp_sproc_columns_vu_prepare_myTableParam READONLY, 
    @t2 babel_sp_sproc_columns_vu_prepare_myTableParam READONLY)
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_tvpProc @tvp babel_sp_sproc_columns_vu_prepare_myTableParam READONLY
AS
SELECT * FROM @tvp
GO

CREATE TYPE babel_sp_sproc_columns_vu_prepare_myDec FROM DECIMAL(23, 5);
GO

CREATE FUNCTION babel_sp_sproc_columns_vu_prepare_myDecFunc (@a babel_sp_sproc_columns_vu_prepare_myDec)
RETURNS babel_sp_sproc_columns_vu_prepare_myDec
AS
BEGIN
    RETURN @a;
END
GO

CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_typeModifier
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

CREATE PROCEDURE babel_sp_sproc_columns_vu_prepare_DataTypeExamples
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
