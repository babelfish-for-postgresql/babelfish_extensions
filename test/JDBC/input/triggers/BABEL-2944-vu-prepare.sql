CREATE TABLE babel_2944_vu_prepare_employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50))
GO

CREATE TRIGGER babel_2944_vu_prepare_updEmployeeData1  ON babel_2944_vu_prepare_employeeData  AFTER INSERT AS    
   select count(*) from deleted;
GO

CREATE TRIGGER babel_2944_vu_prepare_updEmployeeData2  ON babel_2944_vu_prepare_employeeData  AFTER DELETE AS    
   select count(*) from inserted;
GO


