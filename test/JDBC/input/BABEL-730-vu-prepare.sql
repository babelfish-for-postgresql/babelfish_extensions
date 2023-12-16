CREATE DATABASE test_babel730
GO

USE test_babel730
GO

CREATE FUNCTION TestLogFunction(@input float)
RETURNS float
AS
BEGIN
  DECLARE @output float
  SET @output = LOG(@input)
  RETURN @output
END
GO

CREATE FUNCTION TestLogFunctionWithBase(@input float, @base float)
RETURNS float
AS
BEGIN
  DECLARE @output float
  SET @output = LOG(@input, @base)
  RETURN @output
END
GO

CREATE FUNCTION TestLog10Function(@input float)
RETURNS float
AS
BEGIN
  DECLARE @output float
  SET @output = LOG10(@input)
  RETURN @output
END
GO

CREATE PROCEDURE TestLogProcedure(@input float)
AS
BEGIN
    SELECT log(@input)
END
GO

CREATE PROCEDURE TestLogProcedureWithBase(@input float, @base float)
AS
BEGIN
    SELECT log(@input, @base)
END
GO

CREATE PROCEDURE TestLog10Procedure(@input float)
AS
BEGIN
    SELECT log10(@input)
END
GO

-- test log on a view
CREATE VIEW TestLogView AS
SELECT log(2.0) AS log_result
GO

CREATE VIEW TestLogBaseView AS
SELECT log(100, 10) AS log_result
GO

CREATE VIEW TestLog10View AS
SELECT log10(100) AS log_result
GO

