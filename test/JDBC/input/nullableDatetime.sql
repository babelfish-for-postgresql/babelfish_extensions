-- [BABEL-2769] Nullable DATETIME column does not store NULL

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
SELECT * FROM Smalldatetime2769;
go
DROP TABLE Smalldatetime2769;
go

CREATE TABLE Datetime2769 (c1 VARCHAR(32) NOT NULL, c2 DATETIME NULL);
go
INSERT INTO Datetime2769 ( c1 ) VALUES ('First');
go
INSERT INTO Datetime2769 ( c1 ) VALUES ('Second');
go
SELECT * FROM Datetime2769;
go
DROP TABLE Datetime2769;
go

CREATE TABLE Datetime2_2769 (c1 VARCHAR(32) NOT NULL, c2 DATETIME2(3) NULL);
go
INSERT INTO Datetime2_2769 ( c1 ) VALUES ('First');
go
INSERT INTO Datetime2_2769 ( c1 ) VALUES ('Second');
go
SELECT * FROM Datetime2_2769;
go
DROP TABLE Datetime2_2769;
go

CREATE TABLE Datetimeoffset2769 (c1 VARCHAR(32) NOT NULL, c2 DATETIMEOFFSET(5) NULL);
go
INSERT INTO Datetimeoffset2769 ( c1 ) VALUES ('First');
go
INSERT INTO Datetimeoffset2769 ( c1 ) VALUES ('Second');
go
SELECT * FROM Datetimeoffset2769;
go
DROP TABLE Datetimeoffset2769;
go

create table #srtestnull_t1 (a varchar(2), dt smalldatetime null);
go
insert into #srtestnull_t1 values ('A', '');
go
insert into #srtestnull_t1 (a) values ('B');
go
select * from #srtestnull_t1;
go
drop table #srtestnull_t1;
go

create table #srtestnull_t2 (a varchar(2), dt datetime null);
go
insert into #srtestnull_t2 values ('A', '');
go
insert into #srtestnull_t2 (a) values ('B');
go
select * from #srtestnull_t2;
go
drop table #srtestnull_t2;
go

create table #srtestnull_t3 (a varchar(2), dt datetime2(4) null);
go
insert into #srtestnull_t3 values ('A', '');
go
insert into #srtestnull_t3 (a) values ('B');
go
select * from #srtestnull_t3;
go
drop table #srtestnull_t3;
go

create table #srtestnull_t4 (a varchar(2), dt datetimeoffset(6) null);
go
insert into #srtestnull_t4 values ('A', '');
go
insert into #srtestnull_t4 (a) values ('B');
go
select * from #srtestnull_t4;
go
drop table #srtestnull_t4;
go

USE master;
go

DROP DATABASE db_babel_2769;
go
