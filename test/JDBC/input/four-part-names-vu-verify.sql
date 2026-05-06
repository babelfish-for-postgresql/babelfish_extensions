-- single_db_mode_expected
-- sla 60000
SET BABELFISH_STATISTICS PROFILE on
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP0 - Start' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

CREATE TABLE fpn_table (a int, b varchar(10))
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP1 - After CREATE TABLE' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM bbf_fpn_server.master.dbo.fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP2 - After SELECT empty remote' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

INSERT INTO fpn_table VALUES (1, 'one')
INSERT INTO fpn_table VALUES (2, 'two')
INSERT INTO fpn_table VALUES (3, 'three')
INSERT INTO fpn_table VALUES (4, 'four')
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP3 - After INSERTs' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT a, b FROM bbf_fpn_server.master.dbo.fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP4 - After SELECT remote table' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM bbf_fpn_server.master.sys.data_spaces
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP5 - After SELECT remote view' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT a + 1, b FROM bbf_fpn_server.master..fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP6 - After SELECT db..object' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM bbf_fpn_server..sys.data_spaces
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP7 - After SELECT ..schema.object' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT a*2, REVERSE(b) FROM bbf_fpn_server...fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP8 - After SELECT ...object' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM invalid_server.master.dbo.fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP9 - After invalid server' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM bbf_fpn_server.invalid_db.dbo.fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP10 - After invalid db' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM bbf_fpn_server.master.invalid_schema.fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP11 - After invalid schema' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM bbf_fpn_server.master.dbo.invalid_fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP12 - After invalid object' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

EXEC bbf_fpn_server.master.dbo.sp_linkedserver
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP13 - After EXEC error' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

INSERT INTO bbf_fpn_server.master.dbo.fpn_table VALUES (5, 'five')
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP14 - After INSERT error' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

UPDATE bbf_fpn_server.master.dbo.fpn_table SET b = 'Update one' WHERE a = 1
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP15 - After UPDATE error' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

DELETE FROM bbf_fpn_server.master.dbo.fpn_table WHERE a = 1
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP16 - After DELETE error' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

CREATE VIEW four_part_names_vu_verify_view AS SELECT * FROM bbf_fpn_server.master.dbo.fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP17 - After CREATE VIEW' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM four_part_names_vu_verify_view
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP18 - After SELECT from view' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

CREATE TABLE fpn_table_insert_into (a int, b varchar(10))
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP19 - After CREATE TABLE insert_into' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

INSERT INTO fpn_table_insert_into SELECT * FROM bbf_fpn_server.master.dbo.fpn_table WHERE a < 4
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP20 - After INSERT INTO SELECT' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM fpn_table_insert_into
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP21 - After SELECT fpn_table_insert_into' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * INTO fpn_table_select_into FROM bbf_fpn_server.master.dbo.fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP22 - After SELECT INTO' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM fpn_table_select_into
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP23 - After SELECT fpn_table_select_into' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT fpn_table.*, t2.*
FROM fpn_table_insert_into fpn_table
LEFT JOIN 
bbf_fpn_server.master.dbo.fpn_table t2
ON fpn_table.a = t2.a
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP24 - After JOIN local+remote' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT fpn_table.a, t2.*
FROM bbf_fpn_server.master.dbo.fpn_table fpn_table
LEFT JOIN 
fpn_table_insert_into t2
ON fpn_table.a = t2.a
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP25 - After JOIN remote+local' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT fpn_table.*, t2.a, t2.b
FROM bbf_fpn_server.master.dbo.fpn_table fpn_table
LEFT JOIN 
bbf_fpn_server.master.dbo.fpn_table_insert_into t2
ON fpn_table.a = t2.a
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP26 - After JOIN remote+remote' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

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

DECLARE @t DATETIME = GETDATE()
SELECT 'CP27 - After UPDATE with JOIN' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM fpn_table_insert_into
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP28 - After SELECT fpn_table_insert_into' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

DELETE Table_A
FROM
fpn_table_select_into AS Table_A
INNER JOIN bbf_fpn_server.master.dbo.fpn_table AS Table_B
ON Table_A.a = Table_B.a
WHERE
(Table_A.a + Table_B.a) % 4 = 0
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP29 - After DELETE with JOIN' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM fpn_table_select_into
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP30 - After SELECT fpn_table_select_into' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

WITH cte_table_for_fpn (a)
AS
(
        SELECT a from bbf_fpn_server.master.dbo.fpn_table
)
SELECT AVG(a) FROM cte_table_for_fpn
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP31 - After CTE' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM fpn_table_insert_into WHERE a > (SELECT MAX(a) FROM bbf_fpn_server.master.dbo.fpn_table)
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP32 - After subquery MAX' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM fpn_table_select_into WHERE b IN (SELECT b FROM bbf_fpn_server.master.dbo.fpn_table)
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP33 - After subquery IN' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT a, (SELECT b from bbf_fpn_server.master.dbo.fpn_table where b = t.b) as c
FROM fpn_table_insert_into t
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP34 - After subquery as column' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT * FROM fpn_table_insert_into WHERE EXISTS (SELECT * FROM bbf_fpn_server.master.dbo.fpn_table as fpn_table_alias WHERE fpn_table_alias.a = fpn_table_insert_into.a)
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP35 - After correlated subquery' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

CREATE PROCEDURE fpn_vu_prepare__fpn_proc AS SELECT * FROM bbf_fpn_server.master..fpn_table
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP36 - After CREATE PROC' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

CREATE FUNCTION fpn_vu_prepare__fpn_func()
RETURNS INT
AS
BEGIN
DECLARE @i int
SELECT @i = COUNT(*) FROM bbf_fpn_server.master.dbo.fpn_table
RETURN @i
END
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP37 - After CREATE FUNC' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

EXEC fpn_vu_prepare__fpn_proc
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP38 - After EXEC proc' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SELECT fpn_vu_prepare__fpn_func()
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP39 - After SELECT func' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

SET QUOTED_IDENTIFIER ON
GO

select * from [bbf_fpn_server'', ''select * from fpn_table'') select * from openquery(''bbf_fpn_server].master.sys.databases
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP40 - After injection server []' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

select * from "bbf_fpn_server'', ''select * from fpn_table'') select * from openquery(''bbf_fpn_server".master.sys.databases
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP41 - After injection server ""' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

select * from bbf_fpn_server.[fpn_table'') select * from openquery(''bbf_fpn_server'', ''select * from master].sys.databases
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP42 - After injection db []' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

select * from bbf_fpn_server."fpn_table'') select * from openquery(''bbf_fpn_server'', ''select * from master".sys.databases
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP43 - After injection db ""' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

select * from bbf_fpn_server.master.[sys.tables'') select * from openquery(''bbf_fpn_server'', ''select * from master.sys].databases
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP44 - After injection schema []' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

select * from bbf_fpn_server.master."sys.tables'') select * from openquery(''bbf_fpn_server'', ''select * from master.sys".databases
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP45 - After injection schema ""' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

select * from bbf_fpn_server.master.sys.[tables'') select * from openquery(''bbf_fpn_server'', ''select * from master.sys.databases]
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP46 - After injection object []' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

select * from bbf_fpn_server.master.sys."tables'') select * from openquery(''bbf_fpn_server'', ''select * from master.sys.databases"
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP47 - After injection object ""' as cp, CONVERT(VARCHAR, @t, 121) as t
GO

DROP TABLE fpn_table_insert_into
DROP TABLE fpn_table_select_into
DROP TABLE fpn_table
DROP VIEW four_part_names_vu_verify_view
DROP PROCEDURE fpn_vu_prepare__fpn_proc
DROP FUNCTION fpn_vu_prepare__fpn_func()
GO

DECLARE @t DATETIME = GETDATE()
SELECT 'CP48 - After cleanup (END)' as cp, CONVERT(VARCHAR, @t, 121) as t
GO
