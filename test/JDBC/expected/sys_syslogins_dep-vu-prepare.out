CREATE LOGIN sys_syslogins_dep_vu_prepare_login1 WITH PASSWORD = '12345'
GO

CREATE LOGIN sys_syslogins_dep_vu_prepare_login2 WITH PASSWORD = '12345'
GO

CREATE VIEW sys_syslogins_dep_vu_prepare_view
AS
SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin 
FROM sys.syslogins 
WHERE name LIKE '%sys_syslogins_dep_vu_prepare%'
ORDER BY name
GO

CREATE PROC sys_syslogins_dep_vu_prepare_proc
AS
SELECT name,dbname,default_language_name,status,totcpu,totio,spacelimit,timelimit,
resultlimit,loginname,password,denylogin,hasaccess,isntname,isntgroup,isntuser,sysadmin,securityadmin,serveradmin,setupadmin,
processadmin,diskadmin,dbcreator,bulkadmin 
FROM sys.syslogins 
WHERE name LIKE '%sys_syslogins_dep_vu_prepare%'
ORDER BY name
GO

CREATE FUNCTION sys_syslogins_dep_vu_prepare_func()
RETURNS INT AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.syslogins WHERE name LIKE '%sys_syslogins_dep_vu_prepare%')
END
GO

EXEC sys.babelfish_add_domain_mapping_entry 'xyz', 'xyz.babel';
GO

CREATE LOGIN [xyz\domain_login1] FROM WINDOWS;
GO
