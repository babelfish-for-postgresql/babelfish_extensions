CREATE DATABASE sys_views_vu_prepare_db1;
GO

USE sys_views_vu_prepare_db1
GO

CREATE VIEW sys_views_vu_prepare_t1 AS select 1;
GO

USE master;
GO

CREATE VIEW sys_views_vu_prepare_t2 AS select 1;
GO