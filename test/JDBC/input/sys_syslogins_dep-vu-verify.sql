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

-- temporary adding next two cases to verify script because of issue with upgrade of babelfish_add_domain_mapping_entry
EXEC sys.babelfish_add_domain_mapping_entry 'sysloginsxyz', 'sysloginsxyz.babel';
GO

CREATE LOGIN [sysloginsxyz\domain_login1] FROM WINDOWS;
GO

SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin 
FROM sys.syslogins 
WHERE name = 'sysloginsxyz\domain_login1'
ORDER BY name
GO