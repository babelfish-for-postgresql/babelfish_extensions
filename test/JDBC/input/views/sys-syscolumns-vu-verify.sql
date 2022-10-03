USE sys_syscolumns_vu_prepare_db1;
GO

SELECT name, sys_syscolumns_vu_prepare_OidToObject_pg_proc(id), sys_syscolumns_vu_prepare_OidToDataType(xtype), typestat, length
FROM sys.syscolumns
WHERE name = '@syscolumns_proc1_firstparam' or name = '@syscolumns_proc2_firstparam' or name = '@syscolumns_proc2_secondparam'
ORDER BY sys_syscolumns_vu_prepare_OidToObject_pg_proc(id) asc, name
GO

SELECT name, sys_syscolumns_vu_prepare_OidToObject_pg_class(id), sys_syscolumns_vu_prepare_OidToDataType(xtype), typestat, length
FROM sys.syscolumns
WHERE name = 'syscolumns_t1_col_a' or name = 'syscolumns_t1_col_b' or name = 'syscolumns_t1_col_c' or name = 'syscolumns_t1_col_d'
ORDER BY sys_syscolumns_vu_prepare_OidToObject_pg_class(id) asc, name
GO

SELECT colid, cdefault, domain, number
FROM sys.syscolumns
WHERE name = '@syscolumns_proc1_firstparam'
   or name = '@syscolumns_proc2_firstparam'
   or name = '@syscolumns_proc2_secondparam'
   or name = 'syscolumns_t1_col_a'
   or name = 'syscolumns_t1_col_b'
   or name = 'syscolumns_t1_col_c'
   or name = 'syscolumns_t1_col_d'
ORDER BY name
GO

SELECT sys_syscolumns_vu_prepare_OidToCollation(collationid), status, sys_syscolumns_vu_prepare_OidToDataType(type), prec, scale
FROM sys.syscolumns
WHERE name = '@syscolumns_proc1_firstparam'
   or name = '@syscolumns_proc2_firstparam'
   or name = '@syscolumns_proc2_secondparam'
   or name = 'syscolumns_t1_col_a'
   or name = 'syscolumns_t1_col_b'
   or name = 'syscolumns_t1_col_c'
   or name = 'syscolumns_t1_col_d'
ORDER BY name
GO

SELECT iscomputed, isoutparam, isnullable, collation
FROM sys.syscolumns
WHERE name = '@syscolumns_proc1_firstparam'
   or name = '@syscolumns_proc2_firstparam'
   or name = '@syscolumns_proc2_secondparam'
   or name = 'syscolumns_t1_col_a'
   or name = 'syscolumns_t1_col_b'
   or name = 'syscolumns_t1_col_c'
   or name = 'syscolumns_t1_col_d'
ORDER BY name, id asc
GO

SELECT COUNT(*)
FROM sys.syscolumns
WHERE name = '@syscolumns_proc1_firstparam'
   or name = '@syscolumns_proc2_firstparam'
   or name = '@syscolumns_proc2_secondparam'
   or name = 'syscolumns_t1_col_a'
   or name = 'syscolumns_t1_col_b'
   or name = 'syscolumns_t1_col_c'
GO

USE master;
GO

SELECT COUNT(*) FROM sys.syscolumns WHERE name = '@syscolumns_proc3_thirdparam'
GO

-- should not be visible here
SELECT COUNT(*)
FROM sys.syscolumns
WHERE name = '@syscolumns_proc1_firstparam'
   or name = '@syscolumns_proc2_firstparam'
   or name = '@syscolumns_proc2_secondparam'
   or name = 'syscolumns_t1_col_a'
   or name = 'syscolumns_t1_col_b'
   or name = 'syscolumns_t1_col_c'
GO

USE sys_syscolumns_vu_prepare_db1;
GO

SELECT COUNT(*) 
FROM sys.syscolumns 
WHERE name = '@syscolumns_proc1_firstparam'
   or name = '@syscolumns_proc2_firstparam'
   or name = '@syscolumns_proc2_secondparam'
   or name = 'syscolumns_t1_col_a'
   or name = 'syscolumns_t1_col_b'
   or name = 'syscolumns_t1_col_c'
GO

-- should not be visible here
SELECT COUNT(*) FROM sys.syscolumns WHERE name = '@syscolumns_proc3_thirdparam'
GO
