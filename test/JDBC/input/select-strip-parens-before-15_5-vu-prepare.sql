create table select_strip_parens_t1(field1 int, " field2  " int, [  field3 ] int);
go

insert into select_strip_parens_t1(field1, " field2  ", [  field3 ]) values(41, 42, 43);
go
