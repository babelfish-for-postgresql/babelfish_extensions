-- EXECUTE AS CALLER
-- Create function/procedure/trigger with `EXECUTE AS CALLER` clause should not raise an error.
-- The other variations of WITH EXECUTE AS should raise an error
CREATE TABLE babel_execute_as_caller_table(c1 int);
INSERT INTO babel_execute_as_caller_table values (1);
GO

-- functions
CREATE FUNCTION babel_execute_as_caller_function_return_table() RETURNS TABLE WITH EXECUTE AS CALLER AS
RETURN (SELECT * FROM babel_execute_as_caller_table)
GO
SELECT babel_execute_as_caller_function_return_table()
GO

CREATE FUNCTION babel_execute_as_caller_function_return_table_1() RETURNS TABLE WITH EXECUTE AS OWNER AS
RETURN (SELECT * FROM babel_execute_as_caller_table)
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int(@c int) RETURNS INT WITH EXECUTE AS CALLER AS
BEGIN
    RETURN (@c+1)
END
GO
SELECT babel_execute_as_caller_function_return_int(1)
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int_1(@c int) RETURNS INT WITH EXECUTE AS OWNER AS
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
SELECT babel_execute_as_caller_function_return_bigint()
GO

CREATE FUNCTION babel_execute_as_caller_function_return_int_1 (@v int) RETURNS INT WITH EXECUTE AS CALLER, RETURNS NULL ON NULL INPUT AS
BEGIN
    RETURN @v+1
END;
GO
SELECT babel_execute_as_caller_function_return_int_1(2)
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
CREATE PROCEDURE babel_execute_as_caller_procedure_1 WITH EXECUTE AS CALLER AS 
BEGIN SELECT * FROM babel_execute_as_caller_table END
GO
EXEC babel_execute_as_caller_procedure_1
GO

CREATE PROCEDURE babel_execute_as_caller_procedure_1 WITH EXECUTE AS OWNER AS 
BEGIN SELECT * FROM babel_execute_as_caller_table END
GO

CREATE PROCEDURE babel_execute_as_caller_procedure_2(@c int) WITH EXECUTE AS CALLER AS
BEGIN SELECT @c+1 END;
GO
EXEC babel_execute_as_caller_procedure_2 2
GO

CREATE PROCEDURE babel_execute_as_caller_procedure_2(@c int) WITH EXECUTE AS 'user' AS
BEGIN SELECT @c+1 END;
GO

CREATE PROCEDURE babel_execute_as_caller_procedure_3 (@v int) WITH EXECUTE AS CALLER AS 
BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
GO
EXEC babel_execute_as_caller_procedure_3 3
GO

-- trigger
CREATE TABLE babel_execute_as_caller_table_1 (c varchar(20));
GO
CREATE TRIGGER babel_execute_as_caller_trigger1 on babel_execute_as_caller_table AFTER INSERT AS INSERT INTO babel_execute_as_caller_table_1 values ('triggered');
GO
INSERT INTO babel_execute_as_caller_table values (2);
GO
SELECT * FROM babel_execute_as_caller_table_1;
GO

CREATE TRIGGER babel_execute_as_caller_trigger1 ON babel_execute_as_caller_table WITH EXECUTE AS OWNER
FOR INSERT AS BEGIN UPDATE babel_execute_as_caller_table SET c1 =10 END
GO
