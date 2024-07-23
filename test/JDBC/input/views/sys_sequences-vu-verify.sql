SELECT * FROM sys.sequences
GO

SELECT * FROM sys_sequences_test_view
GO

EXEC sys_sequences_test_proc
GO

SELECT sys_sequences_test_func()
GO

SELECT
SCHEMA_NAME(seq.schema_id) AS [Schema],
seq.name AS [Name]
FROM
sys.sequences AS seq
ORDER BY
[Schema] ASC,[Name] ASC
GO