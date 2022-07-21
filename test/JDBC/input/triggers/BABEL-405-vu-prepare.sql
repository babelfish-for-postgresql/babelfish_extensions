create table babel_405_vu_insert1(x int);
create table babel_405_vu_insert2(x int);
insert into babel_405_vu_insert1 values(1);
insert into babel_405_vu_insert1 select * from babel_405_vu_insert1;
insert into babel_405_vu_insert1 select * from babel_405_vu_insert1;
go

create trigger babel_405_vu_tr1 on babel_405_vu_insert2 instead of insert
as
begin
select * from babel_405_vu_insert1;
end
go

create trigger babel_405_vu_tr2 on babel_405_vu_insert2 instead of insert
as
begin
select * from babel_405_vu_insert1;
end
go

create table babel_405_vu_delete1(x int);
create table babel_405_vu_delete2(x int);
insert into babel_405_vu_delete1 values(1);
insert into babel_405_vu_delete1 select * from babel_405_vu_delete1;
insert into babel_405_vu_delete1 select * from babel_405_vu_delete1;
insert into babel_405_vu_delete2 values(2);
go

create trigger babel_405_vu_tr3 on babel_405_vu_delete2 instead of delete
as
begin
select * from babel_405_vu_delete1;
end
go

create trigger babel_405_vu_tr4 on babel_405_vu_delete2 instead of insert
as
begin
select '1';
end
go

create table babel_405_vu_update1(x int);
create table babel_405_vu_update2(x int);
insert into babel_405_vu_update1 values(1);
insert into babel_405_vu_update1 select * from babel_405_vu_update1;
insert into babel_405_vu_update1 select * from babel_405_vu_update1;
insert into babel_405_vu_update2 values(1);
go

create trigger babel_405_vu_tr5 on babel_405_vu_update2 instead of update
as
begin
select * from babel_405_vu_update1;
end
go

create trigger babel_405_vu_tr6 on babel_405_vu_update2 instead of update
as
begin
select 'hello';
end
go

create table babel_405_vu_insert3(x int);
create table babel_405_vu_insert4(x int);
insert into babel_405_vu_insert3 values(1);
insert into babel_405_vu_insert3 select * from babel_405_vu_insert3;
insert into babel_405_vu_insert3 select * from babel_405_vu_insert3;
go

create trigger babel_405_vu_tr7 on babel_405_vu_insert4 instead of insert
as
begin
select * from babel_405_vu_insert3
end;
go

create trigger babel_405_vu_after_trig on babel_405_vu_insert4 after insert
as
begin
select 'hello'
end;
go



