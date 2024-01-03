-- parallel_query_expected
set babelfish_showplan_all on
GO

SELECT 1 AS [C1] FROM cast_eliminate  WHERE (CAST(ROID AS BIGINT) = 1)
GO

SELECT 1 AS [C1] FROM cast_eliminate  WHERE (CAST(ROID AS int) = 1)
GO

SELECT 1 AS [C1] FROM cast_eliminate  WHERE (ROID = cast(1 as bigint))
GO

SELECT 1 AS [C1] FROM cast_eliminate  WHERE (CAST(ROID AS BIGINT) = cast( 1 as bigint ))
GO

SELECT 1 AS [C1] FROM cast_eliminate2  WHERE (CAST(ROID AS BIGINT) = 1)
GO

SELECT 1 AS [C1] FROM cast_eliminate2  WHERE (CAST(ROID AS int) = 1)
GO

SELECT 1 AS [C1] FROM cast_eliminate2  WHERE (ROID = cast(1 as bigint))
GO

SELECT 1 AS [C1] FROM cast_eliminate  WHERE (CAST(ROID AS BIGINT) = cast( 1 as bigint ))
GO
