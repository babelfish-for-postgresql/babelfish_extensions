use master;
go

create table t2968 (name int);
insert into t2968 values (1);
go

CREATE VIEW  v2968 AS
---these are “smart quotes”
SELECT name objectName FROM t2968
go

select * from v2968;
go

drop view v2968;
go
drop table t2968;
go
