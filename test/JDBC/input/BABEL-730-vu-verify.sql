-- verify log function return value datatype
SELECT * INTO test_log FROM
         (
            SELECT log(5) AS log, log(100, 10) AS log_2args, log10(100) AS log10
         )AS p
GO

SELECT * FROM test_log
GO

SELECT TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'test_log'
GO

-- test natural log with zero/negtive value/postive value/float value
SELECT log(0)
GO

SELECT log(1)
GO

SELECT log(-1)
GO

SELECT log(5)
GO

SELECT log(5.5)
GO

-- test log with base argument
SELECT log(-2, 2)
GO

SELECT log(0, 2)
GO

SELECT log(1, 2)
GO

SELECT log(8, 2)
GO

SELECT log(8.5, 2)
GO

SELECT log(1, 10)
GO

SELECT log(10, 10)
GO

SELECT log(100, 10)
GO

SELECT log(100.10, 10)
GO

SELECT log(-8, -2)
GO

SELECT log(-8, 0)
GO

-- test log10 with zero/negtive value/postive value/float value
SELECT log10(0)
GO

SELECT log10(1)
GO

SELECT log10(-1)
GO

SELECT log10(5)
GO

SELECT log10(5.5)
GO

SELECT log10(100)
GO

-- test user defined function with log function
SELECT TestLogFunction(5)
GO

SELECT TestLogFunctionWithBase(100, 10)
GO

SELECT TestLog10Function(100)
GO

-- test user defined procedure with log function
EXECUTE TestLogProcedure 5
GO

EXECUTE TestLogProcedureWithBase 100, 10
GO

EXECUTE TestLog10Procedure 100
GO


-- test string value as input argument of log functions (implicit casting)
SELECT log('5')
GO

SELECT log('100', '10')
GO

SELECT log10('100')
GO

-- test variable with log function
DECLARE @num INT = 5
SELECT log(@num)
GO

DECLARE @num INT = 100
DECLARE @num2 INT = 10
SELECT log(@num, @num2)
GO

DECLARE @num INT = 100
SELECT log10(@num)
GO

DECLARE @strVar VARCHAR(10) = '5'
SELECT log(@strVar)
GO

DECLARE @strVar VARCHAR(10) = '100'
DECLARE @strVar2 VARCHAR(10) = '10'
SELECT log(@strVar, @strVar2)
GO

DECLARE @strVar VARCHAR(10) = '100'
SELECT log10(@strVar)
GO

SELECT * FROM BABEL_730_LOG_VIEW
GO

-- test bbf_log function to fix upgrade tests failures
SELECT bbf_log(5)
GO

SELECT bbf_log10(10)
GO

SELECT bbf_log(100,10)
GO

SELECT TestBBF_LogFunction(5)
GO

SELECT TestBBF_LogFunctionWithBase(100, 10)
GO

SELECT TestBBF_Log10Function(100)
GO

-- test user defined procedure with log function
EXECUTE TestBBF_LogProcedure 5
GO

EXECUTE TestBBF_LogProcedureWithBase 100, 10
GO

EXECUTE TestBBF_Log10Procedure 100
GO

SELECT * FROM BABEL_730_BBF_LOG_VIEW
GO
