USE isc_columns_db1
GO

--should return nothing
SELECT * FROM information_schema.columns WHERE TABLE_NAME != 'sysdatabases'
SELECT * FROM information_schema.columns WHERE TABLE_NAME != 'SYSDATABASES'
GO

USE master
GO


SELECT * FROM information_schema.columns WHERE TABLE_NAME LIKE '%isc_columns_vu_prepare%' ORDER BY DATA_TYPE,COLUMN_NAME
SELECT * FROM information_schema.columns WHERE TABLE_NAME LIKE '%ISC_COLUMNS_VU_PREPARE%' ORDER BY DATA_TYPE,COLUMN_NAME
GO

SELECT * FROM information_schema.columns WHERE TABLE_NAME LIKE '%isc_columns_udt%' ORDER BY DATA_TYPE,COLUMN_NAME
GO

EXEC isc_columns_vu_prepare_p1
GO

SELECT * FROM isc_columns_vu_prepare_f1()
SELECT * FROM isc_columns_vu_prepare_f2()
GO

SELECT * FROM isc_columns_vu_prepare_v1
GO

SELECT * FROM isc_columns_bytea_v2
GO
