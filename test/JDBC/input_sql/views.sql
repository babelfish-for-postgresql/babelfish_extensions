EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore', 'server';
go

create view test_view_sysdatabases as select * from sys.sysdatabases;
go

create view test_view_pg_namespace_ext as select * from sys.pg_namespace_ext;
go

create view test_view_schemas as select * from sys.schemas;
go

create view test_view_server_principals as select * from sys.server_principals;
go

create view test_view_database_principals as select * from sys.database_principals;
go

create view test_view_databases as select * from sys.databases;
go

create view test_view_tables as select * from sys.tables;
go

create view test_view_views as select * from sys.views;
go

create view test_view_all_columns as select * from sys.all_columns;
go

create view test_view_all_views as select * from sys.all_views;
go

create view test_view_columns as select * from sys.columns;
go

create view test_view_foreign_key_columns as select * from sys.foreign_key_columns;
go

create view test_view_foreign_keys as select * from sys.foreign_keys;
go

create view test_view_identity_columns as select * from sys.identity_columns;
go

create view test_view_indexes as select * from sys.indexes;
go

create view test_view_key_constraints as select * from sys.key_constraints;
go

create view test_view_procedures as select * from sys.procedures;
go

create view test_view_sql_modules as select * from sys.sql_modules;
go

create view test_view_sysforeignkeys as select * from sys.sysforeignkeys;
go

create view test_view_sysindexes as select * from sys.sysindexes;
go

create view test_view_sysprocesses as select * from sys.sysprocesses;
go

create view test_view_types as select * from sys.types;
go

create view test_view_table_types as select * from sys.table_types;
go

create view test_view_check_constraints as select * from sys.check_constraints;
go

create view test_view_objects as select * from sys.objects;
go

create view test_view_sysobjects as select * from sys.sysobjects;
go

create view test_view_all_objects as select * from sys.all_objects;
go

create view test_view_system_objects as select * from sys.system_objects;
go

create view test_view_syscharsets as select * from sys.syscharsets;
go

create view test_view_default_constraints as select * from sys.default_constraints;
go

create view test_view_computed_columns as select * from sys.computed_columns;
go

create view test_view_endpoints as select * from sys.endpoints;
go

create view test_view_index_columns as select * from sys.index_columns;
go

create view test_view_syscolumns as select * from sys.syscolumns;
go

create view test_view_dm_exec_sessions as select * from sys.dm_exec_sessions;
go

create view test_view_dm_exec_connections as select * from sys.dm_exec_connections;
go

create view test_view_configurations as select * from sys.configurations;
go

create view test_view_syscurconfigs as select * from sys.syscurconfigs;
go

create view test_view_sysconfigures as select * from sys.sysconfigures;
go

create view test_view_sp_columns_100_view as select * from sys.sp_columns_100_view;
go

create view test_view_spt_tablecollations_view as select * from sys.spt_tablecollations_view;
go

create view test_view_spt_columns_view_managed as select * from sys.spt_columns_view_managed;
go

create view test_view_sp_tables_view as select * from sys.sp_tables_view;
go

create view test_view_sp_databases_view as select * from sys.sp_databases_view;
go

create view test_view_sp_pkeys_view as select * from sys.sp_pkeys_view;
go

create view test_view_sp_statistics_view as select * from sys.sp_statistics_view;
go

create view test_view_dm_os_host_info as select * from sys.dm_os_host_info;
go

create view test_view_sp_column_privileges_view as select * from sys.sp_column_privileges_view;
go

create view test_view_sp_table_privileges_view as select * from sys.sp_table_privileges_view;
go

create view test_view_sp_special_columns_view as select * from sys.sp_special_columns_view;
go

create view test_view_sp_fkeys_view as select * from sys.sp_fkeys_view;
go

create view test_view_sp_stored_procedures_view as select * from sys.sp_stored_procedures_view;
go

