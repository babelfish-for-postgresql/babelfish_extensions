USE master
GO

CREATE VIEW sys_varbinary_int4_vu_prepare_view AS
SELECT  (CAST(12345 AS varbinary(4)) / 12)
GO

CREATE PROC sys_int4_varbinary_vu_prepare_proc AS
Select 424748364 / 0x101
GO

CREATE FUNCTION sys_varbinary_int4_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (select 0x101 / 0)
END
GO
