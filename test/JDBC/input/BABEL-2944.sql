CREATE TABLE employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50))
GO

CREATE TRIGGER updEmployeeData  ON employeeData  AFTER INSERT AS    
   select count(*) from deleted;
GO

insert into employeeData values ('a'),('b'),('c'),('d');
GO

drop trigger updEmployeeData;
GO

insert into employeeData values ('a'),('b'),('c'),('d');
GO

CREATE TRIGGER updEmployeeData  ON employeeData  AFTER DELETE AS    
   select count(*) from inserted;
GO

delete from employeeData where Emp_First_name = 'a';
GO

drop trigger updEmployeeData;
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF INSERT AS    
   select count(*) from deleted;
GO

insert into employeeData values ('bbb');
GO

drop trigger updEmployeeData;
GO

drop table employeeData
GO
