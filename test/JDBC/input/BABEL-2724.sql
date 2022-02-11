use master;
go

create table t2724(a int);
insert into t2724 values (1);
go

select a from t2724;
go

select t2724.a from t2724;
go

select .t2724.a from t2724;
go

-- valid error
select .a from t2724;
go

-- valid error
select ..a from t2724;
go

-- valid error
select dbo..a from t2724;
go

-- special case on insert-column. DOT and qualifier is totally ignored
insert into t2724(a) values (2);
insert into t2724(.a) values (3);
insert into t2724(........a) values (4);
insert into t2724(invalid.a) values (5);
insert into t2724(x.y...z....w...a) values (6);
go

select * from t2724;
go

drop table t2724;
go
