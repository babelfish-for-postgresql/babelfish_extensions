-- sla_for_parallel_query_enforced 150000
-- create tables with most of the datatypes
create table var(a char(10), b nchar(9), c nvarchar(8), d varchar(7), e text, f ntext, g varbinary(10), h binary(9), i image, j xml)
go

create table dates(a date, b time(5), c datetime, d datetime2(5), e smalldatetime, f sql_variant)
go

create table nums(a int, b smallint, c tinyint, d bigint, e bit, f float, g real, h numeric(5,3), i money, j smallmoney)
go

create table maxx(a varchar(max), b nvarchar(max), c varbinary(max))
go

-- testing sp_columns_100
EXEC [sys].sp_columns_100 'var', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

EXEC [sys].sp_columns_100 'dates', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

EXEC [sys].sp_columns_100 'nums', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

-- Testing with rowversion/timestamp column
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

create table tbl_rv(id int, rv rowversion);
go

create table tbl_tm(id int, tm timestamp);
go

EXEC [sys].sp_columns_100 'tbl_rv', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

EXEC [sys].sp_columns_100 'tbl_tm', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

drop table tbl_rv;
drop table tbl_tm;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

EXEC [sys].sp_columns_100 'maxx', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

-- Testing with UDTS
create type char_t from char(10)
go

create type nchar_t from char(9)
go

create type varchar_t from nvarchar(8)
go

create type nvarchar_t from nvarchar(8)
go

create type text_t from text
go

create type ntext_t from ntext
go

create type varbinary_t from varbinary(10)
go

create type binary_t from binary(8)
go

create type image_t from image
go

create table vart (a char_t, b nchar_t, c nvarchar_t, d varchar_t, e text_t, f ntext_t, g varbinary_t, h binary_t, i image_t)
go

EXEC [sys].sp_columns_100 'vart', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

-- Testing cross db references
Create database sp_cols
go

Use sp_cols
go

EXEC [sys].sp_columns_100 'vart', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

create table nums(a int, b smallint, c tinyint, d bigint, e bit, f float, g real, h numeric(5,3), i money, j smallmoney)
go

create table test_escape_chars_sp_columns_100(a int);
go

CREATE SCHEMA source_test;
CREATE TABLE source_test.testtable (id int primary key);
CREATE TABLE source_test.test_table (id int primary key);
CREATE TABLE source_test.test0table (id int primary key);
GO

EXEC [sys].sp_columns_100 'vart', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

-- TODO: Should NOT return any row once the dependencies on sp_columns_100 has been fixed (added '\' as ESCAPE character as temporary fix for now)
EXEC sys.sp_columns_100 'test\_escape_chars\_sp_columns_100', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
GO

EXEC sys.sp_columns_100 'test\_escape\_chars\_sp\_columns\_100', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
GO

EXEC sys.sp_columns_100 'test_escape_chars_sp_columns_100', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
GO

EXEC sys.sp_columns_100 'test\_escape\_chars\_sp\_columns\_100', 'dbo', NULL, NULL
GO

EXEC sys.sp_columns_100 'test_escape_chars_sp_columns_100', 'dbo', NULL, NULL
GO

EXEC sys.sp_columns_100 'test\_escape_chars\_sp_columns_100', 'dbo', NULL, NULL
GO

EXEC sys.sp_columns_100 @table_name='test_table', @table_owner='source_test';
GO

EXEC sys.sp_columns_100 @table_name='test\_table', @table_owner='source_test';
GO

EXEC sys.sp_columns_100 @table_name='test\_table', @table_owner='source\_test';
GO

drop table nums
go

drop table test_escape_chars_sp_columns_100;
go

drop table source_test.testtable;
go
drop table source_test.test_table;
go
drop table source_test.test0table;
go
drop schema source_test;
go

Use master
go

CREATE TABLE dbo.tidentityintbigwithareallylongtablenamewhickcausesbabelfishtoaddahashcodetothenamebecauseofdefault63 (
	data_type_test CHAR(50) NULL
	, test_scenario CHAR(60) NULL
	, value_test BIGINT IDENTITY (202202081842, 100 ) NOT NULL
	, inserted_dt DATETIME DEFAULT GETDATE()
	, user_login CHAR(255) DEFAULT CURRENT_USER
)
GO

EXEC [sys].sp_columns_100 'tidentityintbigwithareallylongtablenamewhickcausesbabelfishtoaddahashcodetothenamebecauseofdefault63', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
GO

-- test with identity columns
create table tiny_int_identity ( i_col tinyint identity(1,1), tinyint_col tinyint );
go
create table small_int_identity ( i_col smallint identity(1,1), smallint_col smallint );
go
create table int_identity ( i_col int identity(1,1), int_col int );
go
create table big_int_identity ( i_col bigint identity(1,1), bigint_col bigint );
go
create table decimal_int_identity ( i_col decimal(5,0) identity(1,1), dec5int_col decimal(5,0) );
go
create table numeric_int_identity ( i_col numeric(5,0) identity(1,1), num5int_col numeric(5,0) );
go
create table numeric13_int_identity ( i_col numeric(13,0) identity(1,1), num13int_col numeric(13,0) );
go

exec [sys].sp_columns_100 N'tiny_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go
exec [sys].sp_columns N'tiny_int_identity',N'dbo',NULL,NULL,@ODBCVer=3;
go

exec [sys].sp_columns_100 N'small_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go
exec [sys].sp_columns N'small_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go

exec [sys].sp_columns_100 N'int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go
exec [sys].sp_columns N'int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go

exec [sys].sp_columns_100 N'big_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go
exec [sys].sp_columns N'big_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go

exec [sys].sp_columns_100 N'decimal_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go
exec [sys].sp_columns N'decimal_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go

exec [sys].sp_columns_100 N'numeric_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go
exec [sys].sp_columns N'numeric_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go

exec [sys].sp_columns_100 N'numeric13_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go
exec [sys].sp_columns N'numeric13_int_identity',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go

-- Cleanup
drop table var;
drop table dates;
drop table nums;
drop table vart;
drop table maxx;
drop table tidentityintbigwithareallylongtablenamewhickcausesbabelfishtoaddahashcodetothenamebecauseofdefault63;
drop table tiny_int_identity;
drop table small_int_identity;
drop table int_identity;
drop table big_int_identity;
drop table decimal_int_identity;
drop table numeric_int_identity;
drop table numeric13_int_identity;
drop type char_t;
drop type nchar_t;
drop type varchar_t;
drop type nvarchar_t;
drop type text_t;
drop type ntext_t;
drop type varbinary_t;
drop type binary_t;
drop type image_t;
drop database sp_cols;
go

--Collation using BBF_Unicode_CP1_CI_AI
Create database sp_cols collate BBF_Unicode_CP1_CI_AI
go

Use sp_cols
go

EXEC [sys].sp_columns_100 'vart', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

create table nums(a int, b smallint, c tinyint, d bigint, e bit, f float, g real, h numeric(5,3), i money, j smallmoney)
go

create table test_escape_chars_sp_columns_100(a int);
go

CREATE SCHEMA source_test;
CREATE TABLE source_test.testtable (id int primary key);
CREATE TABLE source_test.test_table (id int primary key);
CREATE TABLE source_test.test0table (id int primary key);
GO

EXEC [sys].sp_columns_100 'vart', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
go

-- TODO: Should NOT return any row once the dependencies on sp_columns_100 has been fixed (added '\' as ESCAPE character as temporary fix for now)
EXEC sys.sp_columns_100 'test\_escape_chars\_sp_columns_100', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
GO

EXEC sys.sp_columns_100 'test\_escape\_chars\_sp\_columns\_100', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
GO

EXEC sys.sp_columns_100 'test_escape_chars_sp_columns_100', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1
GO

EXEC sys.sp_columns_100 'test\_escape\_chars\_sp\_columns\_100', 'dbo', NULL, NULL
GO

EXEC sys.sp_columns_100 'test_escape_chars_sp_columns_100', 'dbo', NULL, NULL
GO

EXEC sys.sp_columns_100 'test\_escape_chars\_sp_columns_100', 'dbo', NULL, NULL
GO

EXEC sys.sp_columns_100 @table_name='test_table', @table_owner='source_test';
GO

EXEC sys.sp_columns_100 @table_name='test\_table', @table_owner='source_test';
GO

EXEC sys.sp_columns_100 @table_name='test\_table', @table_owner='source\_test';
GO

drop table nums
go

drop table source_test.testtable;
go
drop table source_test.test_table;
go
drop table source_test.test0table;
go
drop schema source_test;
go

drop table test_escape_chars_sp_columns_100;
go

use master
go

drop database sp_cols
go

