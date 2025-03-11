use master;
go

drop database alter_proc_db
go

drop database alter_func_db
go

SELECT funcname, nspname FROM sys.babelfish_function_ext WHERE funcname LIKE 'alter_func_mvu%'
go

SELECT funcname, nspname FROM sys.babelfish_function_ext WHERE funcname LIKE 'alter_proc%'
go