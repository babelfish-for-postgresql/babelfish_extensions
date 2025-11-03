CREATE FUNCTION dbo.fnSimple()
RETURNS TABLE
AS
RETURN
(
    SELECT 5 AS Value
)
GO

SELECT * FROM dbo.fnSimple()
GO
DROP FUNCTION IF EXISTS dbo.fnSimple
GO


CREATE DATABASE [foo-bar]
GO

USE [foo-bar]
GO

create schema [sch-ema]
GO

CREATE FUNCTION [sch-ema].fnSimple()
RETURNS @@names TABLE
(
    Name VARCHAR(50)
)
AS
BEGIN
      INSERT INTO @@names (Name) VALUES ('Broken');
      INSERT INTO @@names (Name) VALUES ('Wing');
      RETURN;
END;
GO

CREATE FUNCTION [sch-ema].[fn_simple#1]()
RETURNS TABLE
AS
RETURN
(
    SELECT 'ABC@adf#$%#' AS Value
)
GO

CREATE FUNCTION fn_Simple()
RETURNS @names#1 TABLE
(
    Name VARCHAR(50)
)
AS
BEGIN
      INSERT INTO @names#1 (Name) VALUES ('Broken');
      INSERT INTO @names#1 (Name) VALUES ('Wing');
      RETURN;
END;
GO

SELECT * FROM fn_Simple();
GO
DROP FUNCTION IF EXISTS fn_Simple
GO

SELECT * FROM [sch-ema].fnSimple()
GO
DROP FUNCTION IF EXISTS [sch-ema].fnSimple
GO

SELECT * FROM [sch-ema].[fn_simple#1]()
GO
DROP FUNCTION IF EXISTS [sch-ema].[fn_simple#1]
GO

USE master
GO
DROP DATABASE IF EXISTS [foo-bar]
GO


CREATE DATABASE [data-base_name]
GO

USE [data-base_name]
GO

CREATE SCHEMA [sch-ema_test]
GO

CREATE FUNCTION [sch-ema_test].[fn_Sample-Test]()
RETURNS @@result_set1 TABLE
(
    [col-umn_1] VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @@result_set1 ([col-umn_1]) VALUES ('Test-1_A');
    RETURN;
END;
GO

SELECT * FROM [sch-ema_test].[fn_Sample-Test]()
GO
DROP FUNCTION IF EXISTS [sch-ema_test].[fn_Sample-Test]
GO

USE master
GO
DROP DATABASE IF EXISTS [data-base_name]
GO


CREATE DATABASE [My Database 2]
GO

USE [My Database 2]
GO

CREATE FUNCTION [fn Sample]()
RETURNS @result##table@$2 TABLE
(
    [column name 2] VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @result##table@$2 ([column name 2]) VALUES ('Test 2');
    RETURN;
END;
GO

SELECT * FROM dbo. [fn Sample]()
GO
DROP FUNCTION IF EXISTS [fn Sample]
GO

USE master
GO
DROP DATABASE IF EXISTS [My Database 2]
GO


CREATE DATABASE [db#@$]
GO

USE [db#@$]
GO

CREATE SCHEMA [sch#-@$]
GO

CREATE FUNCTION [sch#-@$].[fn#-a@$]()
RETURNS @@res#@$ TABLE
(
    [col@#$] VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @@res#@$ ([col@#$]) VALUES ('Test#@$');
    RETURN;
END;
GO

CREATE FUNCTION dbo.[fn#-a@$]()
RETURNS @@res#@$ TABLE
(
    [col@#$] VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @@res#@$ ([col@#$]) VALUES ('Soln#@$');
    RETURN;
END;
GO

SELECT * FROM [fn#-a@$]()
GO
DROP FUNCTION IF EXISTS [fn#-a@$]
GO

SELECT * FROM [sch#-@$].[fn#-a@$]()
GO
DROP FUNCTION IF EXISTS [sch#-@$].[fn#-a@$]
GO

USE master
GO
DROP DATABASE IF EXISTS [db#@$]
GO


CREATE DATABASE [db@-#_$]
GO

USE [db@-#_$]
GO

CREATE SCHEMA [sch@-#_$]
GO

CREATE FUNCTION [sch@-#_$].[fn@-#_$]()
RETURNS @@res@#_$ TABLE
(
    [col@-#_$] VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @@res@#_$ ([col@-#_$]) VALUES ('Test@-#_$');
    RETURN;
END;
GO

SELECT * FROM [sch@-#_$].[fn@-#_$]()
GO
DROP FUNCTION IF EXISTS [sch@-#_$].[fn@-#_$]
GO

USE master
GO
DROP DATABASE IF EXISTS [db@-#_$]
GO


CREATE DATABASE [db---###$]
GO

USE [db---###$]
GO

CREATE SCHEMA [sch---###$$$]
GO

CREATE FUNCTION [sch---###$$$].[fn---###$$$]()
RETURNS @res###$$$ TABLE
(
    [col---###$$$] VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @res###$$$ ([col---###$$$]) VALUES ('Test---###$$$');
    RETURN;
END;
GO

SELECT * FROM [sch---###$$$].[fn---###$$$]()
GO
DROP FUNCTION IF EXISTS [sch---###$$$].[fn---###$$$]
GO


USE master
GO
DROP DATABASE IF EXISTS [db---###$]
GO


CREATE DATABASE [db-#$-#$-#$]
GO

USE [db-#$-#$-#$]
GO

CREATE SCHEMA [sch-#$-#$-#$]
GO

CREATE FUNCTION [sch-#$-#$-#$].[fn-#$-#$-#$]()
RETURNS @res#$#$#$ TABLE
(
    [col-#$-#$-#$] VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @res#$#$#$ ([col-#$-#$-#$]) VALUES ('Test-#$-#$-#$');
    RETURN;
END;
GO

SELECT * FROM [sch-#$-#$-#$].[fn-#$-#$-#$]()
GO
DROP FUNCTION IF EXISTS [sch-#$-#$-#$].[fn-#$-#$-#$]
GO

USE master
GO
DROP DATABASE IF EXISTS [db-#$-#$-#$]
GO


CREATE DATABASE [123-@#$-456]
GO

USE [123-@#$-456]
GO

CREATE SCHEMA [789-@#$-012]
GO

CREATE FUNCTION [789-@#$-012].[fn345-@#$-678]()
RETURNS @res123@#$456 TABLE
(
    [col789-@#$-012] VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @res123@#$456 ([col789-@#$-012]) VALUES ('Test123-@#$-456');
    RETURN;
END;
GO

SELECT * FROM [789-@#$-012].[fn345-@#$-678]()
GO
DROP FUNCTION IF EXISTS [789-@#$-012].[fn345-@#$-678]
GO

USE master
GO
DROP DATABASE IF EXISTS [123-@#$-456]
GO
