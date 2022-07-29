CREATE TABLE BABEL_2769_vu_prepare_Smalldatetime (c1 VARCHAR(32) NOT NULL, c2 SMALLDATETIME NULL);
go
INSERT INTO BABEL_2769_vu_prepare_Smalldatetime ( c1 ) VALUES ('First');
go
INSERT INTO BABEL_2769_vu_prepare_Smalldatetime ( c1 ) VALUES ('Second');
go

CREATE TABLE BABEL_2769_vu_prepare_Datetime (c1 VARCHAR(32) NOT NULL, c2 DATETIME NULL);
go
INSERT INTO BABEL_2769_vu_prepare_Datetime ( c1 ) VALUES ('First');
go
INSERT INTO BABEL_2769_vu_prepare_Datetime ( c1 ) VALUES ('Second');
go

CREATE TABLE BABEL_2769_vu_prepare_Datetime2 (c1 VARCHAR(32) NOT NULL, c2 DATETIME2(3) NULL);
go
INSERT INTO BABEL_2769_vu_prepare_Datetime2 ( c1 ) VALUES ('First');
go
INSERT INTO BABEL_2769_vu_prepare_Datetime2 ( c1 ) VALUES ('Second');
go

CREATE TABLE BABEL_2769_vu_prepare_Datetimeoffset (c1 VARCHAR(32) NOT NULL, c2 DATETIMEOFFSET(5) NULL);
go
INSERT INTO BABEL_2769_vu_prepare_Datetimeoffset ( c1 ) VALUES ('First');
go
INSERT INTO BABEL_2769_vu_prepare_Datetimeoffset ( c1 ) VALUES ('Second');
go
