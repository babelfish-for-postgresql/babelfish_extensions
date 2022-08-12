USE master
GO

CREATE VIEW sys_hash_indexes_vu_prepare_view AS
SELECT * FROM sys.hash_indexes
GO

CREATE PROC sys_hash_indexes_vu_prepare_proc AS
SELECT * FROM sys.hash_indexes
GO

CREATE FUNCTION dbo.sys_hash_indexes_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.hash_indexes)
END
GO