-- Test to check if initialisation of Parallel Worker crash when babelfishpg_tsql.enable_pg_hint is set

create table babel_4294_t1(id INT, val int);
create table babel_4294_t2(babel_4294_t1_id INT, val int);
create table babel_4294_t3(babel_4294_t1_id INT, val int);
go

insert into babel_4294_t1 values (1, 10), (2, 20), (3, 30);
insert into babel_4294_t2 values (1, 11), (2, 12), (3, 13);
insert into babel_4294_t3 values (1, 99), (2, 77), (3, 55);
go

create table babel_4294_t4(id INT, val int);
go