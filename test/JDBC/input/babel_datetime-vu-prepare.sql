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
INSERT INTO babel_datetime_vu_prepare_testing VALUES(0x0000B022)
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES(0x0000B02200EF28C0)
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES(0x00008EE700C5C100)
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES(0xFFFF2E4600000000)
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES(0x0000B02200EF28C1)
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES(0x002D247F018B81FF)
go
INSERT INTO babel_datetime_vu_prepare_testing VALUES(0x002D247F018B8200)
go

create view babel_datetime_vu_view1
as
	select cast(0x0000B02200EF28C1 as datetime)
go

create view babel_datetime_vu_view2
as
	select cast(0x00008EE700C5C100 as datetime)
go

CREATE PROCEDURE babel_datetime_vu_procedure
AS
BEGIN
	select cast(0x00008EE700C5C100 as datetime)
END;
GO

CREATE FUNCTION babel_datetime_vu_function1 (@inputdate DATETIME)
RETURNS varchar(50)
AS
BEGIN
	RETURN @inputdate
END
GO

-- convert string to datetime test
CREATE VIEW babel_datetime_empty_string_vw as (SELECT CONVERT(datetime, ''));
GO
CREATE PROCEDURE babel_datetime_empty_string_p as (SELECT CONVERT(datetime, ''));
GO
CREATE FUNCTION babel_datetime_empty_string_f()
RETURNS datetime AS
BEGIN
RETURN (SELECT CONVERT(datetime, ''));
END
GO