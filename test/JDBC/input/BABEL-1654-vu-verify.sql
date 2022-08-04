insert into babel_1654_vu_prepare_employeeData values ('d','b',123, 'a','a','a','a','a','a');
go

insert into babel_1654_vu_prepare_t values ('a','b');
go

update babel_1654_vu_prepare_employeeData set Emp_Last_name = 'sss', f = 'ddd' where id = 1;
go

update babel_1654_vu_prepare_employeeData set Emp_First_name = 'sss' where id = 1;
go

update babel_1654_vu_prepare_employeeData set f= 'ddd' where id = 1;
go