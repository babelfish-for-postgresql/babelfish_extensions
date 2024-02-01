-- Test for functions/procedures with multiple definitions
-- Multiple procedures with same name and equal number of parameters
CREATE PROC p492_1 @a INT, @b FLOAT AS
SELECT @a, @b;
GO

CREATE PROC p492_1 @a INT, @b DECIMAL AS
SELECT @a, @b;
GO

-- Multiple procedures with different number of parameters
CREATE PROC p492_2 @a INT AS -- Accepts 1 parameter
SELECT @a;
GO

CREATE PROC p492_2 @a INT, @b FLOAT, @c DECIMAL AS -- Accepts 3 parameters
SELECT @a, @b;
GO

-- Test for unique functions/procedures (Only one definition exists)
-- Procedure with no parameters
CREATE PROC p492_3 AS
SELECT 1;
GO

-- Some parameters not specified.
CREATE PROC p492_4 @a INT, @b FLOAT, @c DECIMAL AS
SELECT @a, @b, @c;
GO

-- Procedure with default parameters.
CREATE PROC p492_5 @a INT, @b FLOAT, @c INT = 3 AS
SELECT @a, @b, @c;
GO