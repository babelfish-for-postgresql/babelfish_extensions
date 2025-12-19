exec sp_datatype_info_100 @data_type = 1
go

exec sp_datatype_info @data_type = 2
go

-- Failed query in BABEL-2448
EXEC sys.sp_datatype_info_100 1, @odbcver = 2
go

-- Should show date data type
EXEC sp_datatype_info @data_type = -9
go

-- Should show datetime data type
EXEC sp_datatype_info @data_type = 11
go

-- PyODBC Driver Metadata Calls

EXEC sp_datatype_info_100 @data_type = 12   -- varchar
go

EXEC sp_datatype_info_100 @data_type = -9   -- nvarchar, sysname
go

EXEC sp_datatype_info_100 @data_type = -3   -- varbinary
go

EXEC sp_datatype_info_100 @data_type = 93   -- (may be empty - not in table)
go

-- Positive types - sp_datatype_info_100

EXEC sp_datatype_info_100 @data_type = 1   -- char
go
EXEC sp_datatype_info_100 @data_type = 2   -- numeric
go
EXEC sp_datatype_info_100 @data_type = 3   -- decimal, money, smallmoney
go
EXEC sp_datatype_info_100 @data_type = 4   -- int
go
EXEC sp_datatype_info_100 @data_type = 5   -- smallint
go
EXEC sp_datatype_info_100 @data_type = 6   -- float
go
EXEC sp_datatype_info_100 @data_type = 7   -- real
go
EXEC sp_datatype_info_100 @data_type = 9   -- date
go
EXEC sp_datatype_info_100 @data_type = 11  -- datetime, datetime2, smalldatetime
go
EXEC sp_datatype_info_100 @data_type = 12  -- varchar
go

-- Positive types - sp_datatype_info

EXEC sp_datatype_info @data_type = 1   -- char
go
EXEC sp_datatype_info @data_type = 2   -- numeric
go
EXEC sp_datatype_info @data_type = 3   -- decimal, money, smallmoney
go
EXEC sp_datatype_info @data_type = 4   -- int
go
EXEC sp_datatype_info @data_type = 5   -- smallint
go
EXEC sp_datatype_info @data_type = 6   -- float
go
EXEC sp_datatype_info @data_type = 7   -- real
go
EXEC sp_datatype_info @data_type = 9   -- date
go
EXEC sp_datatype_info @data_type = 11  -- datetime, datetime2, smalldatetime
go
EXEC sp_datatype_info @data_type = 12  -- varchar
go

-- Negative types - sp_datatype_info_100

EXEC sp_datatype_info_100 @data_type = -1   -- text
go
EXEC sp_datatype_info_100 @data_type = -2   -- binary, timestamp
go
EXEC sp_datatype_info_100 @data_type = -3   -- varbinary
go
EXEC sp_datatype_info_100 @data_type = -4   -- image
go
EXEC sp_datatype_info_100 @data_type = -5   -- bigint
go
EXEC sp_datatype_info_100 @data_type = -6   -- tinyint
go
EXEC sp_datatype_info_100 @data_type = -7   -- bit
go
EXEC sp_datatype_info_100 @data_type = -8   -- nchar
go
EXEC sp_datatype_info_100 @data_type = -9   -- nvarchar, sysname
go
EXEC sp_datatype_info_100 @data_type = -10  -- ntext
go
EXEC sp_datatype_info_100 @data_type = -11  -- uniqueidentifier
go

-- Negative types - sp_datatype_info

EXEC sp_datatype_info @data_type = -1   -- text
go
EXEC sp_datatype_info @data_type = -2   -- binary, timestamp
go
EXEC sp_datatype_info @data_type = -3   -- varbinary
go
EXEC sp_datatype_info @data_type = -4   -- image
go
EXEC sp_datatype_info @data_type = -5   -- bigint
go
EXEC sp_datatype_info @data_type = -6   -- tinyint
go
EXEC sp_datatype_info @data_type = -7   -- bit
go
EXEC sp_datatype_info @data_type = -8   -- nchar
go
EXEC sp_datatype_info @data_type = -9   -- nvarchar, sysname
go
EXEC sp_datatype_info @data_type = -10  -- ntext
go
EXEC sp_datatype_info @data_type = -11  -- uniqueidentifier
go

-- Other types - sp_datatype_info_100

EXEC sp_datatype_info_100 @data_type = -150  -- sql_variant
go
EXEC sp_datatype_info_100 @data_type = -151  -- geography, geometry
go
EXEC sp_datatype_info_100 @data_type = -152  -- xml
go
EXEC sp_datatype_info_100 @data_type = -154  -- time
go
EXEC sp_datatype_info_100 @data_type = -155  -- datetimeoffset
go
EXEC sp_datatype_info_100 @data_type = -2147483648  -- vector
go

-- Other types - sp_datatype_info

EXEC sp_datatype_info @data_type = -150  -- sql_variant
go
EXEC sp_datatype_info @data_type = -151  -- geography, geometry
go
EXEC sp_datatype_info @data_type = -152  -- xml
go
EXEC sp_datatype_info @data_type = -154  -- time
go
EXEC sp_datatype_info @data_type = -155  -- datetimeoffset
go
EXEC sp_datatype_info @data_type = -2147483648  -- vector
go

-- @odbcver parameter tests - sp_datatype_info_100

EXEC sp_datatype_info_100 @data_type = 12, @odbcver = 2
go
EXEC sp_datatype_info_100 @data_type = 12, @odbcver = 3
go
EXEC sp_datatype_info_100 @data_type = -9, @odbcver = 2
go
EXEC sp_datatype_info_100 @data_type = -9, @odbcver = 3
go

-- @odbcver parameter tests - sp_datatype_info

EXEC sp_datatype_info @data_type = 12, @odbcver = 2
go
EXEC sp_datatype_info @data_type = 12, @odbcver = 3
go
EXEC sp_datatype_info @data_type = -9, @odbcver = 2
go
EXEC sp_datatype_info @data_type = -9, @odbcver = 3
go

-- No parameters (return all data types)

EXEC sp_datatype_info
go

EXEC sp_datatype_info_100
go

-- NULL parameter handling

EXEC sp_datatype_info @data_type = NULL
go
EXEC sp_datatype_info_100 @data_type = NULL
go

-- Positional parameters

EXEC sp_datatype_info 1
go
EXEC sp_datatype_info_100 1
go

EXEC sp_datatype_info 12
go
EXEC sp_datatype_info_100 12
go

EXEC sp_datatype_info 12, 2
go
EXEC sp_datatype_info_100 12, 2
go

EXEC sp_datatype_info 12, 3
go
EXEC sp_datatype_info_100 12, 3
go

-- Mixed positional and named parameters

EXEC sp_datatype_info 12, @odbcver = 2
go
EXEC sp_datatype_info_100 12, @odbcver = 2
go

EXEC sp_datatype_info 12, @odbcver = 3
go
EXEC sp_datatype_info_100 12, @odbcver = 3
go

-- Fully qualified name (sys schema)

EXEC sys.sp_datatype_info @data_type = 12
go
EXEC sys.sp_datatype_info_100 @data_type = 12
go

EXEC sys.sp_datatype_info 12, @odbcver = 2
go
EXEC sys.sp_datatype_info_100 12, @odbcver = 2
go

-- Invalid/Edge cases

-- Return all types (data_type = 0)
EXEC sp_datatype_info @data_type = 0
go
EXEC sp_datatype_info_100 @data_type = 0
go

-- Non-existent data type
EXEC sp_datatype_info @data_type = 999
go
EXEC sp_datatype_info_100 @data_type = 999
go

EXEC sp_datatype_info @data_type = -999
go
EXEC sp_datatype_info_100 @data_type = -999
go

-- Wrapper Procedures
EXEC sp_datatype_info_100_vu_prepare_p1;
GO

EXEC sp_datatype_info_100_vu_prepare_p2 @data_type = 0;
GO

EXEC sp_datatype_info_100_vu_prepare_p3 @data_type = 0, @odbcver = 2;
GO

EXEC sp_datatype_info_100_vu_prepare_int_types;
GO

EXEC sp_datatype_info_100_vu_prepare_string_types;
GO

EXEC sp_datatype_info_100_vu_prepare_binary_types;
GO

EXEC sp_datatype_info_100_vu_prepare_datetime_types;
GO

EXEC sp_datatype_info_100_vu_prepare_decimal_types;
GO

EXEC sp_datatype_info_100_vu_prepare_float_types;
GO

EXEC sp_datatype_info_100_vu_prepare_special_types;
GO

EXEC sp_datatype_info_100_vu_prepare_odbcver;
GO

EXEC sp_datatype_info_100_vu_prepare_edge_cases;
GO

EXEC sp_datatype_info_vu_prepare_p1;
GO

EXEC sp_datatype_info_vu_prepare_p2 @data_type = 0;
GO

EXEC sp_datatype_info_vu_prepare_p3 @data_type = 0, @odbcver = 2;
GO

EXEC sp_datatype_info_vu_prepare_int_types;
GO

EXEC sp_datatype_info_vu_prepare_string_types;
GO

EXEC sp_datatype_info_vu_prepare_binary_types;
GO

EXEC sp_datatype_info_vu_prepare_datetime_types;
GO

EXEC sp_datatype_info_vu_prepare_decimal_types;
GO

EXEC sp_datatype_info_vu_prepare_float_types;
GO

EXEC sp_datatype_info_vu_prepare_special_types;
GO

EXEC sp_datatype_info_vu_prepare_odbcver;
GO

EXEC sp_datatype_info_vu_prepare_edge_cases;
GO

EXEC sys.sp_datatype_info_100;
GO

EXEC sys.sp_datatype_info_100 @data_type = 4;
GO

EXEC sys.sp_datatype_info_100 @data_type = 4, @odbcver = 2;
GO

EXEC sys.sp_datatype_info_100 0, 2;
GO

EXEC sys.sp_datatype_info_100 @odbcver = 2, @data_type = 4;
GO

EXEC sys.sp_datatype_info;
GO

EXEC sys.sp_datatype_info @data_type = 4;
GO

EXEC sys.sp_datatype_info @data_type = 4, @odbcver = 2;
GO

EXEC sys.sp_datatype_info 0, 2;
GO

EXEC sys.sp_datatype_info @odbcver = 2, @data_type = 4;
GO
