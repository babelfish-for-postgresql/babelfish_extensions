create sequence t1_sec start with 1;
go
create table t1 (id int default nextval('t1_sec'), a int);
go

-- Only checking the syntax. 
-- INSERT
insert into t1 with() (a) values (1);             -- syntax error
go
insert into t1 with((nowait)) (a) values (2);      -- syntax error
go
insert into t1 with('nowait') (a) values (3);      -- syntax error
go
insert into t1 with(123nowait) (a) values (4);     -- syntax error
go
insert into t1 with($nowait) (a) values (5);       -- syntax error
go
insert into t1 with(nowait.serializable) (a) values (6);  -- syntax error
go
insert into t1 with(nowait) (a) values (7);
go
insert into t1 with(nowait serializable) (a) values (8);
go
insert into t1 with(nowait, serializable) (a) values (9);
go
select * from t1 order by id;
go

-- DELETE
delete from t1 with (nowait) where a = 7;
go
delete from t1 with (nowait serializable) where a = 8;
go
delete from t1 with (nowait, serializable) where a = 9;
go
select * from t1 order by id;
go

-- UPDATE
insert into t1 (a) values (1), (2), (3);
go
select * from t1 order by id;
go
update t1 with (nowait)
set a = 11 where a = 1;
go
update t1 with (nowait serializable) 
set a = 22 where a = 2;
go
update t1 with (nowait, serializable)
set a = 33 where a = 3;
go
select * from t1 order by id;
go

-- SELECT
select * from t1 with (nowait) order by id;
go
select * from t1 with (nowait serializable) order by id;
go
select * from t1 with (nowait, serializable) order by id;
go

select * from t1 with (index=i1) order by id;
go
select * from t1 with (index(i1)) order by id;
go
select * from t1 with (index(i1, i2)) order by id;
go
select count(*) from t1 s1 with (index(i1,i2)) join t1 s2 with (index=i3) on s1.a=s2.a;
go

-- BABEL-1148: Use table hints w/o WITH keyword
select * from t1 (tablock) order by id; -- success 
go
select * from t1 (tablock, index(i1)) order by id; -- syntax error
go
-- BABEL-1263: syntax "FROM [table] ([table_hint]) [alias]" should be supported
Select * FROM t1 n1 (Nolock) WHERE (Select Count(*) FROM t1 (Nolock) n2) <= 0;
go

-- Clean up
drop table t1;
go
