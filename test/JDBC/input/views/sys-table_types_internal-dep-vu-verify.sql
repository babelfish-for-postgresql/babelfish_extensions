
EXEC sys_table_types_internal_test_dep_proc 'TT_table_types_internal_dep_test1%'
GO

EXEC sys_table_types_internal_test_dep_proc 'TT_table_types_internal_dep_test2%'
GO

EXEC sys_table_types_internal_test_dep_proc 'TT_table_types_internal_dep_test_non_existent%'
GO

SELECT table_type_count FROM sys_table_types_internal_test_dep_view
GO

SELECT * FROM sys_table_types_internal_test_dep_view
GO

SELECT sys_table_types_internal_test_dep_func()
GO

SELECT * FROM sys_table_types_internal_test_dep_func()
GO
