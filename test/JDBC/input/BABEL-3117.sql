USE master
GO

CREATE TABLE BABEL_3117_employeeData(ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50))
GO

CREATE TRIGGER BABEL_3117_trigger
    on BABEL_3117_employeeData
    INSTEAD OF INSERT AS
BEGIN
    SELECT count(*) FROM inserted;
END
GO

CREATE DATABASE BABEL_3117_db
GO

USE BABEL_3117_db
GO

CREATE TABLE BABEL_3117_employeeData(ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50))
GO

CREATE TRIGGER BABEL_3117_trigger
    on BABEL_3117_employeeData
    INSTEAD OF INSERT AS
BEGIN
    SELECT count(*) FROM inserted;
END
GO

INSERT INTO BABEL_3117_employeeData VALUES ('a'),('b'),('c');
GO

-- Should return 0
SELECT count(*) FROM BABEL_3117_employeeData;
GO

DROP TRIGGER BABEL_3117_trigger
GO

DROP TABLE BABEL_3117_employeeData

USE master
GO

--Should return 3 since trigger exits
DROP TRIGGER BABEL_3117_trigger
GO

INSERT INTO BABEL_3117_employeeData VALUES ('a'),('b'),('c');
GO

SELECT count(*) FROM BABEL_3117_employeeData;
GO

DROP TABLE BABEL_3117_employeeData
DROP DATABASE BABEL_3117_db
GO
