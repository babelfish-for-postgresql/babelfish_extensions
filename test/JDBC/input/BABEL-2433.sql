USE master;
GO

create table obytt (a int);
insert into obytt values (1);
go

select a as B from obytt order by b;
go

select a as B from obytt order by B;
go

-- ORDER BY b+3 is not allowed in either the tsql or the postgres dialect
-- error is: column "b" does not exist
select a as B from obytt order by b+3;
go

-- However, order by a+3 is allowed because a is a column name
select a+3 as B from obytt order by a+3;
go

-- and it is done case-insensitively if the db collation is CI
select a+3 as B from obytt order by a+3;
go
  
select a+3 as B from obytt order by a;
go

select a+3 as b from obytt order by B;
go

drop table obytt;
go
