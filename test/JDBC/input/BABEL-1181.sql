create table t1 (a int);
insert into t1 values (1);
insert into t1 values (2);
insert into t1 values (3);
go
-- top (2) should only return 2 rows
select top (2) * from t1;
go
-- top (NULL) should throw error
select top (NULL) * from t1;
go

create table t2 (a int, b int);
insert into t2 values (1, NULL);
go
-- top (1) should only return 1 row
select top (select a from t2) * from t1;
go
-- top (NULL) should throw error
select top (select b from t2) * from t1;
go

declare @a int;
set @a = 1;
-- top (1) should only return 1 row
select top (@a) * from t1;
go
declare @a int;
set @a = NULL;
-- top (NULL) should throw error
select top (@a) * from t1;
go

-- test CTE
create table t3 (a int, b int);
insert into t3 values (1, NULL);
insert into t3 values (100, 1);
insert into t3 values (200, 2);
go
-- test TOP as part of query
-- top (1) should only return 1 row
with cte (cte_a) as (select a from t3 as cte)
select top (1) * from cte;
go
-- top (NULL) should throw error
with cte (cte_a) as (select a from t3 as cte)
select top (NULL) * from cte;
go

-- test TOP as part of CTE
-- top (2) should only return 2 rows
with cte (cte_a) as (select top(2) a from t3 as cte)
select * from cte;
go
-- top (NULL) should throw error
with cte (cte_a) as (select top(NULL) a from t3 as cte)
select * from cte;
go

-- test TOP as part of both CTE and query
-- top (1) should only return 1 row
with cte (cte_a) as (select top(2) a from t3 as cte)
select top(1) * from cte;
go
-- top (NULL) should throw error
with cte (cte_a) as (select top(2) a from t3 as cte)
select top(NULL) * from cte;
go

-- cleanup
drop table t1;
drop table t2;
drop table t3;
go
