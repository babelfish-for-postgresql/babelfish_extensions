create table babel_4359_t1 (a numeric(6,4), b numeric(6,3), c numeric);
go

insert into babel_4359_t1 values (4, 16, 1111);
insert into babel_4359_t1 values (10.1234, 10.123, 222222);
insert into babel_4359_t1 values (1.2, 6, 33333333333333333);
insert into babel_4359_t1 values (NULL, 101.123, 444444444444444444);
insert into babel_4359_t1 values (10.123, NULL, 444444444444444444.44);
insert into babel_4359_t1 values (10.12, 10.1234, NULL);
go

select * from 
	(
		select a as col from babel_4359_t1 Union All
		select b as col from babel_4359_t1
	) dummy
order by col
go

select * from 
	(
		select a as col from babel_4359_t1 union all
		select b as col from babel_4359_t1 union all
		select c as col from babel_4359_t1
	) dummy
order by col
go

select * from
	(
		select avg(a) as col from t1 union all
		select avg(b) as col from t1
	) dummy
order by col

select * from 
	(
		select a + b as col from babel_4359_t1 Union All
		select b + c as col from babel_4359_t1
	) dummy
order by col
go

select * from 
	(
		(select a as col from babel_4359_t1 order by a) union all
		(select b as col from babel_4359_t1 order by a) union all
		(select c as col from babel_4359_t1 order by a)
	) dummy
order by col
go

select * from 
	(
		(select min(a) as col from babel_4359_t1 ) union all
		(select min(b) as col from babel_4359_t1 ) union all
		(select min(c) as col from babel_4359_t1 )
	) dummy
order by col

select min(col) from 
	(
		(select min(a) as col from babel_4359_t1 ) union all
		(select min(b) as col from babel_4359_t1 ) union all
		(select min(c) as col from babel_4359_t1 )
	) dummy
go

select * from 
	(
		select max(a + b) as col from babel_4359_t1 Union All
		select min(b + c) as col from babel_4359_t1
	) dummy
order by col
go

drop table babel_4359_t1
go