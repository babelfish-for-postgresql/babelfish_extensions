-- Only need to scan the entire table and ensure no error is raised
DECLARE @a INT
SELECT @a = COUNT(*) FROM sys.objects
SELECT (CASE WHEN @a > 1 THEN 'true' ELSE 'false' END) AS result
go
