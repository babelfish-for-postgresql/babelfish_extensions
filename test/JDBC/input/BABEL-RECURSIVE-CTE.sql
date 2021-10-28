USE master;
GO

CREATE SCHEMA babel_recursive_cte;
GO

CREATE TABLE babel_recursive_cte.numbers (c1 int);
GO

INSERT INTO babel_recursive_cte.numbers VALUES (3)
GO

-- basic positive case
WITH numbers(c1)
AS (
    SELECT 1
    UNION ALL
    SELECT c1 + 1 FROM numbers WHERE c1 <= 5
)
SELECT c1 FROM numbers ORDER BY c1
GO

-- basic negative case (not recursive)
WITH numbers(c1)
AS (
    SELECT 1
    UNION ALL
    SELECT c1 + 1 FROM babel_recursive_cte.numbers WHERE c1 <= 5  -- referring physical table
)
SELECT c1 FROM numbers ORDER BY c1
GO

-- invalid recursive cte 1
WITH numbers(c1)
AS (
    SELECT 1 FROM numbers
    UNION ALL
    SELECT c1 + 1 FROM numbers WHERE c1 <= 5
)
SELECT c1 FROM numbers ORDER BY c1
GO

-- invalid recursive cte 2
WITH numbers(c1)
AS (
    SELECT c1 + 1 FROM numbers WHERE c1 <= 5
)
SELECT c1 FROM numbers ORDER BY c1
GO

-- recursive + join
WITH numbers(c1)
AS (
    SELECT 1
    UNION ALL
    SELECT Y.c1 + 1 FROM babel_recursive_cte.numbers X INNER JOIN numbers Y on 1 = 1 WHERE Y.c1 <= 5
)
SELECT c1 FROM numbers ORDER BY c1
GO

-- recursive + subquery
WITH numbers(c1)
AS (
    SELECT 1
    UNION ALL
    SELECT c1 + 1 FROM (SELECT * FROM numbers) X WHERE c1 <= 5
)
SELECT c1 FROM numbers ORDER BY c1
GO

-- recursive + expr-subquery (unsupported)
WITH numbers(c1)
AS (
    SELECT 1
    UNION ALL
    SELECT (SELECT c1 FROM numbers) + 1 FROM babel_recursive_cte.numbers X WHERE c1 <= 5
)
SELECT c1 FROM numbers ORDER BY c1
GO

DROP TABLE babel_recursive_cte.numbers;
GO

DROP SCHEMA babel_recursive_cte;
GO