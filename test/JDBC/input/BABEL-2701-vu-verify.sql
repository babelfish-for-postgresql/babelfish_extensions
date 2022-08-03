select t.relname from pg_class t inner join pg_namespace s on s.oid = t.relnamespace where t.relpersistence in ('p', 'u', 't') and t.relkind = 'r' and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER') and s.nspname not in ('information_schema', 'pg_catalog');
go

select object_name(object_id) from sys.objects where name = 'babel_2701_vu_prepare_t1';
GO
