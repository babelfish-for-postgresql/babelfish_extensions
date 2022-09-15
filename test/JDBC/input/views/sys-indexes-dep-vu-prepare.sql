DROP TABLE IF EXISTS sys_indexes_dep_vu_prepare_t1
GO

CREATE TABLE sys_indexes_dep_vu_prepare_t1 (
	c1 INT, 
	c2 VARCHAR(128)
);
GO

INSERT INTO sys_indexes_dep_vu_prepare_t1 (c1, c2) VALUES
(100, 'abc'),
(200, 'bcd'),
(300, 'cde'),
(1400, 'def')
GO

-- two NONCLUSTERED indexes created
CREATE INDEX sys_indexes_dep_vu_prepare_i1 ON sys_indexes_dep_vu_prepare_t1 (c1);
CREATE INDEX sys_indexes_dep_vu_prepare_i1a ON sys_indexes_dep_vu_prepare_t1 (c2);
GO

CREATE PROCEDURE sys_indexes_dep_vu_prepare_p1 AS
    SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.indexes')
GO

CREATE FUNCTION sys_indexes_dep_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('sys_indexes_dep_vu_prepare_t1'))
END
GO

CREATE VIEW sys_indexes_dep_vu_prepare_v1 AS
    SELECT COUNT(*) FROM sys.indexes WHERE name LIKE 'sys_indexes_dep_vu_prepare_i1%'
GO
