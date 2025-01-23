-- TEST FOR CHAR
DECLARE @TestCases TABLE (
    FloatValue FLOAT,
    ScenarioDescription VARCHAR(200)
);

INSERT INTO @TestCases
SELECT FloatValue, Description FROM float_char_t1;

-- 1. Test Direct CAST/CONVERT
INSERT INTO TestResults (TestCategory, TestName, TestScenario, ExpectedResult, ActualResult)
SELECT 
    'Direct Conversion',
    'CAST vs CONVERT',
    tc.ScenarioDescription,
    CAST(tc.FloatValue AS CHAR(30)),
    CONVERT(CHAR(30), tc.FloatValue)
FROM @TestCases tc;

-- Display Results by Category
SELECT 
    TestCategory,
    TestName,
    TestScenario,
    ExpectedResult,
    ActualResult,
    TestStatus
FROM TestResults
ORDER BY TestCategory, TestID;

-- Test Stored Procedure Execution
DECLARE @FloatValue FLOAT;
DECLARE cur CURSOR FOR SELECT FloatValue FROM @TestCases;
OPEN cur;

FETCH NEXT FROM cur INTO @FloatValue;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC float_char_p1 @FloatValue;
    FETCH NEXT FROM cur INTO @FloatValue;
END

CLOSE cur;
DEALLOCATE cur;
GO

-- 2. Test Views
SELECT * FROM float_char_v1; 
SELECT * FROM float_char_v2; 
GO

-- 3. Test Functions
SELECT float_char_f1('123.4567')
SELECT float_char_f2('123.4567')
GO

-- TEST FOR VARCHAR

DECLARE @TestCases TABLE (
    FloatValue FLOAT,
    ScenarioDescription VARCHAR(200)
);

INSERT INTO @TestCases
SELECT FloatValue, Description FROM float_varchar_t1;

-- 1. Test Direct CAST/CONVERT
INSERT INTO TestResults_1 (TestCategory, TestName, TestScenario, ExpectedResult, ActualResult)
SELECT 
    'Direct Conversion',
    'CAST vs CONVERT',
    tc.ScenarioDescription,
    CAST(tc.FloatValue AS VARCHAR(30)),
    CONVERT(VARCHAR(30), tc.FloatValue)
FROM @TestCases tc;

-- Display Results by Category
SELECT 
    TestCategory,
    TestName,
    TestScenario,
    ExpectedResult,
    ActualResult,
    TestStatus
FROM TestResults_1
ORDER BY TestCategory, TestID;

-- Test Stored Procedure Execution
DECLARE @FloatValue FLOAT;
DECLARE cur CURSOR FOR SELECT FloatValue FROM @TestCases;
OPEN cur;

FETCH NEXT FROM cur INTO @FloatValue;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC float_varchar_p1 @FloatValue;
    FETCH NEXT FROM cur INTO @FloatValue;
END

CLOSE cur;
DEALLOCATE cur;
GO


-- 2. Test Views
SELECT * FROM float_varchar_v1; 
SELECT * FROM float_varchar_v2; 
GO

-- 3. Test Functions
SELECT float_varchar_f1('123.4567')
SELECT float_varchar_f2('123.4567')
GO

-- 4. Test Convert/CAST in WHERE
SELECT COUNT(*) FROM float_varchar_t1 where length(CAST(FloatValue as VARCHAR)) < 8;
GO
SELECT COUNT(*) FROM float_varchar_t1 WHERE length(CONVERT(VARCHAR(30),FloatValue)) = 30;
GO

-- 5. Test Insuffiecient String Length
SELECT CAST(CAST('214555.32435254' AS FLOAT) AS VARCHAR(5));
GO
SELECT CAST(CAST('214555.32435254' AS FLOAT) AS CHAR(5));
GO

-- 6. Test Special Values
SELECT CAST(CAST('NaN' as Float) as VARCHAR(30))
GO
SELECT CAST(CAST('NaN' as Float) as CHAR(30))
GO
SELECT CAST(CAST('Inf' as Float) as VARCHAR)
GO
SELECT CAST(CAST('Inf' as Float) as CHAR)
GO

-- 7. Test Constraints
INSERT INTO float_char_t2 VALUES('-1.245243')
GO
INSERT INTO float_varchar_t2 VALUES('-1.245243')
GO

-- 8. Test With Variables
DECLARE @flt1 Float = 1.3242335
DECLARE @flt2 Float = -54235.4322
SELECT cast(@flt1*@flt2 as varchar(30)),cast(@flt1/@flt2 as varchar(30)),cast(@flt1+@flt2 as char(30)),cast(@flt1/@flt2 as char(30))
GO