create schema test1;
GO

CREATE TABLE test1.t1(c1 int, c2 varchar(10) )
GO
-- Doesn't matter if it's DECLARE or a SELECT @@rowcount
CREATE TRIGGER test1.tr1 ON test1.t1 AFTER DELETE AS
    DECLARE @rowcnt int
    SET @rowcnt = @@ROWCOUNT
    SELECT @rowcnt AS "#rows"
go

CREATE TRIGGER tr1 ON test1.t1 AFTER DELETE AS
    DECLARE @rowcnt int
    SET @rowcnt = @@ROWCOUNT
    SELECT @rowcnt AS "#rows"
go

create schema test2;
go

CREATE TRIGGER test2.tr2 ON test1.t1 AFTER DELETE AS
    DECLARE @rowcnt int
    SET @rowcnt = @@ROWCOUNT
    SELECT @rowcnt AS "#rows"
go

CREATE TRIGGER test2.tr2 ON t1 AFTER DELETE AS
    DECLARE @rowcnt int
    SET @rowcnt = @@ROWCOUNT
    SELECT @rowcnt AS "#rows"
go

drop schema test2;
go

drop trigger tr1
go

drop trigger test2.tr1
go

drop trigger test1.tr1
go

drop table test1.t1
go

drop schema test1
go
