CREATE TABLE dbo.t7 (c TIME(7) NULL, d TIME(7) NULL)
GO
INSERT dbo.t7 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT dbo.t7 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update dbo.t7 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from dbo.t7
go

drop table dbo.t7
go

CREATE TABLE dbo.t7 (c DATETIME2(7) NULL, d DATETIME2(7) NULL)
GO
INSERT dbo.t7 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT dbo.t7 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update dbo.t7 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from dbo.t7
go

drop table dbo.t7
go

CREATE TABLE dbo.t7 (c DATETIMEOFFSET(7) NULL, d DATETIMEOFFSET(7) NULL)
GO
INSERT dbo.t7 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT dbo.t7 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update dbo.t7 set d = dateadd(ns, 300, c)
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from dbo.t7
go

drop table dbo.t7
go