SELECT * FROM a_very_long_function_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa(1);
GO

SELECT * FROM a_short_function_name(1);
GO

SELECT * FROM a_very_long_function_name_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb(1);
GO

SELECT * FROM a_medium_function_name_aaaaaaaaaaaaaaaaa(1);
GO

SELECT * FROM a_nested_function(1);
GO

-- cleanup
DROP FUNCTION a_nested_function;
GO
DROP FUNCTION a_very_long_function_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
GO
DROP FUNCTION a_short_function_name;
GO
DROP FUNCTION a_very_long_function_name_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
GO
DROP FUNCTION a_medium_function_name_aaaaaaaaaaaaaaaaa;
GO