CREATE SCHEMA obj_funcs;
GO

CREATE TABLE obj_funcs.t1(id INT, c1 NVARCHAR);
GO

SELECT (CASE WHEN OBJECT_NAME(OBJECT_ID(N't1 ', N'U')) = 't1' THEN 'true' ELSE 'false' END) result;
GO

SELECT (CASE WHEN OBJECT_NAME(OBJECT_ID(N'  t1', N'U')) = 't1' THEN 'true' ELSE 'false' END) result;
GO

SELECT (CASE WHEN OBJECT_NAME(OBJECT_ID(N'  t1  ')) = 't1' THEN 'true' ELSE 'false' END) result;
GO

SELECT (CASE WHEN OBJECT_NAME(OBJECT_ID(N' [t1] ', N'U')) = 't1' THEN 'true' ELSE 'false' END) result;
GO

SELECT (CASE WHEN OBJECT_NAME(OBJECT_ID(N'   [obj_funcs].[t1]  ', N'U')) = 't1' THEN 'true' ELSE 'false' END) result;
GO

DROP TABLE obj_funcs.t1;
GO
DROP SCHEMA obj_funcs;
GO
