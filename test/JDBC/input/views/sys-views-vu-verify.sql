USE sys_views_vu_prepare_db1
GO

SELECT COUNT(*) FROM sys.views WHERE name = 'sys_views_vu_prepare_t1';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='V' and name = 'sys_views_vu_prepare_t1';
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type='V' and name = 'sys_views_vu_prepare_t1';
GO

USE master;
GO

#view sys_views_vu_prepare_t1 should not be visible in master database.
SELECT COUNT(*) FROM sys.views WHERE name = 'sys_views_vu_prepare_t1';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='V' and name = 'sys_views_vu_prepare_t1';
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type='V' and name = 'sys_views_vu_prepare_t1';
GO

SELECT COUNT(*) FROM sys.views WHERE name = 'sys_views_vu_prepare_t2';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='V' and name = 'sys_views_vu_prepare_t2';
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type='V' and name = 'sys_views_vu_prepare_t2';
GO

USE sys_views_vu_prepare_db1
GO

#view sys_views_vu_prepare_t2 should not be visible in sys_views_vu_prepare_db1 database.
SELECT COUNT(*) FROM sys.views WHERE name = 'sys_views_vu_prepare_t2';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='V' and name = 'sys_views_vu_prepare_t2';
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type='V' and name = 'sys_views_vu_prepare_t2';
GO
