USE master
GO

CREATE VIEW sys_sequences_vu_prepare_view AS
SELECT * FROM sys.sequences
GO

CREATE PROC sys_sequences_vu_prepare_proc AS
SELECT * FROM sys.sequences
GO

CREATE FUNCTION sys_sequences_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sequences WHERE is_cycling= 0)
END
GO