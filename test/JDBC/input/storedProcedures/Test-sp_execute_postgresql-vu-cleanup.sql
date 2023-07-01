DROP PROC test_sp_execute_postgresql_proc
GO
EXEC sp_execute_postgresql 'DROP EXTENSION fuzzystrmatch;'
GO
