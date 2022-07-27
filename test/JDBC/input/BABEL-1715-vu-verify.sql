USE MASTER
GO


INSERT INTO babel_1715_vu_prepare_t1 VALUES (1, 1);
INSERT INTO babel_1715_vu_prepare_t1 VALUES (2, 2);
go
INSERT INTO babel_1715_vu_prepare_t1 VALUES (2, 3);
go

INSERT INTO babel_1715_vu_prepare_t2 (a) VALUES (1);
INSERT INTO babel_1715_vu_prepare_t2 (a) VALUES (2);
go
INSERT INTO babel_1715_vu_prepare_t2 (a) VALUES (2);
go

CREATE TABLE babel_1715_vu_prepare_invalid1 (a int b int);
go
CREATE TABLE babel_1715_vu_prepare_invalid2 (a int CONSTRAINT uk_a PRIMARY KEY (a) b int);
go
CREATE TABLE babel_1715_vu_prepare_invalid3 (a int CONSTRAINT uk_a PRIMARY KEY (a) CONSTRAINT uk_b UNIQUE (b));
go
