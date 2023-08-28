select name from sys.types where system_type_id = 
(
  select system_type_id from sys.columns where 
    name = 'my_computed_column' and 
	object_id = 
	(
	  select object_id from sys.tables where name = 'test_isnull_table'
	)
) and is_user_defined = 0;
GO

select * from [dbo].[test_isnull_table]
GO

select
  ISNULL(NULL, NULL),
  ISNULL(NULL, 'Unassigned'),
  ISNULL([my_varchar_data], 'Unassigned'),
  ISNULL('Unassigned', 1),
  ISNULL ('', 5)
from [dbo].[test_isnull_table];
GO

select * from [dbo].[test_isnull_view];
GO

select * from [dbo].[test_isnull_view1];
GO

select * from [dbo].[test_isnull_view2];
GO

select * from [dbo].[test_isnull_view3];
GO

select * from [dbo].[test_isnull_view4];
GO

select * from [dbo].[test_isnull_view5];
GO

select * from [dbo].[test_isnull_view6];
GO

select * from [dbo].[test_isnull_view7];
GO

select name from sys.types where system_type_id = 
(
  select system_type_id from sys.columns where 
	object_id = 
	(
	  select object_id from sys.views where name = 'test_isnull_view3'
	)
) and is_user_defined = 0;
GO

select name from sys.types where system_type_id = 
(
  select system_type_id from sys.columns where 
	object_id = 
	(
	  select object_id from sys.views where name = 'test_isnull_view4'
	)
) and is_user_defined = 0;
GO

select name from sys.types where system_type_id = 
(
  select system_type_id from sys.columns where 
	object_id = 
	(
	  select object_id from sys.views where name = 'test_isnull_view5'
	)
) and is_user_defined = 0;
GO

select name from sys.types where system_type_id = 
(
  select system_type_id from sys.columns where 
	object_id = 
	(
	  select object_id from sys.views where name = 'test_isnull_view6'
	)
) and is_user_defined = 0;
GO

select name from sys.types where system_type_id = 
(
  select system_type_id from sys.columns where 
	object_id = 
	(
	  select object_id from sys.views where name = 'test_isnull_view7'
	)
) and is_user_defined = 0;
GO

select [dbo].[test_isnull_func1]();
GO

select [dbo].[test_isnull_func2]('1', 1);
GO

exec [dbo].[test_isnull_proc1];
GO