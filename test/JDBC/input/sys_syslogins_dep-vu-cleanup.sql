DROP VIEW sys_syslogins_dep_vu_prepare_view
GO

DROP PROC sys_syslogins_dep_vu_prepare_proc
GO

DROP FUNCTION sys_syslogins_dep_vu_prepare_func
GO

DROP LOGIN sys_syslogins_dep_vu_prepare_login1
GO

DROP LOGIN sys_syslogins_dep_vu_prepare_login2
GO

DROP LOGIN [sysloginsxyz\domain_login1]
GO

EXEC babelfish_remove_domain_mapping_entry 'sysloginsxyz'
GO