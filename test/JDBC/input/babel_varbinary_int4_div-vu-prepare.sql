USE master
GO

CREATE VIEW sys_varbinary_int4_vu_prepare_view AS
SELECT  (CAST(12345 AS varbinary(4)) / 12)
GO

CREATE PROC sys_varbinary_int4_vu_prepare_proc AS
Select (CAST(424748364 as varbinary(4)) / 13)
GO

CREATE FUNCTION sys_varbinary_int4_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (select 0x101 / 0)
END
GO
