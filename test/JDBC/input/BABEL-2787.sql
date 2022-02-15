CREATE TABLE employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50));
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF UPDATE AS
BEGIN
   select count(*) from inserted;
END
GO

CREATE TRIGGER updEmployeeData  ON employeeData  INSTEAD OF DELETE AS    
BEGIN
   select count(*) from inserted;
END
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

CREATE TRIGGER updEmployeeData2  ON employeeData  AFTER INSERT AS  
BEGIN  
   select "after insert";
END
GO

insert into employeeData values ('bb'),('cc');
GO

drop trigger updEmployeeData
GO

drop trigger updEmployeeData2
GO

drop table employeeData
GO