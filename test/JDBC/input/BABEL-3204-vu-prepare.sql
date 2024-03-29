-- create ITVF which uses inbuilt functions
-- function's body should not get compiled during restore
CREATE FUNCTION babel_3204_complex_func
(
	@String NVARCHAR(4000),
	@Delimiter NCHAR(1)
)
RETURNS TABLE
AS
RETURN
(
	WITH Split(stpos, endpos) AS
	(
		SELECT 0 AS stpos, CHARINDEX(@Delimiter,@String) AS endpos
		UNION ALL
		SELECT endpos+1, CHARINDEX(@Delimiter,@String,endpos+1)
		FROM Split
		WHERE endpos > 0
	)
	SELECT 'Value' = SUBSTRING(@String, stpos, COALESCE(NULLIF(endpos, 0), LEN(@String) + 1) - stpos)
	FROM Split
);
go

SELECT babel_3204_complex_func('abc def', ' ');
go

-- create ITVF which returns table with text column
CREATE FUNCTION babel_3204_text()
RETURNS TABLE
AS RETURN
(
	SELECT CAST('Hello' AS TEXT) AS message
);
go

SELECT babel_3204_text();
go

-- create ITVF which returns table with ntext column
CREATE FUNCTION babel_3204_ntext()
RETURNS TABLE
AS RETURN
(
	SELECT CAST('Hello' AS sys.NTEXT) AS message
);
go

SELECT babel_3204_ntext();
go

-- create ITVF which returns table with image column
CREATE FUNCTION babel_3204_image()
RETURNS TABLE
AS RETURN
(
	SELECT CAST(0xFE AS sys.IMAGE) AS message
);
go

SELECT babel_3204_image();
go