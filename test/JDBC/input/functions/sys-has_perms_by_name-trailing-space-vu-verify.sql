-- test blank space end of the database name
SELECT HAS_PERMS_BY_NAME(' blank space    ','DATABASE','CREATE FUNCTION');
GO

SELECT HAS_PERMS_BY_NAME('[ blank space    ]','DATABASE','CREATE FUNCTION');
GO