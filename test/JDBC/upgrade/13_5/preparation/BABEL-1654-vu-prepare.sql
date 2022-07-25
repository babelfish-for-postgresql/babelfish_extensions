if update(x) select 1;
GO

select COLUMNS_UPDATED();
GO

CREATE TABLE bbl_1654_employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50),Emp_Last_name VARCHAR (50),Emp_Salary INT,
a varchar (50), b varchar(50), c varchar(50), d varchar(50), e varchar(50), f varchar(50))
GO

create table bbl_1654_t ( ID INT IDENTITY (1,1) PRIMARY KEY , a varchar(50), b varchar(50))
GO

CREATE TRIGGER bbl_1654_trig_t on bbl_1654_t after update as
	select COLUMNS_UPDATED();
GO

CREATE TRIGGER bbl_1654_updEmployeeDatas ON bbl_1654_employeeData  AFTER UPDATE,INSERT AS   
	select COLUMNS_UPDATED();
	update bbl_1654_t set a = 'sss' , b = 'sss' where id = 1;
	select COLUMNS_UPDATED();
GO
