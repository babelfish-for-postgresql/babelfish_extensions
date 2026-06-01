-- Test PERSISTED computed columns with deterministic STABLE functions

SET QUOTED_IDENTIFIER ON
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
GO

-- DDL: Table creation with whitelisted functions

-- String concatenation via + operator
CREATE TABLE pcc_concat (
    id INT IDENTITY(1,1),
    a VARCHAR(20),
    b VARCHAR(20),
    c AS (a + b) PERSISTED
)
GO

-- CONVERT with explicit style
CREATE TABLE pcc_convert (
    id INT IDENTITY(1,1),
    d DATE,
    formatted AS CONVERT(VARCHAR(10), d, 101) PERSISTED
)
GO

-- Multiple computed columns
CREATE TABLE pcc_multi (
    id INT,
    a VARCHAR(20),
    b VARCHAR(20),
    c AS (a + b) PERSISTED,
    d AS (b + a) PERSISTED
)
GO

-- CONCAT function
CREATE TABLE pcc_concatfn (
    id INT IDENTITY(1,1),
    first_name VARCHAR(20),
    last_name VARCHAR(20),
    full_name AS CONCAT(first_name, ' ', last_name) PERSISTED
)
GO

-- CAST to INT
CREATE TABLE pcc_cast (
    id INT IDENTITY(1,1),
    val DECIMAL(10,4),
    int_val AS CAST(val AS INT) PERSISTED
)
GO

-- EOMONTH
CREATE TABLE pcc_eomonth (
    id INT IDENTITY(1,1),
    d DATE,
    eom AS EOMONTH(d) PERSISTED
)
GO

-- CONCAT_WS
CREATE TABLE pcc_concatws (
    id INT IDENTITY(1,1),
    a VARCHAR(20),
    b VARCHAR(20),
    c VARCHAR(20),
    combined AS CONCAT_WS('-', a, b, c) PERSISTED
)
GO

-- DATETRUNC
CREATE TABLE pcc_datetrunc (
    id INT IDENTITY(1,1),
    dt DATETIME,
    truncated AS DATETRUNC(month, dt) PERSISTED
)
GO

-- CAST to BIGINT
CREATE TABLE pcc_castbig (
    id INT IDENTITY(1,1),
    val DECIMAL(18,4),
    big_val AS CAST(val AS BIGINT) PERSISTED
)
GO

-- CAST to SMALLINT
CREATE TABLE pcc_castsmall (
    id INT IDENTITY(1,1),
    val DECIMAL(5,2),
    small_val AS CAST(val AS SMALLINT) PERSISTED
)
GO

-- CONVERT money with explicit style
CREATE TABLE pcc_conv_money (
    id INT IDENTITY(1,1),
    m MONEY,
    formatted AS CONVERT(VARCHAR(30), m, 1) PERSISTED
)
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

-- Insert test data

INSERT INTO pcc_concat (a, b) VALUES ('Hello', 'World')
INSERT INTO pcc_concat (a, b) VALUES ('X', NULL)
INSERT INTO pcc_concat (a, b) VALUES ('A', 'B')
INSERT INTO pcc_concat (a, b) VALUES (NULL, 'test')
GO

INSERT INTO pcc_convert (d) VALUES ('2024-01-15'), ('2024-12-25')
GO

INSERT INTO pcc_multi (id, a, b) VALUES (1, 'Foo', 'Bar'), (2, 'P', NULL)
GO

INSERT INTO pcc_concatfn (first_name, last_name) VALUES ('John', 'Doe'), ('Jane', NULL)
GO

INSERT INTO pcc_cast (val) VALUES (123.4567), (99.9)
GO

INSERT INTO pcc_eomonth (d) VALUES ('2024-01-15'), ('2024-02-10')
GO

INSERT INTO pcc_concatws (a, b, c) VALUES ('one', 'two', 'three'), ('x', NULL, 'z')
GO

INSERT INTO pcc_datetrunc (dt) VALUES ('2024-03-15 10:30:45'), ('2024-07-22 08:15:00')
GO

INSERT INTO pcc_castbig (val) VALUES (123456.7890), (999999.9)
GO

INSERT INTO pcc_castsmall (val) VALUES (123.45), (32.1)
GO

INSERT INTO pcc_conv_money (m) VALUES (1234.56), (99999.99)
GO

-- Normal table (no computed cols)
CREATE TABLE pcc_normal (id INT, val VARCHAR(50))
GO
INSERT INTO pcc_normal VALUES (1, 'test')
GO

-- View on pcc_concat
CREATE VIEW pcc_view AS SELECT id, a, b, c FROM pcc_concat
GO

-- FK parent with persisted computed col
CREATE TABLE pcc_fk_parent (
    a INT NOT NULL,
    b INT NOT NULL,
    c AS (a + b) PERSISTED UNIQUE
)
GO

-- FK child referencing parent
CREATE TABLE pcc_fk_child (
    id INT PRIMARY KEY,
    parent_c INT,
    CONSTRAINT fk_pcc_child FOREIGN KEY (parent_c) REFERENCES pcc_fk_parent(c)
)
GO

INSERT INTO pcc_fk_parent (a, b) VALUES (1, 2), (5, 5)
INSERT INTO pcc_fk_child VALUES (1, 3)
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

-- Self-JOIN with wrong GUC (re-evaluates both sides)
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

-- Bulk load re-evaluation (20 rows: 10 non-null, 10 null)

CREATE TABLE pcc_bulk (
    id INT,
    a VARCHAR(20),
    b VARCHAR(20),
    c AS (a + b) PERSISTED
)
GO

-- 10 non-null rows
INSERT INTO pcc_bulk (id, a, b) VALUES (1, 'A1', 'B1')
INSERT INTO pcc_bulk (id, a, b) VALUES (2, 'A2', 'B2')
INSERT INTO pcc_bulk (id, a, b) VALUES (3, 'A3', 'B3')
INSERT INTO pcc_bulk (id, a, b) VALUES (4, 'A4', 'B4')
INSERT INTO pcc_bulk (id, a, b) VALUES (5, 'A5', 'B5')
INSERT INTO pcc_bulk (id, a, b) VALUES (6, 'A6', 'B6')
INSERT INTO pcc_bulk (id, a, b) VALUES (7, 'A7', 'B7')
INSERT INTO pcc_bulk (id, a, b) VALUES (8, 'A8', 'B8')
INSERT INTO pcc_bulk (id, a, b) VALUES (9, 'A9', 'B9')
INSERT INTO pcc_bulk (id, a, b) VALUES (10, 'A10', 'B10')
GO

-- 10 null rows (c = NULL because b is NULL and CONCAT_NULL_YIELDS_NULL ON)
INSERT INTO pcc_bulk (id, a, b) VALUES (11, 'X11', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (12, 'X12', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (13, 'X13', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (14, 'X14', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (15, 'X15', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (16, 'X16', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (17, 'X17', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (18, 'X18', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (19, 'X19', NULL)
INSERT INTO pcc_bulk (id, a, b) VALUES (20, 'X20', NULL)
GO

-- COUNT with GUC=ON (should be 10)
SELECT COUNT(*) AS cnt FROM pcc_bulk WHERE c IS NOT NULL
GO

-- COUNT with GUC=OFF (should be 20 — all re-evaluated as non-null)
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT COUNT(*) AS cnt FROM pcc_bulk WHERE c IS NOT NULL
GO
SET CONCAT_NULL_YIELDS_NULL ON
GO

-- Partition tables (partition func/scheme from prepare)

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

-- Additional edge cases

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
