insert into babel_2787_2_employeeData values ('a'),('b'),('c'),('d');
GO

CREATE TRIGGER babel_2787_2_updEmployeeData  ON babel_2787_2_employeeData  INSTEAD OF INSERT AS  
BEGIN  
   BEGIN TRAN;
    update babel_2787_2_employeeData set Emp_First_name = 'dddd';
   Rollback tran;
END
GO

insert into babel_2787_2_employeeData values ('e')
GO

select * from babel_2787_2_employeeData
GO

drop trigger babel_2787_2_updEmployeeData;
GO

CREATE TRIGGER babel_2787_2_updEmployeeData  ON babel_2787_2_employeeData  INSTEAD OF UPDATE AS  
BEGIN  
   BEGIN TRAN;
    insert into babel_2787_2_employeeData values ('e')
   Rollback tran;
END
GO

update babel_2787_2_employeeData set Emp_First_name = 'dddd';
GO

select * from babel_2787_2_employeeData
GO

drop trigger babel_2787_2_updEmployeeData;
GO

CREATE TRIGGER babel_2787_2_updEmployeeData  ON babel_2787_2_employeeData  INSTEAD OF DELETE AS  
BEGIN  
   BEGIN TRAN;
    update babel_2787_2_employeeData set Emp_First_name = 'dddd';
   Rollback tran;
END
GO

delete from babel_2787_2_employeeData where Emp_First_name = 'a';
GO

select * from babel_2787_2_employeeData
GO