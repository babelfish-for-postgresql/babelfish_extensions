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