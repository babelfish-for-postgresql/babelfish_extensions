USE master
GO

CREATE SCHEMA tds72;
GO

CREATE FUNCTION tds72.test_tds_72_date_datatypes(@a date) RETURNS date AS BEGIN RETURN @a; END;
GO

DECLARE @a date = '2020-05-14'; 
SELECT tds72.test_tds_72_date_datatypes(@a);
GO

DROP FUNCTION tds72.test_tds_72_date_datatypes;
GO

CREATE FUNCTION tds72.test_tds_72_date_datatypes(@a DATETIME2) RETURNS DATETIME2 AS BEGIN RETURN @a; END;
GO

DECLARE @a DATETIME2 = '2016-10-23 12:45:37.333'; 
SELECT tds72.test_tds_72_date_datatypes(@a);
GO

DROP FUNCTION tds72.test_tds_72_date_datatypes;
GO

CREATE FUNCTION tds72.test_tds_72_date_datatypes(@a DATETIMEOFFSET) RETURNS DATETIMEOFFSET AS BEGIN RETURN @a; END;
GO

DECLARE @a DATETIMEOFFSET = '12-10-25 12:32:10 +01:00'; 
SELECT tds72.test_tds_72_date_datatypes(@a);
GO

DROP FUNCTION tds72.test_tds_72_date_datatypes;
GO

CREATE FUNCTION tds72.test_tds_72_date_datatypes(@a TIME) RETURNS TIME AS BEGIN RETURN @a; END;
GO

DECLARE @a TIME = '12:15:04.1237'; 
SELECT tds72.test_tds_72_date_datatypes(@a);
GO

DROP FUNCTION tds72.test_tds_72_date_datatypes;
DROP SCHEMA tds72;
GO
