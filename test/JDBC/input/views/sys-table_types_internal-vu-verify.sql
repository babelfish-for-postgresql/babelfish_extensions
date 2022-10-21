

SELECT COUNT (typrelid) FROM sys.table_types_internal 
WHERE typrelid IN (SELECT object_id FROM sys.all_objects WHERE name LIKE 'TT_table_types_internal_test1%' );
GO

SELECT COUNT (typrelid) FROM sys.table_types_internal 
WHERE typrelid IN (SELECT object_id FROM sys.all_objects WHERE name LIKE 'TT_table_types_internal_test2%');
GO

SELECT COUNT (typrelid) FROM sys.table_types_internal 
WHERE typrelid IN 
(SELECT object_id FROM sys.all_objects WHERE name LIKE 'TT_table_types_internal_test1%' or name LIKE 'TT_table_types_internal_test2%')
GO

