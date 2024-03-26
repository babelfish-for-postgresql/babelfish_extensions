-- BABEL-3311 TVF name truncation

-- function name longer than 63 characters
CREATE FUNCTION babel_table_type_vu_a_very_long_function_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa(@id INT)
RETURNS @a_short_table_name TABLE (result INT)
AS
BEGIN
	INSERT INTO @a_short_table_name
		SELECT @id;
	RETURN;
END;
GO

-- table name longer than 63 characters
CREATE FUNCTION babel_table_type_vu_a_short_function_name(@id INT)
RETURNS @a_very_long_table_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa TABLE (result INT)
AS
BEGIN
	INSERT INTO @a_very_long_table_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
		SELECT @id;
	RETURN;
END;
GO

-- both function name and table name longer than 63 characters
CREATE FUNCTION babel_table_type_vu_a_very_long_function_name_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb(@id INT)
RETURNS @a_very_long_table_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa TABLE (result INT)
AS
BEGIN
	INSERT INTO @a_very_long_table_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
		SELECT @id;
	RETURN;
END;
GO

-- each shorter than 63 characters, but combined are longer than 63 characters
CREATE FUNCTION babel_table_type_vu_a_medium_function_name_aaaaaaaaaaaaaaaaa(@id INT)
RETURNS @a_medium_table_name_aaaaaaaaaaaaaaaaaaaa TABLE (result INT)
AS
BEGIN
	INSERT INTO @a_medium_table_name_aaaaaaaaaaaaaaaaaaaa
		SELECT @id;
	RETURN;
END;
GO

-- nesting TVFs using the same long table variable name
CREATE FUNCTION babel_table_type_vu_a_nested_function(@id INT)
RETURNS @a_very_long_table_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa TABLE (result INT)
AS
BEGIN
	INSERT INTO @a_very_long_table_name_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
		SELECT result FROM babel_table_type_vu_a_short_function_name(@id);
	RETURN;
END;
GO