USE MASTER;
GO

CREATE TABLE dbo.test_table1 (test_id INT IDENTITY, test_col1 INT);
go

CREATE PROCEDURE insert_test_table1
    @id INT, 
    @val INT
AS
    INSERT INTO dbo.test_table1 (test_id, test_col1) VALUES (@id, @val);
go

SELECT @@IDENTITY;
go
SELECT SCOPE_IDENTITY();
go
INSERT INTO dbo.test_table1 (test_col1) VALUES (10);
go
SELECT @@IDENTITY;
go
SELECT SCOPE_IDENTITY();
go
SELECT @@SERVERNAME;
go
-- Expect an error
INSERT INTO dbo.test_table1 (test_id, test_col1) VALUES (2, 10);
go

SET IDENTITY_INSERT dbo.test_table1 ON;
go

-- Test custom insert
EXECUTE insert_test_table1 2, 10;
go

-- Insert a non-sequential max identity value
EXECUTE insert_test_table1 10, 10;
go

-- Insert a lesser identity value
EXECUTE insert_test_table1 5, 10;
go

-- Set to off. Notice we're not specifying the schema this time
SET IDENTITY_INSERT test_table1 OFF;
go

-- Verify the identity sequence value is updated to the max value
INSERT INTO dbo.test_table1 (test_col1) VALUES (11);
go
INSERT INTO dbo.test_table1 (test_col1) VALUES (12);
go

SELECT * FROM dbo.test_table1;
go

-- Expect an error. Verify IDENTITY_INSERT set off
INSERT INTO dbo.test_table1 (test_id, test_col1) VALUES (2, 10);
go

-- Set to table then drop it. Should implicitly turn IDENTITY_INSERT off
SET IDENTITY_INSERT dbo.test_table1 ON;
go
DROP TABLE test_table1;
go

-- Create a table with the same name
CREATE TABLE dbo.test_table1 (test_id INT IDENTITY, test_col1 INT);
go

-- Try to insert. Expect an error. Same name but different OID
INSERT INTO dbo.test_table1 (test_id, test_col1) VALUES (2, 10);
go

-- Expect errors
SET IDENTITY_INSERT test_table2 ON;
go
SET IDENTITY_INSERT fake_schema.test_table1 ON;
go
SET IDENTITY_INSERT fake_db.dbo.test_table1 ON;
go

CREATE TABLE dbo.test_table2 (test_id INT IDENTITY(7,2), test_col1 INT);
go

-- Expect error. Set IDENTITY_INSERT to a table then try setting it to another
SET IDENTITY_INSERT dbo.test_table1 ON;
go
SET IDENTITY_INSERT dbo.test_table2 ON;
go
SET IDENTITY_INSERT dbo.test_table1 OFF;
go
INSERT INTO dbo.test_table2 (test_col1) VALUES (13);
go
INSERT INTO dbo.test_table2 (test_col1) VALUES (108);
go
SELECT @@IDENTITY;
go
SELECT SCOPE_IDENTITY();
go

SELECT * FROM dbo.test_table2;
go

-- Expect error. Cannot set IDENTITY_INSERT to table without identity property
CREATE TABLE dbo.test_table3 (test_id INT, test_col1 INT);
go

SET IDENTITY_INSERT dbo.test_table3 ON;
go

-- Test INSERT with default target list that omits identity columns
CREATE TABLE dbo.employees 
(person_id int IDENTITY PRIMARY KEY, firstname nvarchar(20), lastname nvarchar(30), salary money);
go

INSERT INTO employees VALUES (N'Neil', N'Armstrong', 11236.9898);
go

SELECT * FROM dbo.employees;
go

-- Test identity insert with multiple columns
SET IDENTITY_INSERT dbo.employees ON;
go

CREATE PROCEDURE insert_employees
    @id INT,
    @first TEXT,
    @last TEXT,
    @salary NUMERIC(18,4)
AS
    INSERT INTO dbo.employees (person_id, firstname, lastname, salary) VALUES (@id, @first, @last, @salary);
go

EXEC insert_employees 5, N'Buzz', N'Aldrin', 11236.9898;
go

SELECT @@IDENTITY;
go

-- Expect Errors. Cannot insert without explicit identity column value
INSERT INTO employees VALUES (N'Michael', N'Collins', 11236.9898);
go

INSERT INTO employees (firstname, lastname, salary) VALUES (N'Michael', N'Collins', 11236.9898);
go

SET IDENTITY_INSERT dbo.employees OFF;
go

INSERT INTO employees VALUES (N'Michael', N'Collins', 11236.9898);
go

SELECT * FROM dbo.employees;
go

-- Test Camel Case
CREATE TABLE [dbo].[Test_Table1]([Test_Id] INT IDENTITY, test_col1 INT);
go

SET IDENTITY_INSERT [Test_Table1] ON;
go

CREATE PROCEDURE insert_test_table_c
    @id INT, 
    @val INT
AS
    INSERT INTO [dbo].[Test_Table1] ([Test_Id], test_col1) VALUES (@id, @val);
go

CREATE PROCEDURE insert_test_table_c_default
    @val INT
AS
    INSERT INTO [dbo].[Test_Table1] (test_col1) VALUES (@val);
go

EXEC insert_test_table_c 1, 10;
go

EXEC insert_test_table_c 5, 20;
go

-- Expect error. Insert restriction
EXEC insert_test_table_c_default 30;
go
-- Expect errors. Not matching case
SET IDENTITY_INSERT Test_Table1 ON;
go
SET IDENTITY_INSERT [tEst_tAble1] ON;
go
SET IDENTITY_INSERT [dbo].[Test_Table1] ON;
go
INSERT INTO [dbo].[Test_Table1] (test_id, test_col1) VALUES (10, 30);
go

-- Set to off and verify table
SET IDENTITY_INSERT [dbo].[Test_Table1] OFF;
go

EXEC insert_test_table_c_default 30;
go

SELECT * FROM [Test_Table1];
go

-- Test updating negative increment
CREATE TABLE dbo.t_neg_inc_1(id INT IDENTITY(1, -1), col1 INT);
go

CREATE PROCEDURE insert_default_neg_inc_1
	@val INT
AS BEGIN
	INSERT INTO dbo.t_neg_inc_1(col1) VALUES (@val);
END;
go

CREATE PROCEDURE insert_id_neg_inc_1
	@id INT,
	@val INT
AS BEGIN
	SET IDENTITY_INSERT t_neg_inc_1 ON;
	INSERT INTO dbo.t_neg_inc_1(id, col1) VALUES (@id, @val);
	SET IDENTITY_INSERT t_neg_inc_1 OFF;
END;
go

EXEC insert_default_neg_inc_1 10;
go

EXEC insert_default_neg_inc_1 20;
go

EXEC insert_id_neg_inc_1 -5, 30;
go

EXEC insert_default_neg_inc_1 40;
go

EXEC insert_id_neg_inc_1 5, 50;
go

EXEC insert_default_neg_inc_1 60;
go

SELECT * FROM t_neg_inc_1;
go

-- Test that identity counters shouldn't rolled back even if the transaction
-- is rolled back.
CREATE TABLE dbo.t1_identity_1(a int identity primary key, b int unique not null);
SET IDENTITY_INSERT dbo.t1_identity_1 ON;
INSERT INTO dbo.t1_identity_1 (a,b) VALUES (1,1);
go

-- Test with an error in setval
ALTER SEQUENCE t1_identity_1_a_seq MAXVALUE 700
INSERT INTO dbo.t1_identity_1 (a,b) VALUES (800,2);
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_1'); SELECT SCOPE_IDENTITY();
go

-- Test with setval after an error
-- It should update on IDENT_CURRENT, not other identity variables
SELECT setval('t1_identity_1_a_seq', 32);
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_1'); SELECT SCOPE_IDENTITY();
go

-- Check transaction rollback should increase identity
BEGIN TRAN t1; INSERT INTO dbo.t1_identity_1 (a,b) VALUES (300,2); ROLLBACK TRAN t1;
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_1'); SELECT SCOPE_IDENTITY();
go

-- Check Statement error shouldn't increase identity
BEGIN TRAN t1; INSERT INTO dbo.t1_identity_1 (a,b) VALUES (400,1); ROLLBACK TRAN t1;
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_1'); SELECT SCOPE_IDENTITY();
go

-- Smaller value shouldn't update identity seed
INSERT INTO dbo.t1_identity_1 (a,b) VALUES (100,3);
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_1'); SELECT SCOPE_IDENTITY();
go

-- After identity insert off, the insert should start from the next seed that
-- setval sets
SELECT setval('t1_identity_1_a_seq', 500);
go

SET IDENTITY_INSERT dbo.t1_identity_1 OFF;
go

INSERT INTO dbo.t1_identity_1 (b) VALUES (4);
SELECT a FROM dbo.t1_identity_1 where b = 4;
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_1'); SELECT SCOPE_IDENTITY();
go

CREATE TABLE dbo.t1_identity_2(a int identity(1, -1) primary key, b int unique not null);
SET IDENTITY_INSERT dbo.t1_identity_2 ON;
INSERT INTO dbo.t1_identity_2 (a,b) VALUES (1,1);
go

-- Check transaction rollback should decrease identity
BEGIN TRAN t1; INSERT INTO dbo.t1_identity_2 (a,b) VALUES (-300,2); ROLLBACK TRAN t1;
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_2'); SELECT SCOPE_IDENTITY();
go

-- Check Statement error shouldn't decrease identity
BEGIN TRAN t1; INSERT INTO dbo.t1_identity_2 (a,b) VALUES (-400,1); ROLLBACK TRAN t1;
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_2'); SELECT SCOPE_IDENTITY();
go

-- Larger value shouldn't update identity seed
INSERT INTO dbo.t1_identity_2 (a,b) VALUES (-100,3);
SELECT @@IDENTITY; SELECT IDENT_CURRENT('dbo.t1_identity_2'); SELECT SCOPE_IDENTITY();
go

SET IDENTITY_INSERT dbo.t1_identity_2 OFF;
go

-- Test that the correct range of values can be inserted into an identity column
CREATE TABLE dbo.test_identity_range (a INT IDENTITY, b INT);
go

SET IDENTITY_INSERT dbo.test_identity_range ON;
go

-- Check nonpositive values
INSERT INTO dbo.test_identity_range (a, b) VALUES (0, 10);
go

INSERT INTO dbo.test_identity_range (a, b) VALUES (-5, 10);
go

-- Check max / min
INSERT INTO dbo.test_identity_range (a, b) VALUES (-2147483648, 10);
go

INSERT INTO dbo.test_identity_range (a, b) VALUES (2147483647, 10);
go

-- Expect overflow
INSERT INTO dbo.test_identity_range (a, b) VALUES (-2147483649, 10);
go

INSERT INTO dbo.test_identity_range (a, b) VALUES (2147483648, 10);
go

SELECT * from dbo.test_identity_range;
go

-- scope_identity in where clause should use index (BABEL-3384)
CREATE TABLE dbo.test_identity_index (id INT IDENTITY(1,1) PRIMARY KEY, mycol INT)
go

INSERT INTO dbo.test_identity_index SELECT 10 FROM generate_series(1,10);
go

CREATE TABLE dbo.test_numeric_index (num_index NUMERIC PRIMARY KEY, mycol INT)
go

INSERT INTO dbo.test_numeric_index VALUES(10,10);
go

SELECT scope_identity();
go

SET babelfish_showplan_all ON;
go

SELECT id, mycol FROM dbo.test_identity_index WHERE id = scope_identity();
go

SELECT id, mycol FROM dbo.test_identity_index WHERE scope_identity() = id;
go

SELECT id, mycol FROM dbo.test_identity_index WHERE dbo.test_identity_index.id = scope_identity();
go

SELECT id, mycol FROM dbo.test_identity_index WHERE id > scope_identity();
go

SELECT id, mycol FROM dbo.test_identity_index WHERE id != scope_identity();
go

SELECT id, mycol FROM dbo.test_identity_index WHERE mycol = 10 AND id = scope_identity();
go

SELECT id, mycol FROM dbo.test_identity_index WHERE id <= scope_identity() OR mycol = 11;
go

SELECT num_index, mycol FROM dbo.test_numeric_index WHERE num_index = scope_identity();
go

SET babelfish_showplan_all OFF;
go

-- Clean up
DROP PROCEDURE insert_test_table1,
insert_employees,
insert_test_table_c,
insert_test_table_c_default,
insert_default_neg_inc_1,
insert_id_neg_inc_1;
go
DROP TABLE dbo.test_table1,
dbo.test_table2,
dbo.test_table3,
dbo.employees,
dbo.t_neg_inc_1,
dbo.t1_identity_1,
dbo.t1_identity_2,
dbo.test_identity_range,
dbo.test_identity_index,
dbo.test_numeric_index
go
