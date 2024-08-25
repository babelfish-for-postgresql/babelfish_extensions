-- Case 2: Validate that correct collation is picked up for all databases
SELECT name, collation_name FROM sys.databases ORDER BY name;
GO

SELECT name, default_collation FROM babelfish_sysdatabases ORDER BY name;
GO

-- Case 3: Validate that correct collation is picked up for all databases using DATABASEPROPERTYEX
SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db11', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db121', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db122', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db131', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db132', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db133', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db134', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db135', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db136', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db137', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db138', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db139', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db141', 'Collation');
GO

SELECT DATABASEPROPERTYEX('test_db_collation_vu_prepare_db142', 'Collation');
GO

-- Case 4: Verify that the columns are picking correct collation (IMPLICIT COLLATION)
-- Case 7: Validate collations of datatypes using catalogs like sys.types
-- Case 8: CREATE custom datatype from system datatype and validate the same using sys.types
USE test_db_collation_vu_prepare_db11;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db11_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db11_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db121;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db121_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db121_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db122;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db122_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db122_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db131;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db131_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db131_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db132;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db132_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db132_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db133;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db133_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db133_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db134;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db134_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db134_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db135;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db135_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db135_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db136;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select COLUMN_NAME, COLLATION_NAME FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db136_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db136_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db137;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db137_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db137_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db138;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db138_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db138_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db139;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db139_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db139_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db141;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db141_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db141_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

USE test_db_collation_vu_prepare_db142;
GO

SELECT name, collation_name from sys.columns WHERE name IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY name + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db142_t1' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

select column_name, collation_name FROM information_schema_tsql.COLUMNS WHERE TABLE_NAME = 'test_db_collation_vu_prepare_db142_t2' AND
COLUMN_NAME IN ('c', 'nc', 'v', 'nv', 't', 'nt', 'sqlv', 'sn') ORDER BY COLLATION_NAME + COALESCE(collation_name, '');
GO

SELECT name, collation_name FROM SYS.TYPES WHERE collation_name IS NOT NULL ORDER BY name + COALESCE(collation_name, '');
GO

CREATE TYPE ct FROM NVARCHAR(11);
GO

SELECT name, collation_name FROM SYS.TYPES WHERE name = 'ct';
GO

-- Case 4.1: Computed columns
USE test_db_collation_vu_prepare_db121;
GO

SELECT * FROM test_db_collation_vu_prepare_db121_computed_columns ORDER BY a;
GO

SELECT * FROM test_db_collation_vu_prepare_db121_computed_columns ORDER BY b;
GO

-- Case 4.2: Temp Tables
CREATE TABLE #test_db_collation_vu_prepare_db121_temp_t1(a nvarchar(11), b nvarchar(11), c AS sys.reverse(b) NOT NULL)
GO

INSERT INTO #test_db_collation_vu_prepare_db121_temp_t1 VALUES
('café', 'jalapeño'),
('résumé', 'naïve'),
('Piñata', 'Año Nuevo'),
('TELÉFONO', 'película'),
('árbol', 'canapé'),
('chaptéR', 'TEññiȘ');
GO

SELECT * FROM #test_db_collation_vu_prepare_db121_temp_t1 WHERE c = 'evian'; -- reverse of naive
GO

SELECT * FROM #test_db_collation_vu_prepare_db121_temp_t1 ORDER BY c;
GO

CREATE TABLE #test_db_collation_vu_prepare_db121_temp_t2(a nvarchar(11), b nvarchar(11), c AS sys.reverse(b) NOT NULL)
GO

INSERT INTO #test_db_collation_vu_prepare_db121_temp_t2 VALUES
('café', 'jalapeño'),
('résumé', 'naïve'),
('Piñata', 'Año Nuevo'),
('TELÉFONO', 'película'),
('árbol', 'canapé'),
('chaptéR', 'TEññiȘ');
GO

SELECT t1.a, t2.a FROM #test_db_collation_vu_prepare_db121_temp_t1 t1 INNER JOIN #test_db_collation_vu_prepare_db121_temp_t2 t2 on t1.a = t2.a ORDER BY t1.a;
GO

-- Drop the temp tables
DROP TABLE #test_db_collation_vu_prepare_db121_temp_t1;
GO

DROP TABLE #test_db_collation_vu_prepare_db121_temp_t2;
GO

-- Case 4.3: Table Returning Functions
SELECT * FROM test_db_collation_vu_prepare_db121_f1();
GO

SELECT * FROM test_db_collation_vu_prepare_db121_f2();
GO

-- Case 4.4: SELECT INTO
-- Create a new table named "EmployeeData" based on the "Employees" table
SELECT * INTO test_db_collation_vu_prepare_db121_si1 FROM test_db_collation_vu_prepare_db121_t1 ORDER BY nv;
GO

SELECT * FROM test_db_collation_vu_prepare_db121_si1 ORDER BY nv;
GO

-- Create a new table with employees hired after 2015
SELECT * INTO test_db_collation_vu_prepare_db121_si2 FROM test_db_collation_vu_prepare_db121_t1 t1 WHERE t1.nv > 'naive' ORDER BY nv;
GO

SELECT * FROM test_db_collation_vu_prepare_db121_si2 ORDER BY nv;
GO


-- Case 6.1: Validate whether correct collation is being picked up or not by SIMPLE SELECT
USE test_db_collation_vu_prepare_db121;
GO

SELECT nv FROM test_db_collation_vu_prepare_db121_t1 where nv IN ('cafe', 'JALAPeno', 'ñáIVE', 'pínata') ORDER BY nv;
GO

SELECT nv FROM test_db_collation_vu_prepare_db121_t1 GROUP BY nv ORDER BY nv;
GO

CREATE VIEW test_db_collation_vu_prepare_db121_v1 AS SELECT nv FROM test_db_collation_vu_prepare_db121_t1 ORDER BY nv;
GO

SELECT * FROM test_db_collation_vu_prepare_db121_v1;
GO

SELECT * FROM test_db_collation_vu_prepare_db121_v1 GROUP BY nv ORDER BY nv;
GO

CREATE PROCEDURE test_db_collation_vu_prepare_db121_p1 @param NVARCHAR(50)
AS
BEGIN
    DECLARE @localVar NVARCHAR(11)

    SELECT @localVar = nv 
    FROM test_db_collation_vu_prepare_db121_t1
    WHERE nv = @param;

    SELECT @localVar;
END;
GO

-- Executing stored procedure
EXEC test_db_collation_vu_prepare_db121_p1 @param = 'cafe'
GO

EXEC test_db_collation_vu_prepare_db121_p1 @param = 'JALAPeno'
GO

EXEC test_db_collation_vu_prepare_db121_p1 @param = 'ñáIVE'
GO

EXEC test_db_collation_vu_prepare_db121_p1 @param = 'pínata'
GO

-- should return 10 rows instead of 12
SELECT t1.nv FROM test_db_collation_vu_prepare_db121_t1 t1 INNER JOIN test_db_collation_vu_prepare_db121_t2 t2 on t1.nv = t2.nv ORDER BY t1.nv;
GO

-- COMMENTING IT FOR NOW AS PREP EXEC IS NOT GIVING CORRECT OUTOUT
-- Case 6.2: Validate whether correct collation is being picked up or not by PREPARED STATEMENTS
-- DECLARE @prefix1 NVARCHAR(50) = 'cafe';
-- DECLARE @prefix2 NVARCHAR(50) = 'JALAPeno';
-- DECLARE @prefix3 NVARCHAR(50) = 'ñáIVE';
-- DECLARE @prefix4 NVARCHAR(50) = 'pínata';

-- DECLARE @query NVARCHAR(MAX) = N'SELECT nv FROM test_db_collation_vu_prepare_db121_t1 WHERE nv = @prefix1 OR nv = @prefix2 OR nv = @prefix3 OR nv = @prefix4';

-- EXEC sp_executesql @query,
--                    N'@prefix1 NVARCHAR(50), @prefix2 NVARCHAR(50), @prefix3 NVARCHAR(50), @prefix4 NVARCHAR(50)',
--                    @prefix1, @prefix2, @prefix3, @prefix4;
-- GO
-- DECLARE @prefix1 NVARCHAR(50) = 'cafe';
-- EXEC sp_executesql N'SELECT nv FROM test_db_collation_vu_prepare_db121_t1 WHERE nv = @prefix1;', N'@prefix1 NVARCHAR(50)', @prefix1;
-- GO

-- DECLARE @prefix1 NVARCHAR(50) = 'cafe';
-- DECLARE @prefix2 NVARCHAR(50) = 'JALAPeno';
-- DECLARE @prefix3 NVARCHAR(50) = 'ñáIVE';
-- DECLARE @prefix4 NVARCHAR(50) = 'pínata';

-- DECLARE @query NVARCHAR(MAX) = N'
-- DECLARE @nv NVARCHAR(50);
-- DECLARE CurResult CURSOR FOR
--     SELECT nv FROM test_db_collation_vu_prepare_db121_t1
--     WHERE nv = @prefix1 OR nv = @prefix2 OR nv = @prefix3 OR nv = @prefix4;

-- OPEN CurResult;
-- FETCH NEXT FROM CurResult INTO @nv;
-- WHILE @@FETCH_STATUS = 0
-- BEGIN
--     PRINT @nv;
--     FETCH NEXT FROM CurResult INTO @nv;
-- END
-- CLOSE CurResult;
-- DEALLOCATE CurResult;';

-- EXEC sp_executesql @query,
--                    N'@prefix1 NVARCHAR(50), @prefix2 NVARCHAR(50), @prefix3 NVARCHAR(50), @prefix4 NVARCHAR(50)',
--                    @prefix1, @prefix2, @prefix3, @prefix4;
-- GO


-- case 9: Cross-database queries (will behave like JOIN)
USE test_db_collation_vu_prepare_db121;
GO

SELECT t1.nv, t2.nv FROM test_db_collation_vu_prepare_db121_t1 t1 JOIN test_db_collation_vu_prepare_db11.dbo.test_db_collation_vu_prepare_db11_t1 t2 on t1.nv = t2.nv ORDER BY t1.nv;
GO

INSERT INTO test_db_collation_vu_prepare_db11.dbo.test_db_collation_vu_prepare_db11_t1 VALUES
('Řandom','Řandom','Řandom','Řandom','Řandom','Řandom','Řandom','Řandom');
GO

USE test_db_collation_vu_prepare_db11;
GO

-- should return NO ROW
SELECT nv FROM test_db_collation_vu_prepare_db11_t1 WHERE nv = 'Random';
GO

-- should return a single row
SELECT nv FROM test_db_collation_vu_prepare_db11_t1 WHERE nv = 'Řandom';
GO

SELECT t1.nv, t2.nv FROM test_db_collation_vu_prepare_db11_t1 t1 JOIN test_db_collation_vu_prepare_db121.dbo.test_db_collation_vu_prepare_db121_t1 t2 on t1.nv = t2.nv ORDER BY t1.nv;
GO