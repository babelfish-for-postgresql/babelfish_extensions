-- This test file fails only in case of new implementation of sys.sys% catalog view
-- which was present only in 'sys' schema but not in 'dbo' schema.
-- If observed the SQLServer behaviour these sys.sys% catalog views are present in
-- both 'sys' and 'dbo' schema.
-- To pass this test, follow the steps:
-- 1. Go to function set_schemaname_dbo_to_sys present in (babelfish_extensions/contrib/babelfish_tsql/src/multidb.c)
-- 2. After checking the behaviour, Add the sys% catalog view name to the list present in function
-- 3. Finally remove the sys% view name in the sys.list_of_view_should_be_present_in_dbo_schema(make sure to remove everywhere)
-- 4. Add tests for the dbo.sys%(which should be behaving same as sys.sys%) in the respective test file
CREATE FUNCTION test_list_of_sys_catalog_present_in_dbo()
RETURNS @tab TABLE (name varchar(100))
AS
BEGIN
DECLARE @a varchar(100);
DECLARE cur CURSOR FOR SELECT * FROM sys.list_of_view_should_be_present_in_dbo_schema;
OPEN cur;
WHILE @@FETCH_STATUS = 0
	  BEGIN
			FETCH NEXT FROM cur INTO @a;
            IF OBJECT_ID(('sys.' + @a ), 'V') IS NOT NULL
                INSERT INTO @tab VALUES (cast(@a as varchar(100)));
	  END
CLOSE cur;
DEALLOCATE cur;
END
GO

select * from test_list_of_sys_catalog_present_in_dbo();
go

DROP FUNCTION test_list_of_sys_catalog_present_in_dbo;
GO
