CREATE VIEW sys_sequences_test_view
AS
    SELECT * FROM sys.sequences;
GO

CREATE PROC sys_sequences_test_proc
AS
    SELECT * FROM sys.sequences
GO

CREATE FUNCTION sys_sequences_test_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sequences)
END
GO