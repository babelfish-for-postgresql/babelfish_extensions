use master
go

create database db3088
go
use db3088
go

create table t3088(a nvarchar(50));
insert into t3088 values ('aaa');
go

create procedure p3088 (@a int)
as
  declare @tv TABLE(a nvarchar(50))
  insert into @tv select * from t3088;
  select * from non_existing_table; -- causing error
go

exec p3088 1;
go

use master
go

drop database db3088 -- should succeed
go
