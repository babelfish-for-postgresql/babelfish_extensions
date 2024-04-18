Create database rename_db_database1;
go
use rename_db_database1
go
Create role rename_db_role1;
go
Create schema rename_db_schema1;
go
Create login rename_db_login1 with password = '1234', default_database = rename_db_database1;
go
Create database [ThisOldDatabaseNameIsCaseSensitiveAndIsLongerThan64DigitsToTestRenameDb];
go
Create login rename_db_login2 with password = '1234';
go
Use rename_db_database1
go
Create User rename_db_login2;
go