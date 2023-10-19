create function test_sp_babelfish_volatility_f1() returns int begin declare @a int; set @a = 1; return @a; end
go

create schema test_sp_babelfish_volatility_schema1
go

create function test_sp_babelfish_volatility_schema1.test_sp_babelfish_volatility_f1() returns int begin declare @a int; set @a = 1; return @a; end
go

create schema [test_sp_babelfish_volatility_schema1 with .dot and spaces]
go

create function [test_sp_babelfish_volatility_schema1 with .dot and spaces].test_sp_babelfish_volatility_f1() returns int begin declare @a int; set @a = 1; return @a; end
go

CREATE LOGIN test_sp_babelfish_volatility_login WITH PASSWORD = '12345678';
GO

CREATE DATABASE test_sp_babelfish_volatility_db1
GO

USE test_sp_babelfish_volatility_db1
GO

CREATE SCHEMA test_sp_babelfish_volatility_schema2
GO

create function test_sp_babelfish_volatility_f2() returns int begin declare @a int; set @a = 1; return @a; end
GO

create function test_sp_babelfish_volatility_duplicate() returns int begin declare @a int; set @a = 1; return @a; end
go

create function test_sp_babelfish_volatility_duplicate(@b int) returns int begin declare @a int; set @a = 1; return @a; end
go

create function test_sp_babelfish_volatility_schema2.test_sp_babelfish_volatility_f1() returns int begin declare @a int; set @a = 1; return @a; end
GO

create schema test_sp_babelfish_volatility_schema_very_long_with_length_greater_than_63_but_less_equal_than_128_random_text_aaaaaaaaaaaaaaaaaa;
go

create function test_sp_babelfish_volatility_function_very_long_with_length_greater_than_63_but_less_equal_than_128_random_text_aaaaaaaaaaaaaaaa()
returns int begin declare @a int; set @a = 1; return @a; end
go

create function test_sp_babelfish_volatility_schema_very_long_with_length_greater_than_63_but_less_equal_than_128_random_text_aaaaaaaaaaaaaaaaaa.test_sp_babelfish_volatility_function_very_long_with_length_greater_than_63_but_less_equal_than_128_random_text_aaaaaaaaaaaaaaaa()
returns int begin declare @a int; set @a = 1; return @a; end
go

CREATE USER test_sp_babelfish_volatility_user FOR LOGIN test_sp_babelfish_volatility_login
GO

use master
go

create table test_bbf_vol_t1(a int)
go

create function test_bbf_vol_f1() returns int begin declare @a int; set @a = 1; return @a; end
go

create function [test_bbf_vol_f1;drop table test_bbf_vol_t1;]() returns int begin declare @a int; set @a = 1; return @a; end
go

use test_sp_babelfish_volatility_db1
go

CREATE LOGIN test_sp_babelfish_volatility_login_2 WITH PASSWORD = '12345678'
GO
