create table ccol(a varchar(20), b as substring(a,1,3))
go
insert into ccol values('hello');
go
select * from ccol;
go

select substring('hello',1,3)
go
select substring(cast('hello' as sys.varchar(5)),1,3)
go
select substring(cast('hello' as sys.char(5)),1,3)
go
select substring(cast('hello' as sys.nvarchar(5)),1,3)
go
select substring(cast('hello' as sys.nchar(5)),1,3)
go
select substring('hello',0, 3)
go
select substring('hello',1, 0)
go
select substring('hello',100, 3)
go
select substring('hello',-1, 3)
go
select substring('hello',-10, 3)
go
select substring('hello',-4, 7)
go
select substring('hello', 1, 100)
go
select substring('ÀÈǸẀ', 1, 3);
go
select substring('Ææ', 1, 4);
go
select substring('hello', null, 3)
go
select substring('hello', 2, null)
go

-- should error
select substring('hello',1, -3)
go
select substring(null, 1, 3)
go


-- cleanup
drop table ccol;
go