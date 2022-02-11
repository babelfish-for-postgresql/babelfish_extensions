CREATE TABLE employeeData(
     ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50),Emp_Last_name VARCHAR (50),Emp_Salary INT)
GO

CREATE TRIGGER updEmployeeDatas ON employeeData  AFTER UPDATE,INSERT AS   
    select * from inserted;
GO

insert into employeeData values ('a','b',234);
GO

update employeeData set Emp_Last_name = 'ccc' where id = 1;
GO

drop trigger updEmployeeDatas
GO

drop table employeeData
GO
