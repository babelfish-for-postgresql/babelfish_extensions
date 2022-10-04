--DATE standard formatting
CREATE TABLE date_testing(d DATE);
INSERT INTO date_testing VALUES('1753-1-1');
go
INSERT INTO date_testing VALUES('9999-12-31');
go
INSERT INTO date_testing VALUES('1992-05-23');
go

select * from date_testing;
go
select FORMAT(d, 'd','en-us') from date_testing;
GO
select FORMAT(d, 'D','en-us') from date_testing;
GO
select FORMAT(d, 'f','en-us') from date_testing;
GO
select FORMAT(d, 'F','en-us') from date_testing;
GO
select FORMAT(d, 'g','en-us') from date_testing;
GO
select FORMAT(d, 'G','en-us') from date_testing;
GO
select FORMAT(d, 'R','en-us') from date_testing;
GO
select FORMAT(d, 'r','en-us') from date_testing;
GO
select FORMAT(d, 's','en-us') from date_testing;
GO
select FORMAT(d, 't','en-us') from date_testing;
GO
select FORMAT(d, 'T','en-us') from date_testing;
GO
select FORMAT(d, 'u','en-us') from date_testing;
GO
select FORMAT(d, 'U','en-us') from date_testing;
GO
select FORMAT(d, 'Y','en-us') from date_testing;
GO
select FORMAT(d, 'y','en-us') from date_testing;
GO

--DateTime standard formatting
create table datetime_testing ( dt DATETIME );
go
INSERT INTO datetime_testing VALUES('1753-1-1 00:00:00.000');
go
INSERT INTO datetime_testing VALUES('9999-12-31 23:59:59.456');
go
INSERT INTO datetime_testing VALUES('1992-05-23 23:40:30.000');
go
INSERT INTO datetime_testing VALUES('1999-12-31 23:59:59.123');
go
INSERT INTO datetime_testing VALUES('23:40:29.456');
go
INSERT INTO datetime_testing VALUES('23:40:30.000');
go
INSERT INTO datetime_testing VALUES('2020-03-14');
go

select * from datetime_testing;
go
select FORMAT(dt, 'd','en-us') from datetime_testing;
GO
select FORMAT(dt, 'D','en-us') from datetime_testing;
GO
select FORMAT(dt, 'f','en-us') from datetime_testing;
GO
select FORMAT(dt, 'F','en-us') from datetime_testing;
GO
select FORMAT(dt, 'g','en-us') from datetime_testing;
GO
select FORMAT(dt, 'G','en-us') from datetime_testing;
GO
select FORMAT(dt, 'R','en-us') from datetime_testing;
GO
select FORMAT(dt, 'r','en-us') from datetime_testing;
GO
select FORMAT(dt, 's','en-us') from datetime_testing;
GO
select FORMAT(dt, 't','en-us') from datetime_testing;
GO
select FORMAT(dt, 'T','en-us') from datetime_testing;
GO
select FORMAT(dt, 'u','en-us') from datetime_testing;
GO
select FORMAT(dt, 'U','en-us') from datetime_testing;
GO
select FORMAT(dt, 'Y','en-us') from datetime_testing;
GO
select FORMAT(dt, 'y','en-us') from datetime_testing;
GO

--DATETIME2 standard formatting
create table datetime2_testing ( dt2 DATETIME2 );
INSERT INTO datetime2_testing VALUES('0001-1-1 00:00:00');
INSERT INTO datetime2_testing VALUES('9999-12-31 23:59:59');
INSERT INTO datetime2_testing VALUES('1992-05-23 23:40:29');
INSERT INTO datetime2_testing VALUES('1992-05-23 23:40:30');
INSERT INTO datetime2_testing VALUES('1999-12-31 23:59:59');
INSERT INTO datetime2_testing VALUES('1999-12-31 23:59:59');
INSERT INTO datetime2_testing VALUES('23:40:29.236');
INSERT INTO datetime2_testing VALUES('23:40:30.000');
INSERT INTO datetime2_testing VALUES('2020-03-14');
select * from datetime2_testing;
go
select FORMAT(dt2, 'd','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'D','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'f','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'F','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'g','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'G','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'R','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'r','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 's','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 't','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'T','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'u','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'U','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'Y','en-us') from datetime2_testing;
GO
select FORMAT(dt2, 'y','en-us') from datetime2_testing;
GO

--SMALLDATETIME standard formatting
create table smalldatetime_testing ( sdt smalldatetime );
INSERT INTO smalldatetime_testing VALUES('1990-05-23 23:40:29');
INSERT INTO smalldatetime_testing VALUES('2022-12-31 23:59:59');
INSERT INTO smalldatetime_testing VALUES('2079-06-06 22:59:59');
select * from smalldatetime_testing;
go
select FORMAT(sdt, 'd','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'D','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'f','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'F','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'g','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'G','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'R','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'r','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 's','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 't','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'T','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'u','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'U','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'Y','en-us') from smalldatetime_testing;
GO
select FORMAT(sdt, 'y','en-us') from smalldatetime_testing;
GO

--TIME standard formatting
create table time_testing ( ti TIME );
INSERT INTO time_testing VALUES('00:00:00.12345');
INSERT INTO time_testing VALUES('3:53:59');
INSERT INTO time_testing VALUES('15:5:45.0000');
INSERT INTO time_testing VALUES('23:59:59.12345');
select * from time_testing;
go
select FORMAT(ti, 'c','en-us') from time_testing;
GO
select FORMAT(ti, 'd','en-us') from time_testing;
GO
select FORMAT(ti, 'D','en-us') from time_testing;
GO
select FORMAT(ti, 'f','en-us') from time_testing;
GO
select FORMAT(ti, 'F','en-us') from time_testing;
GO
select FORMAT(ti, 'g','en-us') from time_testing;
GO
select FORMAT(ti, 'R','en-us') from time_testing;
GO
select FORMAT(ti, 'r','en-us') from time_testing;
GO
select FORMAT(ti, 's','en-us') from time_testing;
GO
select FORMAT(ti, 't','en-us') from time_testing;
GO
select FORMAT(ti, 'T','en-us') from time_testing;
GO
select FORMAT(ti, 'u','en-us') from time_testing;
GO
select FORMAT(ti, 'U','en-us') from time_testing;
GO
select FORMAT(ti, 'Y','en-us') from time_testing;
GO
select FORMAT(ti, 'y','en-us') from time_testing;
GO

-- Clean up
drop table date_testing;
go
drop table datetime_testing;
go
drop table datetime2_testing;
go
drop table smalldatetime_testing;
go
drop table time_testing;
go

