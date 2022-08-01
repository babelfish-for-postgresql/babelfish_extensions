CREATE SCHEMA test_babelfish_namespace_ext_sch1
GO

CREATE SCHEMA test_babelfish_namespace_ext_sch2
GO

CREATE VIEW test_babelfish_namespace_ext_view
AS
SELECT nspname, orig_name 
FROM sys.babelfish_namespace_ext 
WHERE nspname LIKE '%test_babelfish_namespace_ext_sch%'
ORDER BY nspname
GO

CREATE PROC test_babelfish_namespace_ext_proc
AS
SELECT nspname, orig_name 
FROM sys.babelfish_namespace_ext 
WHERE nspname LIKE '%test_babelfish_namespace_ext_sch%'
ORDER BY nspname
GO

CREATE FUNCTION test_babelfish_namespace_ext_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_namespace_ext WHERE nspname LIKE '%test_babelfish_namespace_ext_sch%')
END
GO
