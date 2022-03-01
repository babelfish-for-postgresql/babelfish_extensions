CREATE TABLE employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50));
GO

insert into employeeData values ('a'),('b'),('c'),('d');
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF INSERT AS  
BEGIN  
   BEGIN TRAN;
    update employeeData set Emp_First_name = 'dddd';
   Rollback tran;
END
GO

insert into employeeData values ('e')
GO

select * from employeeData
GO

drop trigger updEmployeeData;
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF UPDATE AS  
BEGIN  
   BEGIN TRAN;
    insert into employeeData values ('e')
   Rollback tran;
END
GO

update employeeData set Emp_First_name = 'dddd';
GO

select * from employeeData
GO

drop trigger updEmployeeData;
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF DELETE AS  
BEGIN  
   BEGIN TRAN;
    update employeeData set Emp_First_name = 'dddd';
   Rollback tran;
END
GO

delete from employeeData where Emp_First_name = 'a';
GO

select * from employeeData
GO

drop trigger updEmployeeData;
GO

drop table employeeData
GO