--------------------------------------------------
--- CREATE PARTITION FUNCTION with Collate clause
--------------------------------------------------

--------------------------------------------------------------------
--- Case 1. Usage of invalid collation with collatable datatype
--------------------------------------------------------------------
-- Try to create a partition function with an invalid collation for a collatable datatype (NVARCHAR)
-- Expected result: Throws an error indicating that collation is invalid
CREATE PARTITION FUNCTION PF_InvalidCollation (NVARCHAR(10) COLLATE invalid_collation)
AS RANGE RIGHT FOR VALUES (N'a', N'b', N'c');
GO

------------------------------------------------------------------------------------------
--- Case 2. Usage of invalid collation with unsupported datatype for partition function
------------------------------------------------------------------------------------------
-- Try to create a partition function with an invalid collation with unsupported datatype
-- Expected result: Throws an error indicating that collation is invalid
CREATE PARTITION FUNCTION VarcharMaxPartitionFunction (VARCHAR(MAX) COLLATE invalid_collation) 
AS RANGE RIGHT FOR VALUES ('A', 'B', 'C', 'D');
GO

CREATE PARTITION FUNCTION NVarcharMaxPartitionFunction (NVARCHAR(MAX) COLLATE invalid_collation) 
AS RANGE RIGHT FOR VALUES (N'A', N'B', N'C', N'D');
GO

CREATE PARTITION FUNCTION VarbinaryMaxPartitionFunction (VARBINARY(MAX) COLLATE invalid_collation) 
AS RANGE RIGHT FOR VALUES (0x000, 0x800, 0x400, 0xC000);
GO

CREATE PARTITION FUNCTION TextPartitionFunction (text COLLATE invalid_collation)
AS RANGE RIGHT FOR VALUES ('a', 'b', 'c');
GO

CREATE PARTITION FUNCTION NTextPartitionFunction (ntext COLLATE invalid_collation)
AS RANGE RIGHT FOR VALUES (N'a', N'b', N'c');
GO

CREATE PARTITION FUNCTION ImagePartitionFunction (image COLLATE invalid_collation)
AS RANGE RIGHT FOR VALUES (0x123456, 0x789ABC, 0xDEF012);
GO

CREATE PARTITION FUNCTION XmlPartitionFunction (xml COLLATE invalid_collation)
AS RANGE RIGHT FOR VALUES ('<a>1</a>', '<b>2</b>', '<c>3</c>');
GO

------------------------------------------------------------------------------------------
--- Case 3. Usage of valid collation with unsupported datatype for partition function
------------------------------------------------------------------------------------------
-- Try to create a partition function with an valid collation with unsupported datatype
-- Expected result: Throws an error indicating that datatype is not supported
CREATE PARTITION FUNCTION VarcharMaxPartitionFunction (VARCHAR(MAX) COLLATE Latin1_General_CI_AS) 
AS RANGE RIGHT FOR VALUES ('A', 'B', 'C', 'D');
GO

CREATE PARTITION FUNCTION NVarcharMaxPartitionFunction (NVARCHAR(MAX) COLLATE Latin1_General_CI_AS) 
AS RANGE RIGHT FOR VALUES (N'A', N'B', N'C', N'D');
GO

CREATE PARTITION FUNCTION VarbinaryMaxPartitionFunction (VARBINARY(MAX) COLLATE Latin1_General_CI_AS) 
AS RANGE RIGHT FOR VALUES (0x000, 0x800, 0x400, 0xC000);
GO

CREATE PARTITION FUNCTION TextPartitionFunction (text COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES ('a', 'b', 'c');
GO

CREATE PARTITION FUNCTION NTextPartitionFunction (ntext COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (N'a', N'b', N'c');
GO

CREATE PARTITION FUNCTION ImagePartitionFunction (image COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (0x123456, 0x789ABC, 0xDEF012);
GO

CREATE PARTITION FUNCTION XmlPartitionFunction (xml COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES ('<a>1</a>', '<b>2</b>', '<c>3</c>');
GO

--------------------------------------------------------------------
--- Case 5. Usage of invalid collation with non-collatable datatype
--------------------------------------------------------------------
-- Try to create a partition function with an invalid collation for a non-collatable datatype
-- Expected result: Throws an error indicating the collation is invalid
CREATE PARTITION FUNCTION PF_InvalidCollationNonCollatable (INT COLLATE invalid_collation)
AS RANGE RIGHT FOR VALUES (1, 10, 100);
Go

--------------------------------------------------------------------
--- Case 6. Usage of valid collation with non-collatable datatype
--------------------------------------------------------------------
-- Try to create a partition function with a valid collation for a non-collatable datatype
-- Expected result: Throws an error indicating that datatype cannot have a collation

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableBIGINT (BIGINT COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1, 10, 100);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableTINYINT (TINYINT COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1, 10, 100);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableSMALLINT (SMALLINT COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1, 10, 100);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableBIT (BIT COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (0, 1);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableREAL (REAL COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1.0, 10.0, 100.0);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableFLOAT (FLOAT COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1.0, 10.0, 100.0);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableDECIMAL (DECIMAL(10,2) COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1.00, 10.00, 100.00);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableNUMERIC (NUMERIC(10,2) COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1.00, 10.00, 100.00);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableMONEY (MONEY COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1.00, 10.00, 100.00);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableSMALLMONEY (SMALLMONEY COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES (1.00, 10.00, 100.00);
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableDATEDATE (DATE COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2023-02-01', '2023-03-01');
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatateTIME (TIME COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES ('00:00:00', '12:00:00', '23:59:59');
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableDATETIME (DATETIME COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES ('2023-01-01 00:00:00', '2023-02-01 12:00:00', '2023-03-01 23:59:59');
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableDATETIME2 (DATETIME2 COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES ('2023-01-01 00:00:00.000', '2023-02-01 12:00:00.000', '2023-03-01 23:59:59.999');
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatableSMALLDATETIME (SMALLDATETIME COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES ('2023-01-01 00:00:00', '2023-02-01 12:00:00', '2023-03-01 23:59:59');
GO

CREATE PARTITION FUNCTION PF_ValidCollationNonCollatatableUNIQUEIDENTIFIER (UNIQUEIDENTIFIER COLLATE Latin1_General_CI_AS)
AS RANGE RIGHT FOR VALUES ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');
GO

--------------------------------------------------------------------
--- Case 7. Partition function with duplicate values under CI_AI collation
--------------------------------------------------------------------
-- Try to create a partition function with values that are considered duplicates 
-- under case-insensitive, accent-insensitive collation
-- Expected result: Should fail with error about duplicate values
CREATE PARTITION FUNCTION PF_DuplicateValues (NVARCHAR(10) COLLATE Latin1_General_CI_AI)
AS RANGE RIGHT FOR VALUES (N'E', N'é', N'e');
GO

-- Test variation with different characters that would be considered duplicates
CREATE PARTITION FUNCTION PF_DuplicateValues2 (NVARCHAR(10) COLLATE Latin1_General_CI_AI)
AS RANGE RIGHT FOR VALUES (N'a', N'A', N'á', N'Á');
GO

-- Test with mix of normal and special characters
CREATE PARTITION FUNCTION PF_DuplicateValues3 (NVARCHAR(10) COLLATE Latin1_General_CI_AI)
AS RANGE RIGHT FOR VALUES (N'o', N'ö', N'O', N'Ö');
GO

----------------------------------------------------------------------------------------
-- Case 8: Verify $PARTITION uses correct collation to find the partition number
----------------------------------------------------------------------------------------
CREATE PARTITION FUNCTION PF_CaseSensitiveAccentSensitive (NVARCHAR(10) COLLATE Latin1_General_CS_AS) 
AS RANGE RIGHT FOR VALUES (N'A', N'á', N'c', N'd');
GO

-- select query to verify collation-sensitive partition mapping
SELECT 
    input_value COLLATE Latin1_General_CS_AS, -- used collate with order by verify the ouptut of partition number
    $PARTITION.PF_CaseSensitiveAccentSensitive(input_value) as partition_number
FROM (
    VALUES 
        ('A'),    -- Tests case sensitivity
        ('a'),    -- Tests case sensitivity
        (N'á'),   -- Tests accent sensitivity
        ('b'),    -- Tests value between partition boundaries
        ('c'),    -- Tests exact boundary match
        ('C'),    -- Tests case sensitivity at boundary
        ('d'),    -- Tests last boundary
        ('e')     -- Tests beyond last boundary
) AS test_cases(input_value)
order by input_value;
GO


DROP PARTITION FUNCTION PF_CaseSensitiveAccentSensitive;
GO

--------------------------------------------------------------------
-- Case 9: Cross database $PARTITION collation verification
--------------------------------------------------------------------
-- Create a test database with CI_AS collation
CREATE DATABASE PartitionCollateTestDB
COLLATE Latin1_General_CI_AS;
GO

USE PartitionCollateTestDB;
GO

-- Part 1: Partition function with explicit collation (CS_AS)
CREATE PARTITION FUNCTION PF_ExplicitCollate (NVARCHAR(10) COLLATE Latin1_General_CS_AS) 
AS RANGE RIGHT FOR VALUES (N'A', N'á', N'c', N'd');
GO

-- Part 2: Partition function without collation (uses database default CI_AS)
CREATE PARTITION FUNCTION PF_ImplicitCollate (NVARCHAR(10)) 
AS RANGE RIGHT FOR VALUES (N'A', N'á', N'c', N'd');
GO

-- Switch to different database to test cross-database access
USE master;
GO

-- Test cross-database $PARTITION with explicit collation (CS_AS)
SELECT 
    input_value COLLATE Latin1_General_CS_AS, -- used collate with order by verify the ouptut of partition number
    PartitionCollateTestDB.$PARTITION.PF_ExplicitCollate(input_value) as partition_number
FROM (
    VALUES 
        ('A'),    -- Tests case sensitivity
        ('a'),    -- Should map different from 'A'
        (N'á'),   -- Tests accent sensitivity
        ('b'),    -- Tests value between boundaries
        ('c'),    -- Tests boundary value
        ('C'),    -- Should map different from 'c'
        ('d'),    -- Tests last boundary
        ('e')     -- Tests beyond last boundary
) AS test_cases(input_value)
ORDER BY 
    input_value;
GO

-- Test cross-database $PARTITION with implicit collation (database default CI_AS)
SELECT 
    input_value COLLATE Latin1_General_CI_AS, -- used collate with order by verify the ouptut of partition number
    PartitionCollateTestDB.$PARTITION.PF_ImplicitCollate(input_value) as partition_number
FROM (
    VALUES 
        ('A'),    -- Tests case insensitivity
        ('a'),    -- Should map same as 'A'
        (N'á'),   -- Tests accent sensitivity
        ('b'),    -- Tests value between boundaries
        ('c'),    -- Tests boundary value
        ('C'),    -- Should map same as 'c'
        ('d'),    -- Tests last boundary
        ('e')     -- Tests beyond last boundary
) AS test_cases(input_value)
ORDER BY 
    input_value;
GO

-- Cleanup
USE master;
GO

DROP DATABASE PartitionCollateTestDB;
GO



--------------------------------------------------
--- CREATE PARTITIONED TABLE with Collate clause
--------------------------------------------------
-- Create a database with a specific collation
CREATE DATABASE CaseInsensitiveAccentSensitive
COLLATE Latin1_General_CI_AS;
GO

USE CaseInsensitiveAccentSensitive;
GO

-------------------------------------------------------------------------------------------
--- Case 1. Partition function and partition key with explicit collation with collation mismatch.
-------------------------------------------------------------------------------------------
-- Create a partition function with a specific collation
CREATE PARTITION FUNCTION PF_AccentSensitive (NVARCHAR(10) COLLATE Latin1_General_CS_AS)
AS RANGE RIGHT FOR VALUES (N'a', N'b', N'c', N'd');
GO

-- Create a partition scheme using the above partition function
CREATE PARTITION SCHEME PS_AccentSensitive
AS PARTITION PF_AccentSensitive ALL TO ([PRIMARY]);
GO

-- Create a partitioned table with a partition key column using a different collation
-- Expected result: Table creation should fail with an error indicating the collation mismatch
CREATE TABLE PartitionedTable1 (
    ID INT IDENTITY(1,1),
    PartitionKey NVARCHAR(10) COLLATE Latin1_General_CI_AI, -- collation doesn't match partition function
    Value NVARCHAR(100)
) ON PS_AccentSensitive(PartitionKey);
GO


DROP PARTITION SCHEME PS_AccentSensitive;
GO

DROP PARTITION FUNCTION PF_AccentSensitive;
GO
--------------------------------------------------------------------------
--- Case 2. Partition function with explicit collation different than
---         database default doesn't match partition key default collation.
--------------------------------------------------------------------------
-- Create a partition function with a collation different than the database default
CREATE PARTITION FUNCTION PF_AccentSensitive (NVARCHAR(10) COLLATE Latin1_General_CS_AS)
AS RANGE RIGHT FOR VALUES (N'a', N'b', N'c', N'd');
GO

-- Create a partition scheme using the above partition function
CREATE PARTITION SCHEME PS_AccentSensitive
AS PARTITION PF_AccentSensitive ALL TO ([PRIMARY]);
GO

-- Create a partitioned table with a partition key column using the database default collation
-- Expected result: Table creation should fail with an error indicating the collation mismatch
CREATE TABLE PartitionedTable2 (
    ID INT IDENTITY(1,1),
    PartitionKey NVARCHAR(10), -- using database default collation
    Value NVARCHAR(100)
) ON PS_AccentSensitive(PartitionKey);
GO

DROP PARTITION SCHEME PS_AccentSensitive;
GO

DROP PARTITION FUNCTION PF_AccentSensitive;
GO

-----------------------------------------------------------------------------------------
--- Case 3. Partition function with default collation doesn't match explicit collation of partition key
--------------------------------------------------------------------
-- Create a partition function without specifying a collation
CREATE PARTITION FUNCTION PF_CaseInsensitive (NVARCHAR(10))
AS RANGE RIGHT FOR VALUES (N'a', N'b', N'c', N'd');
GO

-- Create a partition scheme using the above partition function
CREATE PARTITION SCHEME PS_CaseInsensitive
AS PARTITION PF_CaseInsensitive ALL TO ([PRIMARY]);
GO

-- Create a partitioned table with a partition key column using a specific collation
-- Expected result: Table creation should fail with an error indicating the collation mismatch
CREATE TABLE PartitionedTable3 (
    ID INT IDENTITY(1,1),
    PartitionKey NVARCHAR(10) COLLATE Latin1_General_CS_AS, -- collation doesn't match default partition function collation
    Value NVARCHAR(100)
) ON PS_CaseInsensitive(PartitionKey);
GO

DROP PARTITION SCHEME PS_CaseInsensitive;
GO

DROP PARTITION FUNCTION PF_CaseInsensitive;
GO

---------------------------------------------------------------------------------
--- Case 4. Both partition function and table are with default database collation
---------------------------------------------------------------------------------
-- Create a partition function without specifying a collation
CREATE PARTITION FUNCTION PF_DefaultCollation (NVARCHAR(10))
AS RANGE RIGHT FOR VALUES (N'a', N'b', N'c', N'd');
GO

-- Create a partition scheme using the above partition function
CREATE PARTITION SCHEME PS_DefaultCollation
AS PARTITION PF_DefaultCollation ALL TO ([PRIMARY]);
GO

-- Create a partitioned table with a partition key column using the database default collation
-- Expected result: Table creation should succeed, with the partition key column using the database default collation
CREATE TABLE PartitionedTable4 (
    ID INT IDENTITY(1,1),
    PartitionKey NVARCHAR(10), -- using database default collation
    Value NVARCHAR(100)
) ON PS_DefaultCollation(PartitionKey);
GO

-- check partition key column collation
SELECT name, collation_name FROM sys.all_columns where object_id = object_id('PartitionedTable4') order by name;
GO

DROP TABLE PartitionedTable4;
GO

DROP PARTITION SCHEME PS_DefaultCollation;
GO

DROP PARTITION FUNCTION PF_DefaultCollation;
Go

--------------------------------------------------------------------
--- Case 5. Partition function and table with explicit collation matches
--------------------------------------------------------------------
-- Create a partition function with a specific collation
CREATE PARTITION FUNCTION PF_AccentInsensitive (NVARCHAR(10) COLLATE Latin1_General_CI_AI)
AS RANGE RIGHT FOR VALUES (N'a', N'b', N'c', N'd');
GO

-- Create a partition scheme using the above partition function
CREATE PARTITION SCHEME PS_AccentInsensitive
AS PARTITION PF_AccentInsensitive ALL TO ([PRIMARY]);
GO

-- Create a partitioned table with a partition key column using the same collation as the partition function
-- Expected result: Table creation should succeed
CREATE TABLE PartitionedTable5 (
    ID INT IDENTITY(1,1),
    PartitionKey NVARCHAR(10) COLLATE Latin1_General_CI_AI,
    Value NVARCHAR(100)
) ON PS_AccentInsensitive(PartitionKey);
GO

-- check partition key column collation
SELECT name, collation_name FROM sys.all_columns where object_id = object_id('PartitionedTable5') order by name;
GO

DROP TABLE PartitionedTable5;
GO

DROP PARTITION SCHEME PS_AccentInsensitive;
GO

DROP PARTITION FUNCTION PF_AccentInsensitive;
GO

--------------------------------------------------------------------
--- Case 6: Usage of invalid collation with non-collatable partition key column
--------------------------------------------------------------------
-- Create a partition function without specifying a collation
CREATE PARTITION FUNCTION PF_DefaultCollation (INT)
AS RANGE RIGHT FOR VALUES (1, 10, 100);
GO

-- Create a partition scheme using the above partition function
CREATE PARTITION SCHEME PS_DefaultCollation
AS PARTITION PF_DefaultCollation ALL TO ([PRIMARY]);
GO

-- Try to create a partitioned table with a partition key column using an invalid collation
-- Expected result: Throws an error indicating the collation is invalid
CREATE TABLE PartitionedTable6 (
    ID INT IDENTITY(1,1),
    PartitionKey INT COLLATE invalid_collation, -- using invalid collation
    Value NVARCHAR(100)
) ON PS_DefaultCollation(PartitionKey);
GO

DROP PARTITION SCHEME PS_DefaultCollation
DROP PARTITION FUNCTION PF_DefaultCollation
GO

--------------------------------------------------------------------
--- Case 7: Usage of valid collation with non-collatable partition key column
--------------------------------------------------------------------
-- Create a partition function with non-collatable datatype
CREATE PARTITION FUNCTION PF_DefaultCollation (INT)
AS RANGE RIGHT FOR VALUES (1, 10, 100);
GO

-- Create a partition scheme using the above partition function
CREATE PARTITION SCHEME PS_DefaultCollation
AS PARTITION PF_DefaultCollation ALL TO ([PRIMARY]);
GO

-- Create a partitioned table with a partition key column using a valid collation
-- Expected result: Throws an error indicating the datatype is not collatable
CREATE TABLE PartitionedTable7 (
    ID INT IDENTITY(1,1),
    PartitionKey INT COLLATE Latin1_GENERAL_CI_AS, -- using valid collation with non-collatable datatype
    Value NVARCHAR(100)
) ON PS_DefaultCollation(PartitionKey);
GO

DROP PARTITION SCHEME PS_DefaultCollation
DROP PARTITION FUNCTION PF_DefaultCollation
GO


-----------------------------------------------------------------------------------------------
--- Case 8: Usage of collatable partition key column with non-collatable partition function datatype
------------------------------------------------------------------------------------------------
-- Create a partition function with non-collatable datatype
CREATE PARTITION FUNCTION PF_DefaultCollation (INT)
AS RANGE RIGHT FOR VALUES (1, 10, 100);
GO

-- Create a partition scheme using the above partition function
CREATE PARTITION SCHEME PS_DefaultCollation
AS PARTITION PF_DefaultCollation ALL TO ([PRIMARY]);
GO

-- Create a partitioned table with a partition key column using a valid collation
-- Expected result: Throws an error indicating the datatype is different
CREATE TABLE PartitionedTable7 (
    ID INT IDENTITY(1,1),
    PartitionKey NVARCHAR(10) COLLATE Latin1_GENERAL_CI_AS, -- using valid collation with collatable datatype
    Value NVARCHAR(100)
) ON PS_DefaultCollation(PartitionKey);
GO

DROP PARTITION SCHEME PS_DefaultCollation
DROP PARTITION FUNCTION PF_DefaultCollation
GO

USE master
Go

DROP DATABASE CaseInsensitiveAccentSensitive
GO