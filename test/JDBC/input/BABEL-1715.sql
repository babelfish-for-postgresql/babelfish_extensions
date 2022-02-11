use master;
go

CREATE TABLE t1715 (a int, b int CONSTRAINT uk_a PRIMARY KEY (a));
go
INSERT INTO t1715 VALUES (1, 1);
INSERT INTO t1715 VALUES (2, 2);
go
INSERT INTO t1715 VALUES (2, 3);
go
drop table t1715;
go


CREATE TABLE t1715_2 (a int, b as a+1 CONSTRAINT uk_a PRIMARY KEY (a));
go
INSERT INTO t1715_2 (a) VALUES (1);
INSERT INTO t1715_2 (a) VALUES (2);
go
INSERT INTO t1715_2 (a) VALUES (2);
go
drop table t1715_2;
go


CREATE TABLE t1715_invalid (a int b int);
go
CREATE TABLE t1715_invalid (a int CONSTRAINT uk_a PRIMARY KEY (a) b int);
go
CREATE TABLE t1715_invalid (a int CONSTRAINT uk_a PRIMARY KEY (a) CONSTRAINT uk_b UNIQUE (b));
go


-- cx table
CREATE TABLE cx_t1715 ( name sysname NOT NULL, principal_id int NOT NULL,  diagram_id int PRIMARY KEY IDENTITY, version int, definition varbinary(max) CONSTRAINT UK_principal_name UNIQUE ( principal_id, name ) );
go

DROP TABLE cx_t1715;
go
