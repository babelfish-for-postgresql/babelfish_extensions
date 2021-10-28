create table #tt(a int);
go
select (case when OBJECT_ID('#tt') IS NOT NULL then 'true' else 'false' end) result;
go
select (case when OBJECT_ID('tempdb..#tt') IS NOT NULL then 'true' else 'false' end) result;
go
select (case when OBJECT_ID('tempdb..#tt2') IS NULL then 'true' else 'false' end) result;
go
drop table #tt;
go
