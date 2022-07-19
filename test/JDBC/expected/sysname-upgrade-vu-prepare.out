CREATE FUNCTION sysname_func_vu_prepare(@a sys.sysname)
RETURNS int
AS
BEGIN
	return 1;
END
GO

CREATE VIEW sysname_view_vu_prepare AS
SELECT sysname_func_vu_prepare(-1) as a
GO

CREATE VIEW sysname_view_vu_prepare2 AS
SELECT is_member(-1)
GO

CREATE VIEW sysname_view_vu_prepare3 AS
SELECT is_member(-5)
GO

CREATE VIEW sysname_view_vu_prepare4 AS
SELECT suser_sid(-10)
GO
