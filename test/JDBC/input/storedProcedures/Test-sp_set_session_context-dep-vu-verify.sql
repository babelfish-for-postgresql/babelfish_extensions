EXEC test_sp_set_session_context_proc;
GO

SELECT test_sp_set_session_context_func();
GO

SELECT * FROM test_sp_set_session_context_view;
GO
