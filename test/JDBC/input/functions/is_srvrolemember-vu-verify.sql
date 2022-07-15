SELECT is_srvrolemember('PUBLIC')
GO

SELECT is_srvrolemember('public')
GO

SELECT is_srvrolemember('public     ')
GO

SELECT is_srvrolemember('     public')
GO

SELECT is_srvrolemember('public', 'non_existent')
GO

SELECT is_srvrolemember('public', 'jdbc_user')
GO

SELECT is_srvrolemember('SYSADMIN')
GO

SELECT is_srvrolemember('sysadmin')
GO

SELECT is_srvrolemember('sysadmin', 'jdbc_user')
GO

SELECT is_srvrolemember('sysadmin', 'jdbc_user   ')
GO

SELECT is_srvrolemember('sysadmin', '   jdbc_user')
GO

SELECT is_srvrolemember('serveradmin')
GO

SELECT is_srvrolemember('SERVERADMIN')
GO

SELECT is_srvrolemember('serveradmin', 'non_existent')
GO

SELECT is_srvrolemember('setupadmin')
GO

SELECT is_srvrolemember('securityadmin')
GO

SELECT is_srvrolemember('processadmin')
GO

SELECT is_srvrolemember('dbcreator')
GO

SELECT is_srvrolemember('diskadmin')
GO

SELECT is_srvrolemember('bulkadmin')
GO

SELECT is_srvrolemember('non_existent')
GO
