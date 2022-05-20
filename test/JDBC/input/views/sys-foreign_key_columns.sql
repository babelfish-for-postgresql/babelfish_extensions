CREATE DATABASE db1;
GO

USE db1;
GO

create table fk_1 (a int, primary key (a));
GO

create table fk_2 (a int, b int, primary key (a), foreign key (b) references fk_1(a));
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('fk_2');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2');
GO

USE master;
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('fk_2');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2');
GO

create table fk_3 (a int, primary key (a));
GO

create table fk_4 (a int, b int, primary key (a), foreign key (b) references fk_3(a));
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('fk_4');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4');
GO

USE db1;
GO

select count(*) from sys.foreign_key_columns where parent_object_id = object_id('fk_4');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4');
GO

drop table fk_2;
GO

drop table fk_1;
GO

USE master;
GO

drop table fk_4;
GO

drop table fk_3;
GO

USE db1;
GO

CREATE TABLE pk_t1 (
    PID_1 INT NOT NULL,
    PID_2 INT NOT NULL,
    PRIMARY KEY (PID_1, PID_2)
);
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

CREATE TABLE pk_t2 (
    PID_3 INT NOT NULL,
    PID_4 INT NOT NULL,
    PRIMARY KEY (PID_3, PID_4)
);
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

CREATE TABLE fk_t1 (
    PID_1 INT,
    PID_2 INT,
    FOREIGN KEY (PID_1, PID_2) REFERENCES pk_t1(PID_1, PID_2)
);
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

CREATE TABLE fk_t2 (
    PID_3 INT,
    PID_4 INT,
    FOREIGN KEY (PID_3, PID_4) REFERENCES pk_t2(PID_3, PID_4)
);
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

CREATE TABLE pk_t3 (
    PID_5 INT NOT NULL,
    PID_6 INT NOT NULL,
    PRIMARY KEY (PID_5, PID_6)
);
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

CREATE TABLE fk_t3 (
    PID_3 INT NOT NULL,
    PID_4 INT NOT NULL,
    PID_5 INT NOT NULL,
    PID_6 INT NOT NULL,
    FOREIGN KEY (PID_3, PID_4) REFERENCES pk_t2(PID_3, PID_4),
    FOREIGN KEY (PID_5, PID_6) REFERENCES pk_t3(PID_5, PID_6)
);
GO

SELECT COUNT(*) FROM sys.foreign_key_columns;
GO

SELECT constraint_column_id, parent_column_id, referenced_column_id FROM sys.foreign_key_columns ORDER BY constraint_column_id, parent_column_id, referenced_column_id;

DROP TABLE fk_t3;
GO

DROP TABLE fk_t2;
GO

DROP TABLE fk_t1;
GO

DROP TABLE pk_t3;
GO

DROP TABLE pk_t2;
GO

DROP TABLE pk_t1;
GO

USE master;
GO

DROP DATABASE db1;
GO
