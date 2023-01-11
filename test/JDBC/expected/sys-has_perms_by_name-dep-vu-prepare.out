-- Create dependant objects
CREATE TABLE has_perms_by_name_dep_vu_prepare_t1(a int, b int)
GO

CREATE VIEW has_perms_by_name_dep_vu_prepare_view AS
SELECT HAS_PERMS_BY_NAME('has_perms_by_name_dep_vu_prepare_t1','OBJECT', 'SELECT')
GO

CREATE PROC has_perms_by_name_dep_vu_prepare_proc AS
SELECT HAS_PERMS_BY_NAME('has_perms_by_name_dep_vu_prepare_t1','OBJECT', 'SELECT')
GO

CREATE FUNCTION has_perms_by_name_dep_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN HAS_PERMS_BY_NAME('has_perms_by_name_dep_vu_prepare_t1','OBJECT', 'SELECT')
END
GO
