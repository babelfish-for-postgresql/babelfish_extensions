 /*
  * ======================================================================================================================
  *                                                   Jira - BABEL-6117
  *                                     DATETIME TO BINARY CAST TEST CASES SUMMARY
  * ======================================================================================================================
  *
  *  #    |                    Test Case                     |        Type         |                    Remark                   |
  * |-----|--------------------------------------------------|---------------------|---------------------------------------------|
  * |  1  | CAST datetime to BINARY(4)                      | Basic               | Tests truncation to 4 bytes                  |
  * |  2  | CAST datetime to BINARY(16)                     | Basic               | Tests padding to 16 bytes                    |
  * |  3  | CAST minimum datetime to BINARY(8)              | Edge Case           | Tests 1900-01-01 00:00:00.000                |
  * |  4  | CAST maximum datetime to BINARY(8)              | Edge Case           | Tests 2099-12-31 23:59:59.997                |
  * |  5  | CAST NULL datetime to BINARY(8)                 | NULL Handling       | Tests NULL value conversion                  |
  * |  6  | CONVERT datetime to BINARY(8)                   | Basic               | Tests CONVERT function                       |
  * |  7  | CONVERT datetime to BINARY(4)                   | Basic               | Tests CONVERT with 4 bytes                   |
  * |  8  | CONVERT datetime to BINARY(16)                  | Basic               | Tests CONVERT with 16 bytes                  |
  * |  9  | CONVERT minimum datetime to BINARY(8)           | Edge Case           | Tests CONVERT with min datetime              |
  * | 10  | CONVERT maximum datetime to BINARY(8)           | Edge Case           | Tests CONVERT with max datetime              |
  * | 11  | CONVERT NULL datetime to BINARY(8)              | NULL Handling       | Tests CONVERT with NULL                      |
  * | 12  | Basic CAST datetime to BINARY(8)                | Basic               | Standard 8-byte conversion                   |
  * | 13  | CAST datetime format 'Jan 1 2023 12:30PM'       | Format Test         | Tests text datetime format                   |
  * | 14  | CAST datetime format '2023/01/01 12:30:45'      | Format Test         | Tests slash-separated format                 |
  * | 15  | CAST datetime format '01-01-2023 12:30:45.123'  | Format Test         | Tests dash-separated format                  |
  * | 16  | Declare Variable.                               | Validation          | Tests datetime->binary->datetime             |
  * | 17  | Table UPDATE with conversion                    | Table Operations    | Tests UPDATE with binary conversion          |
  * | 18  | SELECT table data with conversion               | Table Operations    | Tests SELECT with converted data             |
  * | 19  | CAST computed datetime (DATEADD)                | Expressions         | Tests DATEADD expression conversion          |
  * | 20  | CONVERT computed datetime                       | Expressions         | Tests DATEADD with CONVERT                   |
  * | 21  | CASE expression with conversion                 | Control Flow        | Tests CASE statement with conversion         |
  * | 22  | WHERE clause with binary comparison             | Filtering           | Tests WHERE with binary comparison           |
  * | 23  | Subqueries with MIN/MAX conversion              | Subqueries          | Tests aggregate functions in subqueries      |
  * | 24  | JOIN operations with conversion                  | Joins               | Tests JOIN with binary conversion           |
  * | 25  | Aggregation function with conversion            | Aggregation         | Tests COUNT with conversion                  |
  * | 26  | UNION with conversion                            | Set Operations      | Tests UNION with binary conversion          |
  * | 27  | Different precision datetime values             | Precision Test      | Tests various millisecond precisions         |
  * | 28  | Variable assignments in WHILE loop              | Control Flow        | Tests loop with conversion                   |
  * | 29  | CTE with conversion                              | Advanced SQL        | Tests Common Table Expression               |
  * | 30  | PIVOT operations with conversion                | Advanced SQL        | Tests PIVOT with binary conversion           |
  * | 31  | Window functions with conversion                | Advanced SQL        | Tests ROW_NUMBER with conversion             |
  * | 32  | Variable assignment with conversion             | Variables           | Tests variable assignment                    |
  * | 33  | Multiple binary size conversions               | Multi-Size Test     | Tests 4,8,12,16 byte conversions              |
  * | 34  | Error handling with BINARY(1)                  | Error Case          | Tests invalid size - should handle gracefully |
  * | 35  | Error handling with BINARY(2)                  | Error Case          | Tests invalid size - should handle gracefully |
  * | 36  | Complex datetime expression                     | Complex Expression  | Tests DATEDIFF/DATEADD combination           |
  * | 37  | View with conversion                            | Dependent Objects   | Tests view using conversion                  |
  * | 38  | User-Defined Function                          | Dependent Objects   | Tests scalar UDF with conversion              |
  * | 39  | User-Defined Function different value          | Dependent Objects   | Tests UDF with different input                |
  * | 40  | Table-Valued Function                          | Dependent Objects   | Tests TVF with conversion                     |
  * | 41  | Stored Procedure with OUTPUT                   | Dependent Objects   | Tests procedure with OUTPUT parameter         |
  * | 42  | Computed Column INSERT                          | Dependent Objects   | Tests computed column functionality          |
  * | 43  | Computed Column SELECT                          | Dependent Objects   | Tests computed column retrieval              |
  * | 44  | Index usage on computed column                 | Dependent Objects   | Tests index on computed binary column         |
  * | 45  | Trigger test - INSERT                          | Dependent Objects   | Tests trigger firing on INSERT                |
  * | 46  | Trigger test - Verification                    | Dependent Objects   | Tests trigger execution result                |
  * | 47  | Check Constraint test                          | Dependent Objects   | Tests constraint with conversion              |
  * | 48  | Check Constraint verification                  | Dependent Objects   | Tests constraint validation                   |
  * | 49  | Default Constraint test                        | Dependent Objects   | Tests default value with conversion           |
  * | 50  | Default Constraint verification                | Dependent Objects   | Tests default constraint behavior             |
  *
  * ======================================================================================================================
  */

-- Test Case 1: CAST datetime to BINARY(4)
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(4));
GO

-- Test Case 2: CAST datetime to BINARY(16)
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(16));
GO

-- Test Case 3: CAST minimum datetime to BINARY(8)
SELECT CAST(CAST('1900-01-01 00:00:00.000' AS DATETIME) AS BINARY(8));
GO

-- Test Case 4: CAST maximum datetime to BINARY(8)
SELECT CAST(CAST('2099-12-31 23:59:59.997' AS DATETIME) AS BINARY(8));
GO

-- Test Case 4.1: Max datetime - 9999-12-31 23:59:59.997
SELECT CAST(CAST('9999-12-31 23:59:59.997' AS DATETIME) AS BINARY(8));
GO

-- Test Case 5: CAST NULL datetime to BINARY(8)
SELECT CAST(CAST(NULL AS DATETIME) AS BINARY(8));
GO

-- Test Case 6: CONVERT datetime to BINARY(8)
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.123' AS DATETIME));
GO

-- Test Case 7: CONVERT datetime to BINARY(4)
SELECT CONVERT(BINARY(4), CAST('2023-01-01 12:30:45.123' AS DATETIME));
GO

-- Test Case 8: CONVERT datetime to BINARY(16)
SELECT CONVERT(BINARY(16), CAST('2023-01-01 12:30:45.123' AS DATETIME));
GO

-- Test Case 9: CONVERT minimum datetime to BINARY(8)
SELECT CONVERT(BINARY(8), CAST('1900-01-01 00:00:00.000' AS DATETIME));
GO

-- Test Case 10: CONVERT maximum datetime to BINARY(8)
SELECT CONVERT(BINARY(8), CAST('2099-12-31 23:59:59.997' AS DATETIME));
GO

-- Test Case 11: CONVERT NULL datetime to BINARY(8)
SELECT CONVERT(BINARY(8), CAST(NULL AS DATETIME));
GO

-- Test Case 12: Basic CAST datetime to BINARY(8)
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(8));
GO

-- Test Case 13: CAST datetime format 'Jan 1 2023 12:30PM' to BINARY(8)
SELECT CAST(CAST('Jan 1 2023 12:30PM' AS DATETIME) AS BINARY(8));
GO

-- Test Case 14: CAST datetime format '2023/01/01 12:30:45' to BINARY(8)
SELECT CAST(CAST('2023/01/01 12:30:45' AS DATETIME) AS BINARY(8));
GO

-- Test Case 15: CAST datetime format '01-01-2023 12:30:45.123' to BINARY(8)
SELECT CAST(CAST('01-01-2023 12:30:45.123' AS DATETIME) AS BINARY(8));
GO

-- Test Case 16: Declare variable
DECLARE @original DATETIME = '2023-06-15 14:25:30.456';
DECLARE @binary_val BINARY(8) = CONVERT(BINARY(8), @original);
SELECT @original AS original, @binary_val AS binary_val;
GO

-- Test Case 17: Table UPDATE with datetime to binary conversion
UPDATE test_datetime_binary 
SET bin_col = CONVERT(BINARY(8), dt_col) 
WHERE dt_col IS NOT NULL;
GO

-- Test Case 18: SELECT table data with binary conversion
SELECT id, dt_col, bin_col FROM test_datetime_binary ORDER BY id;
GO

-- Test Case 19: CAST computed datetime expression (DATEADD) to BINARY(8)
SELECT CAST(DATEADD(day, 100, '2023-01-01') AS BINARY(8));
GO

-- Test Case 20: CONVERT computed datetime expression to BINARY(8)
SELECT CONVERT(BINARY(8), DATEADD(hour, -5, '2023-06-15 12:00:00'));
GO

-- Test Case 21: CASE expression with datetime to binary conversion
SELECT 
    CASE 
        WHEN 1=1 THEN CAST(CAST('2023-01-01' AS DATETIME) AS BINARY(8))
        ELSE CAST(CAST('2024-01-01' AS DATETIME) AS BINARY(8))
    END;
GO

-- Test Case 22: WHERE clause with datetime to binary comparison
SELECT * FROM test_datetime_binary 
WHERE CAST(dt_col AS BINARY(8)) = CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(8));
GO

-- Test Case 23: Subqueries with MIN/MAX datetime to binary conversion
SELECT 
    (SELECT CAST(MAX(dt_col) AS BINARY(8)) FROM test_datetime_binary) AS max_dt_binary,
    (SELECT CAST(MIN(dt_col) AS BINARY(8)) FROM test_datetime_binary) AS min_dt_binary;
GO

-- Test Case 24: JOIN operations with datetime to binary conversion
SELECT t1.id, t1.dt_col, CAST(t1.dt_col AS BINARY(8)) AS dt_binary
FROM test_datetime_binary t1
INNER JOIN test_datetime_binary t2 ON CAST(t1.dt_col AS BINARY(8)) = CAST(t2.dt_col AS BINARY(8))
WHERE t1.dt_col IS NOT NULL;
GO

-- Test Case 25: Aggregation function with datetime to binary conversion
SELECT COUNT(CAST(dt_col AS BINARY(8))) AS binary_count
FROM test_datetime_binary
WHERE dt_col IS NOT NULL;
GO

-- Test Case 26: UNION with datetime to binary conversion
SELECT CAST(CAST('2023-01-01' AS DATETIME) AS BINARY(8)) AS dt_binary
UNION
SELECT CAST(CAST('2023-12-31' AS DATETIME) AS BINARY(8));
GO

-- Test Case 27: Different precision datetime values to binary conversion
SELECT CAST(CAST('2023-01-01 12:30:45.000' AS DATETIME) AS BINARY(8)) AS no_ms;
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(8)) AS with_ms;
SELECT CAST(CAST('2023-01-01 12:30:45.997' AS DATETIME) AS BINARY(8)) AS max_ms;
GO

-- Test Case 28: Variable assignments in WHILE loop with datetime to binary
DECLARE @counter INT = 1;
DECLARE @dt DATETIME;
DECLARE @bin BINARY(8);

WHILE @counter <= 3
BEGIN
    SET @dt = DATEADD(day, @counter, '2023-01-01');
    SET @bin = CAST(@dt AS BINARY(8));
    SELECT @counter AS iteration, @dt AS datetime_val, @bin AS binary_val;
    SET @counter = @counter + 1;
END;
GO

-- Test Case 29: CTE (Common Table Expression) with datetime to binary
WITH datetime_cte AS (
    SELECT CAST('2023-01-01' AS DATETIME) AS dt
    UNION ALL
    SELECT CAST('2023-06-15' AS DATETIME)
    UNION ALL
    SELECT CAST('2023-12-31' AS DATETIME)
)
SELECT dt, CAST(dt AS BINARY(8)) AS dt_binary
FROM datetime_cte
order by dt;
GO

-- Test Case 30: PIVOT operations with datetime to binary conversion
SELECT *
FROM (
    SELECT 
        'dt_' + CAST(id AS VARCHAR(10)) AS pivot_col,
        CAST(dt_col AS BINARY(8)) AS binary_val
    FROM test_datetime_binary
    WHERE dt_col IS NOT NULL
) AS source_table
PIVOT (
    MAX(binary_val)
    FOR pivot_col IN ([dt_1], [dt_2], [dt_3])
) AS pivot_table;
GO

-- Test Case 31: Window functions with datetime to binary conversion
SELECT 
    id,
    dt_col,
    CAST(dt_col AS BINARY(8)) AS dt_binary,
    ROW_NUMBER() OVER (ORDER BY CAST(dt_col AS BINARY(8))) AS row_num
FROM test_datetime_binary
WHERE dt_col IS NOT NULL;
GO

-- Test Case 32: Variable assignment with datetime to binary conversion
DECLARE @input_dt DATETIME = '2023-07-04 16:45:30.789';
DECLARE @output_bin BINARY(8);
SET @output_bin = CAST(@input_dt AS BINARY(8));
SELECT @input_dt AS input_datetime, @output_bin AS output_binary;
GO

-- Test Case 33: Multiple binary size conversions in single statement
SELECT 
    CAST(CAST('2023-01-01' AS DATETIME) AS BINARY(4)) AS bin4,
    CAST(CAST('2023-01-01' AS DATETIME) AS BINARY(8)) AS bin8,
    CAST(CAST('2023-01-01' AS DATETIME) AS BINARY(12)) AS bin12,
    CAST(CAST('2023-01-01' AS DATETIME) AS BINARY(16)) AS bin16;
GO

-- Test Case 34: Error handling with BINARY(1) size
SELECT CAST(CAST('2023-01-01' AS DATETIME) AS BINARY(1));
GO

-- Test Case 35: Error handling with BINARY(2) size
SELECT CAST(CAST('2023-01-01' AS DATETIME) AS BINARY(2));
GO

-- Test Case 36: Complex datetime expression with DATEDIFF/DATEADD to binary
SELECT 
    CAST(
        DATEADD(minute, 
            DATEDIFF(minute, '1900-01-01', '2023-01-01'), 
            '1900-01-01'
        ) AS BINARY(8)
    ) AS complex_dt_binary;
GO


/*
 * ======================================================================================================================
 *                                          DEPENDENT OBJECTS TESTS
 * ======================================================================================================================
 */

-- Test Case 37: View with datetime to binary conversion
SELECT * FROM vw_datetime_binary ORDER BY id;
GO

-- Test Case 38: User-Defined Function with datetime to binary
SELECT dbo.fn_datetime_to_binary('2023-01-01 12:30:45.123') AS function_result;
GO

-- Test Case 39: User-Defined Function with different datetime value
SELECT dbo.fn_datetime_to_binary('2023-12-25 15:45:30.789') AS static_dt_binary;
GO

-- Test Case 40: Table-Valued Function with datetime range
SELECT * FROM dbo.fn_get_datetime_binary_range('1900-01-01', '2050-01-01');
GO

-- Test Case 41: Stored Procedure with OUTPUT parameter
DECLARE @test_dt DATETIME = '2023-07-15 10:30:00.456';
DECLARE @result_bin BINARY(8);
EXEC sp_convert_datetime_binary @test_dt, @result_bin OUTPUT;
SELECT @test_dt AS input_datetime, @result_bin AS output_binary;
GO

-- Test Case 42: Computed Column INSERT test
INSERT INTO test_computed_binary (id, dt_col) VALUES 
(1, '2023-01-01 12:00:00'),
(2, '2023-06-15 18:30:45.123'),
(3, NULL);
GO

-- Test Case 43: Computed Column SELECT test
SELECT id, dt_col, computed_binary FROM test_computed_binary ORDER BY id;
GO

-- Test Case 44: Index usage on computed binary column
SELECT * FROM test_computed_binary 
WHERE computed_binary = CAST(CAST('2023-01-01 12:00:00' AS DATETIME) AS BINARY(8));
GO

-- Test Case 45: Trigger test - INSERT to fire trigger
INSERT INTO test_datetime_binary (id, dt_col) VALUES (100, '2023-08-01 14:25:30');
GO

-- Test Case 46: Trigger test - Verify trigger execution
SELECT * FROM test_computed_binary WHERE dt_col = '2023-08-01 14:25:30';
GO

-- Test Case 47: Check Constraint test with valid data
INSERT INTO test_constraint_binary VALUES (1, '2023-01-01 12:00:00');
INSERT INTO test_constraint_binary VALUES (2, NULL);
GO

-- Test Case 48: Check Constraint verification
SELECT * FROM test_constraint_binary;
GO

-- Test Case 49: Default Constraint test
INSERT INTO test_default_binary (id) VALUES (1);
INSERT INTO test_default_binary (id, dt_col) VALUES (2, '2023-05-15 09:30:15.456');
GO

-- Test Case 50: Default Constraint verification
SELECT id, dt_col, bin_col FROM test_default_binary;
GO

-- Test Case 51: Basic CAST datetime to BINARY( Typmod = 0)
SELECT CAST('2023-01-01 10:00:00' as binary) as Result;
GO

-- Test Case 52-63: CAST datetime to BINARY with typmod 1-12
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(1));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(2));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(3));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(4));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(5));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(6));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(7));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(8));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(9));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(10));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(11));
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(12));
GO

-- Test Case 64-75: CONVERT datetime to BINARY with typmod 1-12
SELECT CONVERT(BINARY(1), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(2), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(3), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(4), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(5), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(6), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(7), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(9), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(10), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(11), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(12), CAST('2023-01-01 12:30:45.456' AS DATETIME));
GO

-- Test Case 76-79: CAST datetime to BINARY with large typmod values
SELECT CAST(CAST('2023-01-01 12:30:45.789' AS DATETIME) AS BINARY(100));
SELECT CAST(CAST('2023-01-01 12:30:45.789' AS DATETIME) AS BINARY(1000));
SELECT CAST(CAST('2023-01-01 12:30:45.789' AS DATETIME) AS BINARY(5000));
SELECT CAST(CAST('2023-01-01 12:30:45.789' AS DATETIME) AS BINARY(8000));
GO

-- Test Case 80-83: CONVERT datetime to BINARY with large typmod values
SELECT CONVERT(BINARY(100), CAST('2023-01-01 12:30:45.321' AS DATETIME));
SELECT CONVERT(BINARY(1000), CAST('2023-01-01 12:30:45.321' AS DATETIME));
SELECT CONVERT(BINARY(5000), CAST('2023-01-01 12:30:45.321' AS DATETIME));
SELECT CONVERT(BINARY(8000), CAST('2023-01-01 12:30:45.321' AS DATETIME));
GO

-- Test Case 84-85: Maximum possible typmod for BINARY (8000)
SELECT CAST(CAST('2023-01-01 12:30:45.999' AS DATETIME) AS BINARY(8000));
SELECT CONVERT(BINARY(8000), CAST('2023-01-01 12:30:45.999' AS DATETIME));
GO

-- Test Case 86-95: Millisecond rounding tests with CAST
SELECT CAST(CAST('2023-01-01 12:30:45.000' AS DATETIME) AS BINARY(8)); -- .000
SELECT CAST(CAST('2023-01-01 12:30:45.001' AS DATETIME) AS BINARY(8)); -- .001
SELECT CAST(CAST('2023-01-01 12:30:45.002' AS DATETIME) AS BINARY(8)); -- .002 -> rounds to .003
SELECT CAST(CAST('2023-01-01 12:30:45.003' AS DATETIME) AS BINARY(8)); -- .003
SELECT CAST(CAST('2023-01-01 12:30:45.004' AS DATETIME) AS BINARY(8)); -- .004 -> rounds to .003
SELECT CAST(CAST('2023-01-01 12:30:45.005' AS DATETIME) AS BINARY(8)); -- .005 -> rounds to .007
SELECT CAST(CAST('2023-01-01 12:30:45.006' AS DATETIME) AS BINARY(8)); -- .006 -> rounds to .007
SELECT CAST(CAST('2023-01-01 12:30:45.007' AS DATETIME) AS BINARY(8)); -- .007
SELECT CAST(CAST('2023-01-01 12:30:45.998' AS DATETIME) AS BINARY(8)); -- .998 -> rounds to .997
SELECT CAST(CAST('2023-01-01 12:30:45.999' AS DATETIME) AS BINARY(8)); -- .999 -> rounds to next second
GO

-- Test Case 96-105: Millisecond rounding tests with CONVERT
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.000' AS DATETIME)); -- .000
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.001' AS DATETIME)); -- .001
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.002' AS DATETIME)); -- .002 -> rounds to .003
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.003' AS DATETIME)); -- .003
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.004' AS DATETIME)); -- .004 -> rounds to .003
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.005' AS DATETIME)); -- .005 -> rounds to .007
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.006' AS DATETIME)); -- .006 -> rounds to .007
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.007' AS DATETIME)); -- .007
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.998' AS DATETIME)); -- .998 -> rounds to .997
SELECT CONVERT(BINARY(8), CAST('2023-01-01 12:30:45.999' AS DATETIME)); -- .999 -> rounds to next second
GO

-- Test Case 106-115: Edge case millisecond values with different typmod
SELECT CAST(CAST('2023-01-01 12:30:45.123' AS DATETIME) AS BINARY(4));
SELECT CAST(CAST('2023-01-01 12:30:45.456' AS DATETIME) AS BINARY(4));
SELECT CAST(CAST('2023-01-01 12:30:45.789' AS DATETIME) AS BINARY(4));
SELECT CAST(CAST('2023-01-01 12:30:45.997' AS DATETIME) AS BINARY(4));
SELECT CONVERT(BINARY(16), CAST('2023-01-01 12:30:45.123' AS DATETIME));
SELECT CONVERT(BINARY(16), CAST('2023-01-01 12:30:45.456' AS DATETIME));
SELECT CONVERT(BINARY(16), CAST('2023-01-01 12:30:45.789' AS DATETIME));
SELECT CONVERT(BINARY(16), CAST('2023-01-01 12:30:45.997' AS DATETIME));
SELECT CAST(CAST('2023-01-01 12:30:45.333' AS DATETIME) AS BINARY(12));
SELECT CONVERT(BINARY(20), CAST('2023-01-01 12:30:45.667' AS DATETIME));
GO