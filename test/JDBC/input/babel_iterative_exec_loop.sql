-- simple loop
DECLARE @Counter INT
SET @Counter=1
WHILE ( @Counter <= 10)
BEGIN
	SELECT @Counter
	SET @Counter  = @Counter  + 1
END
GO

-- continue
DECLARE @Counter INT 
SET @Counter=1
WHILE ( @Counter <= 10)
BEGIN
	if @Counter / 2 = 1
	BEGIN
		SET @Counter  = @Counter  + 1
		CONTINUE
	END
	SELECT @Counter 
	SET @Counter  = @Counter  + 1
END
GO

-- break
DECLARE @Counter INT 
SET @Counter=1
WHILE ( @Counter <= 10)
BEGIN
	if @Counter = 7
		BREAK
	SELECT @Counter 
	SET @Counter  = @Counter  + 1
END
GO

-- nested loop
DECLARE @Counter1 INT 
DECLARE @Counter2 INT 
SET @Counter1 = 1
SET @Counter2 = 10
WHILE ( @Counter1 <= 5)
BEGIN
	SELECT @Counter1
	WHILE ( @Counter2 < 13)
	BEGIN
		SELECT @Counter2
		SET @Counter2  = @Counter2  + 1
	END
	SET @Counter1  = @Counter1  + 1
END
GO

-- test break within try-catch block
DECLARE @i INT
SET @i = 1
WHILE (@i < 3)
BEGIN
	BEGIN TRY
		BREAK
	END TRY
	BEGIN CATCH
	END CATCH
	SET @i = @i + 1
END 
SELECT @i
GO

DECLARE @i INT
SET @i = 1
WHILE (@i < 3)
BEGIN
	BEGIN TRY
		SELECT 1/0
	END TRY
	BEGIN CATCH
		BREAK
	END CATCH
	SET @i = @i + 1
END
SELECT @i
GO

-- test continue within try-catch block
DECLARE @i INT
SET @i = 1
WHILE (@i < 3)
BEGIN
	SELECT @i
	SET @i = @i + 1
	BEGIN TRY
		CONTINUE
	END TRY
	BEGIN CATCH
	END CATCH
	SET @i = @i + 2
END
GO

DECLARE @i INT
SET @i = 1
WHILE (@i < 3)
BEGIN
	SELECT @i
	SET @i = @i + 1
	BEGIN TRY
		SELECT 1/0
	END TRY
	BEGIN CATCH
		CONTINUE
	END CATCH
	SET @i = @i + 2
END
GO
