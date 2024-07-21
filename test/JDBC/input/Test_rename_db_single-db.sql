-- Basic rename db testing for single-db
Create database rename_db_database1;
go
use rename_db_database1
go
Create role rename_db_role1;
go
Create schema rename_db_schema1;
go
use master
go
Create login rename_db_login1 with password = '1234', default_database = rename_db_database1;
go

-- sanity checks for metadata stored in babelfish catalog
select owner, name from sys.babelfish_sysdatabases where name LIKE 'rename_db_database%';
select nspname, orig_name from sys.babelfish_namespace_ext where nspname IN ('rename_db_database1_dbo', 'rename_db_database1_guest', 'rename_db_database1_rename_db_schema1');
select rolname, login_name, orig_username, database_name from sys.babelfish_authid_user_ext where database_name LIKE 'rename_db_database%';
select rolname, default_database_name from sys.babelfish_authid_login_ext where default_database_name LIKE 'rename_db_database%';
go

-- Test Alter Database
alter database rename_db_database1 modify name = rename_db_database2;
go

-- sanity check
use rename_db_database1;
go
use rename_db_database2;
go
use master;
go

-- should return updated rows
select owner, name from sys.babelfish_sysdatabases where name LIKE 'rename_db_database%';
select nspname, orig_name from sys.babelfish_namespace_ext where nspname IN ('rename_db_database2_dbo', 'rename_db_database2_guest', 'rename_db_database2_rename_db_schema1');
select rolname, login_name, orig_username, database_name from sys.babelfish_authid_user_ext where database_name LIKE 'rename_db_database%';
select rolname, default_database_name from sys.babelfish_authid_login_ext where default_database_name LIKE 'rename_db_database%';
go

-- Test sp_renamedb
exec sp_renamedb 'rename_db_database2', 'rename_db_database1';
go

-- sanity check
use rename_db_database1;
go
use rename_db_database2;
go
use master;
go

-- should return updated rows
select owner, name from sys.babelfish_sysdatabases where name LIKE 'rename_db_database%';
select nspname, orig_name from sys.babelfish_namespace_ext where nspname IN ('rename_db_database1_dbo', 'rename_db_database1_guest', 'rename_db_database1_rename_db_schema1');
select rolname, login_name, orig_username, database_name from sys.babelfish_authid_user_ext where database_name LIKE 'rename_db_database%';
select rolname, default_database_name from sys.babelfish_authid_login_ext where default_database_name LIKE 'rename_db_database%';
go

-- Test sp_rename
exec sp_rename 'rename_db_database1', 'rename_db_database2', 'Database';
go

-- sanity check
use rename_db_database1;
go
use rename_db_database2;
go
use master;
go

-- should return updated rows
select owner, name from sys.babelfish_sysdatabases where name LIKE 'rename_db_database%';
select nspname, orig_name from sys.babelfish_namespace_ext where nspname IN ('rename_db_database2_dbo', 'rename_db_database2_guest', 'rename_db_database2_rename_db_schema1');
select rolname, login_name, orig_username, database_name from sys.babelfish_authid_user_ext where database_name LIKE 'rename_db_database%';
select rolname, default_database_name from sys.babelfish_authid_login_ext where default_database_name LIKE 'rename_db_database%';
go

-- cleanup
Use rename_db_database2
go
Drop role rename_db_role1;
go
Drop schema rename_db_schema1;
go
use master
go
Drop database rename_db_database2
go
Drop Login rename_db_login1;
go
