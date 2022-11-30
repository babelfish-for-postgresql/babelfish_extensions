-- EXECUTE AS CALLER
-- For created functions/procedure/trigger the EXECUTE AS CALLER should be work without raising an error
-- The other variations of WITH EXECUTE AS should continue to raise an error
CREATE TABLE babel_execute_as_caller_table(c1 int)
GO

-- functions
CREATE FUNCTION babel_execute_as_caller_function_return_table() RETURNS TABLE WITH EXECUTE AS CALLER AS
RETURN (SELECT * FROM babel_execute_as_caller_table)
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int(@c int) RETURNS INT WITH EXECUTE AS CALLER AS
BEGIN
    RETURN (@c+1)
END
GO

CREATE FUNCTION babel_execute_as_caller_function_return_bigint() RETURNS BIGINT WITH EXECUTE AS CALLER AS
BEGIN
    DECLARE @ans BIGINT
    SELECT @ans= SUM(c1) FROM babel_execute_as_caller_table
    RETURN @ans
END
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int_1 (@v int) RETURNS INT WITH EXECUTE AS CALLER, RETURNS NULL ON NULL INPUT AS
BEGIN
    RETURN @v+1
END;
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int_2 (@v int) RETURNS INT WITH RETURNS NULL ON NULL INPUT, EXECUTE AS CALLER AS
BEGIN
    RETURN @v+1
END;
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int_2 (@v int) RETURNS INT WITH RETURNS NULL ON NULL INPUT, EXECUTE AS OWNER AS
BEGIN
    RETURN @v+1
END;
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int_2 (@v int) RETURNS INT WITH RETURNS NULL ON NULL INPUT, EXECUTE AS SELF AS
BEGIN
    RETURN @v+1
END;
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int_2 (@v int) RETURNS INT WITH RETURNS NULL ON NULL INPUT, EXECUTE AS 'user' AS
BEGIN
    RETURN @v+1
END;
GO

-- procedures
CREATE PROCEDURE babel_execute_as_caller_procedure1 WITH EXECUTE AS CALLER AS 
BEGIN SELECT * FROM babel_execute_as_caller_table END
GO

CREATE PROCEDURE babel_execute_as_caller_procedure1 WITH EXECUTE AS OWNER AS 
BEGIN SELECT * FROM babel_execute_as_caller_table END
GO

CREATE PROCEDURE babel_execute_as_caller_procedure2(@c int) WITH EXECUTE AS CALLER AS
BEGIN SELECT @c+1 END;
GO

CREATE PROCEDURE babel_execute_as_caller_procedure2(@c int) WITH EXECUTE AS 'user' AS
BEGIN SELECT @c+1 END;
GO

CREATE PROCEDURE babel_execute_as_caller_procedure3 (@v int) WITH EXECUTE AS CALLER AS 
BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
GO

-- trigger
CREATE TRIGGER babel_execute_as_caller_trigger1 ON babel_execute_as_caller_table WITH EXECUTE AS CALLER
FOR INSERT AS BEGIN UPDATE babel_execute_as_caller_table SET c1 =10 END
GO

CREATE TRIGGER babel_execute_as_caller_trigger1 ON babel_execute_as_caller_table WITH EXECUTE AS OWNER
FOR INSERT AS BEGIN UPDATE babel_execute_as_caller_table SET c1 =10 END
GO

-- CLEANUP
DROP TRIGGER babel_execute_as_caller_trigger1;
DROP PROCEDURE babel_execute_as_caller_procedure3;
DROP PROCEDURE babel_execute_as_caller_procedure2;
DROP PROCEDURE babel_execute_as_caller_procedure1;
DROP FUNCTION babel_execute_as_caller_function_return_int_2;
DROP FUNCTION babel_execute_as_caller_function_return_int_1;
DROP FUNCTION babel_execute_as_caller_function_return_bigint;
DROP FUNCTION babel_execute_as_caller_function_return_int;
DROP FUNCTION babel_execute_as_caller_function_return_table;
DROP TABLE babel_execute_as_caller_table;
GO
