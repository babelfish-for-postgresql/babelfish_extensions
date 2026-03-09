-- BABEL-5264: Test sp_tablecollations_100 functions for BCP temp table support

-- Test 1: Basic test of sys.sp_tablecollations_100_enr and tempdb.dbo.sp_tablecollations_100
CREATE TABLE #collTest1(id int, name varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS, description nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#collTest1')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#collTest1'
GO

DROP TABLE #collTest1
GO

-- Test 2: Test with various column types
CREATE TABLE #collTest2(
    a int,
    b text COLLATE SQL_Latin1_General_CP1_CI_AS,
    c ntext COLLATE SQL_Latin1_General_CP1_CI_AS,
    d varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS,
    e binary(10),
    f varbinary(20),
    g char(5) COLLATE SQL_Latin1_General_CP1_CI_AS,
    h nchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS
)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#collTest2')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#collTest2'
GO

DROP TABLE #collTest2
GO

-- Test 3: Test with different table name formats
CREATE TABLE #collTest3(col1 varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
GO

-- With hash prefix
SELECT * FROM sys.sp_tablecollations_100_enr('#collTest3')
GO

-- With schema prefix
SELECT * FROM sys.sp_tablecollations_100_enr('.[#collTest3]')
GO

-- With brackets
SELECT * FROM sys.sp_tablecollations_100_enr('[#collTest3]')
GO

DROP TABLE #collTest3
GO

-- Test 4: Test with non-existent table (should return empty)
SELECT * FROM sys.sp_tablecollations_100_enr('#nonExistentTable')
GO

-- Test 5: Test with multiple temp tables
CREATE TABLE #multiTest1(a varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS)
GO

CREATE TABLE #multiTest2(b nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#multiTest1')
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#multiTest2')
GO

DROP TABLE #multiTest1
GO

DROP TABLE #multiTest2
GO

-- Test 6: Temp table with different collations and case sensitivity
CREATE TABLE #collTest6(
    col_ci varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
    col_cs varchar(50) COLLATE SQL_Latin1_General_CP1_CS_AS,
    col_ai varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AI
)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#collTest6')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#collTest6'
GO

DROP TABLE #collTest6
GO

-- Test 7: Temp table with no character columns (all numeric/binary)
CREATE TABLE #noCharCols(
    id int,
    amount bigint,
    price decimal(10,2),
    flag bit,
    data binary(8)
)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#noCharCols')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#noCharCols'
GO

DROP TABLE #noCharCols
GO

-- Test 8: Temp table with dropped column
CREATE TABLE #droppedCol(
    id int,
    col_to_drop varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
    name varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS
)
GO

ALTER TABLE #droppedCol DROP COLUMN col_to_drop
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#droppedCol')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#droppedCol'
GO

DROP TABLE #droppedCol
GO

-- =====================================================
-- Non-ENR Temp Table Tests (using UDT to force non-ENR)
-- =====================================================

-- Test 9: Basic non-ENR temp table test
CREATE TABLE #nonEnrTest1(id int, name dbo.TestVarcharType1, description nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#nonEnrTest1')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#nonEnrTest1'
GO

DROP TABLE #nonEnrTest1
GO

-- Test 10: Non-ENR with various column types
CREATE TABLE #nonEnrTest2(
    a int,
    b dbo.TestVarcharType2,
    c nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS,
    d binary(10)
)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#nonEnrTest2')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#nonEnrTest2'
GO

DROP TABLE #nonEnrTest2
GO

-- Test 11: Non-ENR with different collations
CREATE TABLE #nonEnrTest3(
    col_default dbo.TestVarcharType3,
    col_ci varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
    col_cs varchar(50) COLLATE SQL_Latin1_General_CP1_CS_AS
)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#nonEnrTest3')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#nonEnrTest3'
GO

DROP TABLE #nonEnrTest3
GO

-- Test 12: Non-ENR with no character columns
CREATE TABLE #nonEnrNoChar(
    id dbo.TestIntType,
    amount bigint,
    price decimal(10,2)
)
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#nonEnrNoChar')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#nonEnrNoChar'
GO

DROP TABLE #nonEnrNoChar
GO

-- Test 13: Non-ENR with dropped column
CREATE TABLE #nonEnrDropped(
    id int,
    col_to_drop dbo.TestVarcharType4,
    name varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS
)
GO

ALTER TABLE #nonEnrDropped DROP COLUMN col_to_drop
GO

SELECT * FROM sys.sp_tablecollations_100_enr('#nonEnrDropped')
GO

EXEC tempdb.dbo.sp_tablecollations_100 '#nonEnrDropped'
GO

DROP TABLE #nonEnrDropped
GO
