CREATE TABLE t(c1 int)
GO

CREATE TRIGGER trfjk ON t
instead of INSERT
AS
DECLARE @a int
CREATE TABLE #t2(c1 int) --This one is causing the problem
GO

INSERT INTO t(c1) VALUES(1) 
GO

CREATE TABLE t2(c1 int)
GO

CREATE TRIGGER trfjk2 ON t2
instead of UPDATE
AS
DECLARE @a int
CREATE TABLE #t2(c1 int) --This one is causing the problem
GO

INSERT INTO t2(c1) VALUES(1) 
GO

drop trigger trfjk
go

drop trigger trfjk2
go

drop table t
GO

drop table t2
GO
