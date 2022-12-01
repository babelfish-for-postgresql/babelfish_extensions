-- sla 750000
use babel_sp_special_columns_vu_prepare_db1
go

-- syntax error: @table_name is required
exec sp_special_columns
go

exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_t1'
go

exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_t2', @qualifier = 'db1', @scope = 'C'
go

exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_t3', @table_owner = 'dbo', @col_type = 'R'
go

exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_t4', @nullable = 'O'
go

-- Test table with user-defined type
exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_t5'
go

-- Mix-cased table tests
exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_mytable1'
go

exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_MYTABLE1'
go

exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_mytable2'
go

exec sp_special_columns @table_name = 'babel_sp_special_columns_vu_prepare_MYTABLE2'
go

-- Delimiter table tests NOTE: These to do not produce correct output due to BABEL-2883
exec sp_special_columns @table_name = [babel_sp_special_columns_vu_prepare_mytable1]
go

exec sp_special_columns @table_name = [babel_sp_special_columns_vu_prepare_MYTABLE1]
go

exec sp_special_columns @table_name = [babel_sp_special_columns_vu_prepare_mytable2]
go

exec sp_special_columns @table_name = [babel_sp_special_columns_vu_prepare_MYTABLE2]
go

-- unnamed invocation
exec sp_special_columns 'babel_sp_special_columns_vu_prepare_t1', 'dbo', 'babel_sp_special_columns_vu_prepare_db1'
go

-- case-insensitive invocation
EXEC SP_SPECIAL_COLUMNS @TABLE_NAME = 'babel_sp_special_columns_vu_prepare_t2', @TABLE_OWNER = 'dbo', @QUALIFIER = 'babel_sp_special_columns_vu_prepare_db1'
GO

-- square-delimiter invocation
EXEC [sys].[sp_special_columns] @table_name = 'babel_sp_special_columns_vu_prepare_t2', @table_owner = 'dbo', @qualifier = 'babel_sp_special_columns_vu_prepare_db1'
GO

-- Testing datatypes
-- NOTE: Currently, these values do not produce accurate results for some datatypes such as tinyint/decimal/numeric identity, time/datetime2/datetimeoffset with default typemode 7.

EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_bigint'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_binary'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_bit'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_char'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_date'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_datetime'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_datetime2'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_datetimeoffset'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_decimal'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_float'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_int'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_money'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_nchar'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_numeric'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_nvarchar'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_real'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_smalldatetime'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_smallint'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_smallmoney'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_sql_variant'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_sysname'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_time'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_tinyint'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_uniqueidentifier'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_varbinary'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_varchar'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_int_identity'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_bigint_identity'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_smallint_identity'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_tinyint_identity'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_decimal_identity'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_numeric_identity'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_decimal_5_2'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_decimal_5_3'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_float_7'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_char_7'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_varchar_7'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_nchar_7'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_nvarchar_7'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_time_6'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_datetime2_6'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_datetimeoffset_6'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_binary_7'
go
EXEC sp_special_columns 'babel_sp_special_columns_vu_prepare_type_varbinary_7'
go

-- Test unique indexes created after table creation
exec sp_special_columns 'babel_sp_special_columns_vu_prepare_unique_idx_table1'
go
exec sp_special_columns 'babel_sp_special_columns_vu_prepare_unique_idx_table2' -- only primary key should be shown
go

EXEC sp_special_columns @table_name = 'tidentityintbig', @table_owner = 'dbo' , @col_type = 'R', @nullable = 'U', @ODBCVer = 3
GO

EXEC sp_special_columns @table_name = 'tidentityintbigmulti', @table_owner = 'dbo' , @col_type = 'R', @nullable = 'U', @ODBCVer = 3
GO
