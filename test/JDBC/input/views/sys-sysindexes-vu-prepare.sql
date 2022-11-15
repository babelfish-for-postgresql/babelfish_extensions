CREATE DATABASE sys_sysindexes_vu_prepare_db1
GO

USE sys_sysindexes_vu_prepare_db1
GO

CREATE TABLE sys_sysindexes_vu_prepare_t1(a INT, b INT)
GO

CREATE INDEX sys_sysindexes_vu_prepare_t1_i1 on sys_sysindexes_vu_prepare_t1(a)
GO

CREATE PROCEDURE sys_sysindexes_vu_prepare_p1 AS
SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%sys_sysindexes_vu_prepare_t1_i1%'
SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%SYS_SYSINDEXES_VU_PREPARE_T1_I1%'
GO

CREATE FUNCTION sys_sysindexes_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%sys_sysindexes_vu_prepare_t1_i1%')
end
GO

CREATE FUNCTION sys_sysindexes_vu_prepare_f2()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%SYS_SYSINDEXES_VU_PREPARE_T1_I1%')
end
GO

CREATE VIEW sys_sysindexes_vu_prepare_v1 AS
    SELECT COUNT(*) FROM sys.sysindexes WHERE name LIKE '%sys_sysindexes_vu_prepare_t1_i1%'
GO
