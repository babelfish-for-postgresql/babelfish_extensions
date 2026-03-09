-- default value
SELECT @@textsize
GO

-- used in expression
SELECT CASE WHEN @@textsize >= -1 THEN 'valid' ELSE 'invalid' END
GO

-- used with other @@ variables
SELECT @@textsize, @@lock_timeout
GO
