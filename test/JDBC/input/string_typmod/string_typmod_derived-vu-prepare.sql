-- Objects live in their own database: a dbo function named like a built-in
-- (LEFT, CONCAT) takes precedence over the built-in in that database.
CREATE DATABASE string_typmod_derived_db
GO

USE string_typmod_derived_db
GO

CREATE TABLE dbo.t (v10 VARCHAR(10), v30 VARCHAR(30), n15 NVARCHAR(15))
GO

INSERT INTO dbo.t VALUES ('abcdefghij', 'abcdefghijklmnopqrstuvwxyz0123', N'abcdefghijklmno')
GO

CREATE FUNCTION dbo.short_udf (@p VARCHAR(30)) RETURNS VARCHAR(5) AS BEGIN RETURN @p END
GO

CREATE FUNCTION dbo.nshort_udf (@p NVARCHAR(30)) RETURNS NVARCHAR(3) AS BEGIN RETURN @p END
GO

-- user functions named like built-ins: no built-in length rule applies to them
CREATE FUNCTION dbo.[left] (@p VARCHAR(10), @n INT) RETURNS VARCHAR(MAX) AS BEGIN RETURN REPLICATE(@p, 3) END
GO

CREATE FUNCTION dbo.concat (@a VARCHAR(10), @b VARCHAR(10)) RETURNS VARCHAR(MAX) AS BEGIN RETURN REPLICATE(@a + @b, 2) END
GO

CREATE VIEW dbo.v AS SELECT dbo.short_udf(v30) AS s5, v10 + '-' + v30 AS c41 FROM dbo.t
GO

CREATE PROCEDURE dbo.p AS SELECT dbo.short_udf(v30) AS s5, dbo.[left](v10, 2) AS l FROM dbo.t
GO

USE master
GO
