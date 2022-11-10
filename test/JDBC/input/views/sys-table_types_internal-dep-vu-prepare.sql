CREATE TYPE table_types_internal_dep_test1 AS TABLE (Id INT, Name VARCHAR(100));
GO

CREATE TYPE table_types_internal_dep_test2 AS TABLE (Id INT, Name VARCHAR(100), floatNum float, someDate date);
GO

CREATE PROCEDURE sys_table_types_internal_test_dep_proc @table_type_name_like VARCHAR(256) 
AS
    SELECT COUNT (typrelid) FROM sys.table_types_internal 
    WHERE typrelid IN (SELECT object_id FROM sys.all_objects WHERE name LIKE @table_type_name_like);
GO


CREATE VIEW sys_table_types_internal_test_dep_view
AS
    SELECT COUNT (typrelid) AS table_type_count
    FROM sys.table_types_internal 
    WHERE typrelid IN 
    (SELECT object_id FROM sys.all_objects WHERE name LIKE 'TT_table_types_internal_dep_test1%' or name LIKE 'TT_table_types_internal_dep_test2%')
GO

CREATE FUNCTION sys_table_types_internal_test_dep_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT (typrelid) AS table_type_count
    FROM sys.table_types_internal 
    WHERE typrelid IN 
    (SELECT object_id FROM sys.all_objects WHERE name LIKE 'TT_table_types_internal_dep_test1%' or name LIKE 'TT_table_types_internal_dep_test2%'))

END
GO
