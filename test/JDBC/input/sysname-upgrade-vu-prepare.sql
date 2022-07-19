CREATE FUNCTION sysname_func_vu_prepare(@a sys.sysname)
RETURNS int
AS
BEGIN
	return 1;
END
GO

CREATE VIEW sysname_view_vu_prepare AS
SELECT sysname_func_vu_prepare(1) as a
GO
