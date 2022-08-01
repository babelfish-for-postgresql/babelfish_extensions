use master
go

SELECT suser_sid(-10)
go

select * from babel_3402_vu_prepare_v1;
go

select babel_3402_vu_prepare_f1(-10);
go

exec babel_3402_vu_prepare_p1 -10;
go

select * from babel_3402_vu_prepare_v2;
go

DROP VIEW IF EXISTS babel_3402_vu_prepare_v1
go
drop function if exists babel_3402_vu_prepare_f1(int);
go
drop procedure if exists babel_3402_vu_prepare_p1;
go
DROP VIEW IF EXISTS babel_3402_vu_prepare_v2;
go
