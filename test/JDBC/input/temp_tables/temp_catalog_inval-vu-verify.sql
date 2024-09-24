-- Catalog entries for temp tables are not visible from places like `pg_class` or `information_schema.tables`
-- So the best way to check whether the cache entries have been updated locally properly is to just ensure that
-- it's visible in typical use. 

-- pg_class, pg_type, pg_attribute
CREATE TABLE #t1(a int)
go

insert into #t1 values (1)
go

select * from #t1
go

drop table #t1
go

select * from #t1
go

-- constraint, depend, index, sequence, attrdefault

create table #t2(a int identity primary key, b int default 0)
go

alter table #t2 add c int
go

ALTER TABLE #t2 ALTER COLUMN a bigint
go

alter table #t2 alter column b bigint
go

insert into #t2(c) values (2)
go

insert into #t2(c) values (4)
go

insert into #t2(b, c) values (3, 2)
go

select * from #t2
go

drop table #t2
go

select * from #t2
go
