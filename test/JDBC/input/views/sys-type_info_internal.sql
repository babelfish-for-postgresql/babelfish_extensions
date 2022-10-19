-- Simple test to make sure to catch any changes to the sys.type_info_internal view.
-- If the changes are intentional the expected result of this test should be modified.

SELECT pg_type_name, tsql_type_name
FROM sys.type_info_internal;

GO
