use master;
go

create schema s2455;
go
create table t2455_base(a int);
go

-- table
create table .t2455(a int);
insert into .t2455 values (1);
go
select 'ok' from master.dbo.t2455;
select 'ok' from .dbo.t2455;
select 'ok' from master..t2455;
select 'ok' from ...t2455;
select 'ok' from ..t2455;
select 'ok' from .t2455;
go
drop table .t2455;
go

create table ..t2455(a int);
insert into ..t2455 values (1);
go
select 'ok' from master.dbo.t2455;
select 'ok' from .dbo.t2455;
select 'ok' from master..t2455;
select 'ok' from ...t2455;
select 'ok' from ..t2455;
select 'ok' from .t2455;
go
drop table ..t2455;
go

create table master..t2455(a int);
insert into master..t2455 values (1);
go
select 'ok' from master.dbo.t2455;
select 'ok' from .dbo.t2455;
select 'ok' from master..t2455;
select 'ok' from ...t2455;
select 'ok' from ..t2455;
select 'ok' from .t2455;
go
drop table master..t2455;
go

create table .s2455.t2455(a int);
insert into .s2455.t2455 values (1);
go
select 'ok' from master.s2455.t2455;
select 'ok' from .s2455.t2455;
go
drop table .s2455.t2455;
go


-- function
CREATE FUNCTION .f2455 (@v int) RETURNS INT AS BEGIN RETURN @v+1 END;
go
select .f2455(1);
DROP FUNCTION .f2455;
go

CREATE FUNCTION ..f2455 (@v int) RETURNS INT AS BEGIN RETURN @v+1 END;
go
select ..f2455(1);
select ...f2455(1);
DROP FUNCTION ..f2455;
go

CREATE FUNCTION .s2455.f2455 (@v int) RETURNS INT AS BEGIN RETURN @v+1 END;
go
select .s2455.f2455(1);
DROP FUNCTION .s2455.f2455;
go


-- procedure
CREATE PROCEDURE .p2455 (@v int) AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
go
exec .p2455 1;
DROP PROCEDURE .p2455;
go

CREATE PROCEDURE ..p2455 (@v int) AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
go
exec ..p2455 1;
exec ...p2455 1;
DROP PROCEDURE ..p2455;
go

CREATE PROCEDURE .s2455.p2455 (@v int) AS BEGIN PRINT CAST(@v AS VARCHAR(10)) END;
go
exec .s2455.p2455 1;
DROP PROCEDURE .s2455.p2455;
go


-- view
CREATE VIEW .v2455 AS SELECT * FROM t2455_base;
go
select * from .v2455;
DROP VIEW .v2455;
go

CREATE VIEW ..v2455 AS SELECT * FROM t2455_base;
go
select * from ..v2455;
select * from ...v2455;
DROP VIEW ..v2455;
go

CREATE VIEW .s2455.v2455 AS SELECT * FROM t2455_base;
go
DROP VIEW .s2455.v2455
go


-- trigger
CREATE TRIGGER .tr2455 on t2455_base AFTER INSERT AS print 'triggered';
go
DROP TRIGGER .tr2455;
go

CREATE TRIGGER ..tr2455 on t2455_base AFTER INSERT AS print 'triggered';
go
DROP TRIGGER ..tr2455;
go

-- cursor
CREATE TABLE ..t2455(a int);
INSERT INTO ..t2455 VALUES (1);
GO

DECLARE @a varchar(1024);
DECLARE cur CURSOR FOR SELECT 'ok' FROM ..t2455;
OPEN cur;
FETCH FROM cur INTO @a;
SELECT @a;
CLOSE cur;
DEALLOCATE cur;
GO

DROP TABLE ..t2455;
GO

-- TODO: error due to BABEL-955. please update expected file once BABEL-955 is fixed
CREATE TRIGGER .s2455.tr2455 on t2455_base AFTER INSERT AS print 'triggered';
go
DROP TRIGGER .s2455.tr2455;
go

-- servername (not supported)
insert into yourserver.master.dbo.t1 values (1);
go

select yourserver.master.dbo.f1(1);
go

-- cleanup
drop table t2455_base;
go
drop schema s2455;
go
