-- DIFFERENT CASES TO CHECK DATATYPES
-- Exact Numerics
DROP VIEW forjson_datatypes_vu_v_numerics
GO

DROP VIEW forjson_datatypes_vu_v_bit
GO

DROP VIEW forjson_datatypes_vu_v_money
GO

DROP VIEW forjson_datatypes_vu_v_smallmoney
GO

-- Approximate numerics
DROP VIEW forjson_datatypes_vu_v_approx_numerics
GO

-- Date and time
DROP VIEW forjson_datatypes_vu_v_time_date
GO

DROP VIEW forjson_datatypes_vu_v_smalldatetime
GO

DROP VIEW forjson_datatypes_vu_v_datetime
GO

DROP VIEW forjson_datatypes_vu_v_datetime2
GO

DROP VIEW forjson_datatypes_vu_v_datetimeoffset
GO

-- Character strings
DROP VIEW forjson_datatypes_vu_v_strings
GO

-- Unicode character strings
DROP VIEW forjson_datatypes_vu_v_unicode_strings
GO

-- Binary strings
DROP VIEW forjson_datatypes_vu_v_binary_strings
GO

DROP VIEW forjson_datatypes_vu_v_varbinary_strings
GO

-- Rowversion and timestamp
DROP VIEW forjson_datatypes_vu_v_rowversion
GO

DROP VIEW forjson_datatypes_vu_v_timestamp
GO

-- DROP TABLE
DROP TABLE forjson_datatypes_vu_t_exact_numerics
GO

-- Approximate numerics
DROP TABLE forjson_datatypes_vu_t_approx_numerics
GO

-- Date and time
DROP TABLE forjson_datatypes_vu_t_date_and_time
GO

-- Character strings
DROP TABLE forjson_datatypes_vu_t_strings
GO

-- Unicode character strings
DROP TABLE forjson_datatypes_vu_t_unicode_strings
GO

-- Binary strings
DROP TABLE forjson_datatypes_vu_t_binary_strings
GO

-- Rowversion and timestamp
DROP TABLE forjson_datatypes_vu_t_rowversion
GO

DROP TABLE forjson_datatypes_vu_t_timestamp
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
GO
