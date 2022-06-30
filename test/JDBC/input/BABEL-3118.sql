CREATE TABLE t
(
c1 int IDENTITY(1,1) PRIMARY KEY,
c2 varchar(20),
);
GO

INSERT INTO t(c2) VALUES ('Joe'), ('Steve');
GO

SELECT * FROM t
GO

CREATE TRIGGER tr_txz ON t
INSTEAD OF DELETE
AS
DELETE FROM t WHERE c2 IN(SELECT c2 FROM deleted)
SELECT '@@ROWCOUNT from the DELETE trigger, the value should be 1', @@ROWCOUNT
GO

DELETE FROM t WHERE c2 = 'Steve'
GO

SELECT  * FROM t
GO

drop trigger tr_txz;
GO

drop table t
GO