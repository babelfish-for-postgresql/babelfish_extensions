-- Create dependant objects
CREATE TABLE has_perms_by_name_dep_vu_prepare_t1(a int, b int)
GO

CREATE VIEW has_perms_by_name_dep_vu_prepare_view AS
SELECT HAS_PERMS_BY_NAME('t_perms_by_name','OBJECT', 'SELECT')
GO

CREATE PROC has_perms_by_name_dep_vu_prepare_proc AS
SELECT HAS_PERMS_BY_NAME('t_perms_by_name','OBJECT', 'SELECT')
GO

CREATE FUNCTION has_perms_by_name_dep_vu_prepare_func()
RETURNS INT
AS
BEGIN
SELECT HAS_PERMS_BY_NAME('t_perms_by_name','OBJECT', 'SELECT')
END
GO
