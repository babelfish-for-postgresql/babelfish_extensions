
-- Invalid Function Param ,  without catch flag set 
SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','off',false)
GO


BEGIN TRY 
SELECT SWITCHOFFSET('2025-07-23 12:00:00 +00:00', 'abc') AS shifted_time; 
END TRY
BEGIN CATCH 
 SELECT ERROR_NUMBER() AS tsql_error_number, ERROR_MESSAGE() AS message_text;  
END CATCH;
GO

-- Invalid Function Param, with catch flag set 
SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','on',false)
GO


BEGIN TRY 
SELECT SWITCHOFFSET('2025-07-23 12:00:00 +00:00', 'abc') AS shifted_time; 
END TRY
BEGIN CATCH 
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number, ERROR_MESSAGE() AS message_text;  
END CATCH;
GO



-- time field value out of range, Termination scenario
SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','off',false);
GO

BEGIN TRY
    SELECT CAST('2025-13-40 25:61:61' AS DATETIME);  
END TRY
BEGIN CATCH
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number, ERROR_MESSAGE() AS message_text;
END CATCH;
GO


-- time field value out of range, Catch scenario
SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','on',false);
GO

BEGIN TRY
    SELECT CAST('2025-13-40 25:61:61' AS DATETIME);  
END TRY
BEGIN CATCH
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number, ERROR_MESSAGE() AS message_text;
END CATCH;
GO


-- numeric field overflow, without catch flag set
SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','off',false)
GO

BEGIN TRY
    SELECT CAST(123456 AS DECIMAL(5,2));  -- exceeds precision -> overflow at runtime
END TRY
BEGIN CATCH
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number, ERROR_MESSAGE() AS message_text;
END CATCH;
GO


-- numeric field overflow, with catch flag set 
SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','on',false)
GO

BEGIN TRY
    SELECT CAST(123456 AS DECIMAL(5,2));  -- exceeds precision -> overflow at runtime
END TRY
BEGIN CATCH
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number, ERROR_MESSAGE() AS message_text;
END CATCH;
GO


-- invalid input syntax for type integer: "not_an_int", without catch flag set 

DROP TABLE IF EXISTS error_test6;
CREATE TABLE error_test6 (id INT);
GO

SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','off',false)
GO

BEGIN TRY
    INSERT INTO error_test6 VALUES ('not_an_int'); -- bad cast
END TRY
BEGIN CATCH
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number,
           ERROR_MESSAGE() AS message_text;
END CATCH;
GO

DROP TABLE IF EXISTS error_test6;
GO


-- invalid input syntax for type integer: "not_an_int", with catch flag set 

DROP TABLE IF EXISTS error_test6;
CREATE TABLE error_test6 (id INT);
GO

SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','on',false)
GO


BEGIN TRY
    INSERT INTO error_test6 VALUES ('not_an_int'); -- bad cast
END TRY
BEGIN CATCH
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number,
           ERROR_MESSAGE() AS message_text;
END CATCH;
GO

DROP TABLE IF EXISTS error_test6;
GO


-- numeric field overflow, without catch flag set 
SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','off',false)
GO


BEGIN TRY
    SELECT CAST(123456 AS DECIMAL(5,2));  -- exceeds precision -> overflow at runtime
END TRY
BEGIN CATCH
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number, ERROR_MESSAGE() AS message_text;
END CATCH;
GO

-- numeric field overflow, with catch flag set 
SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','on',false)
GO


BEGIN TRY
    SELECT CAST(123456 AS DECIMAL(5,2));  -- exceeds precision -> overflow at runtime
END TRY
BEGIN CATCH
    SELECT 'Catch Error ';
    SELECT ERROR_NUMBER() AS tsql_error_number, ERROR_MESSAGE() AS message_text;
END CATCH;
GO

SELECT SET_CONFIG('babelfishpg_tsql.disable_unmapped_error_termination','off',false)
GO