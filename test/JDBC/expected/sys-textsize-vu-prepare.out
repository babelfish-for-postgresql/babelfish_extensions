-- Test @@textsize configuration function (GitHub issue #2497)

-- Verify @@textsize returns a value
CREATE PROCEDURE sys_textsize_p1 AS
SELECT @@textsize;
GO

-- Verify @@textsize can be used in expressions
CREATE PROCEDURE sys_textsize_p2 AS
SELECT CASE WHEN @@textsize >= 0 THEN 'valid' ELSE 'invalid' END;
GO

-- Verify @@textsize can be used with other @@ variables
CREATE PROCEDURE sys_textsize_p3 AS
SELECT @@textsize AS textsize, @@lock_timeout AS lock_timeout;
GO

-- Verify @@textsize works in a view definition
CREATE VIEW sys_textsize_v1 AS
SELECT @@textsize AS textsize;
GO
