-- default value (0)
SELECT @@textsize
GO

-- used in expression
SELECT CASE WHEN @@textsize >= 0 THEN 'valid' ELSE 'invalid' END
GO

-- used with other @@ variables
SELECT @@textsize AS textsize, @@lock_timeout AS lock_timeout
GO
