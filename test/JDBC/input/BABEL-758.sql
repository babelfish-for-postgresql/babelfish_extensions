CREATE PROCEDURE babel_758_set_stmt
@how_many INT OUT
AS
BEGIN
  SET @how_many = POWER(2, 23) - POWER(2, 3);
END
GO

-- original issue: bigint
DECLARE @ret bigint;
EXECUTE babel_758_set_stmt @ret OUTPUT;
SELECT @ret;
GO

-- double precision
DECLARE @ret double precision;
EXECUTE babel_758_set_stmt @ret OUTPUT;
SELECT @ret;
GO

-- real
DECLARE @ret real;
EXECUTE babel_758_set_stmt @ret OUTPUT;
SELECT @ret;
GO

-- decimal
DECLARE @ret decimal;
EXECUTE babel_758_set_stmt @ret OUTPUT;
SELECT @ret;
GO

-- smallint
DECLARE @ret smallint;
EXECUTE babel_758_set_stmt @ret OUTPUT;
SELECT @ret;
GO

-- tinyint
DECLARE @ret tinyint;
EXECUTE babel_758_set_stmt @ret OUTPUT;
SELECT @ret;
GO


CREATE TABLE [babel_758_employees] (a int);
INSERT INTO [babel_758_employees] values (1), (2), (3), (4), (5), (6), (7), (8), (9);
INSERT INTO [babel_758_employees] SELECT * FROM [babel_758_employees];
INSERT INTO [babel_758_employees] SELECT * FROM [babel_758_employees];
INSERT INTO [babel_758_employees] SELECT * FROM [babel_758_employees];
INSERT INTO [babel_758_employees] SELECT * FROM [babel_758_employees];
INSERT INTO [babel_758_employees] SELECT * FROM [babel_758_employees];
GO

CREATE PROCEDURE babel_758_p_employee_count
@how_many INT OUT
AS
BEGIN
  SELECT @how_many = COUNT(*) from [babel_758_employees];
END
GO

-- original issue: bigint
DECLARE @ret bigint;
EXECUTE babel_758_p_employee_count @ret OUTPUT;
SELECT @ret;
GO

-- double precision
DECLARE @ret double precision;
EXECUTE babel_758_p_employee_count @ret OUTPUT;
SELECT @ret;
GO

-- real
DECLARE @ret real;
EXECUTE babel_758_p_employee_count @ret OUTPUT;
SELECT @ret;
GO

-- decimal
DECLARE @ret decimal;
EXECUTE babel_758_p_employee_count @ret OUTPUT;
SELECT @ret;
GO

-- smallint
DECLARE @ret smallint;
EXECUTE babel_758_p_employee_count @ret OUTPUT;
SELECT @ret;
GO

-- tinyint
DECLARE @ret tinyint;
EXECUTE babel_758_p_employee_count @ret OUTPUT;
SELECT @ret;
GO

DROP PROCEDURE babel_758_set_stmt;
DROP PROCEDURE babel_758_p_employee_count;
DROP TABLE babel_758_employees;
