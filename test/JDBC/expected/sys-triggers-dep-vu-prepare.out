CREATE TABLE sys_triggers_dep_vu_prepare_table(a int)
GO

CREATE TRIGGER sys_triggers_dep_vu_prepare_trig ON sys_triggers_dep_vu_prepare_table AFTER INSERT
AS
BEGIN
SELECT 1
END
GO

CREATE PROCEDURE sys_triggers_dep_vu_prepare_p1 AS
    SELECT name FROM sys.triggers WHERE name = 'sys_triggers_dep_vu_prepare_trig'
GO

CREATE FUNCTION sys_triggers_dep_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.triggers WHERE name = 'sys_triggers_dep_vu_prepare_trig')
END
GO

CREATE VIEW sys_triggers_dep_vu_prepare_v1 AS
    SELECT name FROM sys.triggers WHERE name = 'sys_triggers_dep_vu_prepare_trig'
GO
