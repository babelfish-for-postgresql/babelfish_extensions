-- parallel_query_expected
EXEC sp_babelfish_configure 'babelfishpg_tsql.explain_costs', 'off'
EXEC sp_babelfish_configure 'babelfishpg_tsql.explain_timing', 'off'
EXEC sp_babelfish_configure 'babelfishpg_tsql.explain_summary', 'off'

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

SELECT 1 AS [C1] FROM cast_eliminate WHERE (CAST(ROID AS BIGINT) = 1) OR (CAST(ROID AS BIGINT) = 2)
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE (CAST(ROID AS BIGINT) = 1) AND (CAST(s_int AS BIGINT) = 2)
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE 1 = (CAST(ROID AS BIGINT))
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(CAST(ROID AS BIGINT) as INT) = 1
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(s_int AS INT) = 1
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(CAST(s_int AS BIGINT) as INT) = 1
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(CAST(CAST(s_int AS BIGINT) as INT) as SMALLINT) = 1
GO

-- NOT clause supported
SELECT 1 AS [C1] FROM cast_eliminate WHERE b_int = 10 AND NOT ((CAST(CAST(CAST(s_int AS BIGINT) as INT) as SMALLINT) = 1 OR CAST(ROID AS BIGINT) > 10) AND ROID NOT IN (12, 34))
GO

-- Bad case: cannot remove CAST if a column is typecasted into a type with less precision
SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(CAST(ROID AS BIGINT) as SMALLINT) = 1
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(CAST(ROID AS SMALLINT) as BIGINT) = 1
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(b_int AS BIGINT) = 1
GO

-- Bad case: cannot remove CAST if a column is typecasted into a type with less precision
SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(b_int AS INT) = 1
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(CAST(ROID AS BIGINT) as SMALLINT) = CAST(s_int AS INT)
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE CAST(CAST(ROID AS numeric) as int) = 1
GO

-- Other operators like >/</<=/>= are also supported
SELECT 1 AS [C1] FROM cast_eliminate WHERE (CAST(ROID AS BIGINT) < 1) OR (CAST(ROID AS BIGINT) > 2)
GO

SELECT 1 AS [C1] FROM cast_eliminate WHERE (CAST(ROID AS BIGINT) >= 1) AND (CAST(ROID AS BIGINT) <= 2)
GO

set babelfish_showplan_all off
GO

-- Verify executions
INSERT INTO cast_eliminate VALUES (1, 1, 1), (2, 2938, 2), (3, 32767, 9223372036854775807), (-2147483648, -32768, -9223372036854775808), (2147483647, 2393, 1111111111111111);
GO

set BABELFISH_STATISTICS PROFILE on
GO

-- Operators like !=/<> cannot make use of index, so we don't bother to elimiate the unnecessary CAST
SELECT * FROM cast_eliminate WHERE (CAST(CAST(ROID AS BIGINT) AS BIGINT) = 3 OR CAST(CAST(ROID AS INT) AS BIGINT) = 2147483647) AND CAST(CAST(s_int AS INT) AS BIGINT) != 32767
GO

SELECT * FROM cast_eliminate WHERE CAST(CAST(s_int AS INT) AS BIGINT) >= 2394 AND CAST(CAST(ROID AS BIGINT) AS SMALLINT) >= 3
GO

SELECT * FROM cast_eliminate WHERE -32768 = CAST(s_int AS INT);
GO

SELECT * FROM cast_eliminate WHERE -32768 = CAST(CAST(s_int AS INT) AS BIGINT);
GO

SELECT * FROM cast_eliminate WHERE -32768 < CAST(CAST(s_int AS INT) AS BIGINT) OR CAST(ROID AS BIGINT) = -2147483648
GO

SELECT * FROM cast_eliminate WHERE -9223372036854775808 = CAST(s_int AS BIGINT)
GO

-- Throws an error due to overflow. If we wrongly eliminate the CAST function, the error won't be thrown
SELECT * FROM cast_eliminate WHERE -32768 < CAST(CAST(s_int AS INT) AS BIGINT) OR -9223372036854775808 = CAST(CAST(b_int AS BIGINT) AS INT)
GO
