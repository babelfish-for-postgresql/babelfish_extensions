CREATE PROCEDURE test_sp_reset_connection_proc
AS
BEGIN
    EXEC sys.sp_reset_connection
END
GO
