USE db_babel_3267;
go

select * from [T3267#];
go

select * from [T3267 a];
go

select * from [T3267'b];
go

select * from [T3267\c];
go

select * from [T3267"d];
go

select * from [T3267\schema].[T3267.[CustomTable];
go

select relname, array_to_string(reloptions,',') reloptions from pg_class C where C.relname like 't3267%' order by relname;
go

USE master;
go

DROP DATABASE db_babel_3267;
go
