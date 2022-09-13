CREATE DATABASE db1_sys_foreign_keys;
GO

USE db1_sys_foreign_keys;
GO

create table fk_1_sys_foreign_keys (a int, primary key (a));
GO

create table fk_2_sys_foreign_keys (a int, b int, primary key (a), foreign key (b) references fk_1_sys_foreign_keys(a));
GO

USE master;
GO

create table fk_3_sys_foreign_keys (a int, primary key (a));
GO

create table fk_4_sys_foreign_keys (a int, b int, primary key (a), foreign key (b) references fk_3_sys_foreign_keys(a));
GO

USE db1_sys_foreign_keys;
GO

CREATE TABLE PK1 (
 PK1_ID INT,
 PK1_UNIQUE_INT INT UNIQUE NOT NULL,
 PRIMARY KEY (PK1_ID)
)
GO

CREATE TABLE FK1 (
 FK1_ID INT NOT NULL,
 PK1_ID INT
 FOREIGN KEY (PK1_ID) REFERENCES PK1(PK1_ID)
)
GO

CREATE TABLE PK2 (
 PK2_ID INT,
 PK2_UNIQUE_INT_1 INT UNIQUE NOT NULL,
 PK2_UNIQUE_INT_2 INT UNIQUE NOT NULL,
)
GO

CREATE TABLE FK2 (
 FK2_INT INT NOT NULL,
 FK2_INT_2 INT
 FOREIGN KEY (FK2_INT_2) REFERENCES PK2(PK2_UNIQUE_INT_1)
)
GO

CREATE TABLE PK3 (
 PK3_INT_1 INT,
 PK3_INT_2 INT,
 PRIMARY KEY (PK3_INT_1, PK3_INT_2)
)
GO

CREATE TABLE FK3 (
 PK3_INT_1 INT,
 PK3_INT_2 INT,
 FOREIGN KEY (PK3_INT_1, PK3_INT_2) REFERENCES PK3(PK3_INT_1, PK3_INT_2)
)
GO

