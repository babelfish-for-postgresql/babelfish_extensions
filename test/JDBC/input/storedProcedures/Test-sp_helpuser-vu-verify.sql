-- verify
-- dbo should show database owner login
EXEC check_helpuser;
GO

EXEC check_helpuser 'dbo';
GO

USE db_check_helpuser;
GO

EXEC check_helpuser;
GO

EXEC check_helpuser 'dbo';
GO

-- cleanup
DROP PROCEDURE check_helpuser
GO

USE master;
GO

DROP DATABASE db_check_helpuser;
GO

DROP PROCEDURE check_helpuser
GO

