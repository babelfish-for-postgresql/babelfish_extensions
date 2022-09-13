CREATE DATABASE sys_foreign_key_columns_vu_prepare_db1;
GO

USE sys_foreign_key_columns_vu_prepare_db1;
GO

create table sys_foreign_key_columns_vu_prepare_fk_1 (a int, primary key (a));
GO

create table sys_foreign_key_columns_vu_prepare_fk_2 (a int, b int, primary key (a), foreign key (b) references sys_foreign_key_columns_vu_prepare_fk_1(a));
GO

USE master;
GO

create table sys_foreign_key_columns_vu_prepare_fk_3 (a int, primary key (a));
GO

create table sys_foreign_key_columns_vu_prepare_fk_4 (a int, b int, primary key (a), foreign key (b) references sys_foreign_key_columns_vu_prepare_fk_3(a));
GO

USE sys_foreign_key_columns_vu_prepare_db1;
GO

CREATE TABLE sys_foreign_key_columns_vu_prepare_pk_t1 (
    PID_1 INT NOT NULL,
    PID_2 INT NOT NULL,
    PRIMARY KEY (PID_1, PID_2)
);
GO

CREATE TABLE sys_foreign_key_columns_vu_prepare_pk_t2 (
    PID_3 INT NOT NULL,
    PID_4 INT NOT NULL,
    PRIMARY KEY (PID_3, PID_4)
);
GO

CREATE TABLE sys_foreign_key_columns_vu_prepare_fk_t1 (
    PID_1 INT,
    PID_2 INT,
    FOREIGN KEY (PID_1, PID_2) REFERENCES sys_foreign_key_columns_vu_prepare_pk_t1(PID_1, PID_2)
);
GO

CREATE TABLE sys_foreign_key_columns_vu_prepare_fk_t2 (
    PID_3 INT,
    PID_4 INT,
    FOREIGN KEY (PID_3, PID_4) REFERENCES sys_foreign_key_columns_vu_prepare_pk_t2(PID_3, PID_4)
);
GO

CREATE TABLE sys_foreign_key_columns_vu_prepare_pk_t3 (
    PID_5 INT NOT NULL,
    PID_6 INT NOT NULL,
    PRIMARY KEY (PID_5, PID_6)
);
GO

CREATE TABLE sys_foreign_key_columns_vu_prepare_fk_t3 (
    PID_3 INT NOT NULL,
    PID_4 INT NOT NULL,
    PID_5 INT NOT NULL,
    PID_6 INT NOT NULL,
    FOREIGN KEY (PID_3, PID_4) REFERENCES sys_foreign_key_columns_vu_prepare_pk_t2(PID_3, PID_4),
    FOREIGN KEY (PID_5, PID_6) REFERENCES sys_foreign_key_columns_vu_prepare_pk_t3(PID_5, PID_6)
);
GO
