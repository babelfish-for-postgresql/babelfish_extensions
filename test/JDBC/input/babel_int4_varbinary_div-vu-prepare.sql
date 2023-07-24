USE master
GO

CREATE VIEW sys_int4_varbinary_vu_prepare_view AS
SELECT  (23446576 / CAST(12345 AS varbinary(4)))
GO

CREATE PROC sys_int4_varbinary_vu_prepare_proc AS
Select (21745678/CAST(424748 as varbinary(4)))
GO

CREATE FUNCTION sys_int4_varbinary_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (select 254354 / 0)
END
GO
