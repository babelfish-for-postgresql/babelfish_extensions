-- procedure dependent on sp_execute_postgresql proc
CREATE PROC test_sp_execute_postgresql_proc
AS
BEGIN
    EXEC sp_execute_postgresql 'create extension fuzzystrmatch'
END
go
