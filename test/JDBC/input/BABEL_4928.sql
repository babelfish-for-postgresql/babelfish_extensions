-- UNIQUE CONSTRAINT ON TABLE VARIABLES
-- column constraint on tbale variable
DECLARE @babel_4928 TABLE(id int UNIQUE);
INSERT INTO @babel_4928 VALUES (NULL);
INSERT INTO @babel_4928 VALUES (NULL);
GO

-- multiple column constraint on table variable
DECLARE @babel_4928 TABLE(id int UNIQUE, id1 int UNIQUE, id2 INT PRIMARY KEY);
INSERT INTO @babel_4928 VALUES (NULL, 1, 2);
INSERT INTO @babel_4928 VALUES (NULL, 2, 20);
GO

DECLARE @babel_4928 TABLE(id int UNIQUE, id1 int UNIQUE, id2 INT PRIMARY KEY);
INSERT INTO @babel_4928 VALUES (1, NULL, 2);
INSERT INTO @babel_4928 VALUES (2, NULL, 20);
GO

DECLARE @babel_4928 TABLE(id int UNIQUE, id1 int UNIQUE, id2 INT PRIMARY KEY);
INSERT INTO @babel_4928 VALUES (1, 2, NULL);
INSERT INTO @babel_4928 VALUES (2, 1, NULL);
GO

-- table constraint on tbale variable
DECLARE @babel_4928 TABLE(id int , UNIQUE(id));
INSERT INTO @babel_4928 VALUES (NULL);
INSERT INTO @babel_4928 VALUES (NULL);
GO

-- UNIQUE CONSTRAINT ON TABLE RETURNING FUNCTIONS VARIABLES
-- column constraint on table returning funciton
CREATE FUNCTION babel_4928_f() RETURNS @babel_4928 TABLE(id INT UNIQUE)
AS
BEGIN
    INSERT INTO @babel_4928 VALUES (NULL);
    INSERT INTO @babel_4928 VALUES (NULL);
END
GO

SELECT * FROM babel_4928_f();
GO

DROP FUNCTION babel_4928_f
GO

-- table constraint on table returning funciton
CREATE FUNCTION babel_4928_f() RETURNS @babel_4928 TABLE(id INT, UNIQUE(id))
AS
BEGIN
    INSERT INTO @babel_4928 VALUES (NULL);
    INSERT INTO @babel_4928 VALUES (NULL);
END
GO

SELECT * FROM babel_4928_f();
GO

DROP FUNCTION babel_4928_f
GO

-- temp tables with unique column constraints
CREATE TABLE #babel_4928_temp_table (id INT UNIQUE);
GO
INSERT INTO #babel_4928_temp_table VALUES (NULL);
INSERT INTO #babel_4928_temp_table VALUES (NULL);
GO
DROP TABLE #babel_4928_temp_table
GO

-- temp tables with unique table constraints
CREATE TABLE #babel_4928_temp_table (id INT, UNIQUE(id));
GO
INSERT INTO #babel_4928_temp_table VALUES (NULL);
INSERT INTO #babel_4928_temp_table VALUES (NULL);
GO
DROP TABLE #babel_4928_temp_table
GO

-- test table type with uniqe constraint
CREATE TYPE babel_4928_table_type AS TABLE(id INT UNIQUE)
GO
CREATE TYPE babel_4928_table_type_2 AS TABLE(id INT, UNIQUE(id))
GO
DECLARE @babel_4928 babel_4928_table_type;
INSERT INTO @babel_4928 VALUES (NULL);
INSERT INTO @babel_4928 VALUES (NULL);
GO

-- multiple column constraint on table variable
DECLARE @babel_4928 babel_4928_table_type_2;
INSERT INTO @babel_4928 VALUES (NULL);
INSERT INTO @babel_4928 VALUES (NULL);
GO

DROP TYPE babel_4928_table_type
GO
DROP TYPE babel_4928_table_type_2
GO

-- SAME TESTS AS ABOVE BUT WITH TIMESTAMP TYPE SINCE WE HAVE DIFFERENT GRAMMER RULE FOR TIMESTAMP
sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion','ignore'
GO

DECLARE @babel_4928 TABLE(id TIMESTAMP UNIQUE);
INSERT INTO @babel_4928 VALUES (NULL);
INSERT INTO @babel_4928 VALUES (NULL);
GO

-- table constraint on tbale variable
DECLARE @babel_4928 TABLE(id TIMESTAMP , UNIQUE(id));
INSERT INTO @babel_4928 VALUES (NULL);
INSERT INTO @babel_4928 VALUES (NULL);
GO

-- UNIQUE CONSTRAINT ON TABLE RETURNING FUNCTIONS VARIABLES
-- column constraint on table returning funciton
CREATE FUNCTION babel_4928_f() RETURNS @babel_4928 TABLE(id TIMESTAMP UNIQUE)
AS
BEGIN
    INSERT INTO @babel_4928 VALUES (NULL);
    INSERT INTO @babel_4928 VALUES (NULL);
END
GO

SELECT * FROM babel_4928_f();
GO

DROP FUNCTION babel_4928_f
GO

-- table constraint on table returning funciton
CREATE FUNCTION babel_4928_f() RETURNS @babel_4928 TABLE(id TIMESTAMP, UNIQUE(id))
AS
BEGIN
    INSERT INTO @babel_4928 VALUES (NULL);
    INSERT INTO @babel_4928 VALUES (NULL);
END
GO

SELECT * FROM babel_4928_f();
GO

DROP FUNCTION babel_4928_f
GO

-- temp tables with unique column constraints
CREATE TABLE #babel_4928_temp_table (id TIMESTAMP UNIQUE);
GO

-- temp tables with unique table constraints
CREATE TABLE #babel_4928_temp_table (id TIMESTAMP, UNIQUE(id));
GO


-- without UNIQUE keyword in sql to check if parser conditions are written properly

-- column constraint on tbale variable
DECLARE @babel_4928 TABLE(id int PRIMARY KEY);
INSERT INTO @babel_4928 VALUES (NULL);
INSERT INTO @babel_4928 VALUES (NULL);
GO

-- table constraint on tbale variable
DECLARE @babel_4928 TABLE(id int , PRIMARY KEY(id));
INSERT INTO @babel_4928 VALUES (NULL);
INSERT INTO @babel_4928 VALUES (NULL);
GO

-- column constraint on table returning funciton
CREATE FUNCTION babel_4928_f() RETURNS @babel_4928 TABLE(id INT PRIMARY KEY)
AS
BEGIN
    INSERT INTO @babel_4928 VALUES (NULL);
    INSERT INTO @babel_4928 VALUES (NULL);
END
GO

SELECT * FROM babel_4928_f();
GO

DROP FUNCTION babel_4928_f
GO

-- table constraint on table returning funciton
CREATE FUNCTION babel_4928_f() RETURNS @babel_4928 TABLE(id INT, PRIMARY KEY(id))
AS
BEGIN
    INSERT INTO @babel_4928 VALUES (NULL);
    INSERT INTO @babel_4928 VALUES (NULL);
END
GO

SELECT * FROM babel_4928_f();
GO

DROP FUNCTION babel_4928_f
GO

-- temp tables with PRIMARY KEY column constraints
CREATE TABLE #babel_4928_temp_table (id INT PRIMARY KEY);
GO
INSERT INTO #babel_4928_temp_table VALUES (NULL);
INSERT INTO #babel_4928_temp_table VALUES (NULL);
GO
DROP TABLE #babel_4928_temp_table
GO

-- temp tables with PRIMARY KEY table constraints
CREATE TABLE #babel_4928_temp_table (id INT, PRIMARY KEY(id));
GO
INSERT INTO #babel_4928_temp_table VALUES (NULL);
INSERT INTO #babel_4928_temp_table VALUES (NULL);
GO
DROP TABLE #babel_4928_temp_table
GO

-- test table type with PRIMARY KEY
CREATE TYPE babel_4928_table_type AS TABLE(id INT PRIMARY KEY)
GO
CREATE TYPE babel_4928_table_type_2 AS TABLE(id INT, PRIMARY KEY(id))
GO
DECLARE @babel_4928 babel_4928_table_type;
INSERT INTO @babel_4928 VALUES (NULL);
GO

-- column constraint on table variable
DECLARE @babel_4928 babel_4928_table_type_2;
INSERT INTO @babel_4928 VALUES (NULL);
GO

DROP TYPE babel_4928_table_type
GO
DROP TYPE babel_4928_table_type_2
GO
