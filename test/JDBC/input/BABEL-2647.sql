CREATE FUNCTION dbo.mstvf_2647() RETURNS @tv TABLE (a int NULL)
AS
BEGIN
	INSERT @tv VALUES(0);
	RETURN;
END;
go

SELECT * from dbo.mstvf_2647();
go

DROP FUNCTION dbo.mstvf_2647;
go
