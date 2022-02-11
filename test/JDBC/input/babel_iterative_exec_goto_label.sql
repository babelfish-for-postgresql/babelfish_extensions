GOTO mylabel2
mylabel1:
SELECT 'mylabel1'
mylabel2:
SELECT 'mylabel2'
GO

-- test unsupported GOTOs
-- goto forward into a try block
GOTO mylabel
BEGIN TRY
	mylabel:
END TRY
BEGIN CATCH
END CATCH
GO

-- goto forward into a catch block
GOTO mylabel
BEGIN TRY
	SELECT 1; -- dummy
END TRY
BEGIN CATCH
	mylabel:
END CATCH
GO

-- goto backward into a try block
BEGIN TRY
	mylabel:
END TRY
BEGIN CATCH
END CATCH
GOTO mylabel
GO

-- goto backward into a catch block
BEGIN TRY
	SELECT 1; -- dummy
END TRY
BEGIN CATCH
	mylabel:
END CATCH
GOTO mylabel
GO

-- goto forward into a loop
DECLARE @i int
SET @i = 9
GOTO mylabel
WHILE (@i < 10)
	BEGIN
		mylabel:
	END
GO

-- goto backward into a loop
DECLARE @i int
SET @i = 9
WHILE (@i < 10)
	BEGIN
		mylabel:
	END
GOTO mylabel
GO

-- goto from try block to catch block
BEGIN TRY
	GOTO mylabel
END TRY
BEGIN CATCH
	mylabel:
END CATCH
GO

-- goto from catch block to try block
BEGIN TRY
	mylabel:
END TRY
BEGIN CATCH
	GOTO mylabel
END CATCH
GO

-- goto upper catch block
BEGIN TRY
	BEGIN TRY
		GOTO mylabel
	END TRY
	BEGIN CATCH
	END CATCH
END TRY
BEGIN CATCH
	mylabel:
END CATCH
GO

-- GOTO and escape from TRY-CATCH block
BEGIN TRY
	GOTO mylabel
END TRY
BEGIN CATCH
END CATCH
mylabel:
SELECT 1/0 as X-- shall not be caught, test if context is cleaned
GO

BEGIN TRY
	SELECT 1/0 -- shall not be caught, test if context is cleaned
END TRY
BEGIN CATCH
	GOTO mylabel
END CATCH
mylabel:
SELECT 1/0
GO

BEGIN TRY
	BEGIN TRY
		GOTO mylabel
	END TRY
	BEGIN CATCH
	END CATCH
END TRY
BEGIN CATCH
END CATCH
mylabel:
SELECT 1/0 -- shall not be caught, test if context is cleaned
GO

BEGIN TRY
	BEGIN TRY
		SELECT 1/0
	END TRY
	BEGIN CATCH
		GOTO mylabel
	END CATCH
END TRY
BEGIN CATCH
END CATCH
mylabel:
SELECT 1/0 -- shall not be caught, test if context is cleaned
GO

-- expect duplicate label error
GOTO label
LABEL:
SELECT 'Upper Case'
label:
SELECT 'Lower Case'
GO

-- accept trailing semi-colon
GOTO label1;
SELECT 'Should be skipped'
label1:
SELECT 'Label1 OK!'
GOTO label2
SELECT 'Should be skipped'
label2:
SELECT 'Label2 OK!'
GO
