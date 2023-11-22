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
		select avg(a) as col from babel_4359_t1 union all
		select avg(b) as col from babel_4359_t1
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

create table events (event_id numeric(6,3) primary key);
create table other_events (event_id numeric(6,5) primary key);
create table other_events_2 (event_id numeric);
go

insert into events values (100.123), (10.12);
insert into other_events values (1.123456);
insert into other_events_2 values (111111111111111111), (NULL);
go

-- merge append node
select  event_id
 from ((select event_id from events order by event_id)
       union all
       (select event_id from other_events order by event_id)
	   union all
	   (select event_id from other_events_2 order by event_id)) ss
order by event_id;
go

drop table babel_4359_t1
go
drop table events;
go
drop table other_events;
go
drop table other_events_2;
go

create table babel_4424_t1 (a numeric(38,0));
go

create table babel_4424_t2 (a numeric(6,4));
go

insert into babel_4424_t1 values (9999999999999999999999999999999999999);
insert into babel_4424_t2 values (99.9999);
insert into babel_4424_t1 values (1111111111111111111111111111111111111);
insert into babel_4424_t2 values (11.1111);
go

select * from
	(
	  select a col from babel_4424_t1
	  union all
	  select a col from babel_4424_t2
	)dummy
order by col;
go

select * from
	( select a + a from babel_4424_t1 ) dummy
go

select * from
	(
	  select a col from babel_4424_t1
	  union all
	  select a + a col from babel_4424_t1
	)dummy
order by col;
go

select * from
	(
	  select a + a col from babel_4424_t1
	  union all
	  select a col from babel_4424_t2
	)dummy
order by col;
go

create table babel_4424_t3 (a numeric(37,1));
GO

create table babel_4424_t4 (a numeric(38,1));
GO

insert into babel_4424_t3 values (999999999999999999999999999999999999.9);
insert into babel_4424_t3 values (111111111111111111111111111111111111.1);
go

insert into babel_4424_t4 values (9999999999999999999999999999999999999.9);
insert into babel_4424_t4 values (1111111111111111111111111111111111111.1);
go

select * from (select a + a from babel_4424_t3) dummy;
go

select * from
	(
		select a col from babel_4424_t3
		union all
		select a col from babel_4424_t2
	) dummy
order by col;
GO

select * from
	(
		select a col from babel_4424_t3
		union all
		select a col from babel_4424_t4
	) dummy
order by col;
GO

create table babel_4424_t5 (a numeric(38, 37));
GO

create table babel_4424_t6 (a numeric(10, 10));
GO

insert into babel_4424_t5 values (9.99999999999999999999999999999999999);
insert into babel_4424_t6 values (0.9999999999);
insert into babel_4424_t5 values (1.11111111111111111111111111111111111);
insert into babel_4424_t6 values (0.1111111111);
GO

select * from ( select a + a from babel_4424_t5) dummy;
GO

select * from ( select a + a from babel_4424_t6) dummy;
GO

select * from 
	(
		select a col from babel_4424_t5
		union all
		select a col from babel_4424_t6
	) dummy
order by col;
GO

DROP TABLE babel_4424_t1;
go
DROP TABLE babel_4424_t2;
go
DROP TABLE babel_4424_t3;
go
DROP TABLE babel_4424_t4;
go
DROP TABLE babel_4424_t5;
go
DROP TABLE babel_4424_t6;
go

create table babel_4424_t1 (a numeric(38,0) primary key);
go

create table babel_4424_t2(a numeric(6,3) primary key);
go

insert into babel_4424_t1 values (99999999999999999999999999999999999999);
insert into babel_4424_t2 values (99.9999);
insert into babel_4424_t1 values (11111111111111111111111111111111111111);
insert into babel_4424_t2 values (11.1111);
GO

-- index scan + append
select * from
	(
		select a col from babel_4424_t1 where a = 1
		union all
		select a col from babel_4424_t2 where a = 1
	) dummy
order by col;
go

DROP TABLE babel_4424_t1;
go
DROP TABLE babel_4424_t2;
go

create table babel_4424_t1 (n3_0 numeric(3,0), n3_1 numeric(3,1), n6_0 numeric(6,0), n10_0 numeric(10,0), n10_9 numeric(10, 9),
							n15_0 numeric(15,0), n16_15 numeric(16,15), n20_2 numeric(20,2), n25_5 numeric(25,0), n30_10 numeric(30, 10),
							n30_29 numeric(30,29), n38_37 numeric(38,37));

insert into babel_4424_t1 (n3_0) values (999);
insert into babel_4424_t1 (n3_1) values (99.9);
insert into babel_4424_t1 (n6_0) values (999999);
insert into babel_4424_t1 (n10_0) values (9999999999);
insert into babel_4424_t1 (n10_9) values (9.999999999);
insert into babel_4424_t1 (n15_0) values (999999999999999);
insert into babel_4424_t1 (n16_15) values (9.999999999999999);
insert into babel_4424_t1 (n20_2) values (999999999999999999.99);
insert into babel_4424_t1 (n25_5) values (99999999999999999999.99999);
insert into babel_4424_t1 (n30_10) values (99999999999999999999.9999999999);
insert into babel_4424_t1 (n30_29) values (9.99999999999999999999999999999);
insert into babel_4424_t1 (n38_37) values (9.9999999999999999999999999999999999999);
insert into babel_4424_t1 (n3_0, n3_1, n6_0, n10_0, n10_9, n15_0, n16_15, n20_2, n25_5, n30_10, n30_29, n38_37)
values (999, 99.9, 999999, 9999999999, 9.999999999, 999999999999999, 9.999999999999999, 999999999999999999.99, 
99999999999999999999.99999, 99999999999999999999.9999999999, 9.99999999999999999999999999999, 9.9999999999999999999999999999999999999);
GO

insert into babel_4424_t1 (n3_0) values (111);
insert into babel_4424_t1 (n3_1) values (11.1);
insert into babel_4424_t1 (n6_0) values (111111);
insert into babel_4424_t1 (n10_0) values (1111111111);
insert into babel_4424_t1 (n10_9) values (1.111111111);
insert into babel_4424_t1 (n15_0) values (111111111111111);
insert into babel_4424_t1 (n16_15) values (1.111111111111111);
insert into babel_4424_t1 (n20_2) values (111111111111111111.11);
insert into babel_4424_t1 (n25_5) values (11111111111111111111.11111);
insert into babel_4424_t1 (n30_10) values (11111111111111111111.1111111111);
insert into babel_4424_t1 (n30_29) values (1.11111111111111111111111111111);
insert into babel_4424_t1 (n38_37) values (1.1111111111111111111111111111111111111);
insert into babel_4424_t1 (n3_0, n3_1, n6_0, n10_0, n10_9, n15_0, n16_15, n20_2, n25_5, n30_10, n30_29, n38_37)
values (111, 11.1, 111111, 1111111111, 1.111111111, 111111111111111, 1.111111111111111, 111111111111111111.11, 
11111111111111111111.11111, 11111111111111111111.1111111111, 1.11111111111111111111111111111, 1.1111111111111111111111111111111111111);
GO

select n38_37 + 100 from babel_4424_t1 where n38_37 is not null;
GO

select n38_37 + n38_37 from babel_4424_t1 where n38_37 is not null;
GO

select sum(n38_37) from babel_4424_t1 where n38_37 is not null;
GO

select avg(n38_37) from babel_4424_t1 where n38_37 is not null;
GO

select n30_29 * 100 from babel_4424_t1 where n30_29 is not null;
GO

select n30_29 + n30_29 from babel_4424_t1 where n30_29 is not null;
GO

select n30_29 + n38_37 from babel_4424_t1 where n30_29 is not null and n38_37 is not null;
GO

select n3_0 * n3_0 from babel_4424_t1 where n3_0 is not null;
GO

select n3_0 * n3_1 from babel_4424_t1 where n3_0 is not null and n3_1 is not null;
GO

select n3_0 + n6_0 from babel_4424_t1 where n3_0 is not null and n6_0 is not null;
GO

select n6_0 + n10_9 from babel_4424_t1 where n6_0 is not null and n10_9 is not null;
GO

select n15_0 * n15_0 from babel_4424_t1 where n15_0 is not null;
GO

select n15_0 + n38_37 from babel_4424_t1 where n15_0 is not null and n38_37 is not null;
GO

select n15_0 + n16_15 from babel_4424_t1 where n15_0 is not null and n16_15 is not null;
GO

select avg(n16_15) from babel_4424_t1 where n16_15 is not null;
GO

select n16_15 * n16_15 from babel_4424_t1 where n16_15 is not null;
GO

select n15_0 + n16_15 + n30_10 from babel_4424_t1 where n15_0 is not null and n16_15 is not null and n30_10 is not null;
GO

select n20_2 + n38_37 from babel_4424_t1 where n20_2 is not null and n38_37 is not null;
GO

select  n25_5 + n30_10 from babel_4424_t1 where n25_5 is not null and n30_10 is not null;
GO

select n30_29 + n30_10 from babel_4424_t1 where n30_29 is not null and n30_10 is not null;
GO

select * from
(
	select n3_0 col from babel_4424_t1 where n3_0 is not null
	union all
	select n3_1 col from babel_4424_t1 where n3_1 is not null
	union all
	select n6_0 col from babel_4424_t1 where n6_0 is not null
	union all
	select n10_0 col from babel_4424_t1 where n10_0 is not null
	union all
	select n10_9 col from babel_4424_t1 where n10_9 is not null
	union all
	select n15_0 col from babel_4424_t1 where n15_0 is not null
	union all
	select n16_15 col from babel_4424_t1 where n16_15 is not null
	union all
	select n20_2 col from babel_4424_t1 where n20_2 is not null
	union all
	select n25_5 col from babel_4424_t1 where n25_5 is not null
	union all
	select n30_10 col from babel_4424_t1 where n30_10 is not null
	union all
	select n30_29 col from babel_4424_t1 where n30_29 is not null
	union all
	select n38_37 col from babel_4424_t1 where n38_37 is not null
) dummy
order by col;
GO

DROP table babel_4424_t1;
GO

create table babel_4424_t1 (a numeric(38,38));
GO

insert into babel_4424_t1 values (0.1111111111111111111111111111111111111111);
go

select a + a from babel_4424_t1;
GO

truncate table babel_4424_t1;
GO

insert into babel_4424_t1 values (0.99999999999999999999999999999999999999)
GO

select a + a from babel_4424_t1;
GO

DROP table babel_4424_t1;
GO