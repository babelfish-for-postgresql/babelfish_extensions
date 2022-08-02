USE master
GO

create table babel_1510_vu_prepare_t(dto datetimeoffset, dt2 datetime2, dt datetime, sdt smalldatetime, d date, t time);
go

insert into babel_1510_vu_prepare_t values ('2021-05-01 11:11:11.111', '2021-05-02 22:22:22.222', '2021-05-03 11:33:33.333', '2021-05-04 22:44:44.444', '2021-05-05', '11:55:55.555');
go