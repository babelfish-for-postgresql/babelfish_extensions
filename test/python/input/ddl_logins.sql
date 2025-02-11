CREATE LOGIN login_pwd1   
    WITH PASSWORD = '891$RtQ73nJ#k8';  
   ALTER SERVER ROLE [sysadmin] ADD MEMBER [login_pwd1]
GO

CREATE LOGIN login_pwd2   
    WITH PASSWORD = '673$WpM45hB#j4',
    default_database = tempdb; 
GO

CREATE LOGIN [ad\Aduser] from windows with default_database=[tempdb];
GO

--DROP
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_pwd1')
    DROP LOGIN login_pwd1
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_pwd2')
    DROP LOGIN login_pwd2
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'ad\Aduser')
    DROP LOGIN [ad\Aduser]
GO

