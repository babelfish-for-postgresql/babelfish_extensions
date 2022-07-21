CREATE TABLE babel_2787_employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50));
GO

CREATE TRIGGER babel_2787_updEmployeeData1  ON babel_2787_employeeData  INSTEAD OF INSERT AS  
BEGIN  
   select count(*) from inserted;
END
GO

CREATE TRIGGER babel_2787_updEmployeeData2  ON babel_2787_employeeData  INSTEAD OF DELETE AS    
BEGIN
   select count(*) from deleted;
END
GO

CREATE TRIGGER babel_2787_updEmployeeData3  ON babel_2787_employeeData  INSTEAD OF UPDATE AS
BEGIN
   select * from inserted;
   select * from deleted;
END
GO

