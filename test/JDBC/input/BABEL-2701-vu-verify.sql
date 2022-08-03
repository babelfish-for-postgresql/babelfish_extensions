select schema_name(t.relnamespace), b.nspname from pg_class t inner join sys.schemas sch on t.relnamespace = sch.schema_id inner join sys.babelfish_namespace_ext b on sch.name=b.orig_name where t.relname = 'babel_2701_vu_prepare_t1';
go

select object_name(object_id) from sys.objects where name = 'babel_2701_vu_prepare_t1';
GO
