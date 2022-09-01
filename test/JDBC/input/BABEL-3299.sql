SELECT COUNT(*) FROM ::fn_helpcollations() where [Name] = DATABASEPROPERTYEX(DB_NAME(), 'Collation')
GO

SELECT * FROM ::isnull(NULL, 0)
GO

SELECT * FROM isnull(NULL, 0)
GO

SELECT * FROM ::
GO

CREATE TABLE t3299 (a int);
GO

/* Should throw a syntax error */
CREATE TRIGGER t1
ON t3299
AFTER UPDATE
AS
IF (::UPDATE(a))
BEGIN
RAISERROR(0, 0, 0)
END;
GO

DROP TABLE t3299;
GO
