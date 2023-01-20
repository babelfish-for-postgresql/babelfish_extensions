-- FOR JSON PATH clause without nested support
DROP VIEW forjson_vu_v_people
GO

DROP VIEW forjson_vu_v_countries
GO

-- Multiple tables without nested support
DROP VIEW forjson_vu_v_join
GO

-- ROOT directive without specifying value
DROP VIEW forjson_vu_v_root
GO

-- ROOT directive with specifying ROOT value
DROP VIEW forjson_vu_v_root_value
GO

-- ROOT directive with specifying ROOT value with empty string
DROP VIEW forjson_vu_v_empty_root
GO

-- WITHOUT_ARRAY_WRAPPERS directive
DROP VIEW forjson_vu_v_without_array_wrapper
GO

-- INCLUDE_NULL_VALUES directive
DROP VIEW forjson_vu_v_include_null_values
GO

-- Multiple Directives
DROP VIEW forjson_vu_v_root_include_null_values
GO

DROP VIEW forjson_vu_v_without_array_wrapper_include_null_values
GO


-- Test case with parameters
DROP PROCEDURE forjson_vu_p_params1
GO

DROP PROCEDURE forjson_vu_p_params2
GO

-- All null values test
DROP VIEW forjson_vu_v_nulls
GO

-- Test for all parser rules
DROP VIEW forjson_vu_v_order_by
GO

-- Display Table Contents
DROP TABLE forjson_vu_t_people
GO

DROP TABLE forjson_vu_t_countries
GO

DROP TABLE forjson_vu_t_values
GO