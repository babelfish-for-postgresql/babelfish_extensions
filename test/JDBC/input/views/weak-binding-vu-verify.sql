------------------------------------------------------------
-- Test to DROP the objects that has dependent views
------------------------------------------------------------
USE master
GO

SELECT set_config('babelfishpg_tsql.weak_view_binding', 'false', false)
GO
-- [view_test.strong_view1] has dependent view [view_test.strong_view2] [ERROR] 
DROP VIEW view_test.strong_view1;
GO

-- [view_test.base_table1] has dependent views [view_test.strong_view1] and [view_test.strong_view2] [ERROR]
DROP TABLE view_test.base_table1;
GO

SELECT set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

ALTER VIEW view_test.strong_view1 AS 
    SELECT * FROM view_test.base_table1;
GO

DROP TABLE view_test.base_table1;
GO

SELECT * FROM view_test.strong_view1;
GO

SELECT * FROM view_test.strong_view2;
GO

-- Recreate the base table
CREATE TABLE view_test.base_table1 (
    id INT,
    name VARCHAR(50)
);

SELECT * FROM view_test.strong_view2;
GO

SELECT * FROM view_test.strong_view1;
GO

------------------------------------------------------------
-- Dropping a view having dependent weak view
------------------------------------------------------------
select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

ALTER VIEW view_test.weak_view1 AS 
    SELECT * FROM view_test.base_table2;
GO

-- [view_test.weak_view1] has dependent weak view [view_test.weak_view2]
DROP VIEW view_test.weak_view1;
GO

-- Verify result for dependent view [Should give ERROR]
SELECT * FROM view_test.weak_view2;
GO

-- Recreate the dropped view back
-- Set the GUC to true to allow weak binding views
select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE VIEW view_test.weak_view1 AS 
    SELECT * FROM view_test.base_table2;
GO

SELECT * FROM view_test.weak_view1;
GO

SELECT * FROM view_test.weak_view2;
GO

------------------------------------------------------------
-- Test to check the behavior of weak binding views 
-- when the base table is dropped
------------------------------------------------------------
DROP TABLE view_test.base_table2;
GO

-- Verify result for dependent view [Should give ERROR]
SELECT * FROM view_test.weak_view2;
GO

-- [Should give ERROR]
SELECT * FROM view_test.weak_view1;
GO

-- Recreate the base table
CREATE TABLE view_test.base_table2 (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
GO

-- Verify result for dependent view
SELECT * FROM view_test.weak_view2;
GO

SELECT * FROM view_test.weak_view1;
GO

------------------------------------------------------------
-- SET GUC to false and test the drop behavior on objects
-- with dependent weak views
------------------------------------------------------------

select set_config('babelfishpg_tsql.weak_view_binding', 'false', false)
GO

DROP TABLE view_test.base_table2;
GO

-- Recreate the base table with different structure (more columns)
CREATE TABLE view_test.base_table2 (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    description VARCHAR(100)  -- New column added
);
GO

-- Verify result for dependent view 
SELECT * FROM view_test.weak_view2;
GO

-- Verify result for dependent view 
SELECT * FROM view_test.weak_view1;
GO

DROP TABLE view_test.base_table2;
GO

-- Recreate the base table with less columns
CREATE TABLE view_test.base_table2 (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
GO

-- Verify result for dependent view
SELECT * FROM view_test.weak_view2;
GO

SELECT * FROM view_test.weak_view1;
GO

------------------------------------------------------------
-- Test with multiple base tables
------------------------------------------------------------

-- Create view with join
CREATE VIEW view_test.weak_view3 AS
SELECT a.id, a.name, b.category 
FROM view_test.base_table2 a
JOIN view_test.base_table3 b ON a.id = b.id;
GO

-- Drop one of the base tables [ERROR]
DROP TABLE view_test.base_table3;
GO

-- Set GUC to true 
select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

ALTER VIEW view_test.weak_view3 AS
SELECT a.id, a.name, b.category 
FROM view_test.base_table2 a
JOIN view_test.base_table3 b ON a.id = b.id;
GO

DROP TABLE view_test.base_table3;
GO

-- Verify view behavior [ERROR]
SELECT * FROM view_test.weak_view3;
GO

-- Recreate the base table
CREATE TABLE view_test.base_table3 (
    id INT PRIMARY KEY,
    category VARCHAR(50)
);
GO

-- Verify view behavior
SELECT * FROM view_test.weak_view3;
GO

------------------------------------------------------------
-- Test with creating strong view referencing weak view
------------------------------------------------------------

select set_config('babelfishpg_tsql.weak_view_binding', 'false', false)
GO

-- [ERROR]
CREATE VIEW view_test.strong_view3 AS
SELECT * FROM view_test.weak_view1;
GO

------------------------------------------------------------
-- Test with complex queries in views
------------------------------------------------------------
select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

-- Create view with aggregations
CREATE VIEW view_test.weak_view_complex1 AS
SELECT name, COUNT(*) as count, SUM(id) as sum_id
FROM view_test.base_table2
GROUP BY name;
GO

-- Create view with subquery
CREATE VIEW view_test.weak_view_complex2 AS
SELECT * FROM view_test.base_table2 a
WHERE EXISTS (SELECT 1 FROM view_test.weak_view1 b WHERE a.id = b.id);
GO

-- Drop and recreate base table
DROP TABLE view_test.base_table2;
GO

SELECT * FROM view_test.weak_view_complex1;
GO

SELECT * FROM view_test.weak_view_complex2;
GO

CREATE TABLE view_test.base_table2 (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
GO

SELECT * FROM view_test.weak_view_complex1;
GO

SELECT * FROM view_test.weak_view_complex2;
GO

------------------------------------------------------------
-- Test to drop functions that has dependent views
------------------------------------------------------------

-- Create a function that is used in a view
CREATE FUNCTION view_test.sample_function()
RETURNS TABLE AS
RETURN (
    SELECT id, name FROM view_test.base_table2
);
GO

-- Create a view that uses the function
CREATE VIEW view_test.weak_view_function AS
SELECT * FROM view_test.sample_function();
GO

-- Drop the function
DROP FUNCTION view_test.sample_function();
GO

-- Verify result for dependent view
SELECT * FROM view_test.weak_view_function;
GO

-- Recreate the function
CREATE FUNCTION view_test.sample_function()
RETURNS TABLE AS
RETURN (
    SELECT id, name FROM view_test.base_table2
);
GO

-- Verify result for dependent view
SELECT * FROM view_test.weak_view_function;
GO

-- Drop the view
DROP VIEW view_test.weak_view_function;
GO

DROP FUNCTION view_test.sample_function1();
GO

-- Change view to weak binding
ALTER VIEW view_test.weak_view_function1 AS
SELECT * FROM view_test.sample_function1();
GO

DROP FUNCTION view_test.sample_function1();
GO

SELECT * FROM view_test.weak_view_function1;
GO

----------------------------------------------------------------
-- Test with metadata queries after dropping underlying objects
----------------------------------------------------------------

USE master;
GO

CREATE TABLE t (a INT PRIMARY KEY,b VARCHAR(50),c VARCHAR(50), d INT);
GO

CREATE VIEW master_v1 AS
    SELECT a, b FROM t WHERE d = 1;
GO

DROP TABLE t;
GO

SELECT OBJECT_DEFINITION (OBJECT_ID(N'master_v1'))
GO

------------------------------------------------------------
-- Test with data type changes in base tables
------------------------------------------------------------
USE master;
GO

-- Create a new base table for testing
CREATE TABLE view_test.type_test_table (
    id INT PRIMARY KEY,
    value VARCHAR(50)
);
GO

-- Create a weak binding view
select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE VIEW view_test.weak_type_view AS
SELECT id, value FROM view_test.type_test_table;
GO

SELECT * FROM view_test.weak_type_view;
GO

-- Drop and recreate with different data type
DROP TABLE view_test.type_test_table;
GO

CREATE TABLE view_test.type_test_table (
    id INT PRIMARY KEY,
    value INT  -- Changed from VARCHAR to INT
);
GO

-- Verify view behavior with type mismatch
SELECT * FROM view_test.weak_type_view;
GO

-- Insert data and test again
INSERT INTO view_test.type_test_table VALUES (1, 100), (2, 200);
GO

SELECT * FROM view_test.weak_type_view;
GO

USE master;
GO

-- Create a new base table for testing with binary data
CREATE TABLE view_test.binary_test_table (
    id INT PRIMARY KEY,
    binary_data VARBINARY(50)
);
GO

-- Create a weak binding view
SELECT set_config('babelfishpg_tsql.weak_view_binding', 'true', false);
GO

CREATE VIEW view_test.weak_binary_view AS
SELECT id, binary_data FROM view_test.binary_test_table;
GO

-- Insert some binary data
INSERT INTO view_test.binary_test_table 
VALUES (1, 0x48656C6C6F), (2, 0x576F726C64);
GO

-- View the initial data
SELECT * FROM view_test.weak_binary_view;
GO

DROP TABLE view_test.binary_test_table;
GO

-- Recreate the table with a different data type
CREATE TABLE view_test.binary_test_table (
    id INT PRIMARY KEY,
    binary_data VARCHAR(50)  -- Changed from VARBINARY to VARCHAR
);
GO

-- Insert hexadecimal strings
INSERT INTO view_test.binary_test_table 
VALUES (1, '0x48656C6C6F'), (2, '0x576F726C64');
GO

-- View the data after type change
SELECT * FROM view_test.weak_binary_view;
GO

-- Try to convert the hexadecimal strings back to binary
SELECT id, CAST(binary_data AS VARBINARY(50)) AS converted_binary
FROM view_test.weak_binary_view;
GO

USE master;
GO

-- 1. Test Case: Date/Time Conversions
------------------------------------
CREATE TABLE view_test.datetime_test (
    id INT PRIMARY KEY,
    date_col DATETIME
);
GO

CREATE VIEW view_test.datetime_view AS
SELECT id, date_col FROM view_test.datetime_test;
GO

CREATE VIEW view_test.datetime_view1 AS
SELECT id, date_col FROM view_test.datetime_view;
GO

-- Insert valid datetime
INSERT INTO view_test.datetime_test VALUES (1, '2024-01-01 12:00:00');
GO

-- View initial data
SELECT * FROM view_test.datetime_view;
GO

SELECT * FROM view_test.datetime_view1;
GO

-- Change to VARCHAR
DROP TABLE view_test.datetime_test;
GO

CREATE TABLE view_test.datetime_test (
    id INT PRIMARY KEY,
    date_col VARCHAR(50)
);
GO

-- This should work (valid date string)
INSERT INTO view_test.datetime_test VALUES (1, '2024-01-01 12:00:00');
GO

INSERT INTO view_test.datetime_test VALUES (2, 'not a date');
GO

SELECT * from view_test.datetime_view
GO

SELECT * FROM view_test.datetime_view1;
GO

-- 2. Test Case: Numeric Precision Changes
----------------------------------------
CREATE TABLE view_test.numeric_test (
    id INT PRIMARY KEY,
    num_col DECIMAL(10,2)
);
GO

CREATE VIEW view_test.numeric_view AS
SELECT id, num_col FROM view_test.numeric_test;
GO

INSERT INTO view_test.numeric_test VALUES (1, 123.45);
GO

SELECT * FROM view_test.numeric_view
GO

-- Change precision
DROP TABLE view_test.numeric_test;
GO

CREATE TABLE view_test.numeric_test (
    id INT PRIMARY KEY,
    num_col DECIMAL(5,1)  -- Smaller precision
);
GO

-- This should work
INSERT INTO view_test.numeric_test VALUES (1, 123.4);
GO

-- This should fail (overflow)
INSERT INTO view_test.numeric_test VALUES (2, 12345.67);
GO

SELECT * FROM view_test.numeric_view
GO

-- 3. Test Case: XML/JSON Conversions
-----------------------------------
CREATE TABLE view_test.doc_test (
    id INT PRIMARY KEY,
    doc_col XML
);
GO

CREATE VIEW view_test.doc_view AS
SELECT id, doc_col FROM view_test.doc_test;
GO

-- Insert valid XML
INSERT INTO view_test.doc_test VALUES (1, '<root><item>Test</item></root>');
GO

SELECT * FROM view_test.doc_view
GO

-- Change to VARCHAR
DROP TABLE view_test.doc_test;
GO

CREATE TABLE view_test.doc_test (
    id INT PRIMARY KEY,
    doc_col VARCHAR(MAX)
);
GO

-- Valid XML as string
INSERT INTO view_test.doc_test VALUES (1, '<root><item>Test</item></root>');
-- Invalid XML structure
INSERT INTO view_test.doc_test VALUES (2, '<root><item>Test</root>');
GO

SELECT * FROM view_test.doc_view
GO

-- 4. Test Case: Unicode to Non-Unicode
-------------------------------------
CREATE TABLE view_test.string_test (
    id INT PRIMARY KEY,
    str_col NVARCHAR(100)
);
GO

CREATE VIEW view_test.string_view AS
SELECT id, str_col FROM view_test.string_test;
GO

-- Insert Unicode data
INSERT INTO view_test.string_test VALUES (1, N'Hello 世界');
GO

SELECT * FROM view_test.string_view
GO

-- Change to non-Unicode
DROP TABLE view_test.string_test;
GO

CREATE TABLE view_test.string_test (
    id INT PRIMARY KEY,
    str_col VARCHAR(100)
);
GO

-- This might cause data loss for non-ASCII characters
INSERT INTO view_test.string_test VALUES (1, 'Hello 世界');
GO

SELECT * FROM view_test.string_view
GO

-- 5. Test Case: Multiple Column Type Changes
------------------------------------------
CREATE TABLE view_test.complex_test (
    id INT PRIMARY KEY,
    col1 INT,
    col2 VARCHAR(50),
    col3 DATETIME
);
GO

CREATE VIEW view_test.complex_view AS
SELECT id, col1, col2, col3 FROM view_test.complex_test;
GO

INSERT INTO view_test.complex_test VALUES (1, 100, 'Test', '2024-01-01');
GO

SELECT * FROM view_test.complex_view
GO

-- Change multiple column types
DROP TABLE view_test.complex_test;
GO

CREATE TABLE view_test.complex_test (
    id INT PRIMARY KEY,
    col1 DECIMAL(10,2),  -- INT to DECIMAL
    col2 NVARCHAR(50),   -- VARCHAR to NVARCHAR
    col3 DATE           -- DATETIME to DATE
);
GO

-- Test different scenarios
INSERT INTO view_test.complex_test VALUES 
    (1, 100.50, N'Test', '2024-01-01'),
    (2, 999999.99, N'Test2', '2024-01-01');
GO

-- Should fail due to decimal overflow
INSERT INTO view_test.complex_test VALUES 
    (3, 99999999.99, N'Test3', '2024-01-01');
GO

SELECT * FROM view_test.complex_view
GO

-- 6. Test Case: Computed Columns
-------------------------------
CREATE TABLE view_test.compute_test (
    id INT PRIMARY KEY,
    val1 INT,
    val2 INT,
    computed_col AS (val1 + val2)
);
GO

CREATE VIEW view_test.compute_view AS
SELECT id, val1, val2, computed_col FROM view_test.compute_test;
GO

INSERT INTO view_test.compute_test VALUES (1, 10, 20);
GO

SELECT * FROM view_test.compute_view
GO

-- Change computation logic
DROP TABLE view_test.compute_test;
GO

CREATE TABLE view_test.compute_test (
    id INT PRIMARY KEY,
    val1 INT,
    val2 INT,
    computed_col AS (val1 * val2)  -- Changed from addition to multiplication
);
GO

INSERT INTO view_test.compute_test VALUES (1, 10, 20);
GO

SELECT * FROM view_test.compute_view
GO

------------------------------------------------------------
-- Test with triggers on views
------------------------------------------------------------
USE master;
GO

CREATE TABLE view_test.trigger_base_table (
    id INT PRIMARY KEY,
    value VARCHAR(50)
);
GO

CREATE TABLE view_test.trigger_audit_table (
    id INT,
    action VARCHAR(10)
);
GO

select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE VIEW view_test.trigger_view AS
SELECT * FROM view_test.trigger_base_table;
GO

CREATE TRIGGER trg_view_insert ON view_test.trigger_view
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO view_test.trigger_base_table
    SELECT id, value FROM inserted;
    
    INSERT INTO view_test.trigger_audit_table
    SELECT id, 'INSERT' FROM inserted;
END;
GO

-- Test trigger
INSERT INTO view_test.trigger_view VALUES (1, 'test');
GO

SELECT * FROM view_test.trigger_audit_table;
GO

-- Drop base table and recreate [We can drop table even if it has child view that has dependent trigger Table1 --> View1 --> trigger]
-- We can also drop view if it has dependent trigger (trigger will also get dropped along with view)
DROP TABLE view_test.trigger_base_table;
GO

CREATE TABLE view_test.trigger_base_table (
    id INT PRIMARY KEY,
    value VARCHAR(50)
);
GO

DROP VIEW view_test.trigger_view;
GO

-- Test trigger after table recreation
INSERT INTO view_test.trigger_view VALUES (2, 'test2');
GO

SELECT * FROM view_test.trigger_audit_table;
GO

------------------------------------------------------------
-- Test with temporary tables
------------------------------------------------------------
USE master;
GO

-- Create temporary table
CREATE TABLE #temp_table (
    id INT PRIMARY KEY,
    value VARCHAR(50)
);
GO

INSERT INTO #temp_table VALUES (1, 'temp1'), (2, 'temp2');
GO

-- Create weak binding view on temp table
select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE VIEW view_test.temp_view AS
SELECT * FROM #temp_table;
GO

-- Test view
SELECT * FROM view_test.temp_view;
GO

DROP TABLE #temp_table;
GO

------------------------------------------------------------
-- Test with computed columns
------------------------------------------------------------
USE master;
GO

-- Create table with computed column
CREATE TABLE view_test.computed_table (
    id INT PRIMARY KEY,
    value INT,
    computed_value AS (value * 2)
);
GO

INSERT INTO view_test.computed_table (id, value) VALUES (1, 10), (2, 20);
GO

-- Create weak binding view
select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE VIEW view_test.computed_view AS
SELECT id, value, computed_value FROM view_test.computed_table;
GO

-- Test view
SELECT * FROM view_test.computed_view;
GO

-- Drop and recreate with different computation
DROP TABLE view_test.computed_table;
GO

CREATE TABLE view_test.computed_table (
    id INT PRIMARY KEY,
    value INT,
    computed_value AS (value * 3)  -- Changed from *2 to *3
);
GO

INSERT INTO view_test.computed_table (id, value) VALUES (1, 10), (2, 20);
GO

-- Test view after computation change
SELECT * FROM view_test.computed_view;
GO

------------------------------------------------------------
-- Set of user operations performed to change strong view 
-- to weak view
------------------------------------------------------------

select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE VIEW v1_strong WITH SCHEMABINDING AS SELECT * FROM test_table_for_strong_view;
GO

CREATE VIEW v2_strong WITH SCHEMABINDING AS SELECT * FROM v1_strong;
GO

DROP TABLE IF EXISTS test_table_for_strong_view;
GO

DROP VIEW v1_strong;
GO

ALTER VIEW v1_strong AS SELECT * FROM test_table_for_strong_view;
GO

DROP TABLE test_table_for_strong_view;
GO

SELECT * FROM v1_strong;
GO

SELECT * FROM v2_strong;
GO

CREATE TABLE test_table_for_strong_view (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
GO

SELECT * FROM v1_strong;
GO

SELECT * FROM v2_strong;
GO

---------------------------------------------------------------
-- Test to check INSERT/UPDATE/DELETE operations on broken view
-- during view repair
---------------------------------------------------------------

-- INSERT

CREATE TABLE t (a INT PRIMARY KEY,b VARCHAR(50),c VARCHAR(50), d INT);
GO

select set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE VIEW insert_v1 AS
    SELECT a, b FROM t;
GO

CREATE VIEW insert_v2 AS
    SELECT * FROM insert_v1;
GO

DROP TABLE t;
GO

CREATE TABLE t (a INT PRIMARY KEY,b VARCHAR(50),c VARCHAR(50));
GO

INSERT INTO insert_v1 VALUES (1,'b')
GO

SELECT * FROM insert_v2;
GO

SELECT * FROM insert_v1;
GO

DROP VIEW insert_v2;
GO

DROP VIEW insert_v1;
GO

DROP TABLE t;
GO

-- UPDATE

CREATE TABLE t (a INT PRIMARY KEY, b VARCHAR(50), c VARCHAR(50), d INT);
GO

CREATE VIEW update_v1 AS
    SELECT a, b, d FROM t;
GO

CREATE VIEW update_v2 AS
    SELECT * FROM update_v1;
GO

DROP TABLE t;
GO

CREATE TABLE t (a INT PRIMARY KEY, b VARCHAR(50), c VARCHAR(50), d INT);
GO

UPDATE update_v1 SET b = 'updated_b';
GO

SELECT * FROM update_v2;
GO

SELECT * FROM update_v1;
GO

DROP VIEW update_v2;
GO

DROP VIEW update_v1;
GO

DROP TABLE t;
GO

---------------------------------------------------------------
-- Test to check DELETE operations on broken view
-- during view repair
---------------------------------------------------------------

-- DELETE

CREATE TABLE t (a INT PRIMARY KEY, b VARCHAR(50), c VARCHAR(50), d INT);
GO

CREATE VIEW delete_v1 AS
    SELECT a, b, d FROM t;
GO

CREATE VIEW delete_v2 AS
    SELECT * FROM delete_v1;
GO

DROP TABLE t;
GO

CREATE TABLE t (a INT PRIMARY KEY, b VARCHAR(50), c VARCHAR(50), d INT);
GO

DELETE FROM delete_v1 WHERE a = 2;
GO

SELECT * FROM delete_v2;
GO

SELECT * FROM delete_v1;
GO

DROP VIEW delete_v2;
GO

DROP VIEW delete_v1;
GO

---------------------------------------------------------------
-- Test to check self referencing views during ALTER
---------------------------------------------------------------
CREATE TABLE self_ref_t1 (a INT PRIMARY KEY, b VARCHAR(50), c VARCHAR(50), d INT);
GO

SELECT set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE VIEW self_ref_v1 AS
    SELECT a, b FROM self_ref_t1;
GO

CREATE VIEW self_ref_v2 AS
    SELECT * FROM self_ref_v1;
GO

-- Create a self-referencing view [ERROR]
ALTER VIEW self_ref_v1 AS
    SELECT a FROM self_ref_v1;
GO

-- Attempt to alter view that creates circular reference [ERROR]
ALTER VIEW self_ref_v1 AS
    SELECT a FROM self_ref_v1;
GO

ALTER VIEW vw_fnc_check AS
    SELECT customer_id,
        fnc_dependancy_check(customer_name, 'Code', 'Desc') AS code_desc
    FROM customer;
GO

DROP FUNCTION fnc_dependancy_check;
GO

ALTER VIEW test_view AS
SELECT c.customer_id, c.customer_name, o.order_id, o.order_date
FROM customer c
JOIN test_ord o ON c.customer_id = o.customer_id;
GO

DROP VIEW test_view;
GO

SELECT * FROM dependent_view;
GO

CREATE VIEW test_view AS
SELECT c.customer_id, c.customer_name, o.order_id, o.order_date
FROM customer c
JOIN test_ord o ON c.customer_id = o.customer_id;
GO

SELECT * FROM dependent_view;
GO

---------------------------------------------------------------
-- DMLs on views with weak binding
---------------------------------------------------------------

CREATE TABLE dml_test_table (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
GO

CREATE VIEW dml_test_view AS
    SELECT id, name FROM dml_test_table;
GO

INSERT INTO dml_test_view (id, name) VALUES (1, 'Test1'), (2, 'Test2');
GO

SELECT * FROM dml_test_view;
GO

UPDATE dml_test_view SET name = 'UpdatedTest1' WHERE id = 1;
GO

SELECT * FROM dml_test_view;
GO

DELETE FROM dml_test_view WHERE id = 2;
GO

SELECT * FROM dml_test_view;
GO

-- View with top-level query having an empty rtable
CREATE VIEW no_top_level AS
    SELECT 
        (SELECT MAX(id) FROM dml_test_view) AS max_id,
        (SELECT MIN(id) FROM dml_test_view) AS min_id;
GO

---------------------------------------------------------------
-- Broken Views referenced inside CTE statements
---------------------------------------------------------------

WITH cte AS (
    SELECT * FROM dml_test_view
)
SELECT * FROM cte;
GO

WITH cte AS (
    SELECT * FROM dml_test_view
)
SELECT * FROM cte WHERE id = 1;
GO

DROP TABLE dml_test_table;
GO

CREATE TABLE dml_test_table (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    description VARCHAR(100)
);
GO

INSERT INTO dml_test_view (id, name) VALUES (1, 'Test1'), (2, 'Test2');
GO

WITH cte AS (
    SELECT * FROM dml_test_view
)
SELECT * FROM cte;
GO

WITH cte AS (
    SELECT * FROM dml_test_view
)
SELECT * FROM cte WHERE id = 1;
GO

-- View with top-level query having an empty rtable and broken view
SELECT * FROM no_top_level;
GO

---------------------------------------------------------------
-- Broken Views referenced inside subqueries
---------------------------------------------------------------

SELECT * FROM (
    SELECT * FROM dml_test_view
) AS subquery;
GO

SELECT * FROM (
    SELECT * FROM dml_test_view
) AS subquery WHERE id = 1;
GO

DROP TABLE dml_test_table;
GO

CREATE TABLE dml_test_table (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    description VARCHAR(100)
);
GO

INSERT INTO dml_test_view (id, name) VALUES (1, 'Test1'), (2, 'Test2');
GO

SELECT * FROM (
    SELECT * FROM dml_test_view
) AS subquery;
GO

SELECT * FROM (
    SELECT * FROM dml_test_view
) AS subquery WHERE id = 1;
GO

---------------------------------------------------------------
-- Broken Views in subqueries inside where clause
---------------------------------------------------------------

SELECT * FROM dml_test_view
WHERE id IN (
    SELECT id FROM dml_test_view WHERE name LIKE 'Test%'
);
GO

SELECT * FROM dml_test_view
WHERE id IN (
    SELECT id FROM dml_test_view WHERE id = 2
);
GO

---------------------------------------------------------------
-- Views as derived tables
---------------------------------------------------------------

SELECT * FROM (
    SELECT * FROM dml_test_view
) AS derived_table;
GO

SELECT * FROM (
    SELECT * FROM dml_test_view
) AS derived_table WHERE id = 1;
GO

-- Multiple derived tables in a single query

SELECT * FROM (
    SELECT * FROM dml_test_view
) AS derived_table1,
(
    SELECT * FROM dml_test_view
) AS derived_table2
WHERE derived_table1.id = derived_table2.id;
GO

-- Combining multiple approaches

SELECT * FROM (
    SELECT * FROM dml_test_view
) AS derived_table1
JOIN (
    SELECT * FROM dml_test_view
) AS derived_table2 ON derived_table1.id = derived_table2.id
WHERE derived_table1.name LIKE 'Test%';
GO

------------------------------------------------------------
-- Test with complex view definition
------------------------------------------------------------
SELECT set_config('babelfishpg_tsql.weak_view_binding', 'true', false)
GO

CREATE TABLE cmp_t (a INT PRIMARY KEY, b VARCHAR(50), c VARCHAR(50), d INT);
GO

CREATE TABLE cmp_t2 ( id INT PRIMARY KEY, a INT, e VARCHAR(50));
GO

CREATE TABLE cmp_t3 ( id INT PRIMARY KEY, a INT, f DATE );
GO

CREATE VIEW multi_table_complex_view AS
SELECT 
    cmp_t.a,
    cmp_t.b,
    cmp_t.c,
    subq.e,
    subq.f
FROM cmp_t
JOIN (
    -- Subquery with multiple table references
    SELECT 
        cmp_t2.a,
        cmp_t2.e,
        cmp_t3.f
    FROM cmp_t2
    JOIN cmp_t3 ON cmp_t2.a = cmp_t3.a
    WHERE cmp_t2.id IN (
        SELECT a
        FROM cmp_t 
        WHERE d > (SELECT AVG(d) FROM cmp_t)
    )
) AS subq ON cmp_t.a = subq.a
UNION ALL
SELECT 
    cmp_t.a,
    cmp_t.b,
    cmp_t.c,
    subq2.e,
    subq2.f
FROM cmp_t
LEFT JOIN (
    -- Another subquery with multiple table references
    SELECT 
        cmp_t2.a,
        cmp_t2.e,
        cmp_t3.f
    FROM cmp_t2
    FULL OUTER JOIN cmp_t3 ON cmp_t2.a = cmp_t3.a
    WHERE EXISTS (
        SELECT 1 
        FROM cmp_t 
        WHERE cmp_t.a = cmp_t2.a OR cmp_t.a = cmp_t3.a
    )
) AS subq2 ON cmp_t.a = subq2.a
WHERE cmp_t.d < (SELECT MAX(d) FROM cmp_t);
GO

DROP TABLE cmp_t;
GO

SELECT * FROM multi_table_complex_view;
GO

-- Recreate the base table
CREATE TABLE cmp_t (
    a INT PRIMARY KEY,
    b VARCHAR(50),
    c VARCHAR(50),
    d INT
);
GO

SELECT * FROM multi_table_complex_view;
GO

CREATE VIEW avg_d_per_c AS
SELECT c, AVG(d) AS avg_d
FROM t
GROUP BY c;
GO

CREATE VIEW above_avg_d AS
SELECT t.a, t.b, t.c, t.d
FROM t
JOIN avg_d_per_c ON t.c = avg_d_per_c.c
WHERE t.d > avg_d_per_c.avg_d;
GO

CREATE VIEW complex_nested_view AS
SELECT 
    t.a,
    t.b,
    t.c,
    t.d,
    (SELECT AVG(avg_d) FROM avg_d_per_c) AS overall_avg_d
FROM t
WHERE t.a IN (
    SELECT a
    FROM above_avg_d
    WHERE above_avg_d.d > (
        SELECT AVG(d)
        FROM t AS t2
        WHERE t2.c IN (
            SELECT c
            FROM avg_d_per_c
            WHERE avg_d > (SELECT AVG(avg_d) FROM avg_d_per_c)
        )
    )
);
GO

DROP VIEW avg_d_per_c;
GO

SELECT * FROM complex_nested_view;
GO

-- Recreate the base table
CREATE VIEW avg_d_per_c AS
SELECT c, AVG(d) AS avg_d
FROM t
GROUP BY c;
GO

SELECT * FROM complex_nested_view;
GO