CREATE VIEW sys_views_dep_vu_prepare_t1 AS select 1;
GO

CREATE PROCEDURE sys_views_dep_vu_prepare_p1 AS
    SELECT COUNT(*) FROM sys.views WHERE name = 'sys_views_dep_vu_prepare_t1'
GO

CREATE FUNCTION sys_views_dep_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.views WHERE name = 'sys_views_dep_vu_prepare_t1')
END
GO

CREATE VIEW sys_views_dep_vu_prepare_v1 AS
    SELECT COUNT(*) FROM sys.views WHERE name = 'sys_views_dep_vu_prepare_t1'
GO

