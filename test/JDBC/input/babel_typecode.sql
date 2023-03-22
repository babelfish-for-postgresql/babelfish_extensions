DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

-- test typecode list sys table
SELECT pg_namespace, pg_typname, tsql_typname, type_family_priority, priority, sql_variant_hdr_size FROM sys.babelfish_typecode_list();
GO