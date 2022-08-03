select * from sys.schemas;
GO

select name, has_schema_privilege(schema_id, 'USAGE') from sys.schemas
GO

select * from sys.tables where name = 'babel_2701_vu_prepare_t1';
GO

select * from pg_class where relname = 'babel_2701_vu_prepare_t1';
GO

select relname, has_table_privilege(oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER') from pg_class where relname = 'babel_2701_vu_prepare_t1';
GO

insert into table babel_2701_vu_prepare_t1 values (1);
GO

select * from babel_2701_vu_prepare_t1;
go

select object_name(object_id) from sys.objects where name = 'babel_2701_vu_prepare_t1';
GO