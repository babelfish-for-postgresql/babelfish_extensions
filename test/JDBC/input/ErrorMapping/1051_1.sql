-- simple batch start

CREATE TABLE t1051
(
 c1 int
,c2 int NULL
)
GO


CREATE PROC p1051_1
 @a CURSOR OUTPUT VARYING 
 AS
DECLARE c CURSOR 
 READ_ONLY
FOR 
SELECT * FROM t1051

GO
DROP TABLE t1051
GO


SET XACT_ABORT ON;
GO

begin transaction
GO
CREATE TABLE t1051
(
 c1 int
,c2 int NULL
)
GO


CREATE PROC p1051_1
 @a CURSOR OUTPUT VARYING 
 AS
DECLARE c CURSOR 
 READ_ONLY
FOR 
SELECT * FROM t1051

GO

if (@@trancount > 0) select cast('Does not respect xact_abort flag' as text) else select cast('Respects xact_abort flag' as text)
GO

if (@@trancount > 0) rollback tran
GO

DROP TABLE t1051
GO

SET XACT_ABORT OFF;
GO

