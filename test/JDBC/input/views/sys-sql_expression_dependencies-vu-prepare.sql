USE master
GO

CREATE VIEW sys_sql_expression_dependencies_vu_prepare_view AS
SELECT * FROM sys.sql_expression_dependencies
GO

CREATE PROC sys_sql_expression_dependencies_vu_prepare_proc AS
SELECT * FROM sys.sql_expression_dependencies
GO

CREATE FUNCTION sys_sql_expression_dependencies_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sql_expression_dependencies WHERE referencing_id= 1)
END
GO
