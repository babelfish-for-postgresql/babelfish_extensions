--------------------------------------------------------------------------------
-- Test basic
SELECT  
    MIN(col_nchar) AS min_nchar, MAX(col_nchar) AS max_nchar,
    MIN(col_char) AS min_char, MAX(col_char) AS max_char,
    MIN(col_nvarchar) AS min_nvarchar, MAX(col_nvarchar) AS max_nvarchar,
    MIN(col_varchar) AS min_varchar, MAX(col_varchar) AS max_varchar 
FROM babel_5688_all_types;
GO


-- Test: Empty strings and spaces
INSERT INTO babel_5688_all_types (col_nchar, col_char, col_nvarchar, col_varchar, category, amount) VALUES 
('', '', '', '', 'EmptyTest', 0),
('   ', '   ', '   ', '   ', 'SpaceTest', 0)
GO

SELECT  
    MIN(col_nchar) AS min_nchar, MAX(col_nchar) AS max_nchar,
    MIN(col_char) AS min_char, MAX(col_char) AS max_char
FROM babel_5688_all_types;
GO

-- Test with GROUP BY and ORDER BY
SELECT 
    category,
    MIN(col_nchar) AS min_nchar, MAX(col_nchar) AS max_nchar,
    MIN(col_char) AS min_char, MAX(col_char) AS max_char
FROM babel_5688_all_types
GROUP BY category
ORDER BY category;
GO

select min(col_char) FROM babel_5688_all_types GROUP BY col_nchar ORDER BY col_nchar
go


-- Test with having clause 
SELECT 
    category,
    MIN(col_nchar) AS min_nchar,
    MAX(col_nchar) AS max_nchar,
    COUNT(*) AS cnt
FROM babel_5688_all_types
GROUP BY category
HAVING MIN(col_nchar) IS NOT NULL AND MAX(col_nchar) IS NOT NULL
ORDER BY category;
GO


-- Test Where clause 
SELECT 
    MIN(col_nchar) AS min_nchar, MAX(col_nchar) AS max_nchar,
    MIN(col_char) AS min_char, MAX(col_char) AS max_char,
    MIN(col_nvarchar) AS min_nvarchar, MAX(col_nvarchar) AS max_nvarchar,
    MIN(col_varchar) AS min_varchar
FROM babel_5688_all_types
WHERE category = 'Fruit';
GO

SELECT 
    MIN(col_nchar) AS min_nchar, MAX(col_nchar) AS max_nchar,
    MIN(col_char) AS min_char, MAX(col_char) AS max_char
FROM babel_5688_all_types
WHERE col_nchar IS NOT NULL AND col_char IS NOT NULL;
GO


-- Test distinct
SELECT 
    MIN(DISTINCT col_nchar) AS min_distinct_nchar, MAX(DISTINCT col_nchar) AS max_distinct_nchar,
    MIN(DISTINCT col_char) AS min_distinct_char, MAX(DISTINCT col_char) AS max_distinct_char,
    MIN(DISTINCT col_nvarchar) AS min_distinct_nvarchar, MAX(DISTINCT col_nvarchar) AS max_distinct_nvarchar,
    MIN(DISTINCT col_varchar) AS min_distinct_varchar
FROM babel_5688_all_types;
GO


-- Test subquery
SELECT * FROM babel_5688_all_types WHERE col_nchar = (SELECT MIN(col_nchar) FROM babel_5688_all_types);
GO
SELECT * FROM babel_5688_all_types WHERE col_char = (SELECT MIN(col_char) FROM babel_5688_all_types WHERE col_char IS NOT NULL);
GO
SELECT * FROM babel_5688_all_types WHERE col_nvarchar = (SELECT MIN(col_nvarchar) FROM babel_5688_all_types);
GO
SELECT * FROM babel_5688_all_types WHERE col_varchar = (SELECT MIN(col_varchar) FROM babel_5688_all_types);
GO


-- Test UNION ALL
SELECT 'NCHAR' AS col_type, MIN(col_nchar) AS min_val, MAX(col_nchar) AS max_val FROM babel_5688_all_types WHERE col_nchar IS NOT NULL
UNION ALL
SELECT 'CHAR' AS col_type, MIN(col_char) AS min_val, MAX(col_char) AS max_val FROM babel_5688_all_types WHERE col_char IS NOT NULL
UNION ALL
SELECT 'NVARCHAR' AS col_type, MIN(col_nvarchar) AS min_val, MAX(col_nvarchar) AS max_val FROM babel_5688_all_types WHERE col_nvarchar IS NOT NULL
GO

SELECT MIN(col_nchar) AS min_val, MAX(col_char) AS max_val FROM babel_5688_all_types WHERE col_nchar IS NOT NULL
UNION ALL
SELECT MIN(col1_nchar) AS min_val, MAX(col1_char) AS max_val FROM babel_5688_table2 WHERE col1_char IS NOT NULL
UNION ALL
SELECT MIN(col1_nchar) AS min_val, MAX(col1_char) AS max_val FROM babel_5688_table3 WHERE col1_char IS NOT NULL;
GO


-- Test CTEs
WITH MinMaxCTE AS (
    SELECT 
        category,
        MIN(col_nchar) AS min_nchar,
        MAX(col_nchar) AS max_nchar,
        MIN(col_char) AS min_char,
        MAX(col_char) AS max_char
    FROM babel_5688_all_types
    GROUP BY category
)
SELECT * FROM MinMaxCTE WHERE min_nchar IS NOT NULL ORDER BY category;
GO

WITH CategoryStats AS (
    SELECT 
        category,
        MIN(col_nchar) AS min_val,
        MAX(col_nchar) AS max_val,
        COUNT(*) AS cnt
    FROM babel_5688_all_types
    WHERE col_nchar IS NOT NULL
    GROUP BY category
)
SELECT 
    cs.category, 
    cs.min_val, 
    cs.max_val, 
    cs.cnt,
    t.col_nchar AS sample_value
FROM CategoryStats cs
JOIN babel_5688_all_types t ON t.category = cs.category AND t.col_nchar = cs.min_val
ORDER BY cs.category, sample_value;
GO

-- Test CASE EXPRESSION
SELECT 
    category,
    CASE 
        WHEN MIN(col_nchar) = MAX(col_nchar) THEN 'Same'
        WHEN MIN(col_nchar) IS NULL OR MAX(col_nchar) IS NULL THEN 'Has Nulls'
        ELSE 'Different'
    END AS nchar_status,
    CASE 
        WHEN MIN(col_char) = MAX(col_char) THEN 'Same'
        WHEN MIN(col_char) IS NULL OR MAX(col_char) IS NULL THEN 'Has Nulls'
        ELSE 'Different'
    END AS varchar_status
FROM babel_5688_all_types
GROUP BY category
ORDER BY category;
GO

-- Test expressions inside min/max
SELECT  
    MIN(UPPER(col_nchar)) AS min_upper_nchar,
    MAX(UPPER(col_nchar)) AS max_upper_nchar,
    MIN(LOWER(col_nchar)) AS min_lower_nchar,
    MAX(LOWER(col_nchar)) AS max_lower_nchar,
    MIN(UPPER(col_char)) AS min_upper_char,
    MAX(UPPER(col_char)) AS max_upper_char,
    MIN(LOWER(col_char)) AS min_lower_char,
    MAX(LOWER(col_char)) AS max_lower_char 
FROM babel_5688_all_types 
WHERE col_nchar IS NOT NULL AND col_char IS NOT NULL;
GO

-- Test TOP WITH MIN/MAX
SELECT TOP 5 
    category,
    MIN(col_nchar) AS min_nchar,
    MAX(col_nchar) AS max_nchar 
FROM babel_5688_all_types 
WHERE col_nchar IS NOT NULL 
GROUP BY category 
ORDER BY MIN(col_nchar);
GO

SELECT TOP 3
    category,
    MIN(col_char) AS min_char,
    MAX(col_char) AS max_char
FROM babel_5688_all_types
WHERE col_char IS NOT NULL
GROUP BY category
ORDER BY MAX(col_char) DESC;
GO


-- Test COALESCE/ISNULL 
SELECT COALESCE(MIN(col1_nchar), N'No Value') AS min_nchar FROM babel_5688_table2;
GO
SELECT ISNULL(MAX(col1_nchar), N'No Value') AS max_nchar FROM babel_5688_table2;
GO
SELECT COALESCE(MIN(col1_char), 'No Value') AS min_char FROM babel_5688_table2;
GO
SELECT ISNULL(MAX(col1_char), 'No Value') AS max_char FROM babel_5688_table2;
GO

-- All null values in tables
SELECT MIN(col1_nchar) AS min_nchar FROM babel_5688_table3;
GO
SELECT MIN(col1_char) AS min_char FROM babel_5688_table3;
GO
SELECT MAX(col1_nchar) AS min_nchar FROM babel_5688_table3;
GO
SELECT MAX(col1_char) AS min_char FROM babel_5688_table3;
GO

-- Test Empty table
SELECT MIN(col1_nchar) AS min_nchar FROM babel_5688_table4;
GO
SELECT MIN(col1_char) AS min_nchar FROM babel_5688_table4;
GO
SELECT MAX(col1_nchar) AS min_nchar FROM babel_5688_table4;
GO
SELECT MAX(col1_char) AS min_nchar FROM babel_5688_table4;
GO


-- Test JOINs
-- Inner Join
SELECT 
    t1.category,
    t1.min_nchar AS all_types_min,
    t1.max_nchar AS all_types_max,
    t2.col1_nchar AS table2_nchar,
    t2.col1_char AS table2_char
FROM (
    SELECT category, MIN(col_nchar) AS min_nchar, MAX(col_nchar) AS max_nchar
    FROM babel_5688_all_types
    GROUP BY category
) t1
INNER JOIN babel_5688_table2 t2 ON t1.min_nchar = t2.col1_nchar;
GO

-- Left Join
SELECT 
    t1.category,
    t1.min_nchar AS all_types_min,
    t1.max_nchar AS all_types_max,
    t2.col1_nchar AS table2_nchar,
    t2.col1_char AS table2_char,
    CASE WHEN t2.col1_nchar IS NULL THEN 'No Match' ELSE 'Matched' END AS match_status
FROM (
    SELECT category, MIN(col_nchar) AS min_nchar, MAX(col_nchar) AS max_nchar
    FROM babel_5688_all_types
    GROUP BY category
) t1
LEFT JOIN babel_5688_table2 t2 ON t1.min_nchar = t2.col1_nchar
ORDER BY t1.category;
GO

-- Complex query combining all elements
SELECT 
    source_info,
    category,
    min_val,
    max_val,
    CASE 
        WHEN min_val IS NULL AND max_val IS NULL THEN 'Empty/All NULL'
        WHEN min_val = max_val THEN 'Single Unique Value'
        ELSE 'Multiple Values'
    END AS data_status
FROM (
    -- From babel_5688_all_types grouped by category
    SELECT 
        'AllTypes-ByCategory' AS source_info,
        category,
        MIN(col_nchar) AS min_val,
        MAX(col_nchar) AS max_val
    FROM babel_5688_all_types
    GROUP BY category
    
    UNION ALL
    
    -- From babel_5688_table2
    SELECT 
        'Table2-All' AS source_info,
        'N/A' AS category,
        MIN(col1_nchar) AS min_val,
        MAX(col1_nchar) AS max_val
    FROM babel_5688_table2
    
    UNION ALL
    
    -- From babel_5688_table3 (all nulls)
    SELECT 
        'Table3-AllNulls' AS source_info,
        'N/A' AS category,
        MIN(col1_nchar) AS min_val,
        MAX(col1_nchar) AS max_val
    FROM babel_5688_table3
    
    UNION ALL
    
    -- From babel_5688_table4 (empty)
    SELECT 
        'Table4-Empty' AS source_info,
        'N/A' AS category,
        MIN(col1_nchar) AS min_val,
        MAX(col1_nchar) AS max_val
    FROM babel_5688_table4
) combined_data
ORDER BY source_info, category;
GO


-- Test multiple JOINs with CASE
SELECT 
    t1.category,
    MIN(t1.col_nchar) AS t1_min_nchar,
    MAX(t1.col_nchar) AS t1_max_nchar,
    MIN(t2.col1_nchar) AS t2_min_nchar,
    MIN(t3.col1_nchar) AS t3_min_nchar,
    CASE 
        WHEN MIN(t2.col1_nchar) IS NOT NULL AND MIN(t3.col1_nchar) IS NOT NULL THEN 'Both Match'
        WHEN MIN(t2.col1_nchar) IS NOT NULL THEN 'Only T2 Match'
        WHEN MIN(t3.col1_nchar) IS NOT NULL THEN 'Only T3 Match'
        ELSE 'No Match'
    END AS match_status
FROM babel_5688_all_types t1
LEFT JOIN babel_5688_table2 t2 ON t1.col_nchar = t2.col1_nchar
LEFT JOIN babel_5688_table3 t3 ON t1.col_nchar = t3.col1_nchar
GROUP BY t1.category
ORDER BY t1.category;
GO

-- Test declare statements
DECLARE @nchar_var nchar(50) = N'abc';
DECLARE @nchar_var1 nchar(50) = N'日本語';
DECLARE @nchar_var2 nchar(50) = N'';
DECLARE @nchar_var3 nchar(50) = NULL;
SELECT 
    min(@nchar_var), max(@nchar_var), 
    min(@nchar_var1), max(@nchar_var1),
    min(@nchar_var2), max(@nchar_var2),
    min(@nchar_var3), max(@nchar_var3)
go

DECLARE @char_var char(50) = 'abc';
DECLARE @char_var1 char(50) = N'日本語';
DECLARE @char_var2 char(50) = '';
DECLARE @char_var3 char(50) = NULL;
SELECT 
    min(@char_var), max(@char_var), 
    min(@char_var1), max(@char_var1),
    min(@char_var2), max(@char_var2),
    min(@char_var3), max(@char_var3)
GO

DECLARE @nvarchar_var nvarchar(100) = N'test';
DECLARE @nvarchar_var1 nvarchar(100) = N'unicode日本語';
DECLARE @nvarchar_var2 nvarchar(100) = N'';
DECLARE @nvarchar_var3 nvarchar(100) = NULL;
SELECT 
    min(@nvarchar_var), max(@nvarchar_var), 
    min(@nvarchar_var1), max(@nvarchar_var1),
    min(@nvarchar_var2), max(@nvarchar_var2),
    min(@nvarchar_var3), max(@nvarchar_var3)
GO

DECLARE @varchar_var varchar(100) = 'hello';
DECLARE @varchar_var1 varchar(100) = 'world';
DECLARE @varchar_var2 varchar(100) = '';
DECLARE @varchar_var3 varchar(100) = NULL;
SELECT 
    min(@varchar_var), max(@varchar_var), 
    min(@varchar_var1), max(@varchar_var1),
    min(@varchar_var2), max(@varchar_var2),
    min(@varchar_var3), max(@varchar_var3)
GO

-- Basic test using babel_5688_all_types columns
DECLARE @min_nchar NCHAR(50);
DECLARE @max_nchar NCHAR(50);
DECLARE @min_char CHAR(50);
DECLARE @max_char CHAR(50);
DECLARE @min_nvarchar NVARCHAR(100);
DECLARE @max_nvarchar NVARCHAR(100);
DECLARE @min_varchar VARCHAR(100);

SELECT @min_nchar = MIN(col_nchar) FROM babel_5688_all_types;
SELECT @max_nchar = MAX(col_nchar) FROM babel_5688_all_types;
SELECT @min_char = MIN(col_char) FROM babel_5688_all_types;
SELECT @max_char = MAX(col_char) FROM babel_5688_all_types;
SELECT @min_nvarchar = MIN(col_nvarchar) FROM babel_5688_all_types;
SELECT @max_nvarchar = MAX(col_nvarchar) FROM babel_5688_all_types;
SELECT @min_varchar = MIN(col_varchar) FROM babel_5688_all_types;

SELECT 
    @min_nchar AS min_nchar, @max_nchar AS max_nchar,
    @min_char AS min_char, @max_char AS max_char,
    @min_nvarchar AS min_nvarchar, @max_nvarchar AS max_nvarchar,
    @min_varchar AS min_varchar;
GO

-- Test Declare with table variable
SELECT 'TEST D7: DECLARE with table variable' AS TestName;
GO

DECLARE @results TABLE (
    col_type VARCHAR(20),
    min_val NVARCHAR(100),
    max_val NVARCHAR(100)
);

INSERT INTO @results (col_type, min_val, max_val)
SELECT 'NCHAR', MIN(col_nchar), MAX(col_nchar) FROM babel_5688_all_types;

INSERT INTO @results (col_type, min_val, max_val)
SELECT 'CHAR', MIN(col_char), MAX(col_char) FROM babel_5688_all_types;

INSERT INTO @results (col_type, min_val, max_val)
SELECT 'NVARCHAR', MIN(col_nvarchar), MAX(col_nvarchar) FROM babel_5688_all_types;

SELECT * FROM @results;
GO

-- Functions 

-- Procedures
-- Test Functions
SELECT dbo.babel_5688_f1() AS f1_min_nchar;
GO
SELECT dbo.babel_5688_f2() AS f2_max_nchar;
GO
SELECT dbo.babel_5688_f3() AS f3_min_char;
GO
SELECT dbo.babel_5688_f4() AS f4_max_char;
GO
SELECT dbo.babel_5688_f5(N'default') AS f8_coalesce;
GO
SELECT dbo.babel_5688_f5(N'') AS result_empty_default;
GO
SELECT dbo.babel_5688_f6('Fruit') AS f9_category_min;
GO
SELECT dbo.babel_5688_f7() AS f10_var_min;
GO

-- Test Procedures
EXEC babel_5688_p1;
GO
EXEC babel_5688_p2 'Fruit';
GO
EXEC babel_5688_p3 N'test_var';
GO
EXEC babel_5688_p4 N'default_value';
GO
EXEC babel_5688_p5;
GO
EXEC babel_5688_p6 'Animal';
GO