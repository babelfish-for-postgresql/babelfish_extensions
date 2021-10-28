USE master;
GO

-- test volatility of functions in multi-row insert
-- newsequentialid()
CREATE TABLE myTable (ColumnA uniqueidentifier DEFAULT NEWSEQUENTIALID(), a int);
go
insert myTable (a) values (1), (2)
go
-- should be equal to 2
select count(distinct a) from myTable
go

-- newid()
CREATE TABLE t1_2011 (a int);
CREATE TABLE myTable2 (ColumnA uniqueidentifier, a int);
go
insert t1_2011 (a) values (1), (2)
go
insert myTable2 select newid(), a from t1_2011
go
-- should be equal to 2
select count(distinct a) from myTable2
go

drop table myTable2;
drop table myTable;
drop table t1_2011;
go