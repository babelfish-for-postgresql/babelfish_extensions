if update(x) select 1;
GO

select COLUMNS_UPDATED();
GO

CREATE TABLE babel_1654_vu_prepare_employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50),Emp_Last_name VARCHAR (50),Emp_Salary INT,
a varchar (50), b varchar(50), c varchar(50), d varchar(50), e varchar(50), f varchar(50))
GO

create table babel_1654_vu_prepare_t ( ID INT IDENTITY (1,1) PRIMARY KEY , a varchar(50), b varchar(50))
GO

CREATE TRIGGER babel_1654_vu_prepare_trig_t on babel_1654_vu_prepare_t after update as
	select COLUMNS_UPDATED();
GO

CREATE TRIGGER babel_1654_vu_prepare_updEmployeeDatas ON babel_1654_vu_prepare_employeeData  AFTER UPDATE,INSERT AS   
	select COLUMNS_UPDATED();
	update babel_1654_vu_prepare_t set a = 'sss' , b = 'sss' where id = 1;
	select COLUMNS_UPDATED();
GO
