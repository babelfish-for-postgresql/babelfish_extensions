CREATE DATABASE db1_sys_foreign_key_columns;
GO

USE db1_sys_foreign_key_columns;
GO

create table fk_1_sys_foreign_key_columns (a int, primary key (a));
GO

create table fk_2_sys_foreign_key_columns (a int, b int, primary key (a), foreign key (b) references fk_1_sys_foreign_key_columns(a));
GO

USE master;
GO

create table fk_3_sys_foreign_key_columns (a int, primary key (a));
GO

create table fk_4_sys_foreign_key_columns (a int, b int, primary key (a), foreign key (b) references fk_3_sys_foreign_key_columns(a));
GO

USE db1_sys_foreign_key_columns;
GO

CREATE TABLE pk_t1 (
    PID_1 INT NOT NULL,
    PID_2 INT NOT NULL,
    PRIMARY KEY (PID_1, PID_2)
);
GO

CREATE TABLE pk_t2 (
    PID_3 INT NOT NULL,
    PID_4 INT NOT NULL,
    PRIMARY KEY (PID_3, PID_4)
);
GO

CREATE TABLE fk_t1 (
    PID_1 INT,
    PID_2 INT,
    FOREIGN KEY (PID_1, PID_2) REFERENCES pk_t1(PID_1, PID_2)
);
GO

CREATE TABLE fk_t2 (
    PID_3 INT,
    PID_4 INT,
    FOREIGN KEY (PID_3, PID_4) REFERENCES pk_t2(PID_3, PID_4)
);
GO

CREATE TABLE pk_t3 (
    PID_5 INT NOT NULL,
    PID_6 INT NOT NULL,
    PRIMARY KEY (PID_5, PID_6)
);
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
