USE master
GO

create table babel_1510_t(dto datetimeoffset, dt2 datetime2, dt datetime, sdt smalldatetime, d date, t time);
go

insert into babel_1510_t values ('2021-05-01 11:11:11.111', '2021-05-02 22:22:22.222', '2021-05-03 11:33:33.333', '2021-05-04 22:44:44.444', '2021-05-05', '11:55:55.555');
go

select datediff(dd, dto, dt2) from babel_1510_t;
go
select datediff(dd, dto, dt) from babel_1510_t;
go
select datediff(dd, dto, sdt) from babel_1510_t;
go
select datediff(dd, dto, d) from babel_1510_t;
go
select datediff(dd, dto, t) from babel_1510_t;
go

select datediff(dd, dt2, dto) from babel_1510_t;
go
select datediff(dd, dt2, dt2) from babel_1510_t;
go
select datediff(dd, dt2, sdt) from babel_1510_t;
go
select datediff(dd, dt2, d) from babel_1510_t;
go
select datediff(dd, dt2, t) from babel_1510_t;
go

select datediff(dd, dt, dto) from babel_1510_t;
go
select datediff(dd, dt, dt2) from babel_1510_t;
go
select datediff(dd, dt, sdt) from babel_1510_t;
go
select datediff(dd, dt, d) from babel_1510_t;
go
select datediff(dd, dt, t) from babel_1510_t;
go

select datediff(dd, sdt, dto) from babel_1510_t;
go
select datediff(dd, sdt, dt2) from babel_1510_t;
go
select datediff(dd, sdt, dt) from babel_1510_t;
go
select datediff(dd, sdt, d) from babel_1510_t;
go
select datediff(dd, sdt, t) from babel_1510_t;
go

select datediff(dd, d, dto) from babel_1510_t;
go
select datediff(dd, d, dt2) from babel_1510_t;
go
select datediff(dd, d, dt) from babel_1510_t;
go
select datediff(dd, d, sdt) from babel_1510_t;
go
select datediff(dd, d, t) from babel_1510_t;
go

select datediff(dd, t, dto) from babel_1510_t;
go
select datediff(dd, t, dt2) from babel_1510_t;
go
select datediff(dd, t, dt) from babel_1510_t;
go
select datediff(dd, t, sdt) from babel_1510_t;
go
select datediff(dd, t, d) from babel_1510_t;
go
