-- enable FULLTEXT
SELECT set_config('role', 'jdbc_user', false);
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

CREATE DATABASE fti_test_db;
GO

USE fti_test_db;
GO

-- Index creation on different character data type columns
CREATE TABLE fti_table_t1(id int not null, a text);
GO

-- should throw syntax error for NULL index name
CREATE FULLTEXT INDEX ON fti_table_t1(a) KEY INDEX NULL;
GO

CREATE UNIQUE INDEX IX_t1_a ON fti_table_t1(id);
GO

CREATE FULLTEXT INDEX ON fti_table_t1(a) KEY INDEX IX_t1_a;
GO

CREATE TABLE fti_table_t2(id int not null, b char(10));
GO

CREATE UNIQUE INDEX IX_t2_b ON fti_table_t2(id);
GO

CREATE FULLTEXT INDEX ON fti_table_t2(b) KEY INDEX IX_t2_b;
GO

CREATE TABLE fti_table_t3(id int not null, c varchar(10));
GO

CREATE UNIQUE INDEX IX_t3_c ON fti_table_t3(id);
GO

CREATE FULLTEXT INDEX ON fti_table_t3(c) KEY INDEX IX_t3_c;
GO

CREATE TABLE fti_table_t4(id int not null, d nvarchar(10));
GO

CREATE UNIQUE INDEX IX_t4_d ON fti_table_t4(id);
GO

CREATE FULLTEXT INDEX ON fti_table_t4(d) KEY INDEX IX_t4_d;
GO

CREATE TABLE fti_table_t5(id int not null, e nchar(10));
GO

CREATE UNIQUE INDEX IX_t5_e ON fti_table_t5(id);
GO

CREATE FULLTEXT INDEX ON fti_table_t5(e) KEY INDEX IX_t5_e;
GO

CREATE TABLE fti_table_t6(id int not null, f ntext);
GO

CREATE UNIQUE INDEX IX_t6_f ON fti_table_t6(id);
GO

CREATE FULLTEXT INDEX ON fti_table_t6(f) KEY INDEX IX_t6_f;
GO

CREATE TABLE fti_table_t7(id int not null, a1 text, b1 char(10), c1 varchar(10));
GO

CREATE UNIQUE INDEX IX_t7_a1b1c1 ON fti_table_t7(id);
GO

-- multi column index creation
CREATE FULLTEXT INDEX ON fti_table_t7(a1, b1, c1) KEY INDEX IX_t7_a1b1c1;
GO

-- checking if the indexes are created correctly
CREATE VIEW fti_prepare_v1 AS (SELECT indexname FROM pg_indexes WHERE tablename='fti_table_t1');
GO

CREATE PROCEDURE fti_prepare_p1 AS (SELECT indexname FROM pg_indexes WHERE tablename='fti_table_t2');
GO

CREATE FUNCTION fti_prepare_f1()
RETURNS NVARCHAR(MAX) AS
BEGIN
    DECLARE @indexName NVARCHAR(MAX);
    SELECT @indexName= indexname 
    FROM pg_indexes 
    WHERE tablename='fti_table_t3';

    RETURN @indexName;
END
GO

-- Creating index in a new schema
CREATE SCHEMA fti_schema_s1;
GO

CREATE TABLE fti_schema_s1.fti_table_t8(id int not null, a text, b text);
GO

CREATE UNIQUE INDEX IX_s1_t8_a ON fti_schema_s1.fti_table_t8(id);
GO

CREATE FULLTEXT INDEX ON fti_schema_s1.fti_table_t8(a) KEY INDEX IX_s1_t8_a;
GO

CREATE SCHEMA fti_schema_s2;
GO

CREATE TABLE fti_schema_s2.fti_table_t8(id int not null, a text, b text);
GO

CREATE UNIQUE INDEX IX_s2_t8_a ON fti_schema_s2.fti_table_t8(id);
GO

-- Case for same table name on different schemas
CREATE FULLTEXT INDEX ON fti_schema_s2.fti_table_t8(a) KEY INDEX IX_s2_t8_a;
GO

-- Table for testing dropping non-existent index, should throw error on dropping
CREATE TABLE fti_table_no_ix(id int not null, a text)
GO

-- Table for testing unsupported options
CREATE TABLE fti_table_unsupported(id int not null, a text)
GO

CREATE UNIQUE INDEX ix_unsupported_fti ON fti_table_unsupported(id);
GO

-- disable FULLTEXT
SELECT set_config('role', 'jdbc_user', false);
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO