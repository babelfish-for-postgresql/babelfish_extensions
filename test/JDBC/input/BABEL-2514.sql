USE master;
go

select 'value' = '1';
go

drop view if exists babel_2514_view;
go
create view babel_2514_view as (
	select (select 'value' = '1')
);
go
select * from babel_2514_view;
go
drop view if exists babel_2514_view;
go

drop function if exists babel_2514_func;
go
create function babel_2514_func()
	returns table as return 
	(
		select * from (select 'value' = '1') col1
	)
go
select babel_2514_func();
go
drop function if exists babel_2514_func;
go

DECLARE babel_2514_cursor CURSOR FOR select * from (select 'value' = '1') col1;
OPEN babel_2514_cursor
FETCH NEXT FROM babel_2514_cursor;
close babel_2514_cursor;
deallocate babel_2514_cursor;
go

declare @babel_2514_cursor cursor
set @babel_2514_cursor = CURSOR FOR select * from (select 'value' = '1') col1;
open @babel_2514_cursor;
fetch next from @babel_2514_cursor;
go

select (select 'value' = '1');
go

select * from (select 'value' = '1') a;
go

WITH babel_2514_cte (a) AS
(
	select 'value' = '1'
)
SELECT * from babel_2514_cte;
go

WITH XMLNAMESPACES ('uri' as ns1)
SELECT 'value' = '1'
go

declare @string1 nvarchar(5);
SELECT 'v' = @String1;
go

drop function if exists babel_2514_func_local_id_1;
go
create function babel_2514_func_local_id_1(@String NVARCHAR(4000))
returns table as return
(
	SELECT @string
);
go
select babel_2514_func_local_id_1('abc');
go
drop function if exists babel_2514_func_local_id_1;
go

drop function if exists babel_2514_func_local_id_2;
go
create function babel_2514_func_local_id_2(@String NVARCHAR(4000))
returns table as return
(
	SELECT 'value' = @String
);
go
select babel_2514_func_local_id_2('abc def');
go
drop function if exists babel_2514_func_local_id_2;
go

drop function if exists babel_2514_complex_func;
go
CREATE FUNCTION babel_2514_complex_func
(
	@String NVARCHAR(4000),
	@Delimiter NCHAR(1)
)
RETURNS TABLE
AS
RETURN
(
	WITH Split(stpos, endpos) AS
	(
		SELECT 0 AS stpos, CHARINDEX(@Delimiter,@String) AS endpos
		UNION ALL
		SELECT endpos+1, CHARINDEX(@Delimiter,@String,endpos+1)
		FROM Split
		WHERE endpos > 0
	)
	SELECT 'Value' = SUBSTRING(@String, stpos, COALESCE(NULLIF(endpos, 0), LEN(@String) + 1) - stpos)
	FROM Split
);
go
select babel_2514_complex_func('abc def', ' ');
go
drop function if exists babel_2514_complex_func;
go

drop view if exists babel_2514_complex_view;
go
create view babel_2514_complex_view as (
	select (select a = 1) col1, * from (select b = 2 union all select b = 3) t
);
go
select * from babel_2514_complex_view;
go
drop view if exists babel_2514_complex_view;
go