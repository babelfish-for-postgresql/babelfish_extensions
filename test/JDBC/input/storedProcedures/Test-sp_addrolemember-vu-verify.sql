-- tsql
CREATE ROLE sp_addrolemember_r1;
GO

CREATE ROLE sp_addrolemember_r2;
GO

CREATE ROLE sp_addrolemember_r3;
GO

-- Throw an error if passed rolename or membername contains \ or between whitespaces
Exec sp_addrolemember 'sp_addrolemember_ r1', 'sp_addrolemember_r2';
GO

Exec sp_addrolemember 'sp_addrolemember_r1', 'sp_addrolemember_\r2';
GO

-- Throw an error when same roles are passed
Exec sp_addrolemember 'sp_addrolemember_r1', 'sp_addrolemember_r1';
GO

-- Check whether sp_addrolemember_r2 is rolemember of sp_addrolemember_r1
SELECT IS_ROLEMEMBER('sp_addrolemember_r1', 'sp_addrolemember_r2')
GO

Exec sp_addrolemember 'sp_addrolemember_r1', 'sp_addrolemember_r2';
GO

-- Check whether sp_addrolemember_r2 is rolemember of sp_addrolemember_r1
SELECT IS_ROLEMEMBER('sp_addrolemember_r1', 'sp_addrolemember_r2')
GO

-- Executes even if rolename or membername contains leading and trailing whitespaces
Exec sp_addrolemember '    sp_addrolemember_r1   ', '    sp_addrolemember_r3    ';
GO

-- Check whether sp_addrolemember_r3 is rolemember of sp_addrolemember_r1
SELECT IS_ROLEMEMBER('sp_addrolemember_r1', 'sp_addrolemember_r3')
GO

-- Throw an error when member doesn't exist
Exec sp_addrolemember 'sp_addrolemember_r1', 'sp_addrolemember_r4';
GO
