CREATE LOGIN login_pwd1   
    WITH PASSWORD = '425$LnK92mP#x5';  
GO

CREATE LOGIN login_pwd2   
    WITH PASSWORD = '891$RtQ73nJ#k8';  
GO

CREATE LOGIN login_pwd3   
    WITH PASSWORD = '673$WpM45hB#j6'; 
GO

--DROP
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_pwd1')
    DROP LOGIN login_pwd1
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_pwd2')
    DROP LOGIN login_pwd2
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_pwd3')
    DROP LOGIN login_pwd3
GO
