-- create procedure with incomplete definition
create procedure [p_employee_insert]
@person_id int, @fname varchar(20), @lname varchar(30), @sal money
as
begin
go
