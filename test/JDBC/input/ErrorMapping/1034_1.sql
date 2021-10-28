-- simple batch start

CREATE TABLE t1034
(
 c1 int
,c2 int
)
GO

GO
CREATE TRIGGER tr1034
ON t1034
FOR UPDATE, UPDATE
AS
SELECT 1

GO
DROP TABLE t1034
GO

SET XACT_ABORT ON;
GO

begin transaction
GO
CREATE TABLE t1034
(
 c1 int
,c2 int
)
GO

GO
CREATE TRIGGER tr1034
ON t1034
FOR UPDATE, UPDATE
AS
SELECT 1

GO


if (@@trancount > 0) select cast('Does not respect xact_abort flag' as text) else select cast('Respects xact_abort flag' as text)
GO

if (@@trancount > 0) rollback tran
GO

DROP TABLE t1034
GO

SET XACT_ABORT OFF;
GO

