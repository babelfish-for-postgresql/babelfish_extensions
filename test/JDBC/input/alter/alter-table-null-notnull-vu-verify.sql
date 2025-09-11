SELECT * FROM test_datatypes;
GO

ALTER TABLE test_datatypes ALTER COLUMN num_col BIGINT NULL;
GO

ALTER TABLE test_datatypes ALTER COLUMN price FLOAT NULL;
GO

INSERT INTO test_datatypes VALUES (NULL, NULL); -- [Test nullability]
GO

INSERT INTO test_datatypes VALUES (9223372036854775807, 123456.789); -- [Test larger numbers]
GO

SELECT * FROM test_datatypes;
GO
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
SELECT * FROM test_strings;
GO

ALTER TABLE test_strings ALTER COLUMN short_text VARCHAR(100) NULL;
GO

ALTER TABLE test_strings ALTER COLUMN fixed_text VARCHAR(20) NOT NULL;
GO

ALTER TABLE test_strings ALTER COLUMN text_col VARCHAR(MAX) NOT NULL;
GO

INSERT INTO test_strings VALUES (NULL, 'New Fixed Text', 'Required Text');
GO
INSERT INTO test_strings VALUES ('Text longer than 50 characters but less than 100 characters', 'Fixed', 'Long text');
GO

SELECT LEN(short_text), LEN(fixed_text) FROM test_strings;
GO

SELECT * FROM test_strings;
GO

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
SELECT simple_date, timestamp_col, precise_time FROM test_datetime;
GO

ALTER TABLE test_datetime ALTER COLUMN simple_date DATETIME2 NULL;
GO

ALTER TABLE test_datetime ALTER COLUMN timestamp_col DATETIME2(7) NOT NULL;
GO

ALTER TABLE test_datetime ALTER COLUMN precise_time TIME(7) NULL;
GO

INSERT INTO test_datetime VALUES (NULL, '2024-01-01 12:34:56.1234567', NULL);
GO

INSERT INTO test_datetime VALUES ('2024-01-01 12:34:56.1234567', '2024-01-01 12:34:56.1234567', '12:34:56.1234567');
GO

SELECT simple_date, timestamp_col, precise_time FROM test_datetime;
GO

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
SELECT * FROM test_complex;
GO

ALTER TABLE test_complex ALTER COLUMN json_col VARCHAR(MAX) NOT NULL;
GO
ALTER TABLE test_complex ALTER COLUMN binary_col VARBINARY(MAX) NULL;
GO

INSERT INTO test_complex VALUES ('{"complex": "json"}', '<root><test>xml</test></root>', NULL);
GO

SELECT DATALENGTH(json_col),binary_col FROM test_complex;
GO

SELECT * FROM test_complex;
GO

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
SELECT * FROM test_precision;
GO

ALTER TABLE test_precision ALTER COLUMN decimal_col DECIMAL(15,4) NULL;
GO

ALTER TABLE test_precision ALTER COLUMN numeric_col NUMERIC(12,6) NOT NULL;
GO

ALTER TABLE test_precision ALTER COLUMN float_col DECIMAL(10,2) NOT NULL;
GO

INSERT INTO test_precision VALUES (12345678901.2345, 123456.123456, 123.45);
GO

SELECT * FROM test_precision;
GO

------------------------------------------------------------------------------------------------
-- Computed Column Change
------------------------------------------------------------------------------------------------
SELECT * FROM test_computed;
GO

ALTER TABLE test_computed ALTER COLUMN price DECIMAL(15,4);
GO

INSERT INTO test_computed (price, quantity) VALUES (10.9999, 3);
GO

SELECT * FROM test_computed;
GO

-------------------------------------------------------------------------------------------------
-- Altering a NOT NULL Column to NULL When It's Part of a UNIQUE Constraint:
-------------------------------------------------------------------------------------------------

SELECT * FROM unique_test;
GO

ALTER TABLE unique_test ALTER COLUMN email VARCHAR(100) NULL;
GO

INSERT INTO unique_test VALUES (1, NULL); -- [Should succeed]
GO

INSERT INTO unique_test VALUES (2, 'abcde');
GO

INSERT INTO unique_test VALUES (3, 'abcde'); -- [Should fail due to UNIQUE constraint]
GO

SELECT * FROM unique_test;
GO

-------------------------------------------------------------------------------------------------
-- Pre-existing Data and Updates
-------------------------------------------------------------------------------------------------

SELECT * FROM employee_records;
GO

UPDATE employee_records SET department = 'Unassigned' WHERE department IS NULL;
GO

ALTER TABLE employee_records ALTER COLUMN department VARCHAR(50) NOT NULL;
GO

ALTER TABLE employee_records ALTER COLUMN email VARCHAR(100) NOT NULL; -- [should fail due to existing NULLs]
GO

SELECT * FROM employee_records;
GO

-----------------------------------------------------------------------------------------------
-- Testing Updates After Column Alteration
-----------------------------------------------------------------------------------------------

SELECT * FROM cust_orders;
GO

ALTER TABLE cust_orders ALTER COLUMN status VARCHAR(20) NULL;
GO

UPDATE cust_orders SET status = NULL WHERE order_id = 1;
GO

UPDATE cust_orders SET notes = NULL WHERE order_id = 3;
GO

SELECT * FROM cust_orders;
GO

-----------------------------------------------------------------------------------------------
-- Redundant NULL/NOT NULL Alterations
-----------------------------------------------------------------------------------------------

SELECT * FROM redundant_test;
GO

ALTER TABLE redundant_test ALTER COLUMN col1 VARCHAR(50) NULL;
GO

ALTER TABLE redundant_test ALTER COLUMN col2 VARCHAR(50) NOT NULL;
GO

SELECT * FROM redundant_test;
GO

INSERT INTO redundant_test VALUES (3, NULL, 'Required3');
GO

INSERT INTO redundant_test VALUES (4, 'Test4', 'Required4');
GO

SELECT * FROM redundant_test;
GO

-----------------------------------------------------------------------------------------------
-- Insert, Update, Alter
-----------------------------------------------------------------------------------------------
SELECT * FROM employee_projects;
GO

-- Update existing data to ensure no NULLs before altering
UPDATE employee_projects SET status = 'Active' WHERE status IS NULL;
GO

-- alter status to NOT NULL
ALTER TABLE employee_projects ALTER COLUMN status VARCHAR(20) NOT NULL;
GO

-- Update after alteration
UPDATE employee_projects SET status = 'Completed' WHERE emp_id = 1;
GO

-- Update with NULL (should fail)
UPDATE employee_projects SET status = NULL WHERE emp_id = 2;
GO

-----------------------------------------------------------------------------------------------
-- Testing with Transaction Boundaries
-----------------------------------------------------------------------------------------------
BEGIN TRANSACTION;

    UPDATE financial_records
    SET description = 'No description provided' 
    WHERE description IS NULL;

    ALTER TABLE financial_records 
    ALTER COLUMN description VARCHAR(100) NOT NULL;

    SELECT * FROM financial_records;

COMMIT TRANSACTION;
GO

-- Try updates after transaction [Should fail]
UPDATE financial_records SET description = NULL WHERE transaction_id = 1; 
GO

-------------------------------------------------------------------------------------------------
-- Altering Columns in Views
-------------------------------------------------------------------------------------------------
SELECT * FROM product_summary;
GO

--[ERROR] Attempting to alter base table column type used in view
ALTER TABLE products ALTER COLUMN price DECIMAL(12,4) NOT NULL;
GO

-- [SUCCESS] Altering to the same type but changing nullability
ALTER TABLE products ALTER COLUMN price DECIMAL(10,2) NOT NULL;
GO

SELECT * FROM product_summary;
GO

SELECT * FROM price_list;
GO

INSERT INTO product_summary VALUES (3, 'Test3', 15.99); -- [Should succeed]
GO

INSERT INTO product_summary VALUES (4, 'Test4', NULL); -- [Should fail due to NOT NULL constraint]
GO

CREATE TABLE products_weak (
    id INT,
    name VARCHAR(50),
    price DECIMAL(10,2)
);
GO

-- Weak binding view will also error if base table column type is changed
EXEC sp_babelfish_configure 'babelfishpg_tsql.weak_view_binding', 'on';
GO

CREATE VIEW product_summary_weak AS
SELECT id, name, price FROM products_weak;
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.weak_view_binding', 'off';
GO

--[ERROR] Attempting to alter base table column type used in weak view
ALTER TABLE products_weak ALTER COLUMN price DECIMAL(12,4) NOT NULL;
GO

-- [SUCCESS] Altering to the same type but changing nullability
ALTER TABLE products_weak ALTER COLUMN price DECIMAL(10,2) NOT NULL;
GO

SELECT * FROM product_summary_weak;
GO

INSERT INTO product_summary_weak VALUES (3, 'Test3', 15.99); -- [Should succeed]
GO

INSERT INTO product_summary_weak VALUES (4, 'Test4', NULL); -- [Should fail due to NOT NULL constraint]
GO

-------------------------------------------------------------------------------------------------
-- View with Joins
-------------------------------------------------------------------------------------------------
SELECT * FROM customer_order_view;
GO

--[ERROR] Attempting to alter base table column typmod used in view
ALTER TABLE customers ALTER COLUMN name VARCHAR(100) NOT NULL;
GO

--[ERROR] Attempting to alter base table column type used in view
ALTER TABLE customer_orders ALTER COLUMN order_date DATETIME2 NULL;
GO

ALTER TABLE customers ALTER COLUMN name VARCHAR(50) NOT NULL;
GO

ALTER TABLE customer_orders ALTER COLUMN order_date DATE NOT NULL;
GO

--[Both inserts should fail anyways as views that don't select from single table cannot be updated automatically]
INSERT INTO customer_order_view VALUES (3, 'New Customer', 103, NULL);
GO

INSERT INTO customer_order_view VALUES (4, 'New Customer 2', 104, '2024-01-02');
GO

INSERT INTO customers VALUES (3, 'New Customer'), (4, 'New Customer 2'); -- [Should succeed]
GO

INSERT INTO customer_orders VALUES (103, 3, NULL), (104, 4, '2024-01-02'); -- [Should fail due to NOT NULL constraint]
GO

SELECT * FROM customer_order_view;
GO
