CREATE DATABASE babel_5010_vu_prepare_db1;
GO

USE babel_5010_vu_prepare_db1;
GO

CREATE TABLE babel_5010_temp_table (
    TABLE_QUALIFIER sys.sysname,
    TABLE_OWNER sys.nvarchar(384),
    TABLE_NAME sys.nvarchar(384),
    TABLE_TYPE sys.nvarchar(100),
    REMARKS sys.bit
);
GO

CREATE TABLE babel_5010_vu_prepare_t1(a INT)
GO

CREATE TABLE babel_5010_vu_prepare_t2(a INT)
GO

CREATE VIEW babel_5010_vu_prepare_v1 AS SELECT 1;
GO

CREATE VIEW babel_5010_vu_prepare_v2 AS SELECT 1;
GO

USE master;
GO