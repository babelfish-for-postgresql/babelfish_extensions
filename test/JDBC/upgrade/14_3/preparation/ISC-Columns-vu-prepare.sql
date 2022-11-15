-- test all variable types
CREATE TABLE isc_columns_vu_prepare_var(a CHAR(10), b NCHAR(9), c NVARCHAR(8), d VARCHAR(7), e TEXT, f NTEXT, g VARBINARY(10), h BINARY(9), i IMAGE, j XML)
GO

-- test all date types
CREATE TABLE isc_columns_vu_prepare_dates(a DATE, b TIME(5), c DATETIME, d DATETIME2(5), e SMALLDATETIME, f SQL_VARIANT)
GO

--test all numeric types
CREATE TABLE isc_columns_vu_prepare_nums(a INT, b SMALLINT, c TINYINT, d BIGINT, e BIT, f FLOAT, g REAL, h NUMERIC(5,3), i MONEY, j SMALLMONEY)
GO

-- test with different db
CREATE DATABASE isc_columns_db1
GO

--User Defined Types
CREATE TYPE isc_columns_int FROM INT
CREATE TYPE isc_columns_varchar FROM VARCHAR(10)
GO

CREATE TABLE isc_columns_udt(a isc_columns_int, b isc_columns_varchar)
GO

--Dep Proc
CREATE PROCEDURE isc_columns_vu_prepare_p1 AS
SELECT COUNT(*) FROM information_schema.columns WHERE TABLE_NAME LIKE '%isc_columns_vu_prepare%'
SELECT * FROM information_schema.columns WHERE TABLE_NAME LIKE '%isc_columns_VU_PREPARE%' ORDER BY DATA_TYPE,COLUMN_NAME
GO

-- Dep Funcs
CREATE FUNCTION isc_columns_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM information_schema.columns WHERE TABLE_NAME LIKE '%isc_columns_vu_prepare%')
end
GO

CREATE FUNCTION isc_columns_vu_prepare_f2()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM information_schema.columns WHERE TABLE_NAME LIKE '%isc_columns_udt%')
end
GO

-- Dep View
CREATE VIEW isc_columns_vu_prepare_v1 AS
    SELECT * FROM information_schema.columns WHERE TABLE_NAME LIKE '%isc_columns_UDT%' ORDER BY DATA_TYPE,COLUMN_NAME
GO
