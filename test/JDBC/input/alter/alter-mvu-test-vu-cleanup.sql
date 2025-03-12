use master;
go

SELECT funcname, nspname FROM sys.babelfish_function_ext WHERE funcname LIKE 'alter_func_mvu%' and nspname = 'alter_func_db_dbo' order by funcname;
go

SELECT funcname, nspname FROM sys.babelfish_function_ext WHERE funcname LIKE 'alter_proc%' and nspname = 'alter_proc_db_dbo' order by funcname;
go

drop database alter_proc_db
go

drop database alter_func_db
go

SELECT funcname, nspname FROM sys.babelfish_function_ext WHERE funcname LIKE 'alter_func_mvu%' and nspname = 'alter_func_db_dbo'
go

SELECT funcname, nspname FROM sys.babelfish_function_ext WHERE funcname LIKE 'alter_proc%' and nspname = 'alter_proc_db_dbo'
go

-- psql currentSchema=master_dbo,public
select * from pg_depend where refobjid = (select oid from pg_namespace where nspname = 'alter_func_db_dbo');
go

select * from pg_depend where refobjid = (select oid from pg_namespace where nspname = 'alter_proc_db_dbo');
go
