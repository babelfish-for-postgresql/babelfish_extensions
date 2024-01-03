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
