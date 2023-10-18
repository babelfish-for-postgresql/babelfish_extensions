-- Display Table Contents
SELECT * FROM forjson_vu_t_people
GO

SELECT * FROM forjson_vu_t_countries
GO

SELECT * FROM forjson_vu_t_values
GO

-- FOR JSON PATH clause without nested support
SELECT * FROM forjson_vu_v_people
GO

SELECT * FROM forjson_vu_v_countries
GO

-- Multiple tables without nested support
SELECT * FROM forjson_vu_v_join
GO

-- ROOT directive without specifying value
SELECT * FROM forjson_vu_v_root
GO

-- ROOT directive with specifying ROOT value
SELECT * FROM forjson_vu_v_root_value
GO

-- ROOT directive with specifying ROOT value with empty string
SELECT * FROM forjson_vu_v_empty_root
GO

-- WITHOUT_ARRAY_WRAPPERS directive
SELECT * FROM forjson_vu_v_without_array_wrapper
GO

-- INCLUDE_NULL_VALUES directive
SELECT * FROM forjson_vu_v_include_null_values
GO

-- Multiple Directives
SELECT * FROM forjson_vu_v_root_include_null_values
GO

SELECT * FROM forjson_vu_v_without_array_wrapper_include_null_values
GO


-- Test case with parameters
EXECUTE forjson_vu_p_params1 @id = 2
GO

EXECUTE forjson_vu_p_params2 @id = 3
GO

-- All null values test
SELECT * FROM forjson_vu_v_nulls
GO

-- Test for all parser rules
SELECT * FROM forjson_vu_v_order_by
GO