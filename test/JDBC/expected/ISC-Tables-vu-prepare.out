CREATE TABLE isc_tables_vu_prepare_t1(a INT,b INT)
GO

-- test different schema 
CREATE SCHEMA isc_tables_sc1
GO

CREATE TABLE isc_tables_sc1.t2(a INT,b INT)
GO

--Dep Proc
CREATE PROCEDURE isc_tables_vu_prepare_p1 AS
SELECT * FROM information_schema.tables WHERE TABLE_NAME = 'isc_tables_vu_prepare_t1'
SELECT * FROM information_schema.tables WHERE TABLE_NAME = 'ISC_TABLES_VU_PREPARE_T1'
GO

-- Dep Funcs
CREATE FUNCTION isc_tables_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_NAME = 'isc_tables_vu_prepare_t1')
end
GO

CREATE FUNCTION isc_tables_vu_prepare_f2()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_NAME = 'ISC_TABLES_VU_PREPARE_T1')
end
GO

-- Dep View
CREATE VIEW isc_tables_vu_prepare_v1 AS
    SELECT * FROM information_schema.tables WHERE TABLE_NAME = 'ISC_TABLES_VU_PREPARE_T1'
GO
