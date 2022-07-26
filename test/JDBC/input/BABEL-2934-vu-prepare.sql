CREATE TABLE BABEL_2934_vu_1 (c TIME(7) NULL, d TIME(7) NULL)
GO
INSERT BABEL_2934_vu_1 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT BABEL_2934_vu_1 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update BABEL_2934_vu_1 set d = dateadd(ns, 300, c)
go

CREATE TABLE BABEL_2934_vu_2 (c DATETIME2(7) NULL, d DATETIME2(7) NULL)
GO
INSERT BABEL_2934_vu_2 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT BABEL_2934_vu_2 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update BABEL_2934_vu_2 set d = dateadd(ns, 300, c)
go

CREATE TABLE BABEL_2934_vu_3 (c DATETIMEOFFSET(7) NULL, d DATETIMEOFFSET(7) NULL)
GO
INSERT BABEL_2934_vu_3 VALUES ('00:59:59.9999123' , NULL)
GO
INSERT BABEL_2934_vu_3 VALUES ('00:00:01.0000120' , NULL)
go

-- add 300 nanoseconds (the 7th digit shows as '3')
update BABEL_2934_vu_3 set d = dateadd(ns, 300, c)
go

CREATE VIEW BABEL_2934_vu_v1 as select cast('12:15:04.1234567' as TIME(7))
go

CREATE FUNCTION BABEL_2934_vu_f1 (@t TIME(7))
RETURNS TIME(7) AS
BEGIN
    RETURN @t
END;
go
