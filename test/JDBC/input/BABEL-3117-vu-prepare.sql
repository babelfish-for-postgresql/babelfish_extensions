CREATE DATABASE BABEL_3117_prepare_db1
CREATE DATABASE BABEL_3117_prepare_db2
GO

USE BABEL_3117_prepare_db1
GO
CREATE TABLE BABEL_3117_prepare_db1_employeeData(ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50))
GO
CREATE TRIGGER BABEL_3117_prepare_trigger1
    on BABEL_3117_prepare_db1_employeeData
    INSTEAD OF INSERT AS
BEGIN
    SELECT count(*) FROM inserted;
END
GO
INSERT INTO BABEL_3117_prepare_db1_employeeData VALUES ('a'),('b'),('c');
GO

USE BABEL_3117_prepare_db2
GO
CREATE TABLE BABEL_3117_prepare_db2_employeeData(ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50))
GO
CREATE TRIGGER BABEL_3117_prepare_trigger1
    on BABEL_3117_prepare_db2_employeeData
    INSTEAD OF INSERT AS
BEGIN
    SELECT count(*) FROM inserted;
END
GO
INSERT INTO BABEL_3117_prepare_db2_employeeData VALUES ('a'),('b'),('c');
GO
DROP TRIGGER BABEL_3117_prepare_trigger1
GO
INSERT INTO BABEL_3117_prepare_db2_employeeData VALUES ('a'),('b'),('c');
GO
