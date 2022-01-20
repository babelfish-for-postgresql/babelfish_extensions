CREATE TABLE t1(c1 int, c2 varchar(10) )
GO
-- Doesn't matter if it's DECLARE or a SELECT @@rowcount
CREATE TRIGGER tr1 ON t1
AFTER DELETE AS
    DECLARE @rowcnt int
    SET @rowcnt = @@ROWCOUNT
    SELECT @rowcnt AS "#rows"
go
INSERT INTO t1 VALUES
    (1, 'string1' ),(2, 'string2' ),(3, 'string3' ),(4, 'string4' )
go
--Rowcount in trigger should return 1
DELETE FROM t1 WHERE c1 = 1
go
--Rowcount in trigger should return 2
DELETE FROM t1 WHERE c1 IN(2,3)
go

CREATE TABLE t2(c1 int, c2 varchar(10) )
go

CREATE TRIGGER tr2 ON t2
AFTER insert AS
    DECLARE @rowcnt int
    SET @rowcnt = @@ROWCOUNT
    SELECT @rowcnt AS "#rows"
go
--Rowcount in trigger should return 4
INSERT INTO t2 VALUES (1, 'string1' ),(2, 'string2' ),(3, 'string3' ),(4, 'string4' )
go

INSERT INTO t2 VALUES (1, 'string1' ),(2, 'string2' ),(3, 'string3' )
GO

drop trigger tr2;
GO

drop trigger tr1;
GO

drop table t2;
GO

drop table t1;
GO