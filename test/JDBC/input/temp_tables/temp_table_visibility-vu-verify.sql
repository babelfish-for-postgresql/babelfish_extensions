EXEC object_id_outer_proc
go

EXEC enr_list_outer_outer_proc
go


-- 4122 test case
create table #t4122 (a int)
insert #t4122 values(123)
insert #t4122 values(456)
go

-- Sanity check to ensure object_id is able to return an OID.
if object_id('#t4122') is null
    print 'fail'
go

exec babel_4122_proc '#t4122'
go

SELECT * INTO #temptable5605 FROM generate_series(1,100);
GO
EXEC p_nested
GO
SELECT COUNT(*) FROM #temptable5605
GO
EXEC p_nested_2
GO
EXEC p_index_create
GO
-- FIXME: BABEL-6268
-- EXEC p_drop
-- GO
-- SELECT * FROM #temptable5605
-- GO

-- Test 1: Comprehensive System Functions, Operators, and DML Operations
CREATE TABLE #sys_comprehensive (
	id INT PRIMARY KEY,
	created_date DATETIME DEFAULT GETDATE(),
	guid_col UNIQUEIDENTIFIER DEFAULT NEWID(),
	age INT CHECK (age > 0 AND age < 200),
	salary MONEY CHECK (salary >= 0),
	discount DECIMAL(5,2) CHECK (discount <= 100.00),
	quantity INT CHECK (quantity <> 0),
	status CHAR(1) CHECK (status = 'A' OR status = 'I' OR status = 'P'),
	score INT CHECK (score BETWEEN 0 AND 100),
	start_date DATETIME,
	end_date DATETIME,
	price MONEY,
	total AS (price * quantity),
	CHECK (end_date > start_date),
	CHECK (DATEDIFF(DAY, start_date, end_date) <= 365)
)
GO

-- Verify in ENR
SELECT * FROM enr_view;
GO

-- Insert test data with system function defaults
INSERT INTO #sys_comprehensive (id, age, salary, discount, quantity, status, score, start_date, end_date, price) 
VALUES (1, 30, 50000, 10.5, 5, 'A', 85, '2024-01-01', '2024-06-30', 100.00)
INSERT INTO #sys_comprehensive (id, age, salary, discount, quantity, status, score, start_date, end_date, price) 
VALUES (2, 45, 75000, 15.0, -3, 'I', 92, '2024-02-01', '2024-08-15', 250.50)
INSERT INTO #sys_comprehensive (id, age, salary, discount, quantity, status, score, start_date, end_date, price) 
VALUES (3, 28, 62000, 8.0, 10, 'P', 78, '2024-03-01', '2024-09-30', 75.25)
GO

SELECT id, age, status, score, quantity FROM #sys_comprehensive
GO

-- Test UPDATE operations
UPDATE #sys_comprehensive SET salary = salary * 1.1 WHERE id = 1
GO

UPDATE #sys_comprehensive SET status = 'I', score = 95 WHERE age < 30
GO

SELECT id, age, salary, status, score FROM #sys_comprehensive ORDER BY id
GO

-- Test DELETE operation
DELETE FROM #sys_comprehensive WHERE quantity < 0
GO

SELECT COUNT(*) as record_count FROM #sys_comprehensive
GO

-- ALTER TABLE: Add new column with default
ALTER TABLE #sys_comprehensive ADD department VARCHAR(50) DEFAULT 'Unknown'
GO

SELECT id, department FROM #sys_comprehensive
GO

-- ALTER TABLE: Add new column with CHECK constraint
ALTER TABLE #sys_comprehensive ADD bonus MONEY CHECK (bonus >= 0 AND bonus <= 50000)
GO

-- Update new column
UPDATE #sys_comprehensive SET bonus = salary * 0.1, department = 'Sales' WHERE id = 1
UPDATE #sys_comprehensive SET bonus = salary * 0.15, department = 'Engineering' WHERE id = 3
GO

SELECT id, department, bonus FROM #sys_comprehensive ORDER BY id
GO

-- ALTER TABLE: Add computed column
ALTER TABLE #sys_comprehensive ADD bonus_tax AS (bonus * 0.25)
GO

SELECT id, bonus, bonus_tax FROM #sys_comprehensive WHERE bonus IS NOT NULL
GO

-- ALTER TABLE: Add CHECK constraint to existing table
ALTER TABLE #sys_comprehensive ADD CONSTRAINT chk_department CHECK (department IN ('Sales', 'Engineering', 'Marketing', 'Unknown'))
GO

-- Test constraint (should fail)
UPDATE #sys_comprehensive SET department = 'InvalidDept' WHERE id = 1
GO

SELECT id, department FROM #sys_comprehensive ORDER BY id
GO

-- Test CHECK constraint violations (should fail)
INSERT INTO #sys_comprehensive (id, age, salary, discount, quantity, status, score, start_date, end_date, price) 
VALUES (10, 0, 50000, 10.0, 1, 'A', 50, '2024-01-01', '2024-06-30', 100.00)
GO

INSERT INTO #sys_comprehensive (id, age, salary, discount, quantity, status, score, start_date, end_date, price) 
VALUES (11, 30, -1000, 10.0, 1, 'A', 50, '2024-01-01', '2024-06-30', 100.00)
GO

DROP TABLE #sys_comprehensive
GO

-- Test 2: Advanced Column Features with NULL Handling and Computed Columns
CREATE TABLE #advanced_columns (
	id INT PRIMARY KEY,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	age INT,
	balance BIGINT,
	amount AS (balance * 1000 / NULLIF(age, 0)),
	nullable_col INT,
	default_col INT DEFAULT COALESCE(NULL, 100),
	is_null_col AS (CASE WHEN nullable_col IS NULL THEN 1 ELSE 0 END),
	created_date DATETIME DEFAULT GETDATE(),
	year_created AS YEAR(created_date),
	CHECK (ISNULL(nullable_col, 0) >= 0),
	CHECK (age > 0)
)
GO

-- Verify in ENR
SELECT * FROM enr_view;
GO

-- Insert test data
INSERT INTO #advanced_columns (id, first_name, last_name, age, balance, nullable_col) 
VALUES (1, 'John', 'Doe', 24, 50000, NULL)
INSERT INTO #advanced_columns (id, first_name, last_name, age, balance, nullable_col) 
VALUES (2, 'Jane', 'Smith', 35, 104230, 50)
INSERT INTO #advanced_columns (id, first_name, last_name, age, balance) 
VALUES (3, 'Bob', 'Johnson', 42, 75000)
GO

SELECT id, amount, is_null_col, default_col FROM #advanced_columns
GO

-- Test UPDATE on base columns (computed columns auto-update)
UPDATE #advanced_columns SET first_name = 'Johnny' WHERE id = 1
GO

UPDATE #advanced_columns SET balance = balance + 10000, age = age + 1 WHERE id = 2
GO

SELECT id, age, balance, amount FROM #advanced_columns ORDER BY id
GO

-- Update nullable columns
UPDATE #advanced_columns SET nullable_col = 100 WHERE id = 1
GO

SELECT id, nullable_col, is_null_col FROM #advanced_columns ORDER BY id
GO

-- ALTER TABLE: Add new computed column
ALTER TABLE #advanced_columns ADD age_group AS (
	CASE 
		WHEN age < 30 THEN 'Young'
		WHEN age BETWEEN 30 AND 50 THEN 'Middle'
		ELSE 'Senior'
	END
)
GO

SELECT id, age, age_group FROM #advanced_columns
GO

-- ALTER TABLE: Add column with COALESCE default
ALTER TABLE #advanced_columns ADD priority INT DEFAULT COALESCE(NULL, 5)
GO

SELECT id, priority FROM #advanced_columns
GO

-- Update priority
UPDATE #advanced_columns SET priority = 10 WHERE age < 30
UPDATE #advanced_columns SET priority = 20 WHERE age >= 40
GO

SELECT id, age, priority FROM #advanced_columns ORDER BY id
GO

-- ALTER TABLE: Add new column and update based on computed values
ALTER TABLE #advanced_columns ADD category VARCHAR(20)
GO

UPDATE #advanced_columns SET category = 
	CASE 
		WHEN amount > 2000000 THEN 'Premium'
		WHEN amount > 1000000 THEN 'Gold'
		ELSE 'Standard'
	END
WHERE amount IS NOT NULL
GO

SELECT id, amount, category FROM #advanced_columns ORDER BY id
GO

DROP TABLE #advanced_columns
GO

-- Test 3: Indexes with DML Operations and ALTER TABLE
CREATE TABLE #indexed_dml (
	id INT PRIMARY KEY,
	text_col VARCHAR(100),
	int_col INT DEFAULT 0,
	date_col DATETIME DEFAULT GETDATE(),
	money_col MONEY DEFAULT 0,
	description VARCHAR(200),
	status CHAR(1) DEFAULT 'A'
)
GO

-- Create indexes on various data types
CREATE INDEX IX_text ON #indexed_dml(text_col)
GO

CREATE INDEX IX_int ON #indexed_dml(int_col)
GO

CREATE INDEX IX_date ON #indexed_dml(date_col)
GO

CREATE INDEX IX_money ON #indexed_dml(money_col)
GO

CREATE INDEX IX_composite ON #indexed_dml(status, int_col)
GO

-- Verify in ENR
SELECT * FROM enr_view;
GO

-- Insert test data
INSERT INTO #indexed_dml VALUES (1, 'Test One', 100, GETDATE(), 1000.00, 'First record', 'A')
INSERT INTO #indexed_dml VALUES (2, 'Test Two', 200, GETDATE(), 2000.00, 'Second record', 'A')
INSERT INTO #indexed_dml VALUES (3, 'Test Three', 300, GETDATE(), 3000.00, 'Third record', 'I')
INSERT INTO #indexed_dml VALUES (4, 'Sample Four', 150, GETDATE(), 1500.00, 'Fourth record', 'A')
INSERT INTO #indexed_dml VALUES (5, 'Sample Five', 250, GETDATE(), 2500.00, 'Fifth record', 'P')
GO

-- Query using indexes
SELECT id, text_col FROM #indexed_dml WHERE text_col LIKE 'Test%'
GO

SELECT id, int_col FROM #indexed_dml WHERE int_col > 150
GO

SELECT id, money_col FROM #indexed_dml WHERE money_col BETWEEN 1500 AND 2500
GO

SELECT id, status, int_col FROM #indexed_dml WHERE status = 'A' AND int_col > 100
GO

-- UPDATE operations on indexed columns
UPDATE #indexed_dml SET int_col = int_col + 50 WHERE status = 'A'
GO

UPDATE #indexed_dml SET money_col = money_col * 1.1, description = 'Updated: ' + description WHERE int_col > 200
GO

SELECT id, int_col, money_col, status FROM #indexed_dml ORDER BY id
GO

-- DELETE operation
DELETE FROM #indexed_dml WHERE status = 'P'
GO

SELECT COUNT(*) as remaining_records FROM #indexed_dml
GO

-- ALTER TABLE: Add new indexed column
ALTER TABLE #indexed_dml ADD category VARCHAR(30)
GO

UPDATE #indexed_dml SET category = 
	CASE 
		WHEN money_col < 1500 THEN 'Budget'
		WHEN money_col < 2500 THEN 'Standard'
		ELSE 'Premium'
	END
GO

-- Create index on new column
CREATE INDEX IX_category ON #indexed_dml(category)
GO

SELECT id, category FROM #indexed_dml WHERE category = 'Standard'
GO

-- Bulk UPDATE to test index maintenance
UPDATE #indexed_dml SET text_col = 'Bulk Update ' + CAST(id AS VARCHAR(10))
GO

SELECT id, text_col FROM #indexed_dml ORDER BY id
GO

-- ALTER TABLE: Add column with index in same operation
ALTER TABLE #indexed_dml ADD sequence_num INT
GO

UPDATE #indexed_dml SET sequence_num = id * 10
GO

CREATE INDEX IX_sequence ON #indexed_dml(sequence_num)
GO

SELECT id, sequence_num FROM #indexed_dml WHERE sequence_num > 20
GO

-- Test DELETE with indexes
DELETE FROM #indexed_dml WHERE int_col < 150
GO

SELECT id, int_col, text_col FROM #indexed_dml ORDER BY id
GO

DROP TABLE #indexed_dml
GO

EXEC p_def_cons;
GO

-- Test 4: Trying to create a default with UDF which should throw an error
CREATE TABLE #temp_table_with_computed_udf (
	id INT PRIMARY KEY,
	credit BIGINT,
	debit BIGINT,
	total as custom_adder(credit, debit)
)
GO

CREATE TABLE #temp_table_with_default_udf (
	num INT DEFAULT custom_adder(5,10)
)
GO

CREATE TABLE #temp_table_with_default_udf (
	num INT CHECK(custom_adder(num,10) > 100)
)
GO

-- SP_EXECUTESQL index creation/drop on temp tables
EXEC p_sp_executesql_index;
GO

-- SP_EXECUTESQL ALTER TABLE ADD column that creates toast table
EXEC p_sp_executesql_toast;
GO

-- Inline index creation via SP_EXECUTESQL
CREATE TABLE #temp_index1 (a INT, b VARCHAR(50));
GO
INSERT INTO #temp_index1 VALUES (1, 'one'), (2, 'two'), (3, 'three');
GO

DECLARE @sql1 NVARCHAR(MAX) = 'CREATE INDEX index1 ON #temp_index1(a)';
EXEC SP_EXECUTESQL @sql1;
GO

SELECT * FROM #temp_index1 WHERE a = 2;
GO

DROP INDEX index1 ON #temp_index1;
GO

SELECT * FROM #temp_index1 ORDER BY a;
GO

DROP TABLE #temp_index1;
GO

-- Inline ALTER TABLE ADD column (text type triggers toast) via SP_EXECUTESQL
CREATE TABLE #temp_heap1 (a INT);
GO
INSERT INTO #temp_heap1 VALUES (1);
GO

DECLARE @sql2 NVARCHAR(MAX) = 'ALTER TABLE #temp_heap1 ADD col1 TEXT';
EXEC SP_EXECUTESQL @sql2;
GO

UPDATE #temp_heap1 SET col1 = REPLICATE('x', 5000) WHERE a = 1;
GO

SELECT a, LEN(col1) as col1_len FROM #temp_heap1;
GO

DROP TABLE #temp_heap1;
GO

-- Index on column added via SP_EXECUTESQL
CREATE TABLE #temp_index2 (a INT);
GO
INSERT INTO #temp_index2 VALUES (1), (2), (3);
GO

DECLARE @sql4 NVARCHAR(MAX) = 'ALTER TABLE #temp_index2 ADD b INT DEFAULT 0';
EXEC SP_EXECUTESQL @sql4;
GO

UPDATE #temp_index2 SET b = a * 10;
GO

DECLARE @sql5 NVARCHAR(MAX) = 'CREATE INDEX index2 ON #temp_index2(b)';
EXEC SP_EXECUTESQL @sql5;
GO

SELECT * FROM #temp_index2 WHERE b > 10 ORDER BY b;
GO

DROP INDEX index2 ON #temp_index2;
GO

DROP TABLE #temp_index2;
GO
