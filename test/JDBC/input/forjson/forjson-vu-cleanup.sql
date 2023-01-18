-- FOR JSON AUTO clause not supported
DROP VIEW forjson_vu_v_auto
GO

-- Alias/colname is not present
DROP VIEW forjson_vu_v_no_alias
GO

DROP VIEW forjson_vu_v_with
GO

DROP VIEW forjson_vu_v_with_order_by
GO

DROP TABLE forjson_vu_t_countries
GO

DROP TABLE forjson_vu_t1
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