/* Test a variety of normal/pg datatypes */
CREATE TABLE #temp_1(
	a int,
	b date,
	c varchar,
	d text,
	e json,
	f xml
)
GO

/* Test a variety of babelfish-specific datatypes */
CREATE TABLE #temp_2(
	a sysname,
	b datetime,
	c datetime2,
	d nchar,
	e nvarchar,
	f varbinary,
	g numeric,
	h smallmoney, 
	i money
)
GO

/* Test user-created datatypes */
CREATE TYPE typa FROM int
GO

CREATE TYPE typb FROM nvarchar(100)
GO

CREATE TABLE #temp_3(
	a typa,
	b typb
)
GO

DROP TYPE typb
GO

DROP TYPE typa
GO

DROP TABLE #temp_3
DROP TYPE typb
GO

DROP TYPE typa
GO

/* Test computed columns */
CREATE TABLE #temp_3_5(
	a int,
	b as a + 1)
GO

INSERT INTO #temp_3_5(a) VALUES (1)
GO

SELECT * FROM #temp_3_5
GO

DROP TABLE #temp_3_5
GO


/* Test SELECT INTO */
CREATE TYPE typc FROM nchar
GO

CREATE TABLE tab_1 (a int, b typc)
GO

INSERT INTO tab_1 VALUES (1, 'a')
GO

SELECT * INTO #temp_4 FROM tab_1
GO

SELECT * FROM #temp_4
GO

DROP TYPE typc
GO

DROP TABLE tab_1
GO

DROP TABLE #temp_4
GO

DROP TYPE typc
GO

/* Test Ownership + Roles, for pg_shdepend */
CREATE ROLE role_a
GO

CREATE TABLE #temp_5 (a int)
GO

GRANT ALL ON #temp_5 TO role_a
GO

DROP ROLE role_a
GO

DROP TABLE #temp_5
GO

DROP ROLE role_a
GO
