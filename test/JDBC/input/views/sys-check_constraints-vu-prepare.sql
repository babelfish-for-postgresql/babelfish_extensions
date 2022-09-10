CREATE TABLE sys_check_constraints_vu_prepare
(
column_a bit default 0,
column_b varchar(5) CHECK (column_b <> 'wrong'),
CHECK (column_a = 0)
)
GO

CREATE PROC sys_check_constraints_vu_prepare_proc AS
    SELECT definition FROM sys.check_constraints WHERE name LIKE '%sys_check_constraints%' ORDER BY definition
GO

CREATE FUNCTION sys_check_constraints_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.check_constraints WHERE name LIKE '%sys_check_constraints%' )
END
GO

CREATE VIEW sys_check_constraints_vu_prepare_view AS
    SELECT definition FROM sys.check_constraints WHERE name LIKE '%sys_check_constraints%' ORDER BY definition
GO
