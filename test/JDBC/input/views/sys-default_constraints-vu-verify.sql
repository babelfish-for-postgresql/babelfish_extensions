SELECT definition FROM sys.default_constraints where name LIKE '%sys_default_constraints_vu_prepare_t1%'
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.default_constraints');
GO

SELECT definition FROM sys.default_constraints where name LIKE '%sys_default_definitions%' ORDER BY definition;
GO

ALTER TABLE sys_default_definitions_vu_prepare ADD CONSTRAINT default_column_a_varchar DEFAULT 'ab' FOR column_a;
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.default_constraints');
GO

-- Verify generated columns do not appear as default constraints (attgenerated filter working)
CREATE TABLE sys_default_constraints_vu_verify_generated (a INT DEFAULT 5, b AS (a + 1), c INT DEFAULT 10);
GO

-- Only columns with actual defaults (a, c) should appear, not generated column (b)
SELECT COUNT(*) FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_generated');
GO

-- Verify same count in sys.all_objects for this table
SELECT COUNT(*) FROM sys.all_objects WHERE type = 'D' AND parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_generated');
GO

-- Verify default constraints appear correctly in sys.all_objects with correct type
SELECT type, type_desc FROM sys.all_objects
WHERE parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_generated') AND type = 'D'
ORDER BY name;
GO

-- Verify table with all columns having named defaults shows correct count
CREATE TABLE sys_default_constraints_vu_verify_alldef (a INT CONSTRAINT DF_alldef_a DEFAULT 1, b INT CONSTRAINT DF_alldef_b DEFAULT 2, c VARCHAR(10) CONSTRAINT DF_alldef_c DEFAULT 'abc');
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_alldef');
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type = 'D' AND parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_alldef');
GO

-- Verify table with NO defaults shows zero constraints
CREATE TABLE sys_default_constraints_vu_verify_nodef (a INT, b INT, c VARCHAR(10));
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_nodef');
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type = 'D' AND parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_nodef');
GO

-- Verify add default - constraint appears in both views
ALTER TABLE sys_default_constraints_vu_verify_nodef ADD CONSTRAINT DF_nodef_a DEFAULT 99 FOR a;
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_nodef');
GO

SELECT COUNT(*) FROM sys.all_objects WHERE type = 'D' AND parent_object_id = OBJECT_ID('sys_default_constraints_vu_verify_nodef');
GO
