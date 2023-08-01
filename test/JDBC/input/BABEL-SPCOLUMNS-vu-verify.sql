-- sla 800000
USE babel_sp_columns_vu_prepare_mydb1
GO

-- Error: have to provide table name
EXEC sp_columns
GO

-- Testing a few different types
EXEC sp_columns @table_name = 'babel_sp_columns_vu_prepare_t_time'
GO

exec sp_columns @table_name = 'babel_sp_columns_vu_prepare_t_text'
GO

exec sp_columns @table_name = 'babel_sp_columns_vu_prepare_t_int'
GO

exec sp_columns @table_name = 'babel_sp_columns_vu_prepare_t_money'
GO

-- Testing all parameters
EXEC sp_columns @table_name = 'babel_sp_columns_vu_prepare_t_int', @table_owner = 'dbo', @table_qualifier = 'babel_sp_columns_vu_prepare_mydb1', @column_name = 'a'
GO
EXEC sp_columns 'babel_sp_columns_vu_prepare_t_int', 'dbo', 'babel_sp_columns_vu_prepare_mydb1', 'a'
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

EXEC sp_columns_100 'babel_sp_columns_vu_prepare_t_[a-z][a-z][a-z][a-z][a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 'babel_sp_columns_vu_prepare_t_[a-z][a-z][a-z][a-z][a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 'babel_sp_columns_vu_prepare_T_[A-Z][A-Z][A-Z][A-Z][A-Z]', 'dbo', NULL, NULL, 0, 2, 1
GO

EXEC sp_columns_100 'babel_sp_columns_vu_prepare_t_[a-z][a-z][a-z][a-z][^a-z]', 'dbo', NULL, NULL, 0, 2, 1
GO

-- test sp_columns_100 for bytea
EXEC [sys].sp_columns_100 'babel_sp_columns_vu_prepare_bytea', 'dbo', NULL, NULL, @ODBCVer = 3, @fUsePattern = 1;
GO
