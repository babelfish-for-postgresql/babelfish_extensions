CREATE TABLE babel_3118_vu_prepare_t
(
c1 int IDENTITY(1,1) PRIMARY KEY,
c2 varchar(20),
);
GO

CREATE TRIGGER babel_3118_vu_prepare_tr_txz ON babel_3118_vu_prepare_t
INSTEAD OF DELETE
AS
DELETE FROM babel_3118_vu_prepare_t WHERE c2 IN(SELECT c2 FROM deleted);
SELECT '@@ROWCOUNT from the DELETE trigger, the value should be 1', @@ROWCOUNT;
GO

