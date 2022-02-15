CREATE TYPE my_tbl_type AS TABLE(a INT);
GO

CREATE TYPE type_2649 from INT
GO

-- table type should not be shown as 'U' - user defined table
SELECT COUNT(*) FROM sys.objects WHERE name = 'my_tbl_type' AND type = 'U';
GO

SELECT COUNT(*) FROM sys.tables WHERE name = 'my_tbl_type';
GO

SELECT COUNT(*) FROM sys.types WHERE name = 'my_tbl_type' AND is_table_type = 1;
GO

SELECT COUNT(*) FROM sys.types WHERE name = 'type_2649' AND is_table_type = 0;
GO

DROP TYPE type_2649;
GO

DROP TYPE my_tbl_type;
GO
