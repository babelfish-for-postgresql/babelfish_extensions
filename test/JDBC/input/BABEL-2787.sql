CREATE TABLE employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50));
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF INSERT AS  
BEGIN  
   select count(*) from inserted;
END
GO

insert into employeeData values ('a'),('b'),('c');
GO

select count(*) from employeeData;
GO

drop trigger updEmployeeData;
GO

insert into employeeData values ('a'),('b'),('c'),('d');
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF DELETE AS    
BEGIN
   select count(*) from deleted;
END
GO

delete from employeeData where id = 1;
GO

delete from employeeData;
GO

select * from employeeData;
GO

drop trigger updEmployeeData
GO

delete from employeeData;
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF UPDATE AS
BEGIN
   select * from inserted;
   select * from deleted;
END
GO

insert into employeeData values ('a'),('b'),('c'),('d');
GO

update employeeData set Emp_First_name = 'ppp' where Emp_First_name = 'a'
GO

update employeeData set Emp_First_name = 'kkk' where Emp_First_name = 'a'
GO

update employeeData set Emp_First_name = 'ddd'
GO

drop trigger updEmployeeData
GO

drop table employeeData
GO