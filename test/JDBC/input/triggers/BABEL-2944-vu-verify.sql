insert into babel_2944_vu_prepare_employeeData values ('a'),('b'),('c'),('d');
GO

drop trigger babel_2944_vu_prepare_updEmployeeData1;
GO

insert into babel_2944_vu_prepare_employeeData values ('a'),('b'),('c'),('d');
GO

delete from babel_2944_vu_prepare_employeeData where Emp_First_name = 'a';
GO

CREATE TRIGGER babel_2944_vu_prepare_updEmployeeData3  ON babel_2944_vu_prepare_employeeData  INSTEAD OF INSERT AS    
   select count(*) from deleted;
GO


insert into babel_2944_vu_prepare_employeeData values ('bbb');
GO

