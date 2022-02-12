if update(x) select 1;
GO

select COLUMNS_UPDATED();
GO

CREATE TABLE employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50),Emp_Last_name VARCHAR (50),Emp_Salary INT,
a varchar (50), b varchar(50), c varchar(50), d varchar(50), e varchar(50), f varchar(50))
GO

create table t ( ID INT IDENTITY (1,1) PRIMARY KEY , a varchar(50), b varchar(50))
GO

CREATE TRIGGER trig_t on t after update as
	select COLUMNS_UPDATED();
GO

CREATE TRIGGER updEmployeeDatas ON employeeData  AFTER UPDATE,INSERT AS   
	select COLUMNS_UPDATED();
	update t set a = 'sss' , b = 'sss' where id = 1;
	select COLUMNS_UPDATED();
GO

insert into employeeData values ('d','b',123, 'a','a','a','a','a','a');
go

insert into t values ('a','b');
go

update employeeData set Emp_Last_name = 'sss', f = 'ddd' where id = 1;
go

update employeeData set Emp_First_name = 'sss' where id = 1;
go

update employeeData set f= 'ddd' where id = 1;
go


drop trigger updEmployeeDatas;
go

drop trigger trig_t;
go

drop table t;
go

drop table employeeData;
go
