CREATE FUNCTION my_splitstring_3101 ( @stringToSplit VARCHAR(MAX) )
RETURNS
@returnList TABLE ([Value] [nvarchar] (50))
AS
BEGIN
	DECLARE @name NVARCHAR(255)
	DECLARE @pos INT

	WHILE CHARINDEX(',', @stringToSplit) > 0
		BEGIN
			SELECT @pos  = CHARINDEX(',', @stringToSplit)
			SELECT @name = SUBSTRING(@stringToSplit, 1, @pos-1)

			INSERT INTO @returnList SELECT @name

			SELECT @stringToSplit = SUBSTRING(@stringToSplit, @pos+1, LEN(@stringToSplit)-@pos)
		END

		INSERT INTO @returnList SELECT @stringToSplit

		RETURN
END
GO

select * from my_splitstring_3101('this,is,split')
GO

CREATE FUNCTION ISOweek_3101 (@date datetime)
RETURNS tinyint
AS
BEGIN
	DECLARE @ISOweek tinyint
	SET @ISOweek= DATEPART(wk,@date)+1-DATEPART(wk,CAST(DATEPART(yy,@date) as CHAR(4))+'0104')
	--Special cases: Jan 1-3 may belong to the previous year
	IF (@ISOweek=0)
		SET @ISOweek=dbo.ISOweek(CAST(DATEPART(yy,@date)-1 AS CHAR(4))+'12'+ CAST(24+DATEPART(DAY,@date) AS CHAR(2)))+1
	--Special case: Dec 29-31 may belong to the next year
	IF ((DATEPART(mm,@date)=12) AND ((DATEPART(dd,@date)-DATEPART(dw,@date))>= 28))
		SET @ISOweek=1
	RETURN(@ISOweek)
END
GO

SELECT ISOWeek_3101(GETDATE())
GO

CREATE FUNCTION table_3101_2()
RETURNS INT
AS
BEGIN
	DECLARE @return INT
	SET @return = 0
	SET @return = 1/0
	RETURN @return
END
GO

CREATE FUNCTION table_3101_1()
RETURNS INT
AS
BEGIN
	DECLARE @return INT
	set @return = table_3101_2()
	RETURN @return
END
GO

CREATE FUNCTION table_3101_0()
RETURNS INT
AS
BEGIN
	DECLARE @return INT
	set @return = table_3101_1()
	RETURN @return
END
GO

select table_3101_0()
GO

DROP FUNCTION my_splitstring_3101
GO

DROP FUNCTION ISOWeek_3101
GO

DROP FUNCTION table_3101_0
DROP FUNCTION table_3101_1
DROP FUNCTION table_3101_2
GO
