CREATE FUNCTION custom_diff(
	@one int,
	@two int
)
RETURNS int
AS 
BEGIN
	RETURN (@one - @two);
END;
GO

DECLARE @one int = 100;
DECLARE @two int = 200;
DECLARE @returnstatus int;
-- execute UDF
EXECUTE @returnstatus = custom_diff @one, @two;
SELECT @returnstatus;
-- execute UDF with named arguments
EXECUTE @returnstatus = custom_diff @one = @one, @two = @two;
SELECT @returnstatus;
EXECUTE @returnstatus = custom_diff @two = @one, @one = @two;
SELECT @returnstatus;
-- execute UDF with mixed arguments
EXECUTE @returnstatus = custom_diff @one, @two = @two;
SELECT @returnstatus;
GO

DROP FUNCTION custom_diff
GO
