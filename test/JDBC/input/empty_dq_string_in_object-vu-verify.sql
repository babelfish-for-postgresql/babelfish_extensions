-- Purpose: a double-quoted empty string inside a SQL object body should be treated as an empty string

set quoted_identifier off
go

-- SELECT ""
select "" as empty_str
go
create procedure p1_empty_dq_string
as
select "" as empty_str
go
exec p1_empty_dq_string
go
create function f1_empty_dq_string() returns varchar(10)
as
begin
return ""
end
go
select dbo.f1_empty_dq_string(), len(dbo.f1_empty_dq_string())
go
create trigger tr1_empty_dq_string on t1_empty_dq_string for insert as
begin
select "" as empty_str
end
go
insert t1_empty_dq_string values(1)
go

-- variable declaration and assignment
declare @v varchar(10) = ""
set @v = ""
select @v
go
create procedure p2_empty_dq_string
as
declare @v varchar(10) = ""
set @v = ""
select @v
go
exec p2_empty_dq_string
go
create function f2_empty_dq_string() returns varchar(10)
as
begin
declare @v varchar(10) = ""
set @v = ""
return @v
end
go
select dbo.f2_empty_dq_string(), len(dbo.f2_empty_dq_string())
go
create trigger tr2_empty_dq_string on t2_empty_dq_string for insert as
begin
declare @v varchar(10) = ""
set @v = ""
select @v
end
go
insert t2_empty_dq_string values(1)
go

-- print "" (not visible in JDBC test output)
print ""
go
create procedure p3_empty_dq_string
as
print ""
go
exec p3_empty_dq_string
go
create trigger tr3_empty_dq_string on t3_empty_dq_string for insert as
begin
select 'trigger'
print ""
end
go
insert t3_empty_dq_string values(1)
go

-- usage in condition
if 'a' = "" select 'branch 1' else select 'branch 2'
go
create procedure p4_empty_dq_string as
if 'a' = "" select 'branch 1' else select 'branch 2'
go
exec p4_empty_dq_string
go
create function f4_empty_dq_string() returns int
as
begin
if 'a' = "" return 1 
return 2
end
go
select dbo.f4_empty_dq_string()
go
create trigger tr4_empty_dq_string on t4_empty_dq_string for insert as
begin
if 'a' = "" select 'branch 1' else select 'branch 2'
end
go
insert t4_empty_dq_string values(1)
go

-- usage in WHERE_clause
select * from t5_empty_dq_string where b = "" order by a
go
create procedure p5_empty_dq_string as
select a, '['+b+']' as b from t5_empty_dq_string where b = "" order by a
go
exec p5_empty_dq_string
go
create function f5_empty_dq_string() returns int
as
begin
declare @v int
select @v = count(*) from t5_empty_dq_string where b = "" 
return @v
end
go
select dbo.f5_empty_dq_string()
go
create trigger tr5_empty_dq_string on t5_empty_dq_string for insert as
begin
select a, '['+b+']' as b from t5_empty_dq_string where b = "" order by a
end
go
insert t5_empty_dq_string values(1, 'test 1')
go

-- usage in insert
insert t6_empty_dq_string values (2, "")
go
create procedure p6_empty_dq_string as
insert t6_empty_dq_string values (3, "")
go
exec p6_empty_dq_string
go
select a, '['+b+']' as b from t6_empty_dq_string order by a
go
create trigger tr6_empty_dq_string on t6_empty_dq_string for insert as
begin
insert t6_empty_dq_string values (4, "")
end
go
insert t6_empty_dq_string values(1, 'test 1')
go
select a, '['+b+']' as b from t6_empty_dq_string order by a
go

-- usage in update
update t7_empty_dq_string set b = "" where a = 1
go
create procedure p7_empty_dq_string as
update t7_empty_dq_string set b = "" where a = 1
go
exec p7_empty_dq_string
go
select a, '['+b+']' as b from t7_empty_dq_string order by a
go
create trigger tr7_empty_dq_string on t7_empty_dq_string for insert as
begin
update t7_empty_dq_string set b = "" where a = 1
end
go
insert t7_empty_dq_string values(2, 'test 2')
go
select a, '['+b+']' as b from t7_empty_dq_string order by a
go

-- single-space string in update
create procedure p7a_empty_dq_string as
update t7_empty_dq_string set b = " " where a = 1
go
exec p7a_empty_dq_string
go
select a, '['+b+']' as b from t7_empty_dq_string order by a
go
create trigger tr7a_empty_dq_string on t7_empty_dq_string for insert as
begin
update t7_empty_dq_string set b = " " where a = 1
end
go
insert t7_empty_dq_string values(3, 'test 3')
go
select a, '['+b+']' as b from t7_empty_dq_string order by a
go
