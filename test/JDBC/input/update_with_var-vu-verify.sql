-- Test UPDATE
DECLARE @sum INT = 0;
UPDATE test_int SET val = val, @sum = @sum + val;
SELECT @sum AS result; -- Expected: 60
GO

-- Test SELECT
DECLARE @sum2 INT = 0;
SELECT @sum2 = @sum2 + val FROM test_int;
SELECT @sum2 AS result; -- Expected: 60
GO

-- Test UPDATE
DECLARE @concat VARCHAR(200) = '';
UPDATE test_str SET name = name, @concat = @concat + name;
SELECT @concat AS result; -- Expected: 'ABC'
GO

-- Test with delimiter
DECLARE @concat2 VARCHAR(200) = '';
UPDATE test_str SET name = name, @concat2 = @concat2 + CASE WHEN @concat2 = '' THEN '' ELSE ',' END + name;
SELECT @concat2 AS result; -- Expected: ',A,B,C' or similar
GO

-- Test UPDATE with multiple variables
DECLARE @sum INT = 0, @concat VARCHAR(200) = '', @count INT = 0;
UPDATE test_multi 
SET val = val, 
    @sum = @sum + val, 
    @concat = @concat + name + '|',
    @count = @count + 1;
SELECT @sum AS sum_result, @concat AS concat_result, @count AS count_result;
GO
-- Expected: sum=600, concat='First|Second|Third|', count=3



-- Test UPDATE with WHERE
DECLARE @sum INT = 0;
UPDATE test_where SET val = val, @sum = @sum + val WHERE status = 'active';
SELECT @sum AS result; -- Expected: 40 (10+30)
GO

-- Test SELECT with WHERE
DECLARE @sum2 INT = 0;
SELECT @sum2 = @sum2 + val FROM test_where WHERE status = 'inactive';
SELECT @sum2 AS result; -- Expected: 60 (20+40)
GO

-- Test with NULL values in numeric column
DECLARE @sum INT = 0;
UPDATE test_null SET val = val, @sum = @sum + ISNULL(val, 0);
SELECT @sum AS result; -- Expected: 80
GO

-- Test with NULL values in string column
DECLARE @concat VARCHAR(200) = '';
UPDATE test_null SET name = name, @concat = @concat + ISNULL(name, '');
SELECT @concat AS result; -- Expected: 'ABD'
GO

-- Test UPDATE on empty table
DECLARE @sum INT = 100;
UPDATE test_empty SET val = val, @sum = @sum + val;
SELECT @sum AS result; -- Expected: 100 (unchanged)
GO

-- Test SELECT on empty table
DECLARE @sum2 INT = 100;
SELECT @sum2 = @sum2 + val FROM test_empty;
SELECT @sum2 AS result; -- Expected: 100 (unchanged)
GO

-- Test UPDATE
DECLARE @sum INT = 10;
UPDATE test_single SET val = val, @sum = @sum + val;
SELECT @sum AS result; -- Expected: 60
GO

-- Test with DECIMAL
DECLARE @dec_sum DECIMAL(10,2) = 0;
UPDATE test_numeric SET int_val = int_val, @dec_sum = @dec_sum + decimal_val;
SELECT @dec_sum AS result; -- Expected: 31.00

-- Test with FLOAT
DECLARE @float_sum FLOAT = 0;
UPDATE test_numeric SET int_val = int_val, @float_sum = @float_sum + float_val;
SELECT @float_sum AS result; -- Expected: 30.5
GO

-- Test with BIGINT
DECLARE @bigint_sum BIGINT = 0;
UPDATE test_numeric SET int_val = int_val, @bigint_sum = @bigint_sum + bigint_val;
SELECT @bigint_sum AS result; -- Expected: 3000000000
GO



-- Test multiplication
DECLARE @product INT = 1;
UPDATE test_math SET val = val, @product = @product * val;
SELECT @product AS result; -- Expected: 24 (1*2*3*4)
GO

-- Test subtraction
DECLARE @diff INT = 100;
UPDATE test_math SET val = val, @diff = @diff - val;
SELECT @diff AS result; -- Expected: 91 (100-2-3-4)
GO

-- Test mixed operations
DECLARE @mixed INT = 0;
UPDATE test_math SET val = val, @mixed = @mixed + val * 2;
SELECT @mixed AS result; -- Expected: 18 (2*2 + 3*2 + 4*2)
GO

-- Test UPDATE where variable is used to update column
DECLARE @running INT = 0;
UPDATE test_col_assign 
SET @running = @running + val, 
    running_total = @running;
SELECT * FROM test_col_assign ORDER BY id;
-- Expected: rows with running_total showing cumulative sum
GO

-- Test UPDATE with JOIN
DECLARE @sum INT = 0;
UPDATE m 
SET m.val = m.val, 
    @sum = @sum + m.val * l.multiplier
FROM test_main m
INNER JOIN test_lookup l ON m.id = l.id;
SELECT @sum AS result; -- Expected: 200 (10*2 + 20*3 + 30*4)
GO

-- Test SELECT with JOIN
DECLARE @sum2 INT = 0;
SELECT @sum2 = @sum2 + m.val * l.multiplier
FROM test_main m
INNER JOIN test_lookup l ON m.id = l.id;
SELECT @sum2 AS result; -- Expected: 200
GO

-- Insert 1000 rows
DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO test_large VALUES (@i, @i);
    SET @i = @i + 1;
END
GO

-- Test UPDATE
DECLARE @sum INT = 0;
UPDATE test_large SET val = val, @sum = @sum + val;
SELECT @sum AS result; -- Expected: 500500 (sum of 1 to 1000)
GO

-- Test SELECT
DECLARE @sum2 INT = 0;
SELECT @sum2 = @sum2 + val FROM test_large;
SELECT @sum2 AS result; -- Expected: 500500
GO

-- Test complex string concatenation
DECLARE @result VARCHAR(200) = '';
UPDATE test_str_complex 
SET prefix = prefix, 
    @result = @result + '[' + prefix + '-' + suffix + ']';
SELECT @result AS result; -- Expected: '[A-X][B-Y][C-Z]'
GO

-- Test UPDATE with CASE
DECLARE @sum_a INT = 0, @sum_b INT = 0;
UPDATE test_case 
SET val = val,
    @sum_a = CASE WHEN category = 'A' THEN @sum_a + val ELSE @sum_a END,
    @sum_b = CASE WHEN category = 'B' THEN @sum_b + val ELSE @sum_b END;
SELECT @sum_a AS sum_a, @sum_b AS sum_b; -- Expected: sum_a=40, sum_b=60
GO

-- Test row counter
DECLARE @counter INT = 0;
UPDATE test_counter SET val = val, @counter = @counter + 1;
SELECT @counter AS result; -- Expected: 3
GO

-- Test with initial non-zero value
DECLARE @sum INT = 100;
UPDATE test_init SET val = val, @sum = @sum + val;
SELECT @sum AS result; -- Expected: 130 (100+5+10+15)
GO

-- Test with initial string
DECLARE @str VARCHAR(100) = 'START:';
UPDATE test_init SET val = val, @str = @str + CAST(val AS VARCHAR(10)) + ',';
SELECT @str AS result; -- Expected: 'START:5,10,15,'
GO

-- Test where variable affects the update
DECLARE @prev INT = 0, @sum INT = 0;
UPDATE test_self 
SET @sum = @sum + val,
    val = val + @prev,
    @prev = val;
SELECT @sum AS sum_result, @prev AS prev_result;
SELECT * FROM test_self ORDER BY id;
GO

-- Test with datetime
DECLARE @date DATETIME = '2024-01-01', @total_days INT = 0;
UPDATE test_datetime 
SET days_to_add = days_to_add, 
    @total_days = @total_days + days_to_add;
SELECT @total_days AS result; -- Expected: 6
GO

BEGIN TRANSACTION;
    DECLARE @sum INT = 0;
    UPDATE test_tran SET val = val, @sum = @sum + val;
    SELECT @sum AS result; -- Expected: 30
ROLLBACK TRANSACTION;
GO

-- Verify rollback doesn't affect variable
DECLARE @sum2 INT = 0;
UPDATE test_tran SET val = val, @sum2 = @sum2 + val;
SELECT @sum2 AS result; -- Expected: 30 (data unchanged by rollback)
GO

-- Test UPDATE with TOP
DECLARE @sum INT = 0;
UPDATE TOP(2) test_top SET val = val, @sum = @sum + val;
SELECT @sum AS result; -- Expected: Sum of first 2 rows processed
GO

-- Test conversion during accumulation
DECLARE @sum INT = 0;
UPDATE test_convert 
SET int_val = int_val, 
    @sum = @sum + int_val + CAST(str_val AS INT);
SELECT @sum AS result; -- Expected: 425 (100+50+200+75)
GO

-- Nested subqueries with variables
DECLARE @sum INT = 0;
UPDATE test_nested 
SET val = val, 
    @sum = @sum + (SELECT COUNT(*) FROM test_other WHERE test_other.id = test_nested.id);
SELECT @sum AS result;
GO

-- Variable used in WHERE clause of same UPDATE
DECLARE @threshold INT = 10;
UPDATE test_dynamic 
SET val = val, 
    @threshold = @threshold + 5
WHERE val > @threshold;
SELECT @threshold AS result;
GO

-- Multiple variables with different data types in single UPDATE
DECLARE @int_sum INT = 0, @str_concat NVARCHAR(100) = N'', @float_avg FLOAT = 0, @count INT = 0;
UPDATE test_mixed_types 
SET val = val,
    @int_sum = @int_sum + int_col,
    @str_concat = @str_concat + nvarchar_col + N'|',
    @float_avg = (@float_avg * @count + float_col) / (@count + 1),
    @count = @count + 1;
SELECT @int_sum, @str_concat, @float_avg, @count;
GO

-- Variable assignment with COALESCE/ISNULL
DECLARE @first_non_null VARCHAR(50) = NULL;
UPDATE test_coalesce 
SET val = val,
    @first_non_null = COALESCE(@first_non_null, nullable_col);
SELECT @first_non_null AS result;
GO

-- Variable assignment with aggregate functions
DECLARE @max_so_far INT = 0;
UPDATE test_running_max 
SET val = val,
    @max_so_far = CASE WHEN val > @max_so_far THEN val ELSE @max_so_far END;
SELECT @max_so_far AS result;
GO

-- Cross-database UPDATE with variables (if applicable)
CREATE DATABASE test;
USE test;
DECLARE @sum INT = 0;
UPDATE master.dbo.test_cross_db 
SET val = val, 
    @sum = @sum + val;
SELECT @sum AS result;
GO

use master
GO

-- UPDATE with MERGE-like behavior using variables
DECLARE @inserted_count INT = 0, @updated_count INT = 0;
UPDATE target 
SET target.val = source.val,
    @updated_count = @updated_count + 1
FROM test_target target
INNER JOIN test_source source ON target.id = source.id;

INSERT INTO test_target (id, val)
SELECT id, val FROM test_source 
WHERE id NOT IN (SELECT id FROM test_target);
SET @inserted_count = @@ROWCOUNT;

SELECT @updated_count, @inserted_count;
GO

-- Variable with user-defined functions
DECLARE @sum INT = 0;
UPDATE test_udf 
SET val = val,
    @sum = @sum + dbo.custom_function(val);
SELECT @sum AS result;
GO

-- Concurrent variable updates
DECLARE @counter1 INT = 0, @counter2 INT = 0;
UPDATE test_concurrent 
SET val = val,
    @counter1 = @counter1 + CASE WHEN val % 2 = 0 THEN 1 ELSE 0 END,
    @counter2 = @counter2 + CASE WHEN val % 2 = 1 THEN 1 ELSE 0 END;
SELECT @counter1 AS even_count, @counter2 AS odd_count;
GO

-- Variable overflow scenarios
DECLARE @tiny TINYINT = 250;
UPDATE test_overflow 
SET val = val,
    @tiny = @tiny + val;
SELECT @tiny AS result;
GO

-- Unicode string concatenation
DECLARE @unicode NVARCHAR(100) = N'';
UPDATE test_unicode 
SET name = name,
    @unicode = @unicode + unicode_col + N'→';
SELECT @unicode AS result;
GO

-- Variable assignment with computed columns
DECLARE @sum INT = 0;
UPDATE test_computed 
SET base_val = base_val,
    @sum = @sum + computed_col;
SELECT @sum AS result;
GO

-- Recursive CTE with UPDATE and variables
DECLARE @total_levels INT = 0;

WITH recursive_cte AS (
    SELECT id, val, 1 as level 
    FROM test_recursive 
    WHERE parent_id IS NULL
    
    UNION ALL
    
    SELECT t.id, t.val, r.level + 1 
    FROM test_recursive t
    INNER JOIN recursive_cte r ON t.parent_id = r.id
)
UPDATE t
SET processed = 1,
    @total_levels = @total_levels + ISNULL(r.level, 0)
FROM test_recursive t
LEFT JOIN recursive_cte r ON t.id = r.id;

SELECT @total_levels AS total_accumulated_levels;
GO
SELECT * FROM test_recursive ORDER BY id;
GO

----------------------------------------------------------------------------------------------------------------------
-- These tests are error cases that differ compared to sql server output
----------------------------------------------------------------------------------------------------------------------
-- trigger scenarios
CREATE TABLE simple_test (id INT, val INT);
INSERT INTO simple_test VALUES (1, 10), (2, 20);
GO

CREATE TRIGGER trg_simple_test ON simple_test
AFTER UPDATE AS
BEGIN
    INSERT INTO simple_test VALUES (99, 99);
END;
GO

DECLARE @sum INT = 0;
UPDATE simple_test SET val = val, @sum = @sum + val;
SELECT @sum AS result;
GO

DROP TRIGGER trg_simple_test;
DROP TABLE simple_test;
GO


CREATE TABLE minimal_test (val INT);
INSERT INTO minimal_test VALUES (5);
GO

CREATE TRIGGER trg_minimal ON minimal_test
AFTER UPDATE AS BEGIN
    SELECT 1;
END;
GO

DECLARE @result INT = 0;
UPDATE minimal_test SET val = val, @result = @result + val;
SELECT @result;
GO

DROP TRIGGER trg_minimal;
DROP TABLE minimal_test;
GO

-- UPDATE with OUTPUT clause and variables
DECLARE @sum INT = 0;
UPDATE test_output 
SET val = val * 2,
    @sum = @sum + val
OUTPUT inserted.val, deleted.val;
SELECT @sum AS accumulated_original_values;
GO