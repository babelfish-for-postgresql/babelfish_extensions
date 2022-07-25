use master;
go

CREATE TABLE bbl_1715_t1 (a int, b int CONSTRAINT uk_a PRIMARY KEY (a));
go

CREATE TABLE bbl_1715_t2 (a int, b as a+1 CONSTRAINT uk_a PRIMARY KEY (a));
go

CREATE TABLE bbl_1715_invalid1 (a int b int);
go
CREATE TABLE bbl_1715_invalid2 (a int CONSTRAINT uk_a PRIMARY KEY (a) b int);
go
CREATE TABLE bbl_1715_invalid3 (a int CONSTRAINT uk_a PRIMARY KEY (a) CONSTRAINT uk_b UNIQUE (b));
go

-- cx table
CREATE TABLE cx_bbl_1715 ( name sysname NOT NULL, principal_id int NOT NULL,  diagram_id int PRIMARY KEY IDENTITY, version int, definition varbinary(max) CONSTRAINT UK_principal_name UNIQUE ( principal_id, name ) );
go