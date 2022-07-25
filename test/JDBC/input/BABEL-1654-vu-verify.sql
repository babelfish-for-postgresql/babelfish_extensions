insert into bbl_1654_employeeData values ('d','b',123, 'a','a','a','a','a','a');
go

insert into bbl_1654_t values ('a','b');
go

update bbl_1654_employeeData set Emp_Last_name = 'sss', f = 'ddd' where id = 1;
go

update bbl_1654_employeeData set Emp_First_name = 'sss' where id = 1;
go

update bbl_1654_employeeData set f= 'ddd' where id = 1;
go