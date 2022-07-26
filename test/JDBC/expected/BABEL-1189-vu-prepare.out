create table babel_1189_vu_prepare_t1(a int);
go

create table babel_1189_vu_prepare_t2(a int);
go

create trigger babel_1189_vu_prepare_trig on babel_1189_vu_prepare_t2
for insert as
update babel_1189_vu_prepare_t1 set a = 2
go



