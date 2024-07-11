CREATE DATABASE test_db_collation COLLATE bbf_unicode_cp1_ci_ai;
GO
USE test_db_collation;
GO
SELECT name, collation_name from sys.databases where name = db_name();
GO
GRANT CONNECT TO GUEST;
GO
