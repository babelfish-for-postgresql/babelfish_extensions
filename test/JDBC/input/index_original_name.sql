CREATE TABLE index_original_name_t1(id INT, name VARCHAR);
GO

CREATE PROCEDURE index_original_name_p1 AS
	CREATE INDEX index_original_name_i1 ON index_original_name_t1(id);
	SELECT name FROM sys.indexes WHERE name LIKE 'index_original_name_%';
	DROP INDEX index_original_name_i1 ON index_original_name_t1;
GO

EXEC index_original_name_p1;
GO
EXEC index_original_name_p1;
GO
EXEC index_original_name_p1;
GO
EXEC index_original_name_p1;
GO

DECLARE @handle int;
DECLARE @batch NVARCHAR(500);
SET @batch = '
CREATE INDEX index_original_name_i1 ON index_original_name_t1(id);
SELECT name FROM sys.indexes WHERE name LIKE ''index_original_name_%'';
DROP INDEX index_original_name_i1 ON index_original_name_t1;
'
EXEC SP_PREPARE @handle OUT, NULL, @batch
EXEC SP_EXECUTE @handle
EXEC SP_EXECUTE @handle
EXEC SP_EXECUTE @handle
EXEC SP_EXECUTE @handle
GO

DROP PROCEDURE index_original_name_p1;
GO
DROP TABLE index_original_name_t1;
GO
