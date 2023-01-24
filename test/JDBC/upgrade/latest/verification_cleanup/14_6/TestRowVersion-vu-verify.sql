-- Throws error
SELECT @@DBTS;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

-- Test casting functions
-- (var)binary <-> rowversion
SELECT CAST(CAST(0xfe AS binary(8)) AS rowversion),
       CAST(CAST(0xfe AS varbinary(8)) AS rowversion),
       CAST(CAST(0xfe AS rowversion) AS binary(8)),
       CAST(CAST(0xfe AS rowversion) AS varbinary(8));
GO

-- varchar -> rowversion
SELECT CAST(CAST('abc' AS varchar) AS rowversion),
       CAST(CAST('abc' AS char(3)) AS rowversion);
GO

-- int <-> rowversion
SELECT CAST(CAST(20 AS tinyint) AS rowversion),
       CAST(CAST(20 AS smallint) AS rowversion),
       CAST(CAST(20 AS int) AS rowversion),
       CAST(CAST(20 AS bigint) AS rowversion),
       CAST(CAST(20 AS rowversion) AS tinyint),
       CAST(CAST(20 AS rowversion) AS smallint),
       CAST(CAST(20 AS rowversion) AS int),
       CAST(CAST(20 AS rowversion) AS bigint);
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

-- Verify that rowversion column value is not null
select IIF(rv = NULL, 'null', 'not-null') from testrowversion_t1;
go

-- Test with CTE
with mycte (a, b)
as (select testrowversion_t1.* from testrowversion_t1)
select case when x.b = y.rv then 'equal' else 'not-equal' end
				from mycte x inner join testrowversion_t1 y on x.a = y.id;
go

-- Test view
select case when x.rv = y.rv then 'equal' else 'not-equal' end
				from testrowversion_v1 x inner join testrowversion_t1 y on x.id = y.id;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

-- Test with tvf
select case when f.rv = t.rv then 'equal' else 'not-equal' end
                from testrowversion_tvf1(1) f inner join testrowversion_t1 t on f.id = t.id;
go

-- Updating a rowversion column is not allowed
update testrowversion_t1 set rv = 2 where id = 1;
go

-- Updating a row should result in a new value for the rowversion column
declare @prev_rv rowversion;
select @prev_rv = rv from testrowversion_t1 where id = 2;
update testrowversion_t1 set id = 3 where id = 2;
select case when rv > @prev_rv then 'ok' else 'not-ok' end from testrowversion_t1 where id = 3;
go

-- Test SELECT-INTO
select * into testrowversion_t2 from testrowversion_t1;
go
select case when x.rv = y.rv then 'equal' else 'not-equal' end
                from testrowversion_t1 x inner join testrowversion_t2 y on x.id = y.id;
go

-- SELECT INTO should not result in multiple rowversion columns in new table
select * into testrowversion_t3 from testrowversion_t1, testrowversion_t2;
go

-- Can't add default constraint on rowversion column.
alter table testrowversion_t11 add constraint df DEFAULT 2 for rv;
go

-- Changing type of a column to rowversion should not be allowed
alter table testrowversion_t13 alter column id rowversion;
go

-- Changing type of a rowversion column is not allowed
alter table testrowversion_t13 alter column rv int;
go

-- Test dbts
declare @last_dbts rowversion, @cur_dbts rowversion;
set @last_dbts = @@dbts;
insert into testrowversion_t14(id) values(1);
set @cur_dbts = @@dbts;
select case when (rv >= @last_dbts) and (@cur_dbts > rv) then 'ok'
                else 'not-ok' end from testrowversion_t14 where id = 1;
go

select case when dbts_after_insert > prev_dbts then 'increasing' else 'not increasing' end
    from (select dbts_after_insert, lag(dbts_after_insert) over (order by c1) as prev_dbts from babel_3139_t) t
    where prev_dbts is not null;
go


EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go
