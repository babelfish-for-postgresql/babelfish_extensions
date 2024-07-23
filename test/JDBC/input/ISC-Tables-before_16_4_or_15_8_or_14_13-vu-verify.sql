SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE 'ISC_TABLES%' ORDER BY TABLE_NAME
GO

-- Rename the existing tables to fix the originally stored incorrect bbf_original_rel_name
EXEC sp_rename 'ISC_TABLES_TABLE_SCHEMA.ISC_TABLES_TABLE', 'ISC_TABLES_TABLE2', 'OBJECT'
GO

EXEC sp_rename '"ISC_TABLES SCHEMA . WITH .. DOTS"."ISC_TABLES TABLE . WITH .. DOTS"', 'ISC_TABLES TABLE . WITH .. DOTS2', 'OBJECT'
GO

-- create a new table with name which is prefix of schema name to verify new behavior
CREATE TABLE [ISC_TABLES_TABLE_SCHEMA]  .  [ISC_TABLES_TABLE] (a INT, b INT)
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE 'isc_tables%' ORDER BY TABLE_NAME
SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE 'ISC_TABLES%' ORDER BY TABLE_NAME
GO

-- Table types should not be a result
-- Should not return any rows.
SELECT * FROM information_schema.tables WHERE TABLE_NAME = 'isc_table_type1'
GO

SELECT * FROM information_schema.tables WHERE TABLE_SCHEMA = 'isc_tables_sc1'
SELECT * FROM information_schema.tables WHERE TABLE_SCHEMA = 'ISC_TABLES_SC1'
GO

-- Table types should not be a result
-- Should not return any rows.
SELECT * FROM information_schema.tables WHERE (TABLE_NAME = 'isc_table_type2' AND TABLE_SCHEMA = 'isc_tables_sc1')
GO

EXEC isc_tables_vu_prepare_p1
GO

SELECT * FROM isc_tables_vu_prepare_f1()
SELECT * FROM isc_tables_vu_prepare_f2()
GO

-- Drop and re-create isc_tables_vu_prepare_v1 as it might be dependent upon
-- the deprecated version of information_schema.tables view.
DROP VIEW isc_tables_vu_prepare_v1
GO
CREATE VIEW isc_tables_vu_prepare_v1 AS
    SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE 'ISC_TABLES%' ORDER BY TABLE_NAME
GO

SELECT * FROM isc_tables_vu_prepare_v1
GO

DROP TABLE [ISC_TABLES_TABLE_SCHEMA]  .  [ISC_TABLES_TABLE2]
GO
