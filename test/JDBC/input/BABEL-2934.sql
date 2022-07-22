CREATE TABLE BABEL_2934 (c TIME(7) NULL, d TIME(7) NULL)
GO
INSERT BABEL_2934 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT BABEL_2934 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update BABEL_2934 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from BABEL_2934
go

drop table BABEL_2934
go

CREATE TABLE BABEL_2934 (c DATETIME2(7) NULL, d DATETIME2(7) NULL)
GO
INSERT BABEL_2934 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT BABEL_2934 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update BABEL_2934 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from BABEL_2934
go

drop table BABEL_2934
go

CREATE TABLE BABEL_2934 (c DATETIMEOFFSET(7) NULL, d DATETIMEOFFSET(7) NULL)
GO
INSERT BABEL_2934 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT BABEL_2934 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update BABEL_2934 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from BABEL_2934
go

drop table BABEL_2934
go

select cast('12:15:04.1234567' as TIME(7))
go
