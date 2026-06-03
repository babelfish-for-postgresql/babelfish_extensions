-- Verify: Test PERSISTED computed columns with deterministic STABLE functions

SET QUOTED_IDENTIFIER ON
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
GO

-- DDL: Should FAIL cases

-- CONVERT without explicit style (non-deterministic)
CREATE TABLE pcc_bad1 (d DATE, c AS CONVERT(VARCHAR(10), d) PERSISTED)
GO

-- GETDATE (volatile)
CREATE TABLE pcc_bad2 (c AS GETDATE() PERSISTED)
GO

-- NEWID (volatile)
CREATE TABLE pcc_bad3 (c AS NEWID() PERSISTED)
GO

-- QUOTED_IDENTIFIER OFF at CREATE time
SET QUOTED_IDENTIFIER OFF
GO
CREATE TABLE pcc_bad4 (a VARCHAR(10), b VARCHAR(10), c AS (a+b) PERSISTED)
GO
SET QUOTED_IDENTIFIER ON
GO

-- CONCAT_NULL_YIELDS_NULL OFF at CREATE time
SET CONCAT_NULL_YIELDS_NULL OFF
GO
CREATE TABLE pcc_bad5 (a VARCHAR(10), b VARCHAR(10), c AS (a+b) PERSISTED)
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- DML GUC enforcement: INSERT / UPDATE / DELETE

-- INSERT with correct GUCs (should PASS)
INSERT INTO pcc_concat (a, b) VALUES ('New', 'Row')
GO

-- INSERT with CONCAT_NULL_YIELDS_NULL OFF (should FAIL)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
INSERT INTO pcc_concat (a, b) VALUES ('Bad', 'Insert')
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- UPDATE with CONCAT_NULL_YIELDS_NULL OFF (should FAIL)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
UPDATE pcc_concat SET a = 'Changed' WHERE id = 1
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- DELETE with CONCAT_NULL_YIELDS_NULL OFF (should FAIL)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
DELETE FROM pcc_concat WHERE id = 3
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- INSERT with QUOTED_IDENTIFIER OFF (should FAIL)
SET QUOTED_IDENTIFIER OFF
GO
INSERT INTO pcc_concat (a, b) VALUES ('qi', 'off')
GO
SET QUOTED_IDENTIFIER ON
GO

-- Multiple GUCs wrong simultaneously (should FAIL with multiple GUCs listed)
SET QUOTED_IDENTIFIER OFF
SET CONCAT_NULL_YIELDS_NULL OFF
GO
INSERT INTO pcc_concat (a, b) VALUES ('multi', 'guc')
GO
SET QUOTED_IDENTIFIER ON
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- DML on table WITHOUT computed cols (should PASS regardless of GUC)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
INSERT INTO pcc_normal VALUES (2, 'no_computed_col')
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- SELECT re-evaluation

-- SELECT with correct GUCs (uses stored values)
SELECT id, a, b, c FROM pcc_concat ORDER BY id
GO

-- SELECT with CONCAT_NULL_YIELDS_NULL OFF (re-evaluates)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT id, a, b, c FROM pcc_concat ORDER BY id
GO

-- WHERE clause uses re-evaluated value
SELECT id, a, b, c FROM pcc_concat WHERE c = 'X'
GO

-- COUNT with re-evaluation (all rows non-null with GUC OFF)
SELECT COUNT(*) AS cnt FROM pcc_concat WHERE c IS NOT NULL
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- COUNT with correct GUC (NULL rows stay NULL)
SELECT COUNT(*) AS cnt FROM pcc_concat WHERE c IS NOT NULL
GO

-- Verify all whitelisted function outputs
SELECT * FROM pcc_convert ORDER BY id
GO

SELECT * FROM pcc_eomonth ORDER BY id
GO

SELECT * FROM pcc_cast ORDER BY id
GO

SELECT * FROM pcc_concatws ORDER BY id
GO

SELECT * FROM pcc_datetrunc ORDER BY id
GO

SELECT * FROM pcc_castbig ORDER BY id
GO

SELECT * FROM pcc_castsmall ORDER BY id
GO

SELECT * FROM pcc_conv_money ORDER BY id
GO

-- Query plan verification (BABELFISH_SHOWPLAN_ALL)
SELECT set_config('max_parallel_workers_per_gather', '0', false)
GO

-- Plan with GUC=ON (no re-evaluation, uses stored column)
SET BABELFISH_SHOWPLAN_ALL ON
GO
SELECT COUNT(*) FROM pcc_concat WHERE c IS NOT NULL
GO
SET BABELFISH_SHOWPLAN_ALL OFF
GO

-- Plan with GUC=OFF (expression substitution, re-evaluation)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SET BABELFISH_SHOWPLAN_ALL ON
GO
SELECT COUNT(*) FROM pcc_concat WHERE c IS NOT NULL
GO
SET BABELFISH_SHOWPLAN_ALL OFF
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- Index on computed column: query plan with and without re-evaluation

-- Force index usage so the plan is deterministic
SELECT set_config('enable_seqscan', 'off', false)
GO

-- Plan with GUC=ON (index on stored column can be used)
SET BABELFISH_SHOWPLAN_ALL ON
GO
SELECT id FROM pcc_bulk WHERE c = 'A1B1'
GO
SET BABELFISH_SHOWPLAN_ALL OFF
GO

-- Plan with GUC=OFF 
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SET BABELFISH_SHOWPLAN_ALL ON
GO
SELECT id FROM pcc_bulk WHERE c = 'A1B1'
GO
SET BABELFISH_SHOWPLAN_ALL OFF
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

SELECT set_config('enable_seqscan', 'on', false)
GO

-- Index correctness: same point query returns same row regardless of GUC
SELECT id, c FROM pcc_bulk WHERE c = 'A1B1'
GO
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT id, c FROM pcc_bulk WHERE c = 'A1B1'
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- COUNT non-null with GUC=ON
SELECT COUNT(*) AS cnt FROM pcc_bulk WHERE c IS NOT NULL
GO

-- COUNT non-null with GUC=OFF
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT COUNT(*) AS cnt FROM pcc_bulk WHERE c IS NOT NULL
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- Views

-- View with correct GUCs
SELECT COUNT(*) AS cnt FROM pcc_view WHERE c IS NOT NULL
GO

-- View with wrong GUC (re-evaluates through view)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT COUNT(*) AS cnt FROM pcc_view WHERE c IS NOT NULL
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- CTEs

-- CTE with correct GUCs
;WITH cte AS (SELECT c FROM pcc_concat WHERE c IS NOT NULL)
SELECT COUNT(*) AS cnt FROM cte
GO

-- CTE with wrong GUC (re-evaluates)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
;WITH cte AS (SELECT c FROM pcc_concat WHERE c IS NOT NULL)
SELECT COUNT(*) AS cnt FROM cte
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- INSERT...SELECT

CREATE TABLE pcc_dst (val VARCHAR(50))
GO

-- INSERT...SELECT with correct GUCs
INSERT INTO pcc_dst SELECT c FROM pcc_concat WHERE a = 'Hello'
SELECT * FROM pcc_dst
DELETE FROM pcc_dst
GO

-- INSERT...SELECT with wrong GUC (pcc_dst has no computed cols so INSERT passes)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
INSERT INTO pcc_dst SELECT c FROM pcc_concat WHERE a = 'X'
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO
SELECT * FROM pcc_dst
DELETE FROM pcc_dst
GO

-- JOINs

-- Self-JOIN with correct GUCs
SELECT t1.id, t1.c, t2.id AS id2, t2.c AS c2
FROM pcc_concat t1 JOIN pcc_concat t2 ON t1.c = t2.c
WHERE t1.id < t2.id
ORDER BY t1.id
GO

-- Self-JOIN with wrong GUC
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT t1.id, t1.c, t2.id AS id2, t2.c AS c2
FROM pcc_concat t1 JOIN pcc_concat t2 ON t1.c = t2.c
WHERE t1.id < t2.id
ORDER BY t1.id
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- JOIN between two different tables with computed cols
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT e.full_name, m.c, m.d
FROM pcc_concatfn e JOIN pcc_multi m ON e.first_name = m.a
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- Subqueries

SET CONCAT_NULL_YIELDS_NULL OFF
GO

-- IN subquery
SELECT id, a, b, c FROM pcc_concat WHERE c IN (SELECT c FROM pcc_concat WHERE a = 'X')
GO

-- Scalar subquery
SELECT a, (SELECT MAX(c) FROM pcc_concat) AS max_c FROM pcc_concat WHERE a = 'X'
GO

-- EXISTS subquery
SELECT t1.id, t1.c FROM pcc_concat t1
WHERE EXISTS (SELECT 1 FROM pcc_multi t2 WHERE t1.c = t2.c)
GO

SET CONCAT_NULL_YIELDS_NULL ON
GO

-- UNION / GROUP BY / HAVING / ORDER BY

SET CONCAT_NULL_YIELDS_NULL OFF
GO

-- UNION
SELECT c FROM pcc_concat WHERE a = 'X'
UNION
SELECT c FROM pcc_concat WHERE a = 'Hello'
GO

-- GROUP BY computed column
SELECT c, COUNT(*) AS cnt FROM pcc_concat GROUP BY c ORDER BY c
GO

-- HAVING on computed column
SELECT c, COUNT(*) AS cnt FROM pcc_concat GROUP BY c HAVING c IS NOT NULL ORDER BY c
GO

-- ORDER BY computed column
SELECT id, a, b, c FROM pcc_concat ORDER BY c
GO

SET CONCAT_NULL_YIELDS_NULL ON
GO

-- Foreign key interactions

-- FK violation (value doesn't exist)
INSERT INTO pcc_fk_child VALUES (2, 99)
GO

-- FK child INSERT with wrong GUC (parent has computed col)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
INSERT INTO pcc_fk_child VALUES (3, 3)
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- FK child UPDATE with wrong GUC
SET CONCAT_NULL_YIELDS_NULL OFF
GO
UPDATE pcc_fk_child SET parent_c = 10 WHERE id = 1
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- FK child DELETE with wrong GUC
SET CONCAT_NULL_YIELDS_NULL OFF
GO
DELETE FROM pcc_fk_child WHERE id = 1
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- SELECT from FK child with wrong GUC (should PASS — child has no computed cols)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT * FROM pcc_fk_child
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- Bulk load re-evaluation

-- COUNT with GUC=ON 
SELECT COUNT(*) AS cnt FROM pcc_bulk WHERE c IS NOT NULL
GO

-- COUNT with GUC=OFF 
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT COUNT(*) AS cnt FROM pcc_bulk WHERE c IS NOT NULL
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- Partition tables
CREATE PARTITION FUNCTION pcc_part_func (INT)
AS RANGE RIGHT FOR VALUES (10, 20, 30, 40)
GO

CREATE PARTITION SCHEME pcc_part_scheme
AS PARTITION pcc_part_func ALL TO ([PRIMARY])
GO

-- Partitioned table with PERSISTED computed col (not partition key)
CREATE TABLE pcc_part_persisted (
    id INT,
    a INT,
    b INT,
    c AS (a + b) PERSISTED
) ON pcc_part_scheme(id)
GO

INSERT INTO pcc_part_persisted (id, a, b) VALUES (5, 1, 2), (15, 3, 4), (25, 5, 6), (35, 7, 8), (45, 9, 10)
GO

SELECT * FROM pcc_part_persisted ORDER BY id
GO

-- Partitioned table with CONCAT for re-evaluation
CREATE TABLE pcc_part_concat (
    id INT,
    first_name VARCHAR(20),
    last_name VARCHAR(20),
    full_name AS (first_name + ' ' + last_name) PERSISTED
) ON pcc_part_scheme(id)
GO

INSERT INTO pcc_part_concat (id, first_name, last_name) VALUES
    (5, 'Alice', 'Adams'), (15, 'Bob', NULL), (25, 'Charlie', 'Clark'),
    (35, 'David', 'Davis'), (45, 'Eve', 'Evans')
GO

-- SELECT with correct GUCs on partitioned table
SELECT * FROM pcc_part_concat ORDER BY id
GO

-- SELECT with wrong GUC on partitioned table (re-evaluates)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT * FROM pcc_part_concat ORDER BY id
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- COUNT re-evaluation on partitioned table
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT COUNT(*) AS non_null_cnt FROM pcc_part_concat WHERE full_name IS NOT NULL
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO
SELECT COUNT(*) AS non_null_cnt FROM pcc_part_concat WHERE full_name IS NOT NULL
GO

-- INSERT with wrong GUC into partitioned table (should FAIL)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
INSERT INTO pcc_part_persisted (id, a, b) VALUES (50, 11, 12)
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- DELETE with wrong GUC on partitioned table (should FAIL)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
DELETE FROM pcc_part_persisted WHERE id = 5
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- Verify data unchanged after failed DML on partitioned table
SELECT * FROM pcc_part_persisted ORDER BY id
GO

-- Partitioned table with CONVERT
CREATE TABLE pcc_part_convert (
    id INT,
    d DATE,
    formatted AS CONVERT(VARCHAR(10), d, 101) PERSISTED
) ON pcc_part_scheme(id)
GO

INSERT INTO pcc_part_convert (id, d) VALUES (5, '2024-01-15'), (15, '2024-06-20'), (25, '2024-12-25')
GO

SELECT * FROM pcc_part_convert ORDER BY id
GO

-- ALTER TABLE ADD PERSISTED computed col to partitioned table
CREATE TABLE pcc_part_base (
    id INT,
    x INT,
    y INT
) ON pcc_part_scheme(id)
GO

INSERT INTO pcc_part_base VALUES (5, 10, 20), (15, 30, 40)
GO

ALTER TABLE pcc_part_base ADD z AS (x + y) PERSISTED
GO

SELECT * FROM pcc_part_base ORDER BY id
GO

-- Drop partition tables, scheme and function
DROP TABLE pcc_part_base
GO
DROP TABLE pcc_part_convert
GO
DROP TABLE pcc_part_concat
GO
DROP TABLE pcc_part_persisted
GO
DROP PARTITION SCHEME pcc_part_scheme
GO
DROP PARTITION FUNCTION pcc_part_func
GO

-- ALTER TABLE ADD computed column
ALTER TABLE pcc_concat ADD d AS (b + a) PERSISTED
GO
SELECT id, a, b, c, d FROM pcc_concat ORDER BY id
GO

-- ALTER TABLE ADD computed col with wrong GUC (should FAIL)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
ALTER TABLE pcc_concat ADD e AS (a + 'suffix') PERSISTED
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- DROP computed column
ALTER TABLE pcc_concat DROP COLUMN d
GO

-- Verify data unchanged after all failed DMLs
SELECT id, a, b, c FROM pcc_concat ORDER BY id
GO
