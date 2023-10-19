create database babel_sp_special_columns_vu_prepare_db1
go
use babel_sp_special_columns_vu_prepare_db1
go
CREATE TYPE babel_sp_special_columns_vu_prepare_eyedees FROM int not NULL
go
CREATE TYPE babel_sp_special_columns_vu_prepare_Phone_Num FROM varchar(11) NOT NULL 
go
create table babel_sp_special_columns_vu_prepare_t1(a int, primary key(a))
go
create table babel_sp_special_columns_vu_prepare_t2(a int, b int, c int, primary key(b, c))
go
create table babel_sp_special_columns_vu_prepare_t3(a int not null unique, b int, c int, primary key(c, b))
go
create table babel_sp_special_columns_vu_prepare_t4(a int not null unique)
go
create table babel_sp_special_columns_vu_prepare_t5(Id babel_sp_special_columns_vu_prepare_eyedees, Cellphone babel_sp_special_columns_vu_prepare_phone_num, primary key(Id, Cellphone))
go
create table babel_sp_special_columns_vu_prepare_MyTable1(ColA babel_sp_special_columns_vu_prepare_eyedees, ColB babel_sp_special_columns_vu_prepare_phone_num, primary key(ColA, ColB))
go
create table [babel_sp_special_columns_vu_prepare_MyTable2]([ColA] babel_sp_special_columns_vu_prepare_phone_num, [ColB] babel_sp_special_columns_vu_prepare_eyedees, primary key([ColA], [ColB]))
go
create table babel_sp_special_columns_vu_prepare_unique_idx_table1(a int NOT NULL)
go
create unique index babel_sp_special_columns_vu_prepare_my_index1 ON babel_sp_special_columns_vu_prepare_unique_idx_table1(a)
go
create table babel_sp_special_columns_vu_prepare_unique_idx_table2(a int NOT NULL, b int primary key)
go
create unique index babel_sp_special_columns_vu_prepare_my_index2 ON babel_sp_special_columns_vu_prepare_unique_idx_table2(a)
go
-- Tables for all data types
CREATE TABLE babel_sp_special_columns_vu_prepare_type_bigint (a_bigint bigint primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_binary (a_binary binary primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_bit (a_bit bit primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_char (a_char char primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_date (a_date date primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_datetime (a_datetime datetime primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_datetime2 (a_datetime2 datetime2 primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_datetimeoffset (a_datetimeoffset datetimeoffset primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_decimal (a_decimal decimal primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_float (a_float float primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_int (a_int int primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_money (a_money money primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_nchar (a_nchar nchar primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_numeric(a_numeric numeric primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_nvarchar(a_nvarchar nvarchar primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_real(a_real real primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_smalldatetime(a_smalldatetime smalldatetime primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_smallint (a_smallint smallint primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_smallmoney (a_smallmoney smallmoney primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_sql_variant (a_sql_variant sql_variant primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_sysname (a_sysname sysname primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_time (a_time time primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_tinyint (a_tinyint tinyint primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_uniqueidentifier (a_uniqueidentifier uniqueidentifier primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_varbinary (a_varbinary varbinary primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_varchar (a_varchar varchar primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_int_identity (a_int_identity int identity primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_bigint_identity (a_bigint_identity bigint identity primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_smallint_identity (a_smallint_identity smallint identity primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_tinyint_identity (a_tinyint_identity tinyint identity primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_decimal_identity (a_decimal_identity decimal identity primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_numeric_identity (a_numeric_identity numeric identity primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_decimal_5_2 (a_decimal_5_2 decimal(5,2) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_decimal_5_3 (a_decimal_5_2 decimal(5,3) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_float_7 (a_float_7 float(7) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_char_7 (a_char_7 char(7) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_varchar_7 (a_varchar_7 varchar(7) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_nchar_7 (a_nchar_7 nchar(7) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_nvarchar_7 (a_nvarchar_7 nvarchar(7) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_time_6 (a_time_6 time(6) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_datetime2_6 (a_datetime2_6 datetime2(6) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_datetimeoffset_6 (a_datetimeoffset_6 datetimeoffset(6) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_binary_7 (a_binary_7 binary(7) primary key)
go
CREATE TABLE babel_sp_special_columns_vu_prepare_type_varbinary_7 (a_varbinary_7 varbinary(7) primary key)
go

CREATE TABLE dbo.tidentityintbig (
 data_type_test CHAR(50) NULL
 , test_scenario CHAR(60) NULL
 , value_test BIGINT IDENTITY (202202081842, 100 ) NOT NULL  -- Used for unique index
 , inserted_dt DATETIME DEFAULT GETDATE()
 , user_login CHAR(255) DEFAULT CURRENT_USER
)
GO
CREATE UNIQUE NONCLUSTERED INDEX dbo_tidentityintbig_value_test ON dbo.tidentityintbig (value_test ASC); -- 3rd column in the table
GO

CREATE TABLE dbo.tidentityintbigmulti (
    data_type_test CHAR(50) NULL
    , test_scenario CHAR(60) NOT NULL
    , value_test BIGINT IDENTITY (202202081842, 100 ) NOT NULL
    , inserted_dt DATETIME DEFAULT GETDATE()
    , user_login CHAR(255) DEFAULT CURRENT_USER NOT NULL
)
GO
CREATE UNIQUE NONCLUSTERED INDEX dbo_tidentityintbigmulti_value_test ON dbo.tidentityintbigmulti (user_login ASC, value_test ASC, test_scenario ASC);
GO