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

-- syslogins should also present in dbo schema
SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin
FROM dbo.syslogins
WHERE name LIKE 'sys_syslogins_dep_vu_prepare_login%'
ORDER BY name
GO

-- Cross-db check for syslogins
SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin
FROM sys_syslogins_dep_vu_prepare_db.sys.syslogins
WHERE name LIKE 'sys_syslogins_dep_vu_prepare_login%'
ORDER BY name
GO

SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin
FROM sys_syslogins_dep_vu_prepare_db.dbo.syslogins
WHERE name LIKE 'sys_syslogins_dep_vu_prepare_login%'
ORDER BY name
GO

SELECT loginname, dbname, sysadmin from syslogins where loginname = 'sysadmin'
GO

-- adding alter serverrole cases here because it cant go to prepare
CREATE LOGIN sys_syslogins_dep_vu_prepare_login3 WITH PASSWORD = '12345'
GO

ALTER SERVER ROLE sysadmin ADD MEMBER sys_syslogins_dep_vu_prepare_login3
GO

SELECT loginname,dbname,sysadmin from syslogins WHERE name LIKE '%sys_syslogins_dep_vu_prepare%' ORDER BY name
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_syslogins_dep_vu_prepare_login3
GO

DROP LOGIN sys_syslogins_dep_vu_prepare_login3
GO

-- adding next two cases to verify script because of issue with upgrade of babelfish_add_domain_mapping_entry
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

-- syslogins should also present in dbo schema
SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin
FROM dbo.syslogins
WHERE name = 'sysloginsxyz\domain_login1'
ORDER BY name
GO

-- Cross-db check for syslogins
SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin
FROM sys_syslogins_dep_vu_prepare_db.sys.syslogins
WHERE name = 'sysloginsxyz\domain_login1'
ORDER BY name
GO

SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin
FROM sys_syslogins_dep_vu_prepare_db.dbo.syslogins
WHERE name = 'sysloginsxyz\domain_login1'
ORDER BY name
GO
