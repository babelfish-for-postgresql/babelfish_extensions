USE db_babel_3234;
go

insert into t1 (b1) values (2);
go
insert into t1 values (1, 3);
go
insert into t2 (b1) values (2);
go
insert into t2 values (1, 3);
go
insert into t3 (b1) values (2);
go

select * from t1;
go
select * from t2;
go
select * from t3;
go

drop table t1;
go
drop table t2;
go
drop table t3;
go

use master;
go

drop DATABASE db_babel_3234;
go