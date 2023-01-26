-- FOR JSON AUTO clause not supported
SELECT * FROM forjson_subquery_vu_v_auto
GO

-- Alias/colname is not present
SELECT * FROM forjson_subquery_vu_v_no_alias
GO

SELECT * FROM forjson_subquery_vu_v_with
GO

SELECT * FROM forjson_subquery_vu_v_with_order_by
GO

-- Binary strings
SELECT * FROM forjson_subquery_vu_v_binary_strings
GO

SELECT * FROM forjson_subquery_vu_v_varbinary_strings
GO

-- Rowversion and timestamp
SELECT * FROM forjson_subquery_vu_v_rowversion
GO

SELECT * FROM forjson_subquery_vu_v_timestamp
GO