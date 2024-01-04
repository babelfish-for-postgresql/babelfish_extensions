select cast(name as varchar(20)) 
		, max_length
		, precision
		, scale
		, cast(collation_name as varchar(30)) 
from sys.types where is_user_defined = 0 order by name asc;
GO

CREATE DATABASE db1;
GO

USE db1
GO

CREATE TYPE my_type FROM int;
GO

CREATE TYPE my_type2 FROM varchar(20);
GO

select count(*) from sys.types where collation_name='bbf_unicode_cp1_ci_as';
GO

select count(*) from sys.types where collation_name='BBF_unicode_CP1_ci_as';
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

SELECT count(*) FROM sys.types WHERE name = 'MY_TYPE';
GO

CREATE TYPE tbl_type_sys_types AS TABLE(a INT);
GO

SELECT count(*) FROM sys.types WHERE name = 'tbl_type_sys_types';
GO
SELECT count(*) FROM sys.types WHERE name = 'TBL_type_SYS_types';
GO

USE master;
GO

-- my_type should not be visible here
SELECT count(*) FROM sys.types WHERE name = 'my_type';
GO

CREATE TYPE my_type1 FROM int;
GO

SELECT count(*) FROM sys.types WHERE name = 'my_type1';
GO

SELECT count(*) FROM sys.types WHERE name = 'tbl_type_sys_types';
GO

CREATE TYPE tbl_type_sys_types1 AS TABLE(a INT);
GO

SELECT count(*) FROM sys.types WHERE name = 'tbl_type_sys_types1';
GO

USE db1
GO

SELECT count(*) FROM sys.types WHERE name = 'my_type1';
GO

SELECT count(*) FROM sys.types WHERE name = 'tbl_type_sys_types1';
GO

DROP TYPE my_type;
GO

DROP TYPE my_type2
GO

DROP TYPE tbl_type_sys_types;
GO

USE master;
GO

DROP DATABASE db1;
GO

DROP TYPE my_type1;
GO

DROP TYPE tbl_type_sys_types1;
GO