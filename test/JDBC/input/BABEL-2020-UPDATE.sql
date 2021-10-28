drop procedure if exists babel_2020_update_ct;
go

create procedure babel_2020_update_ct as
begin
    drop table if exists babel_2020_update_t1
    create table babel_2020_update_t1 (a int)
    insert into babel_2020_update_t1 values (1), (2), (NULL)
    drop table if exists babel_2020_update_t2
    create table babel_2020_update_t2 (a int)
    insert into babel_2020_update_t2 values (2), (3), (NULL)
end
go
 
-- single tables in FROM clause
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where x.a = 2;
go
 
-- multiple tables in FROM clause
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t2 y;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t2 y where x.a = 2;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t2 y where y.a = 2;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t2 y where x.a = y.a;
go

-- JOIN clause
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on 1 = 1;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on x.a = 2;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on y.a = 2;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t2 y on x.a = y.a;
go

-- subqueries
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from (select * from babel_2020_update_t1) x;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, (select * from babel_2020_update_t1) y;
go

-- self join
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, (select * from babel_2020_update_t1) y where x.a + 1 = y.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 y, (select * from babel_2020_update_t1) x where x.a + 1 = y.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x join babel_2020_update_t1 on babel_2020_update_t1.a + 1 = x.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 join babel_2020_update_t1 x on babel_2020_update_t1.a + 1 = x.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x, babel_2020_update_t1 y where x.a + 1 = y.a;
go

-- outer joins
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x left outer join babel_2020_update_t2 on babel_2020_update_t2.a = x.a;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t2 left outer join babel_2020_update_t1 x on babel_2020_update_t2.a = x.a;
go

-- null filters
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where x.a is null;
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t2 left outer join babel_2020_update_t1 x on x.a is null;
go

-- updatable views
drop view if exists babel_2020_update_v1;
go

exec babel_2020_update_ct;
go

create view babel_2020_update_v1 as select * from babel_2020_update_t1 where babel_2020_update_t1.a is not null;
go

update babel_2020_update_v1 set a = 100 from babel_2020_update_v1 x where x.a = 2;
go

drop view if exists babel_2020_update_v1;
go
 
-- semi joins
exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where x.a in (select a from babel_2020_update_t1 where babel_2020_update_t1.a = x.a);
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where not exists (select a from babel_2020_update_t1 y where y.a + 1 = x.a);
go

exec babel_2020_update_ct;
update babel_2020_update_t1 set a = 100 from babel_2020_update_t1 x where exists (select a from babel_2020_update_t1 y where y.a + 1 = x.a);
go

drop procedure if exists babel_2020_update_ct;
drop table if exists babel_2020_update_t1;
drop table if exists babel_2020_update_t2;
go