create view v1_bitop as select 99&+2 as c1, 88|-9 as c2, 77^~5 as c3
go
create procedure p1_bitop  as select 99&~5|-4
go
create view v1_bitop_not as select ~+2 as x
go
create procedure p1_bitop_not  as select ~+2
go
create view v1_modulo_op as select 10%-3 as x
go
create procedure p1_modulo_op as select 10%+2
go