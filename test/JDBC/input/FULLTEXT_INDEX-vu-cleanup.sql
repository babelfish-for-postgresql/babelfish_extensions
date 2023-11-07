-- enable FULLTEXT
SELECT set_config('role', 'jdbc_user', false);
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

USE master;
GO

DROP FULLTEXT INDEX ON fti_table_t1;
GO

DROP TABLE IF EXISTS fti_table_t1;
GO

DROP FULLTEXT INDEX ON fti_table_t2;
GO

DROP TABLE IF EXISTS fti_table_t2;
GO

DROP FULLTEXT INDEX ON fti_table_t3;
GO

DROP TABLE IF EXISTS fti_table_t3;
GO

DROP FULLTEXT INDEX ON fti_table_t4;
GO

DROP TABLE IF EXISTS fti_table_t4;
GO

DROP FULLTEXT INDEX ON fti_table_t5;
GO

DROP TABLE IF EXISTS fti_table_t5;
GO

DROP FULLTEXT INDEX ON fti_table_t6;
GO

DROP TABLE IF EXISTS fti_table_t6;
GO

DROP FULLTEXT INDEX ON fti_table_t7;
GO

DROP TABLE IF EXISTS fti_table_t7;
GO

DROP FULLTEXT INDEX ON fti_schema_s1.fti_table_t8;
GO

DROP TABLE IF EXISTS fti_schema_s1.fti_table_t8;
GO

DROP SCHEMA IF EXISTS fti_schema_s1;
GO

DROP FULLTEXT INDEX ON fti_schema_s2.fti_table_t8;
GO

DROP TABLE IF EXISTS fti_schema_s2.fti_table_t8;
GO

DROP SCHEMA IF EXISTS fti_schema_s2;
GO

-- should throw error as there is no index in the table
DROP FULLTEXT INDEX ON fti_table_no_ix;
GO

DROP TABLE IF EXISTS fti_table_no_ix;
GO

DROP TABLE IF EXISTS fti_table_unsupported;
GO

DROP VIEW IF EXISTS fti_prepare_v1;
GO

DROP PROCEDURE IF EXISTS fti_prepare_p1;
GO

DROP FUNCTION IF EXISTS fti_prepare_f1;
GO

-- disable FULLTEXT
SELECT set_config('role', 'jdbc_user', false);
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO