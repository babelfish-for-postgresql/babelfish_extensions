SELECT * FROM information_schema.tables WHERE TABLE_NAME = 'isc_tables_vu_prepare_t1'
SELECT * FROM information_schema.tables WHERE TABLE_NAME = 'ISC_TABLES_VU_PREPARE_T1'
GO

SELECT * FROM information_schema.tables WHERE TABLE_SCHEMA = 'isc_tables_sc1'
SELECT * FROM information_schema.tables WHERE TABLE_SCHEMA = 'ISC_TABLES_SC1'
GO

EXEC isc_tables_vu_prepare_p1
GO

SELECT * FROM isc_tables_vu_prepare_f1()
SELECT * FROM isc_tables_vu_prepare_f2()
GO

SELECT * FROM isc_tables_vu_prepare_v1
GO