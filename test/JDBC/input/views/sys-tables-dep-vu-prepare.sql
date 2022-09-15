CREATE DATABASE sys_tables_dep_vu_prepare_db1
GO

USE sys_tables_dep_vu_prepare_db1
GO

CREATE TABLE sys_tables_dep_vu_prepare_t1(rand_col1 int DEFAULT 1, CHECK (rand_col1 > 0));
GO

CREATE PROCEDURE sys_tables_dep_vu_prepare_p1 AS 
    SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'sys_tables_dep_vu_prepare_t1'
GO

CREATE FUNCTION sys_tables_dep_vu_prepare_f1()
RETURNS INT 
AS
BEGIN 
    RETURN (SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'sys_tables_dep_vu_prepare_t1')
END
GO

CREATE VIEW sys_tables_dep_vu_prepare_view1 AS
    SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'sys_tables_dep_vu_prepare_t1'
GO
