SELECT * FROM forjson_vu_v_1
GO

SELECT * FROM forjson_vu_v_2
GO

SELECT * FROM forjson_vu_v_3
GO

SELECT * FROM forjson_vu_v_4
GO

SELECT * FROM forjson_vu_v_5
GO

SELECT * FROM forjson_vu_v_6
GO

SELECT * FROM forjson_vu_v_7
GO

SELECT * FROM forjson_vu_v_8
GO

SELECT * FROM forjson_vu_v_9
GO

SELECT * FROM forjson_vu_v_10
GO

SELECT * FROM forjson_vu_v_11
GO

SELECT * FROM forjson_vu_v_12
GO

SELECT * FROM forjson_vu_v_13
GO

SELECT * FROM forjson_vu_v_14
GO

EXECUTE forjson_vu_p_1
GO

EXECUTE forjson_vu_p_2
GO

EXECUTE forjson_vu_p_3
GO

EXECUTE forjson_vu_p_4
GO

EXECUTE forjson_vu_p_5
GO

EXECUTE forjson_vu_p_6
GO

EXECUTE forjson_vu_p_7
GO

EXECUTE forjson_vu_p_8
GO

EXECUTE forjson_vu_p_9
GO

EXECUTE forjson_vu_p_10
GO

EXECUTE forjson_vu_p_11
GO

EXECUTE forjson_vu_p_12
GO

EXECUTE forjson_vu_p_13
GO

EXECUTE forjson_vu_p_14
GO

EXECUTE forjson_vu_p_15
GO

SELECT forjson_vu_f_2()
GO

INSERT INTO forjson_auto_vu_t_users VALUES (1, 'e', 'o', 'testemail3')
go

/* BABEL-5910 - Crash inside strcmp(), under buildJsonEntry() */

-- Should fail gracefully with proper error message rather than crash
SELECT 1+2 , firstname as [NULL] FROM forjson_auto_vu_t_users FOR JSON AUTO;
GO

select 1+2 as 'a' for json auto;
GO

select NULL as [NULL] from forjson_auto_vu_t_users for json auto;
GO

-- empty result set
SELECT * FROM forjson_auto_vu_t_users WHERE 1=0 FOR JSON AUTO;
GO

-- NULL testing
SELECT n1.id as "outer.id", 
       n1.data as "outer.data", 
       n2.id as "inner.id", 
       n2.ref_id as "inner.ref_id" 
FROM forjson_test_nested_1 n1 
LEFT JOIN forjson_test_nested_2 n2 ON n1.id = n2.id 
FOR JSON AUTO, INCLUDE_NULL_VALUES;
GO

--Special Unicode characters in column names
SELECT id as "parent.id", 
       column_标 as "parent.子.data" 
FROM forjson_test_unicode 
FOR JSON AUTO;
GO

-- long alias name test check
SELECT id as "ThisIsAnExtremelyLongColumnNameThatExceedsTheNormalLimitForColumnNamesInMostDatabaseSystemsIncludingPostgreSQLAndShouldTriggerOurHashKeyTruncationWarningWithoutCrashing.id"
FROM forjson_auto_vu_t_users
FOR JSON AUTO;
GO

-- ORDER BY with calculation - creates resjunk column
SELECT id, name, value FROM forjson_test_orderby ORDER BY value * 2 DESC FOR JSON AUTO;
GO

-- ORDER BY with multiple expressions - creates multiple resjunk columns
SELECT id, name, value FROM forjson_test_orderby ORDER BY SUBSTRING(name, 1, 1), value DESC FOR JSON AUTO;
GO

-- Simple GROUP BY - creates resjunk columns
SELECT category, SUM(quantity) as total_quantity, AVG(price) as avg_price FROM forjson_test_groupby GROUP BY category FOR JSON AUTO;
GO

-- GROUP BY with HAVING - creates resjunk columns with filtering
SELECT category, COUNT(*) as product_count, SUM(quantity) as total_quantity FROM forjson_test_groupby GROUP BY category
HAVING SUM(quantity) > 20 FOR JSON AUTO;
GO

-- This creates multiple resjunk columns of various types
SELECT category, 
       COUNT(*) as product_count, 
       SUM(quantity) as total_quantity,
       MAX(price) as max_price,
       MIN(price) as min_price
FROM forjson_test_groupby
GROUP BY category
ORDER BY SUM(quantity * price) DESC
FOR JSON AUTO;
GO

-- Test 13: Window functions - create resjunk columns
SELECT id, 
       value,
       ROW_NUMBER() OVER(ORDER BY value) as row_num,
       RANK() OVER(ORDER BY value) as rank_val
FROM forjson_test_orderby
ORDER BY id
FOR JSON AUTO;
GO

-- For Version Upgrade Test
EXECUTE forjson_vu_v_resjunk_orderby_groupby;
GO

EXECUTE forjson_vu_v_resjunk_window_functions;
GO

EXECUTE forjson_vu_p_resjunk_groupby_having_orderby;
GO


/* ----------- Found Incorrect cases with needs to be handled in future  -------------- */

/*
 *  Condition : Only Function in the query
 *  Expected Output: should not throw any error
 *  Actual Output: throws incorrect error message
 */ 
SELECT  b.EmployeeId
FROM dbo.forjson_auto_test_diff_cases_fn(1) as b
FOR JSON AUTO;
GO


/*
 *  Condition : FUNCTION + RELATION
 *  Actual Output: Treats Function as relation and gives incorrect output
 *  Expected Output: should treat function and relation as separate and provides different
 *                   nesting key and level for both
 */ 
SELECT  b.EmployeeId, a.salary
FROM dbo.forjson_auto_test_diff_cases_fn(1) as b, forjson_auto_test_diff_cases a
FOR JSON AUTO;
GO