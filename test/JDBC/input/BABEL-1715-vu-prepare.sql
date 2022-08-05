use master;
go

CREATE TABLE babel_1715_vu_prepare_t1 (a int, b int CONSTRAINT uk_a PRIMARY KEY (a));
go

INSERT INTO babel_1715_vu_prepare_t1 VALUES (1, 1);
INSERT INTO babel_1715_vu_prepare_t1 VALUES (2, 2);
GO

CREATE TABLE babel_1715_vu_prepare_t2 (a int, b as a+1 CONSTRAINT uk_a PRIMARY KEY (a));
go

INSERT INTO babel_1715_vu_prepare_t2 (a) VALUES (1);
INSERT INTO babel_1715_vu_prepare_t2 (a) VALUES (2);
GO

CREATE TABLE babel_1715_vu_prepare_invalid1 (a int b int);
go
CREATE TABLE babel_1715_vu_prepare_invalid2 (a int CONSTRAINT uk_a PRIMARY KEY (a) b int);
go
CREATE TABLE babel_1715_vu_prepare_invalid3 (a int CONSTRAINT uk_a PRIMARY KEY (a) CONSTRAINT uk_b UNIQUE (b));
go

-- cx table
CREATE TABLE cx_babel_1715_vu_prepare ( name sysname NOT NULL, principal_id int NOT NULL,  diagram_id int PRIMARY KEY IDENTITY, version int, definition varbinary(max) CONSTRAINT UK_principal_name UNIQUE ( principal_id, name ) );
go