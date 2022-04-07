CREATE DATABASE db1
GO
USE db1
GO
CREATE LOGIN johndoe with password='Babel123'
GO
CREATE USER johndoe
GO
CREATE TABLE t(a int, b int)
GO

-- Grant select and check table
GRANT SELECT(a) on t to johndoe
GO

-- test sp_column_privileges
EXEC sp_column_privileges 't'
GO
-- test sp_table_privileges
EXEC sp_table_privileges 't'
GO

-- cleanup
DROP TABLE t
GO
USE master
GO
DROP DATABASE db1
GO
DROP LOGIN johndoe
GO
