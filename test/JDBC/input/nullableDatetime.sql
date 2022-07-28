-- Nullable DATETIME column does not store NULL

CREATE TABLE nullableDatetime_Smalldatetime (c1 VARCHAR(32) NOT NULL, c2 SMALLDATETIME NULL);
go
INSERT INTO nullableDatetime_Smalldatetime ( c1 ) VALUES ('First');
go
INSERT INTO nullableDatetime_Smalldatetime ( c1 ) VALUES ('Second');
go
SELECT * FROM nullableDatetime_Smalldatetime;
go
DROP TABLE nullableDatetime_Smalldatetime;
go

CREATE TABLE nullableDatetime_Datetime (c1 VARCHAR(32) NOT NULL, c2 DATETIME NULL);
go
INSERT INTO nullableDatetime_Datetime ( c1 ) VALUES ('First');
go
INSERT INTO nullableDatetime_Datetime ( c1 ) VALUES ('Second');
go
SELECT * FROM nullableDatetime_Datetime;
go
DROP TABLE nullableDatetime_Datetime;
go

CREATE TABLE nullableDatetime_Datetime2 (c1 VARCHAR(32) NOT NULL, c2 DATETIME2(3) NULL);
go
INSERT INTO nullableDatetime_Datetime2 ( c1 ) VALUES ('First');
go
INSERT INTO nullableDatetime_Datetime2 ( c1 ) VALUES ('Second');
go
SELECT * FROM nullableDatetime_Datetime2;
go
DROP TABLE nullableDatetime_Datetime2;
go

CREATE TABLE nullableDatetime_Datetimeoffset (c1 VARCHAR(32) NOT NULL, c2 DATETIMEOFFSET(5) NULL);
go
INSERT INTO nullableDatetime_Datetimeoffset ( c1 ) VALUES ('First');
go
INSERT INTO nullableDatetime_Datetimeoffset ( c1 ) VALUES ('Second');
go
SELECT * FROM nullableDatetime_Datetimeoffset;
go
DROP TABLE nullableDatetime_Datetimeoffset;
go
