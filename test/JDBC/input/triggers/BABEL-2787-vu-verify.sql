insert into babel_2787_vu_prepare_employeeData values ('a'),('b'),('c');
GO

select count(*) from babel_2787_vu_prepare_employeeData;
GO

drop trigger babel_2787_vu_prepare_updEmployeeData1;
GO

insert into babel_2787_vu_prepare_employeeData values ('a'),('b'),('c'),('d');
GO


delete from babel_2787_vu_prepare_employeeData where id = 1;
GO

delete from babel_2787_vu_prepare_employeeData;
GO

select * from babel_2787_vu_prepare_employeeData;
GO

drop trigger babel_2787_vu_prepare_updEmployeeData2;
GO

delete from babel_2787_vu_prepare_employeeData;
GO

insert into babel_2787_vu_prepare_employeeData values ('a'),('b'),('c'),('d');
GO

update babel_2787_vu_prepare_employeeData set Emp_First_name = 'ppp' where Emp_First_name = 'a';
GO

update babel_2787_vu_prepare_employeeData set Emp_First_name = 'kkk' where Emp_First_name = 'a';
GO

update babel_2787_vu_prepare_employeeData set Emp_First_name = 'ddd';
GO

