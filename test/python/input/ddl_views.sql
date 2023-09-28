/* This test files will check for scripting views only */

DROP VIEW IF EXISTS sys_all_views_select_vu_prepare
GO
DROP VIEW IF EXISTS sys_all_views_select_chk_option_vu_prepare
GO
DROP VIEW IF EXISTS sys_all_views_dep_view_vu_prepare 
GO
DROP TABLE IF EXISTS sys_all_views_table_vu_prepare
GO
CREATE TABLE sys_all_views_table_vu_prepare(a int)
GO
CREATE VIEW sys_all_views_select_vu_prepare AS
SELECT * FROM sys_all_views_table_vu_prepare
GO
CREATE VIEW sys_all_views_select_chk_option_vu_prepare AS
SELECT * FROM sys_all_views_table_vu_prepare
WITH CHECK OPTION
GO
CREATE VIEW sys_all_views_dep_view_vu_prepare AS
SELECT name, type, with_check_option FROM sys.all_views where object_id = object_id('sys_all_views_select_vu_prepare')
GO

CREATE LOGIN AbolrousHazem1   
    WITH PASSWORD = '340$Uuxwp7Mcxo7Khy'; 
	
CREATE LOGIN AbolrousHazem2   
    WITH PASSWORD = '340$UuxwpMcxo7Khy';  

CREATE LOGIN AbolrousHazem3   
    WITH PASSWORD = '340$Uuxwp7Mco7Khy'; 
	


CREATE USER AbolrousHazem1 FOR LOGIN AbolrousHazem1;  
GO

CREATE USER AbolrousHaze2m FOR LOGIN AbolrousHazem2;  
GO

CREATE USER AbolrousHazem3 FOR LOGIN AbolrousHazem3;  
GO

--DROP
DROP VIEW IF EXISTS sys_all_views_select_vu_prepare
GO
DROP VIEW IF EXISTS sys_all_views_select_chk_option_vu_prepare
GO
DROP VIEW IF EXISTS sys_all_views_dep_view_vu_prepare 
GO
DROP TABLE IF EXISTS sys_all_views_table_vu_prepare
GO
