CREATE VIEW babelfish_inconsistent_metadata_vu_prepare_view
AS
SELECT object_type, schema_name, object_name 
FROM sys.babelfish_inconsistent_metadata()
GO

CREATE PROC babelfish_inconsistent_metadata_vu_prepare_proc
AS
SELECT object_type, schema_name, object_name 
FROM sys.babelfish_inconsistent_metadata()
GO

CREATE FUNCTION babelfish_inconsistent_metadata_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(DISTINCT detail) FROM sys.babelfish_inconsistent_metadata(false))
END
GO
