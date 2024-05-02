Create database sp_renamedb_database1;
go
use sp_renamedb_database1
go
Create role sp_renamedb_role1;
go
Create schema sp_renamedb_schema1;
go
Create login sp_renamedb_login1 with password = '1234', default_database = sp_renamedb_database1;
go
Create database [sp_renamedb_ThisOldDatabaseNameIsCaseSensitiveAndIsLongerThan64DigitsToTestRenameDb];
go
Create login sp_renamedb_login2 with password = '1234';
go
Use sp_renamedb_database1
go
Create User sp_renamedb_login2;
go