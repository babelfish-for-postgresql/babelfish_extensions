SET IDENTITY_INSERT babel_1251_vu_prepare.t1 ON;
go
INSERT INTO babel_1251_vu_prepare.t1(col1, id) VALUES (1, 10);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251_vu_prepare.t1 OFF;
go
INSERT INTO babel_1251_vu_prepare.t1(col1) VALUES (1);
go
SELECT * FROM babel_1251_vu_prepare.t1;
go
SELECT @@IDENTITY;
go

SET IDENTITY_INSERT babel_1251_vu_prepare.t2 ON;
go
INSERT INTO babel_1251_vu_prepare.t2(col1, id, col2) VALUES ('hello', -10, 1);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251_vu_prepare.t2 OFF;
go
INSERT INTO babel_1251_vu_prepare.t2(col1, col2) VALUES ('world', 1);
go
SELECT @@IDENTITY;
go
SELECT * FROM babel_1251_vu_prepare.t2;
go

INSERT INTO babel_1251_vu_prepare.t3(col1, col2) VALUES ('hello', 1);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251_vu_prepare.t3 ON;
go
INSERT INTO babel_1251_vu_prepare.t3(col1, col2, id) VALUES ('hello', 1, 20);
go
SET IDENTITY_INSERT babel_1251_vu_prepare.t3 OFF;
go
SELECT @@IDENTITY;
go
INSERT INTO babel_1251_vu_prepare.t3(col1, col2) VALUES ('hello', 1);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251_vu_prepare.t3 ON;
go
INSERT INTO babel_1251_vu_prepare.t3(col1, col2, id) VALUES ('hello', 1, 30);
go
SELECT @@IDENTITY;
go
SET IDENTITY_INSERT babel_1251_vu_prepare.t3 OFF;
go
SELECT * FROM babel_1251_vu_prepare.t3;
go
SELECT @@IDENTITY;
go