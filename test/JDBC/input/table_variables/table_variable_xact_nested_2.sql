USE master
go

CREATE DATABASE babel_4263_db
go

USE babel_4263_db
go

CREATE SCHEMA babel_4263_schema
go

CREATE FUNCTION [babel_4263_schema].[babel_4263_fn_DatabaseSelect] (@DatabaseList nvarchar(max))
RETURNS @Database TABLE(DatabaseName nvarchar(max) NOT NULL)
AS
BEGIN
  DECLARE @Database01 TABLE(DatabaseName nvarchar(max),
                            DatabaseStatus bit)
  DECLARE @Database02 TABLE(DatabaseName nvarchar(max),
                            DatabaseStatus bit)
  DECLARE @DatabaseItem nvarchar(max)
  DECLARE @Position int
  SET @DatabaseList = LTRIM(RTRIM(@DatabaseList))
  SET @DatabaseList = REPLACE(@DatabaseList,' ','')
  SET @DatabaseList = REPLACE(@DatabaseList,'[','')
  SET @DatabaseList = REPLACE(@DatabaseList,']','')
  SET @DatabaseList = REPLACE(@DatabaseList,'''','')
  SET @DatabaseList = REPLACE(@DatabaseList,'"','')
  WHILE CHARINDEX(',,',@DatabaseList) > 0 SET @DatabaseList = REPLACE(@DatabaseList,',,',',')
  IF RIGHT(@DatabaseList,1) = ',' SET @DatabaseList = LEFT(@DatabaseList,LEN(@DatabaseList) - 1)
  IF LEFT(@DatabaseList,1) = ','  SET @DatabaseList = RIGHT(@DatabaseList,LEN(@DatabaseList) - 1)
  WHILE LEN(@DatabaseList) > 0
  BEGIN
    SET @Position = CHARINDEX(',', @DatabaseList)
    IF @Position = 0
    BEGIN
      SET @DatabaseItem = @DatabaseList
      SET @DatabaseList = ''
    END
    ELSE
    BEGIN
      SET @DatabaseItem = LEFT(@DatabaseList, @Position - 1)
      SET @DatabaseList = RIGHT(@DatabaseList, LEN(@DatabaseList) - @Position)
    END
    INSERT INTO @Database01 (DatabaseName) VALUES(@DatabaseItem)
  END
  UPDATE @Database01
  SET DatabaseStatus = 1
  WHERE DatabaseName NOT LIKE '-%'
  UPDATE @Database01
  SET  DatabaseName = RIGHT(DatabaseName,LEN(DatabaseName) - 1), DatabaseStatus = 0
  WHERE DatabaseName LIKE '-%'
  INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
  SELECT DISTINCT DatabaseName, DatabaseStatus
  FROM @Database01
  WHERE DatabaseName NOT IN('SYSTEM_DATABASES','USER_DATABASES')
  IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'SYSTEM_DATABASES' AND DatabaseStatus = 0)
  BEGIN
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('master', 0)
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('model', 0)
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('msdb', 0)
  END
  IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'SYSTEM_DATABASES' AND DatabaseStatus = 1)
  BEGIN
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('master', 1)
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('model', 1)
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('msdb', 1)
  END
  IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'USER_DATABASES' AND DatabaseStatus = 0)
  BEGIN
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
    SELECT [name], 0
    FROM sys.databases
    WHERE database_id > 4
  END
  IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'USER_DATABASES' AND DatabaseStatus = 1)
  BEGIN
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
    SELECT [name], 1
    FROM sys.databases
    WHERE database_id > 4
  END
  INSERT INTO @Database (DatabaseName)
  SELECT [name]
  FROM sys.databases
  WHERE [name] <> 'tempdb'
  AND source_database_id IS NULL
  INTERSECT
  SELECT DatabaseName
  FROM @Database02
  WHERE DatabaseStatus = 1
  EXCEPT
  SELECT DatabaseName
  FROM @Database02
  WHERE DatabaseStatus = 0
  RETURN
END
go

CREATE PROCEDURE [babel_4263_schema].[babel_4263_usp_DatabaseIntegrityCheck]
	@Databases nvarchar(max)
AS SET NOCOUNT ON
----------------------------------------------------------------------------------------------------
--// Declare variables //--
----------------------------------------------------------------------------------------------------
DECLARE @StartMessage nvarchar(max)
DECLARE @EndMessage nvarchar(max)
DECLARE @DatabaseMessage nvarchar(max)
DECLARE @ErrorMessage nvarchar(max)
DECLARE @CurrentID int
DECLARE @CurrentDatabase nvarchar(max)
DECLARE @CurrentCommand01 nvarchar(max)
DECLARE @CurrentCommandOutput01 int
DECLARE @tmpDatabases TABLE
(
ID int IDENTITY PRIMARY KEY,
DatabaseName nvarchar(max),
Completed bit
)
DECLARE @Error int
SET @Error = 0
----------------------------------------------------------------------------------------------------
--// Log initial information //--
----------------------------------------------------------------------------------------------------
SET @StartMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(@@PROCID)) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Parameters: @Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')
SET @StartMessage = @StartMessage + CHAR(13) + CHAR(10)
RAISERROR(@StartMessage,10,1) WITH NOWAIT
----------------------------------------------------------------------------------------------------
--// Select databases //--
----------------------------------------------------------------------------------------------------
IF @Databases IS NULL OR @Databases = ''
	BEGIN
		SET @ErrorMessage = 'The value for parameter @Databases is not supported.' + CHAR(13) + CHAR(10)
		RAISERROR(@ErrorMessage,16,1) WITH NOWAIT SET @Error = @@ERROR
	END
INSERT INTO @tmpDatabases (DatabaseName, Completed)
SELECT DatabaseName AS DatabaseName, 0 AS Completed
FROM babel_4263_schema.babel_4263_fn_DatabaseSelect (@Databases)
ORDER BY DatabaseName ASC
IF @@ERROR <> 0 OR @@ROWCOUNT = 0
	BEGIN
		SET @ErrorMessage = 'Error selecting databases.' + CHAR(13) + CHAR(10)
		RAISERROR(@ErrorMessage,16,1) WITH NOWAIT SET @Error = @@ERROR
	END
----------------------------------------------------------------------------------------------------
--// Check error variable //--
----------------------------------------------------------------------------------------------------
IF @Error <> 0
	GOTO Logging
----------------------------------------------------------------------------------------------------
--// Execute commands //--
----------------------------------------------------------------------------------------------------
WHILE EXISTS (
				SELECT *
				FROM @tmpDatabases WHERE Completed = 0
			)
		BEGIN

		SELECT TOP 1 @CurrentID = ID
			, @CurrentDatabase = DatabaseName
		FROM @tmpDatabases
		WHERE Completed = 0
		ORDER BY ID ASC
		-- Set database message

		SET @DatabaseMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
		SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabase) + CHAR(13) + CHAR(10)
		SET @DatabaseMessage = @DatabaseMessage + 'Status: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabase,'status') AS nvarchar) + CHAR(13) + CHAR(10)
		RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT

		IF DATABASEPROPERTYEX(@CurrentDatabase,'status') = 'ONLINE'
			BEGIN
				SET @CurrentCommand01 = 'DBCC CHECKDB (' + QUOTENAME(@CurrentDatabase) + ') '
				EXEC sp_executesql @CurrentCommand01

				SET @Error = @@ERROR
				IF @Error <> 0
					SET @CurrentCommandOutput01 = @Error
			END

			-- Update that the database is completed
			UPDATE @tmpDatabases
			SET Completed = 1
			WHERE ID = @CurrentID

			-- Clear variables
			SET @CurrentID = NULL
			SET @CurrentDatabase = NULL
			SET @CurrentCommand01 = NULL
			SET @CurrentCommandOutput01 = NULL

			RAISERROR('',10,1) WITH NOWAIT

	END
	----------------------------------------------------------------------------------------------------
	--// Log completing information //--
	----------------------------------------------------------------------------------------------------
	Logging:
		SET @EndMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120)
		RAISERROR(@EndMessage,10,1) WITH NOWAIT
	---------------------------------------------------------------------------------------------------- GO
go

EXECUTE babel_4263_schema.babel_4263_usp_DatabaseIntegrityCheck @Databases = NULL
go

USE master
go

DROP DATABASE babel_4263_db
go

---
-- Repeat
---
CREATE DATABASE babel_4263_db
go

USE babel_4263_db
go

CREATE SCHEMA babel_4263_schema
go

CREATE FUNCTION [babel_4263_schema].[babel_4263_fn_DatabaseSelect] (@DatabaseList nvarchar(max))
RETURNS @Database TABLE(DatabaseName nvarchar(max) NOT NULL)
AS
BEGIN
  DECLARE @Database01 TABLE(DatabaseName nvarchar(max),
                            DatabaseStatus bit)
  DECLARE @Database02 TABLE(DatabaseName nvarchar(max),
                            DatabaseStatus bit)
  DECLARE @DatabaseItem nvarchar(max)
  DECLARE @Position int
  SET @DatabaseList = LTRIM(RTRIM(@DatabaseList))
  SET @DatabaseList = REPLACE(@DatabaseList,' ','')
  SET @DatabaseList = REPLACE(@DatabaseList,'[','')
  SET @DatabaseList = REPLACE(@DatabaseList,']','')
  SET @DatabaseList = REPLACE(@DatabaseList,'''','')
  SET @DatabaseList = REPLACE(@DatabaseList,'"','')
  WHILE CHARINDEX(',,',@DatabaseList) > 0 SET @DatabaseList = REPLACE(@DatabaseList,',,',',')
  IF RIGHT(@DatabaseList,1) = ',' SET @DatabaseList = LEFT(@DatabaseList,LEN(@DatabaseList) - 1)
  IF LEFT(@DatabaseList,1) = ','  SET @DatabaseList = RIGHT(@DatabaseList,LEN(@DatabaseList) - 1)
  WHILE LEN(@DatabaseList) > 0
  BEGIN
    SET @Position = CHARINDEX(',', @DatabaseList)
    IF @Position = 0
    BEGIN
      SET @DatabaseItem = @DatabaseList
      SET @DatabaseList = ''
    END
    ELSE
    BEGIN
      SET @DatabaseItem = LEFT(@DatabaseList, @Position - 1)
      SET @DatabaseList = RIGHT(@DatabaseList, LEN(@DatabaseList) - @Position)
    END
    INSERT INTO @Database01 (DatabaseName) VALUES(@DatabaseItem)
  END
  UPDATE @Database01
  SET DatabaseStatus = 1
  WHERE DatabaseName NOT LIKE '-%'
  UPDATE @Database01
  SET  DatabaseName = RIGHT(DatabaseName,LEN(DatabaseName) - 1), DatabaseStatus = 0
  WHERE DatabaseName LIKE '-%'
  INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
  SELECT DISTINCT DatabaseName, DatabaseStatus
  FROM @Database01
  WHERE DatabaseName NOT IN('SYSTEM_DATABASES','USER_DATABASES')
  IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'SYSTEM_DATABASES' AND DatabaseStatus = 0)
  BEGIN
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('master', 0)
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('model', 0)
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('msdb', 0)
  END
  IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'SYSTEM_DATABASES' AND DatabaseStatus = 1)
  BEGIN
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('master', 1)
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('model', 1)
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus) VALUES('msdb', 1)
  END
  IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'USER_DATABASES' AND DatabaseStatus = 0)
  BEGIN
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
    SELECT [name], 0
    FROM sys.databases
    WHERE database_id > 4
  END
  IF EXISTS (SELECT * FROM @Database01 WHERE DatabaseName = 'USER_DATABASES' AND DatabaseStatus = 1)
  BEGIN
    INSERT INTO @Database02 (DatabaseName, DatabaseStatus)
    SELECT [name], 1
    FROM sys.databases
    WHERE database_id > 4
  END
  INSERT INTO @Database (DatabaseName)
  SELECT [name]
  FROM sys.databases
  WHERE [name] <> 'tempdb'
  AND source_database_id IS NULL
  INTERSECT
  SELECT DatabaseName
  FROM @Database02
  WHERE DatabaseStatus = 1
  EXCEPT
  SELECT DatabaseName
  FROM @Database02
  WHERE DatabaseStatus = 0
  RETURN
END
go

CREATE PROCEDURE [babel_4263_schema].[babel_4263_usp_DatabaseIntegrityCheck]
	@Databases nvarchar(max)
AS SET NOCOUNT ON
----------------------------------------------------------------------------------------------------
--// Declare variables //--
----------------------------------------------------------------------------------------------------
DECLARE @StartMessage nvarchar(max)
DECLARE @EndMessage nvarchar(max)
DECLARE @DatabaseMessage nvarchar(max)
DECLARE @ErrorMessage nvarchar(max)
DECLARE @CurrentID int
DECLARE @CurrentDatabase nvarchar(max)
DECLARE @CurrentCommand01 nvarchar(max)
DECLARE @CurrentCommandOutput01 int
DECLARE @tmpDatabases TABLE
(
ID int IDENTITY PRIMARY KEY,
DatabaseName nvarchar(max),
Completed bit
)
DECLARE @Error int
SET @Error = 0
----------------------------------------------------------------------------------------------------
--// Log initial information //--
----------------------------------------------------------------------------------------------------
SET @StartMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(@@PROCID)) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)
SET @StartMessage = @StartMessage + 'Parameters: @Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')
SET @StartMessage = @StartMessage + CHAR(13) + CHAR(10)
RAISERROR(@StartMessage,10,1) WITH NOWAIT
----------------------------------------------------------------------------------------------------
--// Select databases //--
----------------------------------------------------------------------------------------------------
IF @Databases IS NULL OR @Databases = ''
	BEGIN
		SET @ErrorMessage = 'The value for parameter @Databases is not supported.' + CHAR(13) + CHAR(10)
		RAISERROR(@ErrorMessage,16,1) WITH NOWAIT SET @Error = @@ERROR
	END
INSERT INTO @tmpDatabases (DatabaseName, Completed)
SELECT DatabaseName AS DatabaseName, 0 AS Completed
FROM babel_4263_schema.babel_4263_fn_DatabaseSelect (@Databases)
ORDER BY DatabaseName ASC
IF @@ERROR <> 0 OR @@ROWCOUNT = 0
	BEGIN
		SET @ErrorMessage = 'Error selecting databases.' + CHAR(13) + CHAR(10)
		RAISERROR(@ErrorMessage,16,1) WITH NOWAIT SET @Error = @@ERROR
	END
----------------------------------------------------------------------------------------------------
--// Check error variable //--
----------------------------------------------------------------------------------------------------
IF @Error <> 0
	GOTO Logging
----------------------------------------------------------------------------------------------------
--// Execute commands //--
----------------------------------------------------------------------------------------------------
WHILE EXISTS (
				SELECT *
				FROM @tmpDatabases WHERE Completed = 0
			)
		BEGIN

		SELECT TOP 1 @CurrentID = ID
			, @CurrentDatabase = DatabaseName
		FROM @tmpDatabases
		WHERE Completed = 0
		ORDER BY ID ASC
		-- Set database message

		SET @DatabaseMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
		SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabase) + CHAR(13) + CHAR(10)
		SET @DatabaseMessage = @DatabaseMessage + 'Status: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabase,'status') AS nvarchar) + CHAR(13) + CHAR(10)
		RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT

		IF DATABASEPROPERTYEX(@CurrentDatabase,'status') = 'ONLINE'
			BEGIN
				SET @CurrentCommand01 = 'DBCC CHECKDB (' + QUOTENAME(@CurrentDatabase) + ') '
				EXEC sp_executesql @CurrentCommand01

				SET @Error = @@ERROR
				IF @Error <> 0
					SET @CurrentCommandOutput01 = @Error
			END

			-- Update that the database is completed
			UPDATE @tmpDatabases
			SET Completed = 1
			WHERE ID = @CurrentID

			-- Clear variables
			SET @CurrentID = NULL
			SET @CurrentDatabase = NULL
			SET @CurrentCommand01 = NULL
			SET @CurrentCommandOutput01 = NULL

			RAISERROR('',10,1) WITH NOWAIT

	END
	----------------------------------------------------------------------------------------------------
	--// Log completing information //--
	----------------------------------------------------------------------------------------------------
	Logging:
		SET @EndMessage = 'DateTime: ' + CONVERT(nvarchar,GETDATE(),120)
		RAISERROR(@EndMessage,10,1) WITH NOWAIT
	---------------------------------------------------------------------------------------------------- GO
go

EXECUTE babel_4263_schema.babel_4263_usp_DatabaseIntegrityCheck @Databases = NULL
go

USE master
go

DROP DATABASE babel_4263_db
go
