CREATE TABLE isc_tables_vu_prepare_t1(a INT,b INT)
GO

CREATE TYPE isc_table_type1 AS TABLE(a INT)
GO

-- test different schema 
CREATE SCHEMA isc_tables_sc1
GO

CREATE SCHEMA [ISC_TABLES_TABLE_SCHEMA]
GO

CREATE SCHEMA [ISC_TABLES SCHEMA . WITH .. DOTS]
GO

CREATE TABLE isc_tables_sc1.t2(a INT,b INT)
GO

-- Table name which is prefix of schema name
CREATE TABLE [ISC_TABLES_TABLE_SCHEMA]  .  [ISC_TABLES_TABLE] (a INT, b INT)
GO

CREATE TABLE [ISC_TABLES SCHEMA . WITH .. DOTS]  .  [ISC_TABLES TABLE . WITH .. DOTS] (a INT, b INT)
GO

CREATE TYPE isc_tables_sc1.isc_table_type2 AS TABLE(a INT)
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
    RETURN (SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_NAME LIKE 'isc_tables%')
end
GO

CREATE FUNCTION isc_tables_vu_prepare_f2()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_NAME LIKE 'ISC_TABLES%')
end
GO

-- Dep View
CREATE VIEW isc_tables_vu_prepare_v1 AS
    SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE 'ISC_TABLES%' ORDER BY TABLE_NAME
GO
