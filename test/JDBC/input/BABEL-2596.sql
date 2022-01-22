 -- Only need to scan the entire table and ensure no error is raised
DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.system_objects
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go

DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.all_columns
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go

DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.all_objects
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go

DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.all_views
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go

DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.columns
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go

-- TODO: BABEL-2624 Add support for sys.identity_columns
DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.identity_columns
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go

DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.views
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go

DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.tables
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go
