use master;
go

select 'no error' from (select GETUTCDATE()) t;
go

select 'no error' from (select SYSUTCDATETIME()) t;
go
