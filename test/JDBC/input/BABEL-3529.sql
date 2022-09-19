create table t07y (y int, b int)
go
insert into t07y values (10, 1), (20, 1), (30,2), (40,2)
go
SELECT y FROM t07y FOR XML PATH ('')
go
SELECT y FROM t07y FOR XML PATH ('row')
go
drop table t07y
go
