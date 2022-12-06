-- DIFFERENT CASES TO CHECK DATATYPES
-- Exact Numerics
SELECT * FROM forjson_datatypes_vu_v_numerics
GO

SELECT * FROM forjson_datatypes_vu_v_bit
GO

SELECT * FROM forjson_datatypes_vu_v_money
GO

SELECT * FROM forjson_datatypes_vu_v_smallmoney
GO

-- Approximate numerics
SELECT * FROM forjson_datatypes_vu_v_approx_numerics
GO

-- Date and time
SELECT * FROM forjson_datatypes_vu_v_time_date
GO

SELECT * FROM forjson_datatypes_vu_v_smalldatetime
GO

SELECT * FROM forjson_datatypes_vu_v_datetime
GO

SELECT * FROM forjson_datatypes_vu_v_datetime2
GO

SELECT * FROM forjson_datatypes_vu_v_datetimeoffset
GO

-- Character strings
SELECT * FROM forjson_datatypes_vu_v_strings
GO

-- Unicode character strings
SELECT * FROM forjson_datatypes_vu_v_unicode_strings
GO

-- Binary strings
SELECT * FROM forjson_datatypes_vu_v_binary_strings
GO

SELECT * FROM forjson_datatypes_vu_v_varbinary_strings
GO

-- Rowversion and timestamp
SELECT * FROM forjson_datatypes_vu_v_rowversion
GO

SELECT * FROM forjson_datatypes_vu_v_timestamp
GO