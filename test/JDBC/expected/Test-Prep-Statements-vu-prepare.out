--int
CREATE TABLE test_prep_statements_vu_prepare_t1 (a int, b int); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p1
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t1 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t1 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 int, @v2 int, @v3 int, @v4 int'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 1,2,3,4
EXEC SP_EXECUTE @handle, 3,4,5,6
SELECT * FROM test_prep_statements_vu_prepare_t1 
GO

--bigint
CREATE TABLE test_prep_statements_vu_prepare_t2 (a bigint, b bigint); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p2
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t2 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t2 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 bigint, @v2 bigint, @v3 bigint, @v4 bigint'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 9223372036,9223372036,9223372036,9223372036
EXEC SP_EXECUTE @handle, 9223372036,9223372036,9223372036,9223372036
SELECT * FROM test_prep_statements_vu_prepare_t2 
GO

--tinyint
CREATE TABLE test_prep_statements_vu_prepare_t3 (a tinyint, b tinyint); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p3
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t3 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t3 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 tinyint, @v2 tinyint, @v3 tinyint, @v4 tinyint'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 21,22,23,24
EXEC SP_EXECUTE @handle, 25,26,27,28
SELECT * FROM test_prep_statements_vu_prepare_t3 
GO

--binary
CREATE TABLE test_prep_statements_vu_prepare_t4 (a BINARY(8), b BINARY(8)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p4
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t4 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t4 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 BINARY(8), @v2 BINARY(8), @v3 BINARY(8), @v4 BINARY(8)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 0x0102030405060708,0x0102030405060708,0x0102030405060708,0x0102030405060708
EXEC SP_EXECUTE @handle, 0x0102030405060708,0x0102030405060708,0x0102030405060708,0x0102030405060708
SELECT * FROM test_prep_statements_vu_prepare_t4 
GO

--varbinary
CREATE TABLE test_prep_statements_vu_prepare_t5 (a VARBINARY(10), b VARBINARY(10)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p5
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t5 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t5 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 VARBINARY(10), @v2 VARBINARY(10), @v3 VARBINARY(10), @v4 VARBINARY(10)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 0x010203,0x010203,0x010203,0x010203
EXEC SP_EXECUTE @handle, 0x010203,0x010203,0x010203,0x010203
SELECT * FROM test_prep_statements_vu_prepare_t5 
GO


--bit
CREATE TABLE test_prep_statements_vu_prepare_t6 (a BIT, b BIT); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p6
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t6 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t6 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 BIT, @v2 BIT, @v3 BIT, @v4 BIT'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 1,0,1,0
EXEC SP_EXECUTE @handle, 1,0,1,0
SELECT * FROM test_prep_statements_vu_prepare_t6 
GO

--smallint
CREATE TABLE test_prep_statements_vu_prepare_t7 (a SMALLINT, b SMALLINT); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p7
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t7 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t7 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 SMALLINT, @v2 SMALLINT, @v3 SMALLINT, @v4 SMALLINT'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 12,-10,19,20
EXEC SP_EXECUTE @handle, 12,-10,19,20
SELECT * FROM test_prep_statements_vu_prepare_t7 
GO

--money
CREATE TABLE test_prep_statements_vu_prepare_t8 (a MONEY, b MONEY); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p8
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t8 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t8 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 MONEY, @v2 MONEY, @v3 MONEY, @v4 MONEY'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '$22337203685477.5807','$22337203685477.5807','$22337203685477.5807','$22337203685477.5807'
EXEC SP_EXECUTE @handle, '$22337203685477.5807','$22337203685477.5807','$22337203685477.5807','$22337203685477.5807'
SELECT * FROM test_prep_statements_vu_prepare_t8 ;
GO

--numeric
CREATE TABLE test_prep_statements_vu_prepare_t9 (a NUMERIC(38,25), b NUMERIC(38,25)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p9
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t9 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t9 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 NUMERIC(38,25), @v2 NUMERIC(38,25), @v3 NUMERIC(38,25), @v4 NUMERIC(38,25)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 2147483648.123,2147483648.123,2147483648.123,2147483648.123
EXEC SP_EXECUTE @handle, 2147483648.123,2147483648.123,2147483648.123,2147483648.123
SELECT * FROM test_prep_statements_vu_prepare_t9 ;
GO

--decimal
CREATE TABLE test_prep_statements_vu_prepare_t10 (a DECIMAL(5,2), b DECIMAL(5,2)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p10
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t10 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t10 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 DECIMAL(5,2), @v2 DECIMAL(5,2), @v3 DECIMAL(5,2), @v4 DECIMAL(5,2)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 6.9,4.2,6.9,4.2
EXEC SP_EXECUTE @handle, 6.9,4.2,6.9,4.2
SELECT * FROM test_prep_statements_vu_prepare_t10 ;
GO

--float
CREATE TABLE test_prep_statements_vu_prepare_t11 (a FLOAT, b FLOAT); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p11
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t11 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t11 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 FLOAT, @v2 FLOAT, @v3 FLOAT, @v4 FLOAT'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, -0122455324.5,-0122455324.5,-0122455324.5,-0122455324.5
EXEC SP_EXECUTE @handle, -0122455324.5,-0122455324.5,-0122455324.5,-0122455324.5
SELECT * FROM test_prep_statements_vu_prepare_t11 ;
GO

--real
CREATE TABLE test_prep_statements_vu_prepare_t12 (a REAL, b REAL); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p12
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t12 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t12 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 REAL, @v2 REAL, @v3 REAL, @v4 REAL'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 3.40E+38,3.40E+38,3.40E+38,3.40E+38
EXEC SP_EXECUTE @handle, 3.40E+38,3.40E+38,3.40E+38,3.40E+38
SELECT * FROM test_prep_statements_vu_prepare_t12 ;
GO

--char
CREATE TABLE test_prep_statements_vu_prepare_t13 (a CHAR(24), b CHAR(24)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p13
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t13 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t13 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 CHAR(24), @v2 CHAR(24), @v3 CHAR(24), @v4 CHAR(24)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
SELECT * FROM test_prep_statements_vu_prepare_t13 ;
GO

--nchar
CREATE TABLE test_prep_statements_vu_prepare_t14 (a NCHAR(24), b NCHAR(24)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p14
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t14 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t14 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 NCHAR(24), @v2 NCHAR(24), @v3 NCHAR(24), @v4 NCHAR(24)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
SELECT * FROM test_prep_statements_vu_prepare_t14 ;
GO

--varchar
CREATE TABLE test_prep_statements_vu_prepare_t15 (a varchar(10), b varchar(10)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p15
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t15 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t15 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 varchar(10), @v2 varchar(10), @v3 varchar(10), @v4 varchar(10)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
SELECT * FROM test_prep_statements_vu_prepare_t15 ;
GO

--nvarchar
CREATE TABLE test_prep_statements_vu_prepare_t16 (a nvarchar(40), b nvarchar(40)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p16
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t16 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t16 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 nvarchar(40), @v2 nvarchar(40), @v3 nvarchar(40), @v4 nvarchar(40)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '😊😋😎😍😅😆','Babel','Fish','PostgreSQL'
EXEC SP_EXECUTE @handle, '😊😋😎😍😅😆','Babel','Fish','PostgreSQL'
SELECT * FROM test_prep_statements_vu_prepare_t16 ;
GO

--text
CREATE TABLE test_prep_statements_vu_prepare_t17 (a TEXT, b TEXT); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p17
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t17 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t17 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 TEXT, @v2 TEXT, @v3 TEXT, @v4 TEXT'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
SELECT * FROM test_prep_statements_vu_prepare_t17 ;
GO

--ntext
CREATE TABLE test_prep_statements_vu_prepare_t18 (a NTEXT, b NTEXT); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p18
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t18 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t18 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 NTEXT, @v2 NTEXT, @v3 NTEXT, @v4 NTEXT'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
EXEC SP_EXECUTE @handle, 'Babel','Fish','Postgres','SQL'
SELECT * FROM test_prep_statements_vu_prepare_t18 ;
GO

--date
CREATE TABLE test_prep_statements_vu_prepare_t19 (a DATE, b DATE); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p19
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t19 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t19 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 DATE, @v2 DATE, @v3 DATE, @v4 DATE'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '2000-12-13','2000-12-13','2000-12-13','2000-12-13'
EXEC SP_EXECUTE @handle, '2000-12-13','2000-12-13','2000-12-13','2000-12-13'
SELECT * FROM test_prep_statements_vu_prepare_t19 ;
GO

--datetime
CREATE TABLE test_prep_statements_vu_prepare_t20 (a DATETIME, b DATETIME); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p20
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t20 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t20 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 DATETIME, @v2 DATETIME, @v3 DATETIME, @v4 DATETIME'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '2000-12-13 12:58:23.123','2000-12-13 12:58:23.123','2000-12-13 12:58:23.123','2000-12-13 12:58:23.123'
EXEC SP_EXECUTE @handle, '2000-12-13 12:58:23.123','2000-12-13 12:58:23.123','2000-12-13 12:58:23.123','2000-12-13 12:58:23.123'
SELECT * FROM test_prep_statements_vu_prepare_t20 ;
GO

--datetime2
CREATE TABLE test_prep_statements_vu_prepare_t21 (a DATETIME2(6), b DATETIME2(6)); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p21
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t21 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t21 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 DATETIME2(6), @v2 DATETIME2(6), @v3 DATETIME2(6), @v4 DATETIME2(6)'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '2018-06-23 07:30:20','2018-06-23 07:30:20','2018-06-23 07:30:20','2018-06-23 07:30:20'
EXEC SP_EXECUTE @handle, '2018-06-23 07:30:20','2018-06-23 07:30:20','2018-06-23 07:30:20','2018-06-23 07:30:20'
SELECT * FROM test_prep_statements_vu_prepare_t21 ;
GO

--time
CREATE TABLE test_prep_statements_vu_prepare_t22 (a TIME, b TIME); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p22
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t22 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t22 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 TIME, @v2 TIME, @v3 TIME, @v4 TIME'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '12:45:37.123','12:45:37.123','12:45:37.123','12:45:37.123'
EXEC SP_EXECUTE @handle, '12:45:37.123','12:45:37.123','12:45:37.123','12:45:37.123'
SELECT * FROM test_prep_statements_vu_prepare_t22 ;
GO

--datetimeoffset
CREATE TABLE test_prep_statements_vu_prepare_t23 (a DATETIMEOFFSET, b DATETIMEOFFSET); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p23
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t23 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t23 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 DATETIMEOFFSET, @v2 DATETIMEOFFSET, @v3 DATETIMEOFFSET, @v4 DATETIMEOFFSET'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '2020-03-15 09:00:00 +8:00','2020-03-15 09:00:00 +8:00','2020-03-15 09:00:00 +8:00','2020-03-15 09:00:00 +8:00'
EXEC SP_EXECUTE @handle, '2020-03-15 09:00:00 +8:00','2020-03-15 09:00:00 +8:00','2020-03-15 09:00:00 +8:00','2020-03-15 09:00:00 +8:00'
SELECT * FROM test_prep_statements_vu_prepare_t23 ;
GO

--smalldatetime
CREATE TABLE test_prep_statements_vu_prepare_t24 (a SMALLDATETIME, b SMALLDATETIME); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p24
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t24 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t24 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 SMALLDATETIME, @v2 SMALLDATETIME, @v3 SMALLDATETIME, @v4 SMALLDATETIME'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '2000-12-13 12:58:23','2000-12-13 12:58:23','2000-12-13 12:58:23','2000-12-13 12:58:23'
EXEC SP_EXECUTE @handle, '2000-12-13 12:58:23','2000-12-13 12:58:23','2000-12-13 12:58:23','2000-12-13 12:58:23'
SELECT * FROM test_prep_statements_vu_prepare_t24 ;
GO

--xml
CREATE TABLE test_prep_statements_vu_prepare_t25 (a XML, b XML); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p25
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t25 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t25 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 XML, @v2 XML, @v3 XML, @v4 XML'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '<contact><name>Contact Name 2</name></contact>','<contact><name>Contact Name 3</name></contact>','<contact><name>Contact Name 4</name></contact>','<contact><name>Contact Name 5</name></contact>'
EXEC SP_EXECUTE @handle, '<contact><name>Contact Name 6</name></contact>','<contact><name>Contact Name 7</name></contact>','<contact><name>Contact Name 8</name></contact>','<contact><name>Contact Name 9</name></contact>'
SELECT * FROM test_prep_statements_vu_prepare_t25 ;
GO

--uniqidentifier
CREATE TABLE test_prep_statements_vu_prepare_t26 (a UNIQUEIDENTIFIER, b UNIQUEIDENTIFIER); 
GO

CREATE PROCEDURE test_prep_statements_vu_prepare_p26
AS
DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @batch = '
INSERT INTO test_prep_statements_vu_prepare_t26 VALUES (@v1, @v2)
INSERT INTO test_prep_statements_vu_prepare_t26 VALUES (@v3, @v4)
'
SET @paramdef = '@v1 UNIQUEIDENTIFIER, @v2 UNIQUEIDENTIFIER, @v3 UNIQUEIDENTIFIER, @v4 UNIQUEIDENTIFIER'
EXEC SP_PREPARE @handle OUT, @paramdef, @batch
EXEC SP_EXECUTE @handle, '51f178a6-53c7-472c-9be1-1c08942342d7','51f178a6-53c7-472c-9be1-1c08942342d7','51f178a6-53c7-472c-9be1-1c08942342d7','51f178a6-53c7-472c-9be1-1c08942342d7'
EXEC SP_EXECUTE @handle, '51f178a6-53c7-472c-9be1-1c08942342d7','51f178a6-53c7-472c-9be1-1c08942342d7','51f178a6-53c7-472c-9be1-1c08942342d7','51f178a6-53c7-472c-9be1-1c08942342d7'
SELECT * FROM test_prep_statements_vu_prepare_t26 ;
GO
