-- parallel_query_expected

-- deprecated escape hatch should not throw an error but print a simple message
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
CREATE TABLE babel_3571_t (id INT)
GO

EXEC sp_babelfish_configure 'escape_hatch_unique_constraint', 'ignore';
INSERT INTO babel_3571_t VALUES (1);
GO

CREATE PROC babel_3571_p
AS
BEGIN
    EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore', 'server';
    INSERT INTO babel_3571_t VALUES (1);
END
GO

EXEC babel_3571_p
GO

SELECT * FROM babel_3571_t
GO

DROP PROC babel_3571_p
GO

DROP TABLE babel_3571_t
GO

SELECT set_config('babelfishpg_tsql.explain_timing', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_summary', 'off', false)
GO

CREATE TABLE babel_3571_1 (id1 INT UNIQUE, id2 VARCHAR(30) UNIQUE, id3 VARBINARY(30))
GO
CREATE TABLE babel_3571_2 (id1 INT, id2 VARCHAR(30), id3 VARBINARY(30), UNIQUE(id1, id2))
GO
CREATE TABLE babel_3571_3 (id1 INT, id2 VARCHAR(30), id3 VARBINARY(30))
GO
CREATE UNIQUE INDEX babel_3571_3_unique_idx ON babel_3571_3(id1, id2)
GO

-- table 1 id1 & id2 should be individually unique

INSERT INTO babel_3571_1 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_3571_1 VALUES (NULL, 'random', 0x9999)
GO

INSERT INTO babel_3571_1 VALUES (9999, NULL, 0x9999)
GO

INSERT INTO babel_3571_1 VALUES (9999, 'random', NULL)
GO

-- table 2 Combination of id1 & id2 should be unique

INSERT INTO babel_3571_2 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_3571_2 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_3571_2 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_3571_2 VALUES (NULL, NULL, NULL)
GO

INSERT INTO babel_3571_2 VALUES (NULL, NULL, 0x9999)
GO

-- table 3 Combination of id1 & id2 should be unique

INSERT INTO babel_3571_3 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_3571_3 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_3571_3 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_3571_3 VALUES (NULL, NULL, NULL)
GO

INSERT INTO babel_3571_3 VALUES (NULL, NULL, 0x9999)
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_3571%'
ORDER BY indexdef
GO

SET BABELFISH_STATISTICS PROFILE ON;
SELECT set_config('enable_seqscan', 'off', false);
SELECT set_config('enable_bitmapscan', 'off', false);
GO
SELECT * FROM babel_3571_1 ORDER BY id1
GO
SELECT * FROM babel_3571_2 ORDER BY id1
GO
SELECT * FROM babel_3571_3 ORDER BY id1
GO
SET BABELFISH_STATISTICS PROFILE OFF;
SELECT set_config('enable_seqscan', 'on', false);
SELECT set_config('enable_bitmapscan', 'on', false);
GO

DROP TABLE babel_3571_1, babel_3571_2, babel_3571_3
GO

-- Repeat same tests but with more table/column specification

CREATE TABLE babel_3571_1 (id1 INT NOT NULL UNIQUE NULL, id2 VARCHAR(30) UNIQUE, id3 VARBINARY(30) PRIMARY KEY)
GO
CREATE TABLE babel_3571_1 (id1 INT NOT NULL UNIQUE, id2 VARCHAR(30) UNIQUE NOT NULL, id3 VARBINARY(30) PRIMARY KEY)
GO
CREATE TABLE babel_3571_2 (id1 INT, id2 VARCHAR(30), id3 VARBINARY(30), UNIQUE(id1 ASC, id2 DESC), PRIMARY KEY (id3))
GO
CREATE TABLE babel_3571_3 (id1 INT, id2 VARCHAR(30), id3 VARBINARY(30))
GO
ALTER TABLE babel_3571_3 ADD CONSTRAINT babel_3571_3_pkey PRIMARY KEY (id3)
GO
ALTER TABLE babel_3571_3 ADD CONSTRAINT babel_3571_3_unique_idx UNIQUE (id1 DESC, id2 ASC)
GO

-- table 1 id1 & id2 should be individually unique

INSERT INTO babel_3571_1 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (2, '', 0x0002), (0, 'something', 0x0003)
GO

INSERT INTO babel_3571_1 VALUES (NULL, 'random', 0x9999)
GO

INSERT INTO babel_3571_1 VALUES (9999, NULL, 0x9999)
GO

INSERT INTO babel_3571_1 VALUES (9999, 'random', NULL)
GO

INSERT INTO babel_3571_1 VALUES (9999, 'random', 0x1234)
GO

INSERT INTO babel_3571_1 VALUES (8888, 'random_again', 0x1234)
GO

-- table 2 Combination of id1 & id2 should be unique

INSERT INTO babel_3571_2 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', 0x0002), (0, NULL, 0x0003)
GO

INSERT INTO babel_3571_2 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_3571_2 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_3571_2 VALUES (1234, 'somethingrandom', NULL)
GO

INSERT INTO babel_3571_2 VALUES (1234, 'somethingrandom', 0x1234)
GO

INSERT INTO babel_3571_2 VALUES (4321, 'somethingrandomagain', 0x1234)
GO

-- table 3 Combination of id1 & id2 should be unique

INSERT INTO babel_3571_3 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', 0x0002), (0, NULL, 0x0003)
GO

INSERT INTO babel_3571_3 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_3571_3 VALUES (9999, NULL, 0x9999)
GO

INSERT INTO babel_3571_3 VALUES (0, 'somethingagain', NULL)
GO

INSERT INTO babel_3571_3 VALUES (0, 'somethingagain', 0x1234)
GO

INSERT INTO babel_3571_3 VALUES (8888, 'newsomething', 0x1234)
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_3571%'
ORDER BY indexdef
GO

SET BABELFISH_STATISTICS PROFILE ON;
SELECT set_config('enable_seqscan', 'off', false);
SELECT set_config('enable_bitmapscan', 'off', false);
GO
SELECT * FROM babel_3571_1 ORDER BY id1
GO
SELECT * FROM babel_3571_2 ORDER BY id1
GO
SELECT * FROM babel_3571_3 ORDER BY id1
GO
SET BABELFISH_STATISTICS PROFILE OFF;
SELECT set_config('enable_seqscan', 'on', false);
SELECT set_config('enable_bitmapscan', 'on', false);
GO

-- drop constraint
ALTER TABLE babel_3571_3 DROP CONSTRAINT babel_3571_3_unique_idx
GO

-- duplicate values should now accepted in col1 & col2
INSERT INTO babel_3571_3 VALUES (NULL, NULL, 0X91)
INSERT INTO babel_3571_3 VALUES (1, '+a', 0X92)
GO

-- primary key col should still block duplicates
INSERT INTO babel_3571_3 VALUES (NULL, NULL, 0X0001)
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_3571%'
ORDER BY indexdef
GO

-- DROP primary keys as well
ALTER TABLE babel_3571_3 DROP CONSTRAINT babel_3571_3_pkey

-- duplicates should work in col3 now
INSERT INTO babel_3571_3 VALUES (NULL, NULL, 0X0001)
GO

DROP TABLE babel_3571_1, babel_3571_2, babel_3571_3
GO


-- CREATE TABLE WITH CONSTRAINT -- DROP COLUMN -- ADD COLUMN WITHOUT CONTRAINT

CREATE TABLE babel_3571_1 (id1 INT UNIQUE, id2 int)
GO
CREATE TABLE babel_3571_2 (id1 INT, UNIQUE(id1), id2 int)
GO
CREATE TABLE babel_3571_3 (id1 INT, id2 int)
GO
CREATE UNIQUE INDEX babel_3571_3_unique_idx ON babel_3571_3(id1)
GO

ALTER TABLE babel_3571_1 DROP COLUMN id1;
ALTER TABLE babel_3571_2 DROP COLUMN id1;
ALTER TABLE babel_3571_3 DROP COLUMN id1;
GO

ALTER TABLE babel_3571_1 ADD id1 INT;
ALTER TABLE babel_3571_2 ADD id1 INT;
ALTER TABLE babel_3571_3 ADD id1 INT;
GO

INSERT INTO babel_3571_1 VALUES (1,1), (1,1), (NULL, NULL), (NULL, NULL);
INSERT INTO babel_3571_2 VALUES (1,1), (1,1), (NULL, NULL), (NULL, NULL);
INSERT INTO babel_3571_3 VALUES (1,1), (1,1), (NULL, NULL), (NULL, NULL);
GO

DROP TABLE babel_3571_1, babel_3571_2, babel_3571_3
GO

-- Test with identity column
CREATE TABLE babel_3571_1 (id1 INT IDENTITY UNIQUE, id2 int)
GO
CREATE TABLE babel_3571_2 (id1 INT IDENTITY, UNIQUE(id1), id2 int)
GO
CREATE TABLE babel_3571_3 (id1 INT IDENTITY, id2 int)
GO
CREATE UNIQUE INDEX babel_3571_3_unique_idx ON babel_3571_3(id1)
GO

INSERT INTO babel_3571_1 VALUES (1), (2), (3)
INSERT INTO babel_3571_2 VALUES (1), (2), (3)
INSERT INTO babel_3571_3 VALUES (1), (2), (3)
GO

SET IDENTITY_INSERT dbo.babel_3571_1 ON;
GO

-- shoudl fail
INSERT INTO babel_3571_1 (id1, id2) VALUES (1,10)
GO
INSERT INTO babel_3571_1 (id1, id2) VALUES (NULL,10)
GO

-- should insert
INSERT INTO babel_3571_1 (id1, id2) VALUES (4,10)
INSERT INTO babel_3571_1 (id1, id2) VALUES (5, NULL)
GO

SET IDENTITY_INSERT dbo.babel_3571_1 OFF;
GO

SET IDENTITY_INSERT dbo.babel_3571_2 ON;
GO

-- shoudl fail
INSERT INTO babel_3571_2 (id1, id2) VALUES (1,10)
GO
INSERT INTO babel_3571_2 (id1, id2) VALUES (NULL,10)
GO

-- should insert
INSERT INTO babel_3571_2 (id1, id2) VALUES (4,10)
INSERT INTO babel_3571_2 (id1, id2) VALUES (5, NULL)
GO

SET IDENTITY_INSERT dbo.babel_3571_2 OFF;
GO

SET IDENTITY_INSERT dbo.babel_3571_3 ON;
GO

-- shoudl fail
INSERT INTO babel_3571_3 (id1, id2) VALUES (1,10)
GO
INSERT INTO babel_3571_3 (id1, id2) VALUES (NULL,10)
GO

-- should insert
INSERT INTO babel_3571_3 (id1, id2) VALUES (4,10)
INSERT INTO babel_3571_3 (id1, id2) VALUES (5, NULL)
GO

SET IDENTITY_INSERT dbo.babel_3571_3 OFF;
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_3571%'
ORDER BY indexdef
GO

SET BABELFISH_STATISTICS PROFILE ON;
SELECT set_config('enable_seqscan', 'off', false);
SELECT set_config('enable_bitmapscan', 'off', false);
GO
SELECT * FROM babel_3571_1 ORDER BY id1
GO
SELECT * FROM babel_3571_2 ORDER BY id1
GO
SELECT * FROM babel_3571_3 ORDER BY id1
GO
SET BABELFISH_STATISTICS PROFILE OFF;
SELECT set_config('enable_seqscan', 'on', false);
SELECT set_config('enable_bitmapscan', 'on', false);
GO

DROP TABLE babel_3571_1, babel_3571_2, babel_3571_3
GO
