DROP FUNCTION babel_6814_func1;
GO

-- Drop extra tables created for consistent EXPLAIN plan behavior
DECLARE @i INT = 1;
DECLARE @sql NVARCHAR(200);
WHILE @i <= 100
BEGIN
    SET @sql = 'DROP TABLE babel_6814_extra_' + CONVERT(VARCHAR, @i);
    EXEC(@sql);
    SET @i = @i + 1;
END
GO

-- Drop extra schemas
DECLARE @j INT = 1;
DECLARE @sql2 NVARCHAR(200);
WHILE @j <= 500
BEGIN
    SET @sql2 = 'DROP SCHEMA babel_6814_schema_' + CONVERT(VARCHAR, @j);
    EXEC(@sql2);
    SET @j = @j + 1;
END
GO

DROP VIEW babel_6814_view1;
GO

DROP PROCEDURE babel_6814_proc1;
GO

DROP INDEX babel_6814_idx3 ON babel_6814_t2;
GO

DROP INDEX babel_6814_idx2 ON babel_6814_t1;
GO

DROP INDEX babel_6814_idx1 ON babel_6814_t1;
GO

DROP TABLE babel_6814_t2;
GO

DROP TABLE babel_6814_t1;
GO
