CREATE DATABASE db_babel_2769;
go

USE db_babel_2769;
go

CREATE TABLE Smalldatetime2769 (c1 VARCHAR(32) NOT NULL, c2 SMALLDATETIME NULL);
go
INSERT INTO Smalldatetime2769 ( c1 ) VALUES ('First');
go
INSERT INTO Smalldatetime2769 ( c1 ) VALUES ('Second');
go

CREATE TABLE Datetime2769 (c1 VARCHAR(32) NOT NULL, c2 DATETIME NULL);
go
INSERT INTO Datetime2769 ( c1 ) VALUES ('First');
go
INSERT INTO Datetime2769 ( c1 ) VALUES ('Second');
go

CREATE TABLE Datetime2_2769 (c1 VARCHAR(32) NOT NULL, c2 DATETIME2(3) NULL);
go
INSERT INTO Datetime2_2769 ( c1 ) VALUES ('First');
go
INSERT INTO Datetime2_2769 ( c1 ) VALUES ('Second');
go

CREATE TABLE Datetimeoffset2769 (c1 VARCHAR(32) NOT NULL, c2 DATETIMEOFFSET(5) NULL);
go
INSERT INTO Datetimeoffset2769 ( c1 ) VALUES ('First');
go
INSERT INTO Datetimeoffset2769 ( c1 ) VALUES ('Second');
go
