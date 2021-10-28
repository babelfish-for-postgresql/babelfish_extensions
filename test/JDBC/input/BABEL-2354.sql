CREATE TABLE employeeData( ID INT IDENTITY (1,1) PRIMARY KEY,Emp_First_name VARCHAR (50),Emp_Last_name VARCHAR (50),Emp_Salary INT)
GO

CREATE TRIGGER updEmployeeData  ON employeeData  AFTER UPDATE AS    
   IF (COLUMNS_UPDATED() & 14) > 0  
   BEGIN  
     PRINT 'Columns 3, 5 and 9 updated';     
   END;  
GO

drop trigger updEmployeeData
GO

drop table employeeData
GO
