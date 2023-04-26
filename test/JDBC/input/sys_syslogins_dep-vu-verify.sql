SELECT * FROM sys_syslogins_dep_vu_prepare_view
GO

EXEC sys_syslogins_dep_vu_prepare_proc
GO

SELECT sys_syslogins_dep_vu_prepare_func()
GO

SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin 
FROM sys.syslogins
WHERE name LIKE 'sys_syslogins_dep_vu_prepare_login%'
ORDER BY name
GO
