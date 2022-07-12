USE db1_sys_views
GO

SELECT COUNT(*) FROM sys.views WHERE name = 'rand_name1_sys_views';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='V' and name = 'rand_name1_sys_views';
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type='V' and name = 'rand_name1_sys_views';
GO

USE master;
GO

#view rand_name1_sys_views should not be visible in master database.
SELECT COUNT(*) FROM sys.views WHERE name = 'rand_name1_sys_views';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='V' and name = 'rand_name1_sys_views';
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type='V' and name = 'rand_name1_sys_views';
GO

SELECT COUNT(*) FROM sys.views WHERE name = 'rand_name2_sys_views';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='V' and name = 'rand_name2_sys_views';
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type='V' and name = 'rand_name2_sys_views';
GO

USE db1_sys_views
GO

#view rand_name2_sys_views should not be visible in db1_sys_views database.
SELECT COUNT(*) FROM sys.views WHERE name = 'rand_name2_sys_views';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='V' and name = 'rand_name2_sys_views';
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type='V' and name = 'rand_name2_sys_views';
GO
