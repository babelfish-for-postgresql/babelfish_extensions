SELECT * FROM babel_table_type_vu_a_very_long_function_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa(1);
GO

SELECT * FROM babel_table_type_vu_a_short_function_name(1);
GO

SELECT * FROM babel_table_type_vu_a_very_long_function_name_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb(1);
GO

SELECT * FROM babel_table_type_vu_a_medium_function_name_aaaaaaaaaaaaaaaaa(1);
GO

SELECT * FROM babel_table_type_vu_a_nested_function(1);
GO

-- cleanup
DROP FUNCTION babel_table_type_vu_a_nested_function;
GO
DROP FUNCTION babel_table_type_vu_a_very_long_function_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
GO
DROP FUNCTION babel_table_type_vu_a_short_function_name;
GO
DROP FUNCTION babel_table_type_vu_a_very_long_function_name_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
GO
DROP FUNCTION babel_table_type_vu_a_medium_function_name_aaaaaaaaaaaaaaaaa;
GO