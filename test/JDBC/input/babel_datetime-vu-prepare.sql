-- Test datetime default value
create table babel_datetime_vu_prepare_testing_1 (a datetime, b int)
go
insert into babel_datetime_vu_prepare_testing_1 (b) values (1)
go

-- Testing inserting into the table
create table babel_datetime_vu_prepare_testing ( dt DATETIME )
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('1753-1-1 00:00:00.000')
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('9999-12-31 23:59:59.998')
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('1992-05-23 23:40:29.999')
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('1992-05-23 23:40:30.000')
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('1999-12-31 23:59:59.998')
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('1999-12-31 23:59:59.999')
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('23:40:29.999')
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('23:40:30.000')
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES('2020-03-14')
go