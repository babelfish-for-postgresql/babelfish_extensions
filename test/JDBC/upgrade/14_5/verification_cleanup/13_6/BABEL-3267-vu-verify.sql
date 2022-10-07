USE db_babel_3267;
go

select * from [T3267#];
go

select * from [T3267 a];
go

select * from [T3267'b];
go

select * from [T3267\c];
go

select * from [T3267"d];
go

select * from [T3267\schema].[T3267.[CustomTable];
go

-- select only bbf_original_rel_name from reloptions
with all_options as (
	select relname as name, unnest(reloptions) opt from pg_class where relname like 't3267%'
	),
bbf_orig_names as (
	select name, case when opt like 'bbf_original_rel_name=%%' then opt else NULL end as orig_name from all_options
	)
select c.relname, string_agg(b.orig_name, ',') from pg_class c left join bbf_orig_names b on c.relname = b.name
where c.relname like 't3267%' group by c.relname order by c.relname;
go

USE master;
go

DROP DATABASE db_babel_3267;
go
