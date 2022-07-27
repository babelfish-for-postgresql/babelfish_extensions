CREATE TABLE babel_1243_vu_prepare_employeeData(
     ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50),Emp_Last_name VARCHAR (50),Emp_Salary INT)
GO

CREATE TRIGGER babel_1243_vu_prepare_updEmployeeDatas ON babel_1243_vu_prepare_employeeData  AFTER UPDATE,INSERT AS   
    select * from inserted;
GO
