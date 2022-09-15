DROP TABLE IF EXISTS sys_index_columns_dep_vu_prepare_t1
GO

CREATE TABLE sys_index_columns_dep_vu_prepare_t1 (
	sic_name VARCHAR (50),
	sic_surname VARCHAR (50)
)
GO

CREATE INDEX sys_index_columns_dep_vu_prepare_i1
ON sys_index_columns_dep_vu_prepare_t1 (sic_name)
GO

CREATE PROCEDURE sys_index_columns_dep_vu_prepare_p1 AS
    SELECT COUNT(*) FROM sys.index_columns WHERE object_id = OBJECT_ID('sys_index_columns_dep_vu_prepare_t1')
GO

CREATE FUNCTION sys_index_columns_dep_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.index_columns WHERE object_id = OBJECT_ID('sys_index_columns_dep_vu_prepare_t1'))
END
GO

CREATE VIEW sys_index_columns_dep_vu_prepare_v1 AS
    SELECT COUNT(*) FROM sys.index_columns WHERE object_id = OBJECT_ID('sys_index_columns_dep_vu_prepare_t1')
GO
