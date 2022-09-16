USE sys_indexes_vu_prepare_db1
GO

USE master
GO

DROP INDEX sys_indexes_vu_prepare_i1 ON sys_indexes_vu_prepare_t1;
DROP INDEX sys_indexes_vu_prepare_i1a ON sys_indexes_vu_prepare_t1;
GO

DROP TABLE IF EXISTS sys_indexes_vu_prepare_t_unique
GO

DROP TABLE IF EXISTS sys_indexes_vu_prepare_t1
GO

DROP TABLE IF EXISTS sys_indexes_vu_prepare_t2
GO

DROP TABLE IF EXISTS sys_indexes_vu_prepare_t_fkey
GO

DROP TABLE IF EXISTS sys_indexes_vu_prepare_t_pkey
GO

DROP TABLE IF EXISTS sys_indexes_vu_prepare_t_unique
GO

DROP DATABASE sys_indexes_vu_prepare_db1
GO