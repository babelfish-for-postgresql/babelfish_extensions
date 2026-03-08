-- default value (0)
exec sys_textsize_p1
GO

-- used in expression
exec sys_textsize_p2
GO

-- used with other @@ variables
exec sys_textsize_p3
GO

-- from view
SELECT * FROM sys_textsize_v1
GO

-- direct SELECT @@textsize
SELECT @@textsize
GO
