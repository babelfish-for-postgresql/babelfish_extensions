select cast(name as varchar(20)) 
		, max_length
		, precision
		, scale
		, cast(collation_name as varchar(30)) 
from sys.types where is_user_defined = 0 order by name asc;
GO

USE db1_sys_types
GO

select cast(name as varchar(20)) 
		, max_length
		, precision
		, scale
		, cast(collation_name as varchar(30)) 
from sys.types where is_user_defined = 1 order by name asc;
GO

SELECT count(*) FROM sys.types WHERE name = 'my_type';
GO


SELECT count(*) FROM sys.types WHERE name = 'tbl_type_sys_types';
GO

USE master;
GO

-- my_type should not be visible here
SELECT count(*) FROM sys.types WHERE name = 'my_type';
GO

SELECT count(*) FROM sys.types WHERE name = 'my_type1';
GO

SELECT count(*) FROM sys.types WHERE name = 'tbl_type_sys_types';
GO

SELECT count(*) FROM sys.types WHERE name = 'tbl_type_sys_types1';
GO

USE db1_sys_types
GO

SELECT count(*) FROM sys.types WHERE name = 'my_type1';
GO

SELECT count(*) FROM sys.types WHERE name = 'tbl_type_sys_types1';
GO