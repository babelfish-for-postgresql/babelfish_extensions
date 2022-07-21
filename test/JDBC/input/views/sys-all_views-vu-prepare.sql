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

CREATE PROC sys_all_views_dep_proc_vu_prepare AS
SELECT name, type, with_check_option FROM sys.all_views where object_id = object_id('sys_all_views_select_vu_prepare')
GO

CREATE FUNCTION sys_all_views_dep_func_vu_prepare()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.all_views where object_id = object_id('sys_all_views_select_vu_prepare'))
END
GO
