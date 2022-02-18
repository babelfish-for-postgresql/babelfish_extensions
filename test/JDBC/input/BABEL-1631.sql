-- Check if exact input typmod is retrieved on TDS side for char/nchar datatypes
-- when engine provided typmod = -1

DROP FUNCTION IF EXISTS custom_f3;
go
CREATE FUNCTION custom_f3(@one CHAR(10)) RETURNS CHAR(6) AS BEGIN RETURN @one; END;
go
SELECT custom_f3('abcdef');
go

DROP FUNCTION IF EXISTS custom_f4;
go
CREATE FUNCTION custom_f4(@one NCHAR(10)) RETURNS NCHAR(6) AS BEGIN RETURN @one; END;
go
SELECT custom_f4('abc');
go

DROP FUNCTION IF EXISTS custom_f5;
go
CREATE FUNCTION custom_f5(@one CHAR(20)) RETURNS CHAR(8) AS BEGIN RETURN @one; END;
go
SELECT custom_f5('abcdefghij');
go

DROP FUNCTION IF EXISTS custom_f6;
go
CREATE FUNCTION custom_f6(@one CHAR(10)) RETURNS CHAR AS BEGIN RETURN @one; END;
go
SELECT custom_f6('abcdef');
go

DROP FUNCTION custom_f3
DROP FUNCTION custom_f4
DROP FUNCTION custom_f5
DROP FUNCTION custom_f6
GO
