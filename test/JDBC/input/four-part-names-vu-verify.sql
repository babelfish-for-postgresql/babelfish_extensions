CREATE TABLE fpn_table (a int, b varchar(10))
GO

SELECT * FROM bbf_fpn_server.master.dbo.fpn_table
GO

INSERT INTO fpn_table VALUES (1, 'one')
INSERT INTO fpn_table VALUES (2, 'two')
INSERT INTO fpn_table VALUES (3, 'three')
INSERT INTO fpn_table VALUES (4, 'four')
GO

-- server_name.database_name.schema_name.object_name (table)
SELECT a, b FROM bbf_fpn_server.master.dbo.fpn_table
GO

-- server_name.database_name.schema_name.object_name (view)
SELECT * FROM bbf_fpn_server.master.sys.data_spaces
GO

-- server_name.database_name..object_name
SELECT a + 1, b FROM bbf_fpn_server.master..fpn_table
GO

-- server_name..schema_name.object_name
SELECT * FROM bbf_fpn_server..sys.data_spaces
GO

-- server_name...object_name
SELECT a*2, REVERSE(b) FROM bbf_fpn_server...fpn_table
GO

-- Invalid server name (Should throw error)
SELECT * FROM invalid_server.master.dbo.fpn_table
GO

-- Invalid database name (Should throw error)
SELECT * FROM bbf_fpn_server.invalid_db.dbo.fpn_table
GO

-- Invalid schema name (Should throw error)
SELECT * FROM bbf_fpn_server.master.invalid_schema.fpn_table
GO

-- Invalid object name (Should throw error)
SELECT * FROM bbf_fpn_server.master.dbo.invalid_fpn_table
GO

-- four part object is a procedure (Should throw error)
EXEC bbf_fpn_server.master.dbo.sp_linkedserver
GO

-- INSERT should not work with four-part object name
INSERT INTO bbf_fpn_server.master.dbo.fpn_table VALUES (5, 'five')
GO

-- UPDATE should not work with four-part object name
UPDATE bbf_fpn_server.master.dbo.fpn_table SET b = 'Update one' WHERE a = 1
GO

-- DELETE should not work with four-part object name
DELETE FROM bbf_fpn_server.master.dbo.fpn_table WHERE a = 1
GO

-- CREATE VIEW using four-part names
CREATE VIEW four_part_names_vu_verify_view AS SELECT * FROM bbf_fpn_server.master.dbo.fpn_table
GO

SELECT * FROM four_part_names_vu_verify_view
GO

-- INSERT INTO ... SELECT
CREATE TABLE fpn_table_insert_into (a int, b varchar(10))
GO

INSERT INTO fpn_table_insert_into SELECT * FROM bbf_fpn_server.master.dbo.fpn_table WHERE a < 4
GO

SELECT * FROM fpn_table_insert_into
GO

-- SELECT INTO
SELECT * INTO fpn_table_select_into FROM bbf_fpn_server.master.dbo.fpn_table
GO

SELECT * FROM fpn_table_select_into
GO

-- JOIN between local and remote table
SELECT fpn_table.*, t2.*
FROM fpn_table_insert_into fpn_table
LEFT JOIN 
bbf_fpn_server.master.dbo.fpn_table t2
ON fpn_table.a = t2.a
GO

SELECT fpn_table.a, t2.*
FROM bbf_fpn_server.master.dbo.fpn_table fpn_table
LEFT JOIN 
fpn_table_insert_into t2
ON fpn_table.a = t2.a
GO

-- JOIN between two remote tables
SELECT fpn_table.*, t2.a, t2.b
FROM bbf_fpn_server.master.dbo.fpn_table fpn_table
LEFT JOIN 
bbf_fpn_server.master.dbo.fpn_table_insert_into t2
ON fpn_table.a = t2.a
GO

-- UPDATE on local table with JOIN containing remote table
UPDATE Table_A
SET
Table_A.a = Table_B.a + 100,
Table_A.b = Table_B.b + CAST(Table_B.a AS varchar(5))
FROM
fpn_table_insert_into AS Table_A
INNER JOIN bbf_fpn_server.master.dbo.fpn_table AS Table_B
ON Table_A.a = Table_B.a
WHERE
Table_A.a < 3
GO

SELECT * FROM fpn_table_insert_into
GO

-- DELETE on local table with JOIN containing remote table
DELETE Table_A
FROM
fpn_table_select_into AS Table_A
INNER JOIN bbf_fpn_server.master.dbo.fpn_table AS Table_B
ON Table_A.a = Table_B.a
WHERE
(Table_A.a + Table_B.a) % 4 = 0
GO

SELECT * FROM fpn_table_select_into
GO

-- In CTE
WITH cte_table_for_fpn (a)
AS
(
        SELECT a from bbf_fpn_server.master.dbo.fpn_table
)
SELECT AVG(a) FROM cte_table_for_fpn
GO

-- In Subquery
SELECT * FROM fpn_table_insert_into WHERE a > (SELECT MAX(a) FROM bbf_fpn_server.master.dbo.fpn_table)
GO

SELECT * FROM fpn_table_select_into WHERE b IN (SELECT b FROM bbf_fpn_server.master.dbo.fpn_table)
GO

-- In Correlated subquery
SELECT * FROM fpn_table_insert_into WHERE EXISTS (SELECT * FROM bbf_fpn_server.master.dbo.fpn_table as fpn_table_alias WHERE fpn_table_alias.a = fpn_table_insert_into.a)
GO

-- Try SQL Injection
-- We cannot directly inject SQL because it will break T-SQL database identifier rules
-- We have to surround the SQL in double quotes ("") or square brackets ([]) if we want to even attempt that
-- All cases should throw an error

-- To allow identifiers be specified with double quotes
SET QUOTED_IDENTIFIER ON
GO

-- SQL Injection in server name
-- Try to inject SQL such that the final rewritten query looks like:
-- select * from openquery('bbf_fpn_server', 'select * from fpn_table') select * from openquery('bbf_fpn_server', 'select * from master.sys.databases')
-- Will throw error: servername is invalid
select * from [bbf_fpn_server'', ''select * from fpn_table'') select * from openquery(''bbf_fpn_server].master.sys.databases
GO

select * from "bbf_fpn_server'', ''select * from fpn_table'') select * from openquery(''bbf_fpn_server".master.sys.databases
GO

-- SQL Injection in database name
-- Try to inject SQL such that the final rewritten query looks like:
-- select * from openquery('bbf_fpn_server', 'select * from fpn_table') select * from openquery('bbf_fpn_server', 'select * from master.sys.databases')
-- Will throw error: database name is invalid
select * from bbf_fpn_server.[fpn_table'') select * from openquery(''bbf_fpn_server'', ''select * from master].sys.databases
GO

select * from bbf_fpn_server."fpn_table'') select * from openquery(''bbf_fpn_server'', ''select * from master".sys.databases
GO

-- SQL Injection in schema name
-- Try to inject SQL such that the final rewritten query looks like:
-- select * from openquery('bbf_fpn_server', 'select * from master.sys.tables') select * from openquery('bbf_fpn_server', 'select * from master.sys.databases')
-- Will throw error: relation is invalid
select * from bbf_fpn_server.master.[sys.tables'') select * from openquery(''bbf_fpn_server'', ''select * from master.sys].databases
GO

select * from bbf_fpn_server.master."sys.tables'') select * from openquery(''bbf_fpn_server'', ''select * from master.sys".databases
GO

-- SQL Injection in object name
-- Try to inject SQL such that the final rewritten query looks like:
-- select * from openquery('bbf_fpn_server', 'select * from master.sys.tables') select * from openquery('bbf_fpn_server', 'select * from master.sys.databases')
-- Will throw error: relation is invalid
select * from bbf_fpn_server.master.sys.[tables'') select * from openquery(''bbf_fpn_server'', ''select * from master.sys.databases]
GO

select * from bbf_fpn_server.master.sys."tables'') select * from openquery(''bbf_fpn_server'', ''select * from master.sys.databases"
GO

DROP TABLE fpn_table_insert_into
DROP TABLE fpn_table_select_into
DROP TABLE fpn_table
DROP VIEW four_part_names_vu_verify_view
GO
