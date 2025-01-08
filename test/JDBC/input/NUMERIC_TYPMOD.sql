-- T_Var (Variable reference)
DECLARE @num1 NUMERIC(10,4) = 1234.5678;
DECLARE @dec1 DECIMAL(12,2) = 9876.54;

SELECT CASE 
    WHEN 1 = 1 THEN @num1 
    ELSE @dec1 
END AS result;
GO

-- T_Const (Constant value)
SELECT CASE 1
    WHEN 1 THEN CAST(1234.5678 AS NUMERIC(10,4))
    WHEN 2 THEN CAST(9876.54 AS DECIMAL(12,2))
    ELSE CAST(0 AS DECIMAL(9,4))
END AS result;
GO

-- T_SubscriptingRef (Array or json subscripting)
DECLARE @jsonVar NVARCHAR(MAX) = N'{"a": 123.45, "b": 678.90}';
SELECT CASE 
    WHEN 1 = 1 THEN CAST(JSON_VALUE(@jsonVar, '$.a') AS NUMERIC(10,2))
    ELSE CAST(JSON_VALUE(@jsonVar, '$.b') AS DECIMAL(10,2))
END AS result;
GO

-- T_NamedArgExpr (Named argument in a function call)
CREATE FUNCTION dbo.TestNamedArg (@param1 NUMERIC(10,4) = 0, @param2 DECIMAL(12,2) = 0)
RETURNS DECIMAL(15,4)
AS
BEGIN
    RETURN CASE 
        WHEN 1 = 1 THEN @param1 
        ELSE @param2 
    END;
END;
GO

SELECT dbo.TestNamedArg(1234.56, 7890.1234) AS result;
GO

DROP FUNCTION dbo.TestNamedArg
GO

-- T_NullIfExpr (NULLIF expression)
SELECT CASE 
    WHEN 1 = 1 THEN NULLIF(CAST(1234.56 AS NUMERIC(10,2)), CAST(1234.56 AS DECIMAL(12,2)))
    ELSE CAST(9999.99 AS DECIMAL(10,2))
END AS result;
GO

-- T_SubLink (Subquery expressions)
SELECT CASE 
    WHEN 1 = 1 THEN (SELECT AVG(CAST(1234.56 AS NUMERIC(10,2))))
    ELSE CAST(9876.54 AS DECIMAL(12,2))
END AS result;
GO

-- T_SubPlan (Subplan expression)
SELECT CASE 
    WHEN 1 = 1 THEN (SELECT TOP 1 CAST(1234.56 AS NUMERIC(10,2)) WHERE 1=1)
    ELSE CAST(9876.54 AS DECIMAL(12,2))
END AS result;
GO

-- T_AlternativeSubPlan (Alternative subplan)
SELECT CASE 
    WHEN 1 = 1 THEN (
        SELECT CAST(1234.56 AS NUMERIC(10,2)) WHERE 1=1
        UNION ALL
        SELECT CAST(9876.54 AS DECIMAL(12,2)) WHERE 1=0
    )
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- T_FieldSelect (Field selection)
DECLARE @myTable TABLE (id INT, num_col NUMERIC(10,2), dec_col DECIMAL(12,2));
INSERT INTO @myTable VALUES (1, 1234.56, 7890.12);
SELECT CASE 
    WHEN 1 = 1 THEN t.num_col 
    ELSE t.dec_col 
END AS result
FROM @myTable t;
GO

-- T_RelabelType (Relabel Type)
SELECT CASE 
    WHEN 1 = 1 THEN CAST(CAST(1234.56 AS NUMERIC(10,2)) AS DECIMAL(12,2))
    ELSE CAST(9876.54 AS NUMERIC(10,2))
END AS result;
GO

-- T_ArrayCoerceExpr (Array Coerce Expression)
DECLARE @myArray TABLE (val NUMERIC(10,2));
INSERT INTO @myArray VALUES (1234.56), (7890.12), (5678.90);

SELECT CASE 
    WHEN 1 = 1 THEN CAST(val AS DECIMAL(12,2))
    ELSE val
END AS result
FROM @myArray;
GO

-- T_CollateExpr (Collate Expression)
SELECT CASE 
    WHEN 1 = 1 THEN CAST(1234.56 AS NUMERIC(10,2)) COLLATE Latin1_General_CI_AS
    ELSE CAST(9876.54 AS DECIMAL(12,2))
END AS result;
GO

-- T_CaseExpr (Nested CASE expression)
SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN 9876.54 > 5000 THEN CAST(9876.54 AS DECIMAL(12,2))
            ELSE CAST(1234.56 AS NUMERIC(10,2))
        END
    ELSE CAST(5678.90 AS DECIMAL(10,2))
END AS result;
GO

-- T_CaseTestExpr (CASE test expression)
SELECT CASE 3
   WHEN 1 THEN CAST(99999.9999 AS DECIMAL(9,4))
   WHEN 2 THEN CAST(999999.999 AS NUMERIC(9,3))
   WHEN 3 THEN CAST(9999999.99 AS DECIMAL(9,2))
   ELSE CAST(0 AS DECIMAL(9,4))
END AS RESULT;
GO

-- T_CoalesceExpr (COALESCE expression)
SELECT CASE 
    WHEN 1 = 1 THEN COALESCE(CAST(NULL AS NUMERIC(10,2)), CAST(1234.56 AS DECIMAL(12,2)), CAST(7890.12 AS NUMERIC(10,2)))
    ELSE CAST(1111.11 AS NUMERIC(10,2))
END AS result;
GO

-- T_MinMaxExpr (GREATEST and LEAST expressions)
SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN CAST(1234.56 AS NUMERIC(10,2)) > CAST(7890.12 AS DECIMAL(12,2)) 
            THEN CAST(1234.56 AS NUMERIC(10,2))
            ELSE CAST(7890.12 AS DECIMAL(12,2))
        END
    ELSE CAST(0 AS DECIMAL(12,2))
END AS greatest_result;
GO

-- T_JsonValueExpr (JSON Value Expression)
DECLARE @json NVARCHAR(MAX) = N'{"value": 1234.56}';
SELECT CASE 
    WHEN 1 = 1 THEN CAST(JSON_VALUE(@json, '$.value') AS DECIMAL(10,2))
    ELSE CAST(1111.11 AS NUMERIC(10,2))
END AS result;
GO

-- T_JsonConstructorExpr (JSON Constructor Expression)
SELECT CASE 
    WHEN 1 = 1 THEN CAST(JSON_VALUE(JSON_MODIFY('{}', '$.num', CAST(1234.56 AS NUMERIC(10,2))), '$.num') AS DECIMAL(10,3))
    ELSE CAST(1111.11 AS NUMERIC(10,2))
END AS result;
GO

-- T_CoerceToDomain (Coerce to Domain)
CREATE TABLE dbo.MyDomainTable (
    id INT PRIMARY KEY,
    value DECIMAL(10,2) CHECK (value BETWEEN 0 AND 10000)
);

INSERT INTO dbo.MyDomainTable (id, value) 
SELECT 1, CASE 
    WHEN 1 = 1 THEN CAST(1234.56 AS NUMERIC(10,2))
    ELSE CAST(9999.99 AS DECIMAL(10,2))
END;

SELECT * FROM dbo.MyDomainTable;
GO

DROP TABLE dbo.MyDomainTable;
GO

-- T_CoerceToDomainValue (Coerce to Domain Value)
SELECT CASE 
    WHEN 1 = 1 THEN CAST(1234.56 AS NUMERIC(10,2))
    ELSE CAST(9999.99 AS DECIMAL(10,2))
END AS result;
GO

-- T_SetToDefault (Set to Default)
CREATE TABLE dbo.DefaultTable (
    id INT PRIMARY KEY,
    num_col NUMERIC(10,2) DEFAULT 100.00,
    dec_col DECIMAL(12,2) DEFAULT 200.00
);

INSERT INTO dbo.DefaultTable (id, num_col, dec_col)
VALUES (1, DEFAULT, DEFAULT);

SELECT CASE 
    WHEN 1 = 1 THEN num_col
    ELSE dec_col
END AS result
FROM dbo.DefaultTable;
GO

DROP TABLE dbo.DefaultTable;
GO

-- T_PlaceHolderVar (Placeholder Variable)
WITH cte AS (
    SELECT CAST(1234.56 AS NUMERIC(10,2)) AS num_val, CAST(7890.12 AS DECIMAL(12,2)) AS dec_val
)
SELECT CASE 
    WHEN 1 = 1 THEN num_val 
    ELSE dec_val 
END AS result
FROM cte;
GO

-- For union
-- T_Var (Variable reference)
DECLARE @num1 NUMERIC(10,4) = 1234.5678;
DECLARE @dec1 DECIMAL(12,2) = 9876.54;
SELECT @num1 AS result
UNION ALL
SELECT @dec1
ORDER BY result;
GO

-- T_Const (Constant value)
SELECT CAST(1234.5678 AS NUMERIC(10,4)) AS result
UNION ALL
SELECT CAST(9876.54 AS DECIMAL(12,2))
UNION ALL
SELECT CAST(0 AS DECIMAL(9,4))
ORDER BY result;
GO

-- T_SubscriptingRef (Array or json subscripting)
DECLARE @jsonVar NVARCHAR(MAX) = N'{"a": 123.45, "b": 678.90}';
SELECT CAST(JSON_VALUE(@jsonVar, '$.a') AS NUMERIC(10,2)) AS result
UNION ALL
SELECT CAST(JSON_VALUE(@jsonVar, '$.b') AS DECIMAL(10,2))
ORDER BY result;
GO

-- T_NullIfExpr (NULLIF expression)
SELECT NULLIF(CAST(1234.56 AS NUMERIC(10,2)), CAST(1234.56 AS DECIMAL(12,2))) AS result
UNION ALL
SELECT CAST(9999.99 AS DECIMAL(10,2))
ORDER BY result;
GO

-- T_SubLink (Subquery expressions)
SELECT (SELECT AVG(CAST(1234.56 AS NUMERIC(10,2)))) AS result
UNION ALL
SELECT CAST(9876.54 AS DECIMAL(12,2))
ORDER BY result;
GO

-- T_SubPlan (Subplan expression)
SELECT (SELECT TOP 1 CAST(1234.56 AS NUMERIC(10,2)) WHERE 1=1) AS result
UNION ALL
SELECT CAST(9876.54 AS DECIMAL(12,2))
ORDER BY result;
GO

-- T_AlternativeSubPlan (Alternative subplan)
SELECT CAST(1234.56 AS NUMERIC(10,2)) AS result WHERE 1=1
UNION ALL
SELECT CAST(9876.54 AS DECIMAL(12,2)) WHERE 1=1
UNION ALL
SELECT CAST(0 AS DECIMAL(12,2))
ORDER BY result;
GO

-- T_FieldSelect (Field selection)
DECLARE @myTable TABLE (id INT, num_col NUMERIC(10,2), dec_col DECIMAL(12,2));
INSERT INTO @myTable VALUES (1, 1234.56, 7890.12);
SELECT t.num_col AS result
FROM @myTable t
UNION ALL
SELECT t.dec_col
FROM @myTable t
ORDER BY result;
GO



-- T_RelabelType (Relabel Type)
SELECT CAST(CAST(1234.56 AS NUMERIC(10,2)) AS DECIMAL(12,2)) AS result
UNION ALL
SELECT CAST(9876.54 AS NUMERIC(10,2))
ORDER BY result;
GO

-- T_ArrayCoerceExpr (Array Coerce Expression)
DECLARE @myArray TABLE (val NUMERIC(10,2));
INSERT INTO @myArray VALUES (1234.56), (7890.12), (5678.90);
SELECT CAST(val AS DECIMAL(12,2)) AS result
FROM @myArray
UNION ALL
SELECT val
FROM @myArray
ORDER BY result;
GO

-- T_CollateExpr (Collate Expression)
SELECT CAST(1234.56 AS NUMERIC(10,2)) COLLATE Latin1_General_CI_AS AS result
UNION ALL
SELECT CAST(9876.54 AS DECIMAL(12,2))
ORDER BY result;
GO

-- T_CaseExpr (Nested CASE expression)
SELECT CASE 
    WHEN 9876.54 > 5000 THEN CAST(9876.54 AS DECIMAL(12,2))
    ELSE CAST(1234.56 AS NUMERIC(10,2))
END AS result
UNION ALL
SELECT CAST(5678.90 AS DECIMAL(10,2))
ORDER BY result;
GO

-- T_CaseTestExpr (CASE test expression)
SELECT CAST(99999.9999 AS DECIMAL(9,4)) AS result
UNION ALL
SELECT CAST(999999.999 AS NUMERIC(9,3))
UNION ALL
SELECT CAST(9999999.99 AS DECIMAL(9,2))
UNION ALL
SELECT CAST(0 AS DECIMAL(9,4))
ORDER BY result;
GO

-- T_ArrayExpr (Array constructor)
SELECT v
FROM (VALUES (CAST(1234.56 AS DECIMAL(12,2))), (CAST(7890.12 AS NUMERIC(10,2)))) AS t(v)
UNION ALL
SELECT CAST(1111.11 AS NUMERIC(10,2))
ORDER BY v;
GO

-- T_CoalesceExpr (COALESCE expression)
SELECT COALESCE(CAST(NULL AS NUMERIC(10,2)), CAST(1234.56 AS DECIMAL(12,2)), CAST(7890.12 AS NUMERIC(10,2))) AS result
UNION ALL
SELECT CAST(1111.11 AS NUMERIC(10,2))
ORDER BY result;
GO

-- T_MinMaxExpr (GREATEST and LEAST expressions)
SELECT CASE 
    WHEN CAST(1234.56 AS NUMERIC(10,2)) > CAST(7890.12 AS DECIMAL(12,2)) 
    THEN CAST(1234.56 AS NUMERIC(10,2))
    ELSE CAST(7890.12 AS DECIMAL(12,2))
END AS result
UNION ALL
SELECT CAST(0 AS DECIMAL(12,2))
ORDER BY result;
GO

-- T_JsonValueExpr (JSON Value Expression)
DECLARE @json NVARCHAR(MAX) = N'{"value": 1234.56}';
SELECT CAST(JSON_VALUE(@json, '$.value') AS DECIMAL(10,2)) AS result
UNION ALL
SELECT CAST(1111.11 AS NUMERIC(10,2))
ORDER BY result;
GO

-- T_JsonConstructorExpr (JSON Constructor Expression)
SELECT CASE 
    WHEN 1 = 1 THEN CAST(JSON_VALUE(JSON_MODIFY('{}', '$.num', CAST(1234.56 AS NUMERIC(10,2))), '$.num') AS DECIMAL(10,2))
    ELSE CAST(1111.11 AS NUMERIC(10,2))
END AS result;
GO

-- T_CoerceToDomain (Coerce to Domain)
CREATE TABLE dbo.MyDomainTable (
    id INT PRIMARY KEY,
    value DECIMAL(10,2) CHECK (value BETWEEN 0 AND 10000)
);

INSERT INTO dbo.MyDomainTable (id, value) 
VALUES (1, CAST(1234.56 AS NUMERIC(10,2)));

SELECT value AS result FROM dbo.MyDomainTable
UNION ALL
SELECT CAST(9999.99 AS DECIMAL(10,2))
ORDER BY result;
GO

DROP TABLE dbo.MyDomainTable;
GO

-- T_CoerceToDomainValue (Coerce to Domain Value)
SELECT CAST(1234.56 AS NUMERIC(10,2)) AS result
UNION ALL
SELECT CAST(9999.99 AS DECIMAL(10,2))
ORDER BY result;
GO

-- T_SetToDefault (Set to Default)
CREATE TABLE dbo.DefaultTable (
    id INT PRIMARY KEY,
    num_col NUMERIC(10,2) DEFAULT 100.00,
    dec_col DECIMAL(12,2) DEFAULT 200.00
);

INSERT INTO dbo.DefaultTable (id, num_col, dec_col)
VALUES (1, DEFAULT, DEFAULT);

SELECT num_col AS result
FROM dbo.DefaultTable
UNION ALL
SELECT dec_col
FROM dbo.DefaultTable
ORDER BY result;
GO

DROP TABLE dbo.DefaultTable;
GO

-- T_PlaceHolderVar (Placeholder Variable)
WITH cte AS (
    SELECT CAST(1234.56 AS NUMERIC(10,2)) AS num_val, CAST(7890.12 AS DECIMAL(12,2)) AS dec_val
)
SELECT num_val AS result
FROM cte
UNION ALL
SELECT dec_val
FROM cte
ORDER BY result;
GO

-- Test Case 1: Basic T_SubPlan in CASE
SELECT CASE 
    WHEN 1 = 1 THEN (SELECT CAST(1234.5678 AS NUMERIC(10,4)))
    ELSE (SELECT CAST(9876.54 AS DECIMAL(12,2)))
END AS result;
GO

-- Test Case 2: T_SubPlan with different precisions and scales
SELECT CASE 
    WHEN (SELECT value FROM (VALUES (1), (2), (3)) AS t(value) WHERE value = 2) = 2 
    THEN (SELECT CAST(123456.789 AS NUMERIC(9,3)))
    ELSE (SELECT CAST(987.654321 AS DECIMAL(12,6)))
END AS result;
GO

-- Test Case 3: T_SubPlan with aggregation
SELECT CASE 
    WHEN (SELECT AVG(value) FROM (VALUES (1), (2), (3)) AS t(value)) > 1
    THEN (SELECT SUM(value) FROM (VALUES (10.1), (20.2), (30.3)) AS t(value))
    ELSE (SELECT AVG(value) FROM (VALUES (1.1), (2.2), (3.3)) AS t(value))
END AS result;
GO

-- Test Case 4: Multiple T_SubPlans in one CASE
SELECT CASE 
    WHEN (SELECT CAST(1000.00 AS NUMERIC(10,2))) > 
         (SELECT CAST(999.99 AS DECIMAL(10,2)))
    THEN (SELECT MAX(value) FROM (VALUES (1), (2), (3)) AS t(value))
    ELSE (SELECT MIN(value) FROM (VALUES (4), (5), (6)) AS t(value))
END AS result;
GO

-- Test Case 5: Nested CASE with T_SubPlan
SELECT CASE 
    WHEN (SELECT CAST(100 AS NUMERIC(10,0))) > 50
    THEN 
        CASE
            WHEN (SELECT CAST(5.25 AS DECIMAL(5,2))) < 10
            THEN (SELECT AVG(value) FROM (VALUES (1.1111), (2.2222), (3.3333)) AS t(value))
            ELSE (SELECT AVG(value) FROM (VALUES (4.444444), (5.555555), (6.666666)) AS t(value))
        END
    ELSE (SELECT CAST(1000.00 AS NUMERIC(12,2)))
END AS result;
GO

-- Test Case 6: T_SubPlan with arithmetic operations
SELECT CASE 
    WHEN 1 = 1 
    THEN (SELECT CAST(1000.00 AS NUMERIC(10,2)) / 2)
    ELSE (SELECT CAST(500.5555 AS DECIMAL(8,4)) * 3)
END AS result;
GO

-- Test Case 8: T_SubPlan with multiple values
SELECT CASE 
    WHEN (SELECT value FROM (VALUES (1.23), (4.56), (7.89)) AS t(value) WHERE value = 4.56) = 4.56
    THEN (SELECT CAST(123.456 AS NUMERIC(10,3)))
    ELSE (SELECT CAST(789.012 AS DECIMAL(10,3)))
END AS result;
GO

-- Test Case 10: T_SubPlan with conditional aggregation
SELECT CASE 
    WHEN EXISTS (
        SELECT 1 FROM (VALUES (1), (2), (3)) AS t(value)
        WHERE value > 2
    )
    THEN (
        SELECT AVG(CAST(value AS DECIMAL(10,4)))
        FROM (VALUES (10.1111), (20.2222), (30.3333)) AS t(value)
        WHERE value > 15
    )
    ELSE CAST(0 AS DECIMAL(10,4))
END AS result;
GO

-- Test Case 1: Basic GREATEST simulation in CASE
SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN CAST(1234.5678 AS NUMERIC(10,4)) > CAST(9876.54 AS DECIMAL(12,2))
            THEN CAST(1234.5678 AS NUMERIC(10,4))
            ELSE CAST(9876.54 AS DECIMAL(12,2))
        END
    ELSE CAST(0 AS DECIMAL(12,4))
END AS result;
GO

-- Test Case 2: LEAST simulation with different precisions and scales
SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN CAST(123.456 AS NUMERIC(6,3)) < CAST(789.12 AS DECIMAL(8,2))
            THEN CAST(123.456 AS NUMERIC(6,3))
            ELSE CAST(789.12 AS DECIMAL(8,2))
        END
    ELSE CAST(999.999 AS DECIMAL(6,3))
END AS result;
GO

-- Test Case 3: GREATEST with multiple values
SELECT CASE 
    WHEN 1 = 1 THEN 
        (SELECT MAX(v) FROM (VALUES 
            (CAST(1234.56 AS NUMERIC(10,2))),
            (CAST(7890.12 AS DECIMAL(12,2))),
            (CAST(4567.89 AS NUMERIC(8,2)))
        ) AS value(v))
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 4: LEAST with multiple values and different scales
SELECT CASE 
    WHEN 1 = 1 THEN 
        (SELECT MIN(v) FROM (VALUES 
            (CAST(123.4567 AS NUMERIC(10,4))),
            (CAST(789.12 AS DECIMAL(8,2))),
            (CAST(456.789 AS NUMERIC(6,3)))
        ) AS value(v))
    ELSE CAST(999.9999 AS DECIMAL(10,4))
END AS result;
GO

-- Test Case 5: GREATEST with arithmetic operations
SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN CAST(1234.56 AS NUMERIC(10,2)) * 2 > CAST(9876.54 AS DECIMAL(12,2)) / 2
            THEN CAST(1234.56 AS NUMERIC(10,2)) * 2
            ELSE CAST(9876.54 AS DECIMAL(12,2)) / 2
        END
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 6: LEAST with NULL values
SELECT CASE 
    WHEN 1 = 1 THEN 
        (SELECT MIN(v) FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(NULL AS DECIMAL(12,2))),
            (CAST(789.12 AS NUMERIC(8,2)))
        ) AS value(v))
    ELSE CAST(999.99 AS DECIMAL(10,2))
END AS result;
GO

-- Test Case 7: GREATEST with all NULL values
SELECT CASE 
    WHEN 1 = 1 THEN 
        (SELECT MAX(v) FROM (VALUES 
            (CAST(NULL AS NUMERIC(10,2))),
            (CAST(NULL AS DECIMAL(12,2))),
            (CAST(NULL AS NUMERIC(8,2)))
        ) AS value(v))
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 8: LEAST with very small and very large numbers
SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN CAST(0.00000001 AS NUMERIC(16,8)) < CAST(99999999.99 AS DECIMAL(10,2))
            THEN CAST(0.00000001 AS NUMERIC(16,8))
            ELSE CAST(99999999.99 AS DECIMAL(10,2))
        END
    ELSE CAST(1 AS DECIMAL(16,8))
END AS result;
GO

-- Test Case 9: GREATEST with negative numbers
SELECT CASE 
    WHEN 1 = 1 THEN 
        (SELECT MAX(v) FROM (VALUES 
            (CAST(-1234.56 AS NUMERIC(10,2))),
            (CAST(-7890.12 AS DECIMAL(12,2))),
            (CAST(-4567.89 AS NUMERIC(8,2)))
        ) AS value(v))
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 10: Complex CASE with multiple GREATEST/LEAST simulations
SELECT CASE 
    WHEN (SELECT MAX(v) FROM (VALUES 
            (CAST(1234.56 AS NUMERIC(10,2))),
            (CAST(7890.12 AS DECIMAL(12,2)))
        ) AS value(v)) > 5000 
    THEN 
        (SELECT MIN(v) FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(789.12 AS DECIMAL(12,2)))
        ) AS value(v))
    ELSE 
        (SELECT MAX(v) FROM (VALUES 
            (CAST(4567.89 AS NUMERIC(10,2))),
            (CAST(9876.54 AS DECIMAL(12,2)))
        ) AS value(v))
END AS result;
GO

-- T_CoerceToDomainValue:
-- Setup
CREATE TYPE NumericDomain FROM NUMERIC(10,4);
CREATE TYPE DecimalDomain FROM DECIMAL(12,2);
GO

-- Test Case 1
SELECT CASE WHEN 1=1 THEN CAST(123.4567 AS NumericDomain) ELSE CAST(9876.54 AS DecimalDomain) END AS result;
GO

-- Test Case 2
SELECT CASE WHEN 1=0 THEN CAST(123.4567 AS NumericDomain) ELSE CAST(9876.54 AS DecimalDomain) END AS result;
GO

-- Test Case 3
DECLARE @n NumericDomain = 123.4567;
DECLARE @d DecimalDomain = 9876.54;
SELECT CASE WHEN @n > 100 THEN @n ELSE @d END AS result;
GO

-- Test Case 4
SELECT CASE 
    WHEN CAST(123.4567 AS NumericDomain) > CAST(100 AS NumericDomain) THEN CAST(123.4567 AS NumericDomain)
    ELSE CAST(9876.54 AS DecimalDomain)
END AS result;
GO

-- Test Case 5
SELECT CASE 
    WHEN 1=1 THEN CAST(CAST(123.4567 AS NUMERIC(10,4)) AS NumericDomain)
    ELSE CAST(CAST(9876.54 AS DECIMAL(12,2)) AS DecimalDomain)
END AS result;
GO

DROP TYPE NumericDomain
GO

DROP TYPE DecimalDomain
GO

-- T_SQLValueFunction:
-- Test Case 1
SELECT CASE 
    WHEN SERVERPROPERTY('Edition') = 'Express Edition' THEN CAST(1 AS NUMERIC(1,0))
    ELSE CAST(0 AS DECIMAL(1,0))
END AS result;
GO


-- T_MinMaxExpr:
-- Test Case 1
SELECT CASE 
    WHEN 1=1 THEN 
        (SELECT MAX(v) FR FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(678.90 AS DECIMAL(12,2)))
        ) AS value(v))
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 2
SELECT CASE 
    WHEN 1=1 THEN 
        (SELECT MIN(v) FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(678.90 AS DECIMAL(12,2))),
            (CAST(456.78 AS NUMERIC(8,2)))
        ) AS value(v))
    ELSE CAST(999.99 AS DECIMAL(10,2))
END AS result;
GO

-- Test Case 3
DECLARE @num1 NUMERIC(10,4) = 123.4567;
DECLARE @num2 DECIMAL(12,2) = 9876.54;
SELECT CASE 
    WHEN @num1 > @num2 THEN @num1
    ELSE @num2
END AS result;
GO

-- Test Case 4
SELECT CASE 
    WHEN 1=1 THEN 
        (SELECT MAX(v) FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2)) * 2),
            (CAST(678.90 AS DECIMAL(12,2)) / 2)
        ) AS value(v))
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 5
SELECT CASE 
    WHEN (SELECT MAX(v) FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(678.90 AS DECIMAL(12,2)))
        ) AS value(v)) > 500 
    THEN CAST(1 AS NUMERIC(1,0))
    ELSE CAST(0 AS DECIMAL(1,0))
END AS result;
GO

-- T_ArrayExpr:
-- Test Case 1
SELECT CASE 
    WHEN 1=1 THEN 
        (SELECT v FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(678.90 AS DECIMAL(12,2)))
        ) AS value(v) WHERE v > 500)
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 2
SELECT CASE 
    WHEN EXISTS(SELECT 1 FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(678.90 AS DECIMAL(12,2)))
        ) AS value(v) WHERE v > 500)
    THEN CAST(1 AS NUMERIC(1,0))
    ELSE CAST(0 AS DECIMAL(1,0))
END AS result;
GO

-- Test Case 3
DECLARE @values TABLE (v NUMERIC(10,2));
INSERT INTO @values VALUES (123.45), (678.90), (456.78);
SELECT CASE 
    WHEN EXISTS(SELECT 1 FROM @values WHERE v > 500)
    THEN (SELECT MAX(v) FROM @values)
    ELSE (SELECT MIN(v) FROM @values)
END AS result;
GO

-- Test Case 4
SELECT CASE 
    WHEN 1=1 THEN 
        (SELECT AVG(v) FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(678.90 AS DECIMAL(12,2))),
            (CAST(456.78 AS NUMERIC(10,2)))
        ) AS value(v))
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 5
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM (VALUES 
            (CAST(123.45 AS NUMERIC(10,2))),
            (CAST(678.90 AS DECIMAL(12,2))),
            (CAST(456.78 AS NUMERIC(10,2)))
        ) AS value(v) WHERE v > 500) > 1
    THEN CAST(1 AS NUMERIC(1,0))
    ELSE CAST(0 AS DECIMAL(1,0))
END AS result;
GO

-- T_CaseTestExpr
-- Test Case 1
SELECT CASE CAST(2 AS NUMERIC(1,0)) 
    WHEN 1 THEN CAST(100.00 AS NUMERIC(10,2))
    WHEN 2 THEN CAST(200.00 AS DECIMAL(12,2)) 
    ELSE CAST(0 AS NUMERIC(10,2))
END AS result;
GO

-- Test Case 2
DECLARE @test DECIMAL(2,0) = 3;
SELECT CASE @test
    WHEN 1 THEN CAST(100.00 AS NUMERIC(10,2))
    WHEN 2 THEN CAST(200.00 AS DECIMAL(12,2))
    WHEN 3 THEN CAST(300.00 AS NUMERIC(10,2))
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 3
DECLARE @value NUMERIC(3,1) = 10.5;
SELECT CASE CAST(@value AS NUMERIC(3,0))
    WHEN 9 THEN CAST(90.00 AS NUMERIC(10,2))
    WHEN 10 THEN CAST(100.00 AS DECIMAL(10,2))
    ELSE CAST(0 AS NUMERIC(10,2))
END AS result;
GO

-- T_ArrayCoerceExpr:
-- Test Case 1
DECLARE @values TABLE (val NUMERIC(10,2));
INSERT INTO @values VALUES (123.45), (678.90), (456.78);
SELECT CASE 
    WHEN 1 = 1 THEN CAST(val AS DECIMAL(12,2))
    ELSE val
END AS result
FROM @values;
GO

-- Test Case 2
DECLARE @values TABLE (val DECIMAL(12,2));
INSERT INTO @values VALUES (123.45), (678.90), (456.78);
SELECT CASE 
    WHEN 1 = 1 THEN CAST(val AS NUMERIC(10,2))
    ELSE val
END AS result
FROM @values;
GO

-- Test Case 3
DECLARE @values TABLE (val NUMERIC(10,2));
INSERT INTO @values VALUES (123.45), (678.90), (456.78);
SELECT CASE 
    WHEN val > 500 THEN CAST(val AS DECIMAL(12,2))
    ELSE val
END AS result
FROM @values;
GO

-- Test Case 4
DECLARE @values TABLE (val DECIMAL(12,2));
INSERT INTO @values VALUES (123.45), (678.90), (456.78);
SELECT CASE 
    WHEN val < 500 THEN CAST(val AS NUMERIC(10,2))
    ELSE val
END AS result
FROM @values;
GO

-- T_FieldSelect:
-- Setup
CREATE TABLE MyTable (
    id INT PRIMARY KEY,
    num_col NUMERIC(10,2),
    dec_col DECIMAL(12,2)
);
GO

INSERT INTO MyTable (id, num_col, dec_col) VALUES 
(1, 1234.56, 9876.54),
(2, 2345.67, 8765.43),
(3, 3456.78, 7654.32);
GO

-- Test Case 1
SELECT CASE 
    WHEN t.num_col > 2000 THEN t.num_col
    ELSE t.dec_col
END AS result
FROM MyTable t;
GO

-- Test Case 2
SELECT CASE 
    WHEN t.dec_col < 8000 THEN t.num_col
    ELSE t.dec_col
END AS result
FROM MyTable t
WHERE t.id = 2;
GO

-- Test Case 3
DECLARE @id INT = 3;
SELECT CASE 
    WHEN (SELECT num_col FROM MyTable WHERE id = @id) > 3000 THEN (SELECT num_col FROM MyTable WHERE id = @id)
    ELSE (SELECT dec_col FROM MyTable WHERE id = @id)
END AS result;
GO

-- Test Case 4
SELECT CASE 
    WHEN (SELECT AVG(num_col) FROM MyTable) > 2500 THEN (SELECT MAX(num_col) FROM MyTable)
    ELSE (SELECT MIN(dec_col) FROM MyTable)
END AS result;
GO

-- Test Case 5
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM MyTable WHERE num_col > 3000) > 1 THEN (SELECT SUM(num_col) FROM MyTable)
    ELSE (SELECT AVG(dec_col) FROM MyTable)
END AS result;
GO

-- T_AlternativeSubPlan:
-- This is typically an internal optimization structure, but we can simulate with a UNION ALL.

-- Test Case 1
SELECT CASE 
    WHEN 1 = 1 THEN 
        (SELECT CAST(123.45 AS NUMERIC(10,2)) WHERE 1 = 1
         UNION ALL
         SELECT CAST(678.90 AS DECIMAL(12,2)) WHERE 1 = 0)
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 2
DECLARE @flag BIT = 1;
SELECT CASE 
    WHEN @flag = 1 THEN 
        (SELECT CAST(123.45 AS NUMERIC(10,2)) WHERE @flag = 1
         UNION ALL
         SELECT CAST(678.90 AS DECIMAL(12,2)) WHERE @flag = 0)
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 3
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM (
        SELECT CAST(123.45 AS NUMERIC(10,2)) WHERE 1 = 1
        UNION ALL
        SELECT CAST(678.90 AS DECIMAL(12,2)) WHERE 1 = 0
    ) t) > 0 THEN CAST(1 AS NUMERIC(1,0))
    ELSE CAST(0 AS DECIMAL(1,0))
END AS result;
GO

-- Test Case 4
DECLARE @condition BIT = 1;
SELECT CASE 
    WHEN @condition = 1 THEN 
        (SELECT CAST(123.45 AS NUMERIC(10,2)) WHERE @condition = 1
         UNION ALL
         SELECT CAST(678.90 AS DECIMAL(12,2)) WHERE @condition = 0)
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

-- T_SubPlan:
-- Test Case 1
SELECT CASE 
    WHEN 1 = 1 THEN (SELECT TOP 1 CAST(123.45 AS NUMERIC(10,2)) FROM MyTable)
    ELSE (SELECT TOP 1 CAST(678.90 AS DECIMAL(12,2)) FROM MyTable)
END AS result;
GO

-- Test Case 2
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM MyTable WHERE num_col > 2000) > 0 
    THEN (SELECT AVG(CAST(num_col AS NUMERIC(10,2))) FROM MyTable)
    ELSE (SELECT AVG(CAST(dec_col AS DECIMAL(12,2))) FROM MyTable)
END AS result;
GO

-- Test Case 3
SELECT CASE 
    WHEN (SELECT MAX(num_col) FROM MyTable) > (SELECT MIN(dec_col) FROM MyTable)
    THEN (SELECT SUM(CAST(num_col AS NUMERIC(15,2))) FROM MyTable)
    ELSE (SELECT SUM(CAST(dec_col AS DECIMAL(15,2))) FROM MyTable)
END AS result;
GO

-- Test Case 4
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM MyTable WHERE num_col > 3000) 
    THEN (SELECT CAST(num_col AS NUMERIC(10,2)) FROM MyTable WHERE id = 1)
    ELSE (SELECT CAST(dec_col AS DECIMAL(12,2)) FROM MyTable WHERE id = 2)
END AS result;
GO

-- Test Case 5
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM MyTable WHERE num_col > (SELECT AVG(num_col) FROM MyTable)) > 1
    THEN (SELECT CAST(SUM(num_col) AS NUMERIC(18,2)) FROM MyTable)
    ELSE (SELECT CAST(SUM(dec_col) AS DECIMAL(18,2)) FROM MyTable)
END AS result;
GO

DROP TABLE MyTable
GO

-- T_SubscriptingRef:
-- Test Case 1
DECLARE @json NVARCHAR(MAX) = N'{"num": 123.45, "dec": 678.90}';
SELECT CASE 
    WHEN CAST(JSON_VALUE(@json, '$.num') AS NUMERIC(10,2)) > 100 
    THEN CAST(JSON_VALUE(@json, '$.num') AS NUMERIC(10,2))
    ELSE CAST(JSON_VALUE(@json, '$.dec') AS DECIMAL(12,2))
END AS result;
GO

-- Test Case 2
DECLARE @data TABLE (id INT, num_col NUMERIC(10,2), dec_col DECIMAL(12,2));
INSERT INTO @data VALUES (1, 123.45, 678.90), (2, 234.56, 567.89);
SELECT CASE 
    WHEN @data.num_col > 200 THEN @data.num_col
    ELSE @data.dec_col
END AS result
FROM @data
WHERE id = 2;
GO

-- Test Case 3
DECLARE @json NVARCHAR(MAX) = N'{"values": [123.45, 678.90, 456.78]}';
SELECT CASE 
    WHEN CAST(JSON_VALUE(@json, '$.values[0]') AS NUMERIC(10,2)) > 500
    THEN CAST(JSON_VALUE(@json, '$.values[1]') AS DECIMAL(12,2))
    ELSE CAST(JSON_VALUE(@json, '$.values[2]') AS NUMERIC(10,2))
END AS result;
GO

-- Test Case 4
DECLARE @data TABLE (id INT, num_col NUMERIC(10,2), dec_col DECIMAL(12,2));
INSERT INTO @data VALUES (1, 123.45, 678.90), (2, 234.56, 567.89);
SELECT CASE 
    WHEN (SELECT num_col FROM @data WHERE id = 2) > 200
    THEN (SELECT num_col FROM @data WHERE id = 2)
    ELSE (SELECT dec_col FROM @data WHERE id = 2)
END AS result;
GO

-- Test Case 5
DECLARE @json NVARCHAR(MAX) = N'{"nums": [123.45, 234.56, 345.67], "decs": [678.90, 567.89, 456.78]}';
SELECT CASE 
    WHEN CAST(JSON_VALUE(@json, '$.nums[0]') AS NUMERIC(10,2)) > 200
    THEN CAST(JSON_VALUE(@json, '$.decs[1]') AS DECIMAL(12,2))
    ELSE CAST(JSON_VALUE(@json, '$.nums[2]') AS NUMERIC(10,2))
END AS result;
GO

-- TODO FIX: While calculating for money and smallmoney
-- babelfish is calculating it same as numeric logic
-- which is different from TSQL.
-- Money datatypes testing
SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN 1=1
            THEN CAST(1234.56 AS NUMERIC(10,2)) * cast(5.5 as smallmoney)
            ELSE CAST(9876.54 AS DECIMAL(12,2)) / cast(6.43 as smallmoney)
        END
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN 1=1
            THEN CAST(1234.56 AS NUMERIC(10,2)) * cast(5.5 as money)
            ELSE CAST(9876.54 AS DECIMAL(12,2)) / cast(6.43 as smallmoney)
        END
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN 1=1
            THEN CAST(1234.56 AS NUMERIC(10,2)) * cast(5.5 as money)
            ELSE CAST(9876.54 AS DECIMAL(12,2)) / cast(6.43 as money)
        END
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO

SELECT CASE 
    WHEN 1 = 1 THEN 
        CASE 
            WHEN 1=1
            THEN CAST(1234.56 AS NUMERIC(10,2)) * cast(5.5 as smallmoney)
            ELSE CAST(9876.54 AS DECIMAL(12,2)) / cast(6.43 as money)
        END
    ELSE CAST(0 AS DECIMAL(12,2))
END AS result;
GO


-- TODO FIX: Output diff between TSQL and BBF.
-- T_Param (Function parameter)
DROP FUNCTION IF EXISTS dbo.TestParam
GO

CREATE FUNCTION dbo.TestParam (@param1 NUMERIC(10,4), @param2 DECIMAL(12,2))
RETURNS TABLE
AS
RETURN
(
    SELECT CASE 
        WHEN 1 = 1 THEN @param1 
        ELSE @param2 
    END AS result
);
GO

SELECT * FROM dbo.TestParam(1234.5678, 9876.54);
GO

DROP FUNCTION dbo.TestParam
GO

-- T_Param (Function parameter)
DROP FUNCTION IF EXISTS dbo.TestParam
GO

CREATE FUNCTION dbo.TestParam (@param1 NUMERIC(10,4), @param2 DECIMAL(12,2))
RETURNS TABLE
AS
RETURN
(
    SELECT @param1 AS result
    UNION ALL
    SELECT @param2
    ORDER BY result
);
GO

SELECT * FROM dbo.TestParam(1234.5678, 9876.54);
GO

DROP FUNCTION dbo.TestParam
GO

-- T_NamedArgExpr (Named argument in a function call)
DROP FUNCTION IF EXISTS dbo.TestNamedArg
GO

CREATE FUNCTION dbo.TestNamedArg (@param1 NUMERIC(10,4) = 0, @param2 DECIMAL(12,2) = 0)
RETURNS TABLE
AS
RETURN
(
    SELECT @param1 AS result
    UNION ALL
    SELECT @param2
    ORDER BY result
);
GO

SELECT * FROM dbo.TestNamedArg(1234.56, 7890.1234);
GO

DROP FUNCTION dbo.TestNamedArg;
GO

-- Setup
DROP FUNCTION IF EXISTS dbo.TestFunction;
GO

CREATE FUNCTION dbo.TestFunction (@num NUMERIC(10,2), @dec DECIMAL(12,2))
RETURNS TABLE
AS
RETURN
(
    SELECT CASE 
        WHEN @num > @dec THEN @num
        ELSE @dec
    END AS result
);
GO

-- T_NamedArgExpr:
-- Test Case 1
SELECT * FROM dbo.TestFunction(123.45, 678.90);
GO

-- Test Case 2
SELECT * FROM dbo.TestFunction(678.90, 123.45);
GO

-- Test Case 3
DECLARE @n NUMERIC(10,2) = 123.45;
DECLARE @d DECIMAL(12,2) = 678.90;
SELECT * FROM dbo.TestFunction(@n, @d);
GO

-- Test Case 4
SELECT * FROM dbo.TestFunction(678.90, CAST(123.45 AS NUMERIC(10,2)));
GO

-- Test Case 5
SELECT * FROM dbo.TestFunction(CAST(123.45 AS NUMERIC(10,2)), CAST(678.90 AS DECIMAL(12,2)));
GO

DROP FUNCTION dbo.TestFunction;
go



-- TODO FIX: SQRT function returns float in TSQL. while
-- selecting commontype between flaot ansd numeric,
-- is selected. where as in BBF SQRT function returns numeric.
-- Test Case: T_SubPlan with different numeric operations
SELECT CASE 
    WHEN (SELECT POWER(CAST(2 AS NUMERIC(5,2)), 3)) > 7
    THEN (SELECT SQRT(CAST(100 AS NUMERIC(10,4))))
    ELSE (SELECT CAST(PI() AS DECIMAL(10,8)))
END AS result;
GO