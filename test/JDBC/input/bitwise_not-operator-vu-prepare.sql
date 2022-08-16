USE master
GO

CREATE TABLE bitwise_not_vu_prepare_table(c1 bit)
GO

INSERT INTO bitwise_not_vu_prepare_table VALUES 
(~CAST( 0 AS bit )), 
(~CAST( 1 AS bit )) 
GO

CREATE PROCEDURE bitwise_not_vu_prepare_procedure 
AS
SELECT ~CAST( 0 AS bit )
GO

CREATE FUNCTION dbo.bitwise_not_vu_prepare_function ()
RETURNS BIT AS
BEGIN
    DECLARE @res bit
	SELECT @res = (SELECT ~CAST( 0 AS bit ))
    RETURN  @res
END;
GO