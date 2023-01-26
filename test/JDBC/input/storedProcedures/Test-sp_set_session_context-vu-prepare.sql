CREATE PROCEDURE test_sp_set_session_context_proc
AS
BEGIN
    DECLARE @set_session_context_key sys.SYSNAME = 'test_sp_set_session_context_proc';
    DECLARE @set_session_context_val VARCHAR(128) = 'test_sp_set_session_context_proc_val'

    EXEC sp_set_session_context @set_session_context_key, @set_session_context_val;

    SELECT (CASE WHEN SESSION_CONTEXT(@set_session_context_key) = @set_session_context_val 
        THEN 'Match' ELSE 'No Match' END);
END
GO

CREATE FUNCTION test_sp_set_session_context_func() RETURNS INT
AS
BEGIN
    DECLARE @set_session_context_key VARCHAR(128) = 'test_sp_set_session_context_func';
    RETURN (CASE WHEN SESSION_CONTEXT(@set_session_context_key) IS NULL THEN 0 ELSE 1 END)
END
GO

CREATE VIEW test_sp_set_session_context_view AS
SELECT SESSION_CONTEXT(N'test_sp_set_session_context_proc')
GO

CREATE LOGIN session_context_1 WITH PASSWORD = 'abc';
GO

CREATE LOGIN session_context_2 WITH PASSWORD = 'abc';
GO
