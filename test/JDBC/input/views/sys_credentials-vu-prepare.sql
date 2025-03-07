USE master
GO

CREATE VIEW sys_credentials_vu_prepare_view AS
SELECT * FROM sys.credentials
GO

CREATE PROC sys_credentials_vu_prepare_proc AS
SELECT * FROM sys.credentials
GO

CREATE FUNCTION sys_credentials_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.credentials)
END
GO