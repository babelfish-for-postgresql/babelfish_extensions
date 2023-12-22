-- parallel_query_expected
use master;
go
select set_config('babelfishpg_tsql.explain_timing', 'off', false);
go
select set_config('babelfishpg_tsql.explain_summary', 'off', false);
go

set babelfish_statistics profile On;
go
create table babel_2843_t1 (a1 int, b1 int);
go
create table babel_2843_t2 (a2 int, b2 int);
go

-- single statement
select 1;
go
select * from babel_2843_t1 where b1 = 1;
go

-- XML
select set_config('babelfishpg_tsql.explain_format', 'xml', false);
go
select * from babel_2843_t1 where b1 = 1;
go

-- JSON
select set_config('babelfishpg_tsql.explain_format', 'json', false);
go
select * from babel_2843_t1 where b1 = 1;
go

-- YAML
select set_config('babelfishpg_tsql.explain_format', 'yaml', false);
go
select * from babel_2843_t1 where b1 = 1;
go

select set_config('babelfishpg_tsql.explain_format', 'text', false);
go

-- multiple statements
insert babel_2843_t1 values (1, 1);
insert babel_2843_t1 values (2, 2);
insert into babel_2843_t2 select * from babel_2843_t1 where a1 = 1;
select * from babel_2843_t1;
select * from babel_2843_t2;
go

-- procedure
create procedure babel_2843_proc @param int
as
    insert babel_2843_t1 values (3, 3);
    select * from babel_2843_t1 where a1 = @param;
go
execute babel_2843_proc 1;
go
drop procedure babel_2843_proc;
go

-- ITVF (Inline Table-Valued Function)
create function babel_2843_itvf(@param int)
returns table
    as return (
        select * from babel_2843_t1 where a1 = @param
    );
go
select * from babel_2843_itvf(2);
go
drop function babel_2843_itvf;
go

-- MSTVF (Multi-Statement Table-Valued Function)
create function babel_2843_mstvf(@param int)
returns @tab table (a int, b int)
as begin
    insert into @tab select * from babel_2843_t1 where a1 = @param;
    insert into @tab select * from babel_2843_t2 where a2 = @param;
    return;
end;
go
select * from babel_2843_mstvf(1);
go
drop function babel_2843_mstvf;
go

-- Control structure
declare @val int = (select a1 from babel_2843_t1 where b1 = 1);
if @val = 1
    select 1
else
    select 2
;
go

-- execsql
DECLARE @val INT;
DECLARE @sql NVARCHAR(500);
DECLARE @paramdef NVARCHAR(500);
SET @sql = N'select * from babel_2843_t1 where a1 = @param';
SET @paramdef = N'@param int';
SET @val = 2;
EXECUTE sp_executesql @sql, @paramdef,
        @param = @val;
go

drop table babel_2843_t1;
go
drop table babel_2843_t2;
go
set babelfish_statistics profile oFf;
go

select set_config('babelfishpg_tsql.explain_timing', 'on', false);
go
select set_config('babelfishpg_tsql.explain_summary', 'on', false);
go
