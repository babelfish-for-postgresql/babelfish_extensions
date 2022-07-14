USE master;
GO

CREATE VIEW sys_configurations_view AS
SELECT * FROM sys.configurations
GO

CREATE PROC sys_configurations_proc AS
SELECT * FROM sys.configurations
GO

CREATE FUNCTION sys_configurations_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sysconfigures)
END
GO

CREATE VIEW sys_syscurconfigs_view AS
SELECT * FROM sys.syscurconfigs
GO

CREATE PROC sys_syscurconfigs_proc AS
SELECT * FROM sys.syscurconfigs
GO

CREATE FUNCTION sys_syscurconfigs_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sysconfigures)
END
GO

CREATE VIEW sys_sysconfigures_view AS
SELECT * FROM sys.sysconfigures
GO

CREATE PROC sys_sysconfigures_proc AS
SELECT * FROM sys.sysconfigures
GO

CREATE FUNCTION sys_sysconfigures_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sysconfigures)
END
GO
