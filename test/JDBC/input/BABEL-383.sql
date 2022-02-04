CREATE TABLE employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50),Emp_Last_name VARCHAR (50),Emp_Salary INT,
a varchar (50), b varchar(50), c varchar(50), d varchar(50), e varchar(50), f varchar(50))
GO

CREATE TRIGGER updEmployeeDatas ON employeeData  AFTER UPDATE AS   
	IF (UPDATE(emp_first_name))
	BEGIN
		select * from employeeData;
	END
GO

insert into employeeData values ('d','b',123, 'a','a','a','a','a','a');
go

update employeeData set Emp_Last_name = 'sss', f = 'ddd' where id = 1;
go

update employeeData set Emp_First_name = 'sss' where id = 1;
go

update employeeData set f= 'ddd' where id = 1;
go

drop trigger updEmployeeDatas;
go

drop table employeeData;
go

