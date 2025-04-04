CREATE LOGIN login_1   
    WITH PASSWORD = '891$RtQ73nJ#k8';  
   ALTER SERVER ROLE [sysadmin] ADD MEMBER [login_1]
GO

CREATE LOGIN login_2   
    WITH PASSWORD = '673$WpM45hB#j4',
    default_database = tempdb; 
GO
CREATE LOGIN [ad\Aduser] from windows with default_database=[tempdb];
GO
ddlexport#!#0
GO
DROP LOGIN  login_1
GO
DROP LOGIN  login_2
GO
DROP LOGIN  [ad\Aduser]
GO

