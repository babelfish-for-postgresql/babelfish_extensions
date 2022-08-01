-- Add all the datatypes to tables
CREATE TABLE test_default_columns_vu_prepare_t1(c_int INT DEFAULT 10, c_bigint BIGINT DEFAULT 9223372036854775807,c_tinyint TINYINT DEFAULT 002,c_binary BINARY(8) DEFAULT 0x0102030405060708,c_varbinary VARBINARY(10) DEFAULT 0x010203)
GO

CREATE TABLE test_default_columns_vu_prepare_t2(c_bit BIT DEFAULT 1,c_smallint SMALLINT DEFAULT -10 ,c_money MONEY DEFAULT '$22337203685477.5807' ,c_numeric NUMERIC(38,25) DEFAULT 2147483648.123,c_decimal DECIMAL(5,2) DEFAULT 6.9)
GO

CREATE TABLE test_default_columns_vu_prepare_t3(c_float FLOAT DEFAULT -0122455324.5,c_real REAL DEFAULT 3.40E+38,c_char CHAR(24) DEFAULT 'Nirmit' ,c_nchar NCHAR(24) DEFAULT 'Shah' ,c_varchar VARCHAR(20) DEFAULT 'Nirmit',c_nvarchar NVARCHAR(24) DEFAULT '😊😋😎😍😅😆',c_text TEXT DEFAULT 'Nirmit',c_ntext NTEXT DEFAULT 'Shah')
GO

CREATE TABLE test_default_columns_vu_prepare_t4(c_date DATE DEFAULT '2000-12-13',c_datetime DATETIME DEFAULT '2000-12-13 12:58:23.123',c_datetime2 DATETIME2 DEFAULT '2018-06-23 07:30:20',c_time TIME DEFAULT '12:45:37.123',c_datetimeoffset DATETIMEOFFSET DEFAULT '2020-03-15 09:00:00 +8:00', c_smalldatetime SMALLDATETIME DEFAULT '2000-12-13 12:58:23')
GO

CREATE TABLE test_default_columns_vu_prepare_t5(c_xml XML DEFAULT '<contact><name>Contact Name 2</name><phone>YYY-YYY-YYYY</phone></contact>',c_uuid UNIQUEIDENTIFIER DEFAULT '51f178a6-53c7-472c-9be1-1c08942342d7',c_sqlvar SQL_VARIANT DEFAULT CAST('Delhi' as char(24)))
GO

CREATE PROCEDURE test_default_columns_vu_prepare_p1 
AS
    INSERT INTO test_default_columns_vu_prepare_t1 DEFAULT VALUES
GO

CREATE PROCEDURE test_default_columns_vu_prepare_p2 
AS
    INSERT INTO test_default_columns_vu_prepare_t2 DEFAULT VALUES
GO

CREATE PROCEDURE test_default_columns_vu_prepare_p3 
AS
    INSERT INTO test_default_columns_vu_prepare_t3 DEFAULT VALUES
GO

CREATE PROCEDURE test_default_columns_vu_prepare_p4 
AS
    INSERT INTO test_default_columns_vu_prepare_t4 DEFAULT VALUES
GO

CREATE PROCEDURE test_default_columns_vu_prepare_p5 
AS
    INSERT INTO test_default_columns_vu_prepare_t5 DEFAULT VALUES
GO

CREATE FUNCTION test_default_columns_vu_prepare_func_1(@number INT)
RETURNS TABLE
AS
RETURN(
    SELECT * FROM test_default_columns_vu_prepare_t1
)
Go

CREATE FUNCTION test_default_columns_vu_prepare_func_2(@number INT)
RETURNS TABLE
AS
RETURN(
    SELECT * FROM test_default_columns_vu_prepare_t2
)
Go

CREATE FUNCTION test_default_columns_vu_prepare_func_3(@number INT)
RETURNS TABLE
AS
RETURN(
    SELECT * FROM test_default_columns_vu_prepare_t3
)
Go
CREATE FUNCTION test_default_columns_vu_prepare_func_4(@number INT)
RETURNS TABLE
AS
RETURN(
    SELECT * FROM test_default_columns_vu_prepare_t4
)
Go

CREATE FUNCTION test_default_columns_vu_prepare_func_5(@number INT)
RETURNS TABLE
AS
RETURN(
    SELECT * FROM test_default_columns_vu_prepare_t5
)
Go
