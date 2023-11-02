-- Display Table Contents
SELECT * FROM forjson_nesting_vu_t_users
GO

SELECT * FROM forjson_nesting_vu_t_products
GO

SELECT * FROM forjson_nesting_vu_t_orders
GO

-- FOR JSON PATH CLAUSE with nested json support for existing objects
SELECT * FROM forjson_nesting_vu_v_users
GO

SELECT * FROM forjson_nesting_vu_v_products
GO

SELECT * FROM forjson_nesting_vu_v_orders
GO

-- FOR JSON PATH support for multiple layers of nested JSON objects
SELECT * FROM forjson_nesting_vu_v_deep
GO

-- FOR JSON PATH support for multiple layers of nested JSON objects w/ join
SELECT * FROM forjson_nesting_vu_v_join_deep
GO

-- FOR JSON PATH Support for key-values being inserted into mid layer of multi-layered JSON object
SELECT * FROM forjson_nesting_vu_v_layered_insert
GO

-- Error related to inserting value at Json object location
SELECT * FROM forjson_nesting_vu_v_error
GO

-- Queries that check NULL nested json object insert
SELECT * FROM forjson_nesting_vu_v_no_null
GO

SELECT * FROM forjson_nesting_vu_v_with_null
GO

