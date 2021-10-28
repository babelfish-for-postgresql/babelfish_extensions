-- simple batch start

GO


CREATE VIEW v8159(c1, c2) 
AS 
SELECT 
 'a' AS c1
GO
DROP VIEW v8159
GO

SET XACT_ABORT ON;
GO

begin transaction
GO
GO


CREATE VIEW v8159(c1, c2) 
AS 
SELECT 
 'a' AS c1
GO

if (@@trancount > 0) select cast('Does not respect xact_abort flag' as text) else select cast('Respects xact_abort flag' as text)
GO

if (@@trancount > 0) rollback tran
GO

DROP VIEW v8159
GO

SET XACT_ABORT OFF;
GO


