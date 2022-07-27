CREATE TABLE babel_383_vu_prepare_employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50),Emp_Last_name VARCHAR (50),Emp_Salary INT,
a varchar (50), b varchar(50), c varchar(50), d varchar(50), e varchar(50), f varchar(50))
GO

CREATE TRIGGER babel_383_vu_prepare_updEmployeeDatas ON babel_383_vu_prepare_employeeData  AFTER UPDATE AS   
	IF (UPDATE(emp_first_name))
	BEGIN
		select * from babel_383_vu_prepare_employeeData;
	END
GO


