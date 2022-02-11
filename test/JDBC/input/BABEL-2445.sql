USE master;
go

select N'long text more than 30 characters';
go
select 'foo' where N'bar ' = 'bar';
go
select 'foo' where N'bar ' = N'bar';
go
select 'foo' as N'@var';
go