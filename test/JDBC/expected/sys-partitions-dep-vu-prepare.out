CREATE TABLE sys_partitions_dep_vu_prepare_t1 (sp_name VARCHAR (50))
GO

CREATE INDEX sys_partitions_dep_vu_prepare_i1 ON sys_partitions_dep_vu_prepare_t1 (sp_name)
GO

CREATE PROCEDURE sys_partitions_dep_vu_prepare_p1 AS
    SELECT COUNT(*) FROM sys.partitions WHERE object_id = OBJECT_ID('sys_partitions_dep_vu_prepare_t1')
GO

CREATE FUNCTION sys_partitions_dep_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.partitions WHERE object_id = OBJECT_ID('sys_partitions_dep_vu_prepare_t1'))
END
GO

CREATE VIEW sys_partitions_dep_vu_prepare_v1 AS
    SELECT COUNT(*) FROM sys.partitions WHERE object_id = OBJECT_ID('sys_partitions_dep_vu_prepare_t1')
GO
