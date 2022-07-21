CREATE TABLE dbo.babel2934_1 (c TIME(7) NULL, d TIME(7) NULL)
GO
INSERT dbo.babel2934_1 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT dbo.babel2934_1 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update dbo.babel2934_1 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from dbo.babel2934_1
go

CREATE TABLE dbo.babel2934_2 (c DATETIME2(7) NULL, d DATETIME2(7) NULL)
GO
INSERT dbo.babel2934_2 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT dbo.babel2934_2 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update dbo.babel2934_2 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from dbo.babel2934_2
go

CREATE TABLE dbo.babel2934_3 (c DATETIMEOFFSET(7) NULL, d DATETIMEOFFSET(7) NULL)
GO
INSERT dbo.babel2934_3 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT dbo.babel2934_3 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update dbo.babel2934_3 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from dbo.babel2934_3
go
