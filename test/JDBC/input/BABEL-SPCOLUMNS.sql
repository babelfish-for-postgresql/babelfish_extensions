-- sla_for_parallel_query_enforced 60000
USE master
GO
CREATE DATABASE mydb1
GO
USE mydb1
GO

-- Error: have to provide table name
EXEC sp_columns
GO

-- Testing a few different types
CREATE table t_time (a time)
GO
EXEC sp_columns @table_name = 't_time'
GO

CREATE table t_text(a text)
GO
exec sp_columns @table_name = 't_text'
GO

CREATE table t_int (a int)
GO
exec sp_columns @table_name = 't_int'
GO

CREATE table t_money(a money)
GO
exec sp_columns @table_name = 't_money'
GO

-- Testing all parameters
EXEC sp_columns @table_name = 't_int', @table_owner = 'dbo', @table_qualifier = 'mydb1', @column_name = 'a'
GO
EXEC sp_columns 't_int', 'dbo', 'mydb1', 'a'
GO

-- sp_columns_100, wild card matching enabled
EXEC sp_columns_100 '%_money', 'dbo', NULL, NULL, 0, 2, 1
GO

-- no wild card matching
EXEC sp_columns_100 '%_money', 'dbo', NULL, NULL, 0, 2, 0
GO

-- sp_columns_100, wild card matching enabled
EXEC sp_columns_100 '%[_]money', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 '%[_]MONEY', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 't_[a-z][a-z][a-z][a-z][a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 't_[a-z][a-z][a-z][a-z][a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 'T_[A-Z][A-Z][A-Z][A-Z][A-Z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 't_[a-z][a-z][a-z][a-z][^a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

drop table t_int
drop table t_text
drop table t_time
drop table t_money
GO

USE master
GO
DROP DATABASE mydb1
GO

CREATE DATABASE mydb1 COLLATE bbf_unicode_cp1_ci_ai;
GO
USE mydb1
GO

-- Error: have to provide table name
EXEC sp_columns
GO

-- Testing a few different types
CREATE table t_time (a time)
GO
EXEC sp_columns @table_name = 't_time'
GO

CREATE table t_text(a text)
GO
exec sp_columns @table_name = 't_text'
GO

CREATE table t_int (a int)
GO
exec sp_columns @table_name = 't_int'
GO

CREATE table t_money(a money)
GO
exec sp_columns @table_name = 't_money'
GO

-- Testing all parameters
EXEC sp_columns @table_name = 't_int', @table_owner = 'dbo', @table_qualifier = 'mydb1', @column_name = 'a'
GO
EXEC sp_columns 't_int', 'dbo', 'mydb1', 'a'
GO

-- sp_columns_100, wild card matching enabled
EXEC sp_columns_100 '%_money', 'dbo', NULL, NULL, 0, 2, 1
GO

-- no wild card matching
EXEC sp_columns_100 '%_money', 'dbo', NULL, NULL, 0, 2, 0
GO

-- sp_columns_100, wild card matching enabled
EXEC sp_columns_100 '%[_]money', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 '%[_]MONEY', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 't_[a-z][a-z][a-z][a-z][a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 't_[a-z][a-z][a-z][a-z][a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 'T_[A-Z][A-Z][A-Z][A-Z][A-Z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 't_[a-z][a-z][a-z][a-z][^a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

drop table t_int
drop table t_text
drop table t_time
drop table t_money
GO

USE master
GO
DROP DATABASE mydb1
GO
