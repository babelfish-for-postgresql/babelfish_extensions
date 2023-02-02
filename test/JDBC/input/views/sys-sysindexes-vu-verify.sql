USE sys_sysindexes_vu_prepare_db1
GO

--check for entry of index in view
SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%sys_sysindexes_vu_prepare_t1_i1%'
GO

--check for case insensitive comparison
SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%SYS_SYSINDEXES_VU_PREPARE_T1_I1%'
GO

--check indid and index_id return same values
select count(*) from sys.indexes v1 inner join sys.sysindexes v2 on v1.object_id = v2.id and indid=index_id where v1.name LIKE '%SYS_SYSINDEXES_VU_PREPARE_T1_I1%';
GO

EXEC sys_sysindexes_vu_prepare_p1
GO

SELECT * FROM sys_sysindexes_vu_prepare_f1()
SELECT * FROM sys_sysindexes_vu_prepare_f2()
GO

SELECT * FROM sys_sysindexes_vu_prepare_v1
GO


USE master
GO
-- should not be visible here
SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%sys_sysindexes_vu_prepare_t1_i1%'
GO

-- should not be visible here
SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%SYS_SYSINDEXES_VU_PREPARE_T1_I1%'
GO


