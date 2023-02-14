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

-- BABEL-3570
CREATE FUNCTION BABEL_3570_function (@p datetime2(7)) RETURNS INT 
AS
BEGIN
RETURN 0
END
GO

SELECT BABEL_3570_function(getdate())
GO

DECLARE @BABEL_3570_dt datetime = getdate()
SELECT BABEL_3570_function(@BABEL_3570_dt)
GO

CREATE PROC BABEL_3570_proc @p datetime2(7) as print 'pass'
GO

DECLARE @BABEL_3570_dt datetime = getdate()
EXEC BABEL_3570_proc @BABEL_3570_dt
GO

DROP FUNCTION BABEL_3570_function
DROP PROC BABEL_3570_proc
GO
