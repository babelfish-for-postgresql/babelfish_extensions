CREATE SCHEMA sys_schemas_dep_vu_prepare_test1
GO

CREATE PROCEDURE sys_schemas_dep_vu_prepare_p1 AS
    SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.schemas')
GO

CREATE FUNCTION sys_schemas_dep_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.schemas'))
END
GO

CREATE VIEW sys_schemas_dep_vu_prepare_v1 AS
    SELECT name FROM sys.schemas WHERE name='sys_schemas_dep_vu_prepare_test1'
GO
