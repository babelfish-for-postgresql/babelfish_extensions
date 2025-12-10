DROP PROCEDURE IF EXISTS TestMoneyCast;
GO

CREATE PROCEDURE TestMoneyCast(@input VARCHAR(20))
AS
BEGIN
    SELECT CAST(@input AS MONEY);                          
END;
GO

EXEC TestMoneyCast '$.  100';
GO

EXEC TestMoneyCast '$ 1,00,09';
GO

SELECT CAST('$100.000' AS MONEY); 
GO