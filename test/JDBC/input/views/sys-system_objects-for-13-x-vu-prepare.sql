CREATE PROCEDURE sys_system_objects_vu_prepare_p1 AS
SELECT name,type,type_desc FROM sys.system_objects WHERE name = 'key_constraints'
SELECT name,type,type_desc FROM sys.system_objects WHERE name = 'KEY_CONSTRAINTS'
GO

CREATE FUNCTION sys_system_objects_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.system_objects WHERE name = 'key_constraints')
end
GO

CREATE FUNCTION sys_system_objects_vu_prepare_f2()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.system_objects WHERE name = 'KEY_CONSTRAINTS')
end
GO

CREATE VIEW sys_system_objects_vu_prepare_v1 AS
    SELECT name,type,type_desc FROM sys.system_objects WHERE name = 'key_constraints'
GO
