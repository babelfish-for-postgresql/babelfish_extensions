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

CREATE VIEW BABEL_730_LOG_VIEW AS
SELECT log(5) AS log, log(100, 10) AS log_2args, log10(100) AS log10
GO

CREATE FUNCTION TestBBF_LogFunction(@input float)
RETURNS float
AS
BEGIN
  DECLARE @output float
  SET @output = bbf_log(@input)
  RETURN @output
END
GO

CREATE FUNCTION TestBBF_LogFunctionWithBase(@input float, @base float)
RETURNS float
AS
BEGIN
  DECLARE @output float
  SET @output = bbf_log(@input, @base)
  RETURN @output
END
GO

CREATE FUNCTION TestBBF_Log10Function(@input float)
RETURNS float
AS
BEGIN
  DECLARE @output float
  SET @output = bbf_log10(@input)
  RETURN @output
END
GO

CREATE PROCEDURE TestBBF_LogProcedure(@input float)
AS
BEGIN
    SELECT bbf_log(@input)
END
GO

CREATE PROCEDURE TestBBF_LogProcedureWithBase(@input float, @base float)
AS
BEGIN
    SELECT bbf_log(@input, @base)
END
GO

CREATE PROCEDURE TestBBF_Log10Procedure(@input float)
AS
BEGIN
    SELECT bbf_log10(@input)
END
GO

CREATE VIEW BABEL_730_BBF_LOG_VIEW AS
SELECT bbf_log(5) AS log, bbf_log(100, 10) AS log_2args, bbf_log10(100) AS log10
GO
