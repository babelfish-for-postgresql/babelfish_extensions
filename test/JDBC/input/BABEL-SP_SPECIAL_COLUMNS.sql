create database db1
go
use db1
go
CREATE TYPE eyedees FROM int not NULL
go
CREATE TYPE Phone_Num FROM varchar(11) NOT NULL 
go
create table t1(a int, primary key(a))
go
create table t2(a int, b int, c int, primary key(b, c))
go
create table t3(a int not null unique, b int, c int, primary key(c, b))
go
create table t4(a int not null unique)
go
create table t5(Id eyedees, Cellphone phone_num, primary key(Id, Cellphone))
go
create table MyTable1(ColA eyedees, ColB phone_num, primary key(ColA, ColB))
go
create table [MyTable2]([ColA] phone_num, [ColB] eyedees, primary key([ColA], [ColB]))
go
create table unique_idx_table1(a int NOT NULL)
go
create unique index my_index1 ON unique_idx_table1(a)
go
create table unique_idx_table2(a int NOT NULL, b int primary key)
go
create unique index my_index2 ON unique_idx_table2(a)
go
-- Tables for all data types
CREATE TABLE type_bigint (a_bigint bigint primary key)
go
CREATE TABLE type_binary (a_binary binary primary key)
go
CREATE TABLE type_bit (a_bit bit primary key)
go
CREATE TABLE type_char (a_char char primary key)
go
CREATE TABLE type_date (a_date date primary key)
go
CREATE TABLE type_datetime (a_datetime datetime primary key)
go
CREATE TABLE type_datetime2 (a_datetime2 datetime2 primary key)
go
CREATE TABLE type_datetimeoffset (a_datetimeoffset datetimeoffset primary key)
go
CREATE TABLE type_decimal (a_decimal decimal primary key)
go
CREATE TABLE type_float (a_float float primary key)
go
CREATE TABLE type_int (a_int int primary key)
go
CREATE TABLE type_money (a_money money primary key)
go
CREATE TABLE type_nchar (a_nchar nchar primary key)
go
CREATE TABLE type_numeric(a_numeric numeric primary key)
go
CREATE TABLE type_nvarchar(a_nvarchar nvarchar primary key)
go
CREATE TABLE type_real(a_real real primary key)
go
CREATE TABLE type_smalldatetime(a_smalldatetime smalldatetime primary key)
go
CREATE TABLE type_smallint (a_smallint smallint primary key)
go
CREATE TABLE type_smallmoney (a_smallmoney smallmoney primary key)
go
CREATE TABLE type_sql_variant (a_sql_variant sql_variant primary key)
go
CREATE TABLE type_sysname (a_sysname sysname primary key)
go
CREATE TABLE type_time (a_time time primary key)
go
CREATE TABLE type_tinyint (a_tinyint tinyint primary key)
go
CREATE TABLE type_uniqueidentifier (a_uniqueidentifier uniqueidentifier primary key)
go
CREATE TABLE type_varbinary (a_varbinary varbinary primary key)
go
CREATE TABLE type_varchar (a_varchar varchar primary key)
go
CREATE TABLE type_int_identity (a_int_identity int identity primary key)
go
CREATE TABLE type_bigint_identity (a_bigint_identity bigint identity primary key)
go
CREATE TABLE type_smallint_identity (a_smallint_identity smallint identity primary key)
go
CREATE TABLE type_tinyint_identity (a_tinyint_identity tinyint identity primary key)
go
CREATE TABLE type_decimal_identity (a_decimal_identity decimal identity primary key)
go
CREATE TABLE type_numeric_identity (a_numeric_identity numeric identity primary key)
go
CREATE TABLE type_decimal_5_2 (a_decimal_5_2 decimal(5,2) primary key)
go
CREATE TABLE type_decimal_5_3 (a_decimal_5_2 decimal(5,3) primary key)
go
CREATE TABLE type_float_7 (a_float_7 float(7) primary key)
go
CREATE TABLE type_char_7 (a_char_7 char(7) primary key)
go
CREATE TABLE type_varchar_7 (a_varchar_7 varchar(7) primary key)
go
CREATE TABLE type_nchar_7 (a_nchar_7 nchar(7) primary key)
go
CREATE TABLE type_nvarchar_7 (a_nvarchar_7 nvarchar(7) primary key)
go
CREATE TABLE type_time_6 (a_time_6 time(6) primary key)
go
CREATE TABLE type_datetime2_6 (a_datetime2_6 datetime2(6) primary key)
go
CREATE TABLE type_datetimeoffset_6 (a_datetimeoffset_6 datetimeoffset(6) primary key)
go
CREATE TABLE type_binary_7 (a_binary_7 binary(7) primary key)
go
CREATE TABLE type_varbinary_7 (a_varbinary_7 varbinary(7) primary key)
go


-- syntax error: @table_name is required
exec sp_special_columns
go

exec sp_special_columns @table_name = 't1'
go

exec sp_special_columns @table_name = 't2', @qualifier = 'db1', @scope = 'C'
go

exec sp_special_columns @table_name = 't3', @table_owner = 'dbo', @col_type = 'R'
go

exec sp_special_columns @table_name = 't4', @nullable = 'O'
go

-- Test table with user-defined type
exec sp_special_columns @table_name = 't5'
go

-- Mix-cased table tests
exec sp_special_columns @table_name = 'mytable1'
go

exec sp_special_columns @table_name = 'MYTABLE1'
go

exec sp_special_columns @table_name = 'mytable2'
go

exec sp_special_columns @table_name = 'MYTABLE2'
go

-- Delimiter table tests NOTE: These to do not produce correct output due to BABEL-2883
exec sp_special_columns @table_name = [mytable1]
go

exec sp_special_columns @table_name = [MYTABLE1]
go

exec sp_special_columns @table_name = [mytable2]
go

exec sp_special_columns @table_name = [MYTABLE2]
go

-- unnamed invocation
exec sp_special_columns 't1', 'dbo', 'db1'
go

-- case-insensitive invocation
EXEC SP_SPECIAL_COLUMNS @TABLE_NAME = 't2', @TABLE_OWNER = 'dbo', @QUALIFIER = 'db1'
GO

-- square-delimiter invocation
EXEC [sys].[sp_special_columns] @table_name = 't2', @table_owner = 'dbo', @qualifier = 'db1'
GO

-- Testing datatypes
-- NOTE: Currently, these values do not produce accurate results for some datatypes such as tinyint/decimal/numeric identity, time/datetime2/datetimeoffset with default typemode 7.

EXEC sp_special_columns 'type_bigint'
go
EXEC sp_special_columns 'type_binary'
go
EXEC sp_special_columns 'type_bit'
go
EXEC sp_special_columns 'type_char'
go
EXEC sp_special_columns 'type_date'
go
EXEC sp_special_columns 'type_datetime'
go
EXEC sp_special_columns 'type_datetime2'
go
EXEC sp_special_columns 'type_datetimeoffset'
go
EXEC sp_special_columns 'type_decimal'
go
EXEC sp_special_columns 'type_float'
go
EXEC sp_special_columns 'type_int'
go
EXEC sp_special_columns 'type_money'
go
EXEC sp_special_columns 'type_nchar'
go
EXEC sp_special_columns 'type_numeric'
go
EXEC sp_special_columns 'type_nvarchar'
go
EXEC sp_special_columns 'type_real'
go
EXEC sp_special_columns 'type_smalldatetime'
go
EXEC sp_special_columns 'type_smallint'
go
EXEC sp_special_columns 'type_smallmoney'
go
EXEC sp_special_columns 'type_sql_variant'
go
EXEC sp_special_columns 'type_sysname'
go
EXEC sp_special_columns 'type_time'
go
EXEC sp_special_columns 'type_tinyint'
go
EXEC sp_special_columns 'type_uniqueidentifier'
go
EXEC sp_special_columns 'type_varbinary'
go
EXEC sp_special_columns 'type_varchar'
go
EXEC sp_special_columns 'type_int_identity'
go
EXEC sp_special_columns 'type_bigint_identity'
go
EXEC sp_special_columns 'type_smallint_identity'
go
EXEC sp_special_columns 'type_tinyint_identity'
go
EXEC sp_special_columns 'type_decimal_identity'
go
EXEC sp_special_columns 'type_numeric_identity'
go
EXEC sp_special_columns 'type_decimal_5_2'
go
EXEC sp_special_columns 'type_decimal_5_3'
go
EXEC sp_special_columns 'type_float_7'
go
EXEC sp_special_columns 'type_char_7'
go
EXEC sp_special_columns 'type_varchar_7'
go
EXEC sp_special_columns 'type_nchar_7'
go
EXEC sp_special_columns 'type_nvarchar_7'
go
EXEC sp_special_columns 'type_time_6'
go
EXEC sp_special_columns 'type_datetime2_6'
go
EXEC sp_special_columns 'type_datetimeoffset_6'
go
EXEC sp_special_columns 'type_binary_7'
go
EXEC sp_special_columns 'type_varbinary_7'
go

-- Test unique indexes created after table creation
exec sp_special_columns 'unique_idx_table1'
go
exec sp_special_columns 'unique_idx_table2' -- only primary key should be shown
go

-- cleanup
drop table t1
go
drop table t2
go
drop table t3
go
drop table t4
go
drop table t5
go
drop table MyTable1
go
drop table [MyTable2]
go
drop type eyedees
go
drop type phone_num
go
DROP TABLE type_bigint
go
DROP TABLE type_binary
go
DROP TABLE type_bit
go
DROP TABLE type_char
go
DROP TABLE type_date
go
DROP TABLE type_datetime
go
DROP TABLE type_datetime2
go
DROP TABLE type_datetimeoffset
go
DROP TABLE type_decimal
go
DROP TABLE type_float
go
DROP TABLE type_int
go
DROP TABLE type_money
go
DROP TABLE type_nchar
go
DROP TABLE type_numeric
go
DROP TABLE type_nvarchar
go
DROP TABLE type_real
go
DROP TABLE type_smalldatetime
go
DROP TABLE type_smallint
go
DROP TABLE type_smallmoney
go
DROP TABLE type_sql_variant 
go
DROP TABLE type_sysname
go
DROP TABLE type_time 
go
DROP TABLE type_tinyint
go
DROP TABLE type_uniqueidentifier
go
DROP TABLE type_varbinary
go
DROP TABLE type_varchar
go
DROP TABLE type_int_identity
go
DROP TABLE type_bigint_identity
go
DROP TABLE type_smallint_identity
go
DROP TABLE type_tinyint_identity
go
DROP TABLE type_decimal_identity
go
DROP TABLE type_numeric_identity
go
DROP TABLE unique_idx_table1
go
DROP TABLE unique_idx_table2
go
DROP TABLE type_decimal_5_2
go
DROP TABLE type_decimal_5_3
go
DROP TABLE type_float_7
go
DROP TABLE type_char_7
go
DROP TABLE type_varchar_7
go
DROP TABLE type_nchar_7
go
DROP TABLE type_nvarchar_7
go
DROP TABLE type_time_6
go
DROP TABLE type_datetime2_6
go
DROP TABLE type_datetimeoffset_6
go
DROP TABLE type_binary_7
go
DROP TABLE type_varbinary_7
go
use master
go
drop database db1
go
