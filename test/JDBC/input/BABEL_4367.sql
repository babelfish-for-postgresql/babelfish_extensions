CREATE TABLE table_name_1 (
    id INT
)
GO

DROP TABLE table_name_1, table_name_2
GO

DROP TABLE table_name_1
SELECT name FROM sys.tables
GO

CREATE TABLE table_name_1 (
    id INT
)
GO

DROP TABLE IF EXISTS table_name_1, table_name_2
GO
SELECT name FROM sys.tables
GO

CREATE TABLE table_name_1 (
    id INT
)
GO

DROP TABLE IF EXISTS table_name_2, table_name_1
GO
SELECT name FROM sys.tables
GO
