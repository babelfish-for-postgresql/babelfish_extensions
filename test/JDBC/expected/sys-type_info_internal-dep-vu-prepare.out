CREATE PROCEDURE sys_type_info_internal_test_dep_proc 
AS
    SELECT count(pg_type_name) as num_pg_types, count(tsql_type_name) as num_tsql_types
    FROM sys.type_info_internal
GO

CREATE VIEW sys_type_info_internal_test_dep_view
AS
    SELECT count(pg_type_name) as num_pg_types, count(tsql_type_name) as num_tsql_types
    FROM sys.type_info_internal
GO

CREATE FUNCTION sys_type_info_internal_test_dep_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT count(pg_type_name) + count(tsql_type_name)
    FROM sys.type_info_internal)
END
GO

