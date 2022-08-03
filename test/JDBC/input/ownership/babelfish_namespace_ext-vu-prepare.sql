CREATE SCHEMA babelfish_namespace_ext_vu_prepare_sch1
GO

CREATE SCHEMA babelfish_namespace_ext_vu_prepare_sch2
GO

CREATE VIEW babelfish_namespace_ext_vu_prepare_view
AS
SELECT nspname, orig_name 
FROM sys.babelfish_namespace_ext 
WHERE nspname LIKE '%babelfish_namespace_ext_vu_prepare_sch%'
ORDER BY nspname
GO

CREATE PROC babelfish_namespace_ext_vu_prepare_proc
AS
SELECT nspname, orig_name 
FROM sys.babelfish_namespace_ext 
WHERE nspname LIKE '%babelfish_namespace_ext_vu_prepare_sch%'
ORDER BY nspname
GO

CREATE FUNCTION babelfish_namespace_ext_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_namespace_ext WHERE nspname LIKE '%babelfish_namespace_ext_vu_prepare_sch%')
END
GO
