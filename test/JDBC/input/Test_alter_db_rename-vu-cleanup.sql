Use rename_db_database1
go
Drop User rename_db_login2;
go
Drop login rename_db_login2;
go
Drop role rename_db_role1;
go
Drop schema rename_db_schema1;
go
use master
go
Drop database rename_db_database1;
go
Drop login rename_db_login1;
go
Drop database [ThisNewDatabaseNameIsCaseSensitiveAndIsLongerThan64DigitsToTestRenameDb];
go