USE master;
GO

CREATE VIEW sys_configurations_vu_prepare_v1 AS
SELECT * FROM sys.configurations
GO

CREATE PROC sys_configurations_vu_prepare_p1 AS
SELECT * FROM sys.configurations
GO

CREATE FUNCTION sys_configurations_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sysconfigures)
END
GO

CREATE VIEW sys_configurations_vu_prepare_v2 AS
SELECT * FROM sys.syscurconfigs
GO

CREATE PROC sys_configurations_vu_prepare_p2 AS
SELECT * FROM sys.syscurconfigs
GO

CREATE FUNCTION sys_configurations_vu_prepare_f2()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sysconfigures)
END
GO

CREATE VIEW sys_configurations_vu_prepare_v3 AS
SELECT * FROM sys.sysconfigures
GO

CREATE PROC sys_configurations_vu_prepare_p3 AS
SELECT * FROM sys.sysconfigures
GO

CREATE FUNCTION sys_configurations_vu_prepare_f3()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sysconfigures)
END
GO
