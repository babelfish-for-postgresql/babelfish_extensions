-- create database test_Db1
-- go
-- use test_Db1
-- go

-- Create simplified stub tables (Babelfish-compatible)
-- CREATE TABLE R5PartnerProperties (PNP_PARTNER nvarchar(128) NOT NULL, PNP_PROPERTY nvarchar(15) NOT NULL, PNP_ACTIVE nvarchar(1) NOT NULL, PNP_UPDATECOUNT numeric(38,0) NULL, PNP_SQLIDENTITY int IDENTITY(1,1) NOT NULL, PNP_CREATEDBY nvarchar(30) NULL, PNP_CREATEDON datetime NULL, PNP_UPDATEDBY nvarchar(30) NULL, PNP_UPDATEDDON datetime NULL, PRIMARY KEY (PNP_PARTNER, PNP_PROPERTY));
-- CREATE TABLE P5INTERFACEBLANKOUT (IBO_PARTNER nvarchar(128) NOT NULL, IBO_MESSAGE nvarchar(32) NOT NULL, IBO_PATH nvarchar(256) NOT NULL, IBO_ENABLED nvarchar(1) NULL, PRIMARY KEY (IBO_PARTNER, IBO_MESSAGE, IBO_PATH));
-- CREATE TABLE R5PARTNERS (PNR_CODE nvarchar(128) NOT NULL, PNR_DESC nvarchar(80) NULL, PNR_SQLIDENTITY int IDENTITY(1,1) NOT NULL, PRIMARY KEY (PNR_CODE));
-- CREATE TABLE P5TAXINVTRANSACTIONS (TIT_TIVID nvarchar(30) NULL);
-- CREATE TABLE P5TAXINVTEMPDETAILS (TYD_TIVID nvarchar(30) NULL);
-- CREATE TABLE P5TAXINVDETAILS (TXD_TIVID nvarchar(30) NULL);
-- CREATE TABLE P5TAXINVTEMPSUMMARY (TYS_TIVID nvarchar(30) NULL);
-- CREATE TABLE P5TAXINVSUMMARY (TXS_TIVID nvarchar(30) NULL);
-- CREATE TABLE P5TAXINVGROUPHEADER (TXG_TIVID nvarchar(30) NULL);
-- CREATE TABLE P5TAXINVHEADER (TXH_TIVID nvarchar(30) NULL);
-- CREATE TABLE P5TAXINVOICES (TIV_ID nvarchar(30) NULL, TIV_TIPID nvarchar(30) NULL, TIV_STATUSCODE nvarchar(10) NULL, TIV_INVOICENUMBER nvarchar(30) NULL);
-- CREATE TABLE p5archivetablesddl (atd_tablename nvarchar(128) NULL, atd_lineid int NULL, atd_constrainttype varchar(100) NULL, atd_ddlsql varchar(8000) NULL, atd_columnname nvarchar(128) NULL);
-- GO

SELECT set_config('babelfishpg_tsql.enable_adhoc_antlr_parse_cache', 'on', false);
GO

SET BABELFISH_SHOWPLAN_ALL ON
GO

-- SET STATISTICS TIME on
-- go

-- simple prepared statement
-- EXEC sp_executesql N'SELECT 1+2 AS result', N'';
-- GO

-- -- prepared statement for activatePartnerProperty (parameterized UPDATE)
-- EXEC sp_executesql
-- 	N'UPDATE R5PartnerProperties
-- 	SET PNP_Active = ''+''
-- 		,PNP_UpdatedBy = ''activatePartnerProperty''
-- 		,PNP_UpdateddOn = getDate()
-- 	WHERE PNP_Partner = @partnerCode
-- 		AND PNP_Property = @propertyCode',
-- 	N'@partnerCode nvarchar(128), @propertyCode nvarchar(15)',
-- 	@partnerCode = N'SOME_PARTNER',
-- 	@propertyCode = N'SOME_PROPERTY';
-- GO

-- -- standalone batch for AUDITSQL_CREATE_TRIGGERS (variable assignments, IF control flow)
-- DECLARE @sTable nvarchar(128) = N'R5PartnerProperties';
-- DECLARE @sChk nvarchar(10);
-- DECLARE @nReturn int;
-- DECLARE @sCheckresult nvarchar(10);

-- SET NOCOUNT ON;
-- SET @sChk = N'0';

-- /*Create INSERT trigger - inline replacement*/
-- SET @nReturn = 0;
-- SET @sCheckresult = N'0';
-- IF @sCheckresult <> N'0'
-- BEGIN
-- 	SET @sChk = N'1' + @sCheckresult;
-- 	RETURN;
-- END

-- /*Create UPDATE trigger - inline replacement*/
-- SET @nReturn = 0;
-- SET @sCheckresult = N'0';
-- IF @sCheckresult <> N'0'
-- BEGIN
-- 	SET @sChk = N'2' + @sCheckresult;
-- 	RETURN;
-- END

-- /*Create DELETE trigger - inline replacement*/
-- SET @nReturn = 0;
-- SET @sCheckresult = N'0';
-- IF @sCheckresult <> N'0'
-- BEGIN
-- 	SET @sChk = N'3' + @sCheckresult;
-- 	RETURN;
-- END
-- GO

-- Dynamic SQL building a 101-way UNION ALL (forces measurable parse time)
-- DECLARE @sql nvarchar(max) = N'';
-- DECLARE @i int = 1;
-- WHILE @i <= 100
-- BEGIN
--     SET @sql = @sql + N'SELECT ' + CAST(@i as nvarchar) + N' AS col' + CAST(@i as nvarchar) + N' UNION ALL ';
--     SET @i = @i + 1;
-- END
-- SET @sql = @sql + N'SELECT 101 AS col101';
-- EXEC sp_executesql @sql;
-- GO

-- Complex query with many JOINs and subqueries
SELECT t2.name, t1.name, t3.name
FROM sys.objects t3
CROSS JOIN sys.objects t1
CROSS JOIN sys.columns t2
WHERE t2.object_id IN (SELECT object_id FROM sys.columns WHERE column_id < 6)
AND t1.object_id IN (SELECT object_id FROM sys.indexes WHERE index_id > 0)
AND t3.object_id = t2.object_id
AND EXISTS (SELECT 1 FROM sys.types WHERE system_type_id = t3.system_type_id)
OPTION (MAXDOP 1);
GO

-- Large CASE expression with many branches
SELECT
    CASE
        WHEN object_id % 50 = 0 THEN 'zero'
        WHEN object_id % 50 = 1 THEN 'one'
        WHEN object_id % 50 = 2 THEN 'two'
        WHEN object_id % 50 = 3 THEN 'three'
        WHEN object_id % 50 = 4 THEN 'four'
        WHEN object_id % 50 = 5 THEN 'five'
        WHEN object_id % 50 = 6 THEN 'six'
        WHEN object_id % 50 = 7 THEN 'seven'
        WHEN object_id % 50 = 8 THEN 'eight'
        WHEN object_id % 50 = 9 THEN 'nine'
        WHEN object_id % 50 = 10 THEN 'ten'
        WHEN object_id % 50 = 11 THEN 'eleven'
        WHEN object_id % 50 = 12 THEN 'twelve'
        WHEN object_id % 50 = 13 THEN 'thirteen'
        WHEN object_id % 50 = 14 THEN 'fourteen'
        WHEN object_id % 50 = 15 THEN 'fifteen'
        WHEN object_id % 50 = 16 THEN 'sixteen'
        WHEN object_id % 50 = 17 THEN 'seventeen'
        WHEN object_id % 50 = 18 THEN 'eighteen'
        WHEN object_id % 50 = 19 THEN 'nineteen'
        WHEN object_id % 50 = 20 THEN 'twenty'
        ELSE 'other'
    END AS category,
    COUNT(*) AS cnt
FROM sys.objects
GROUP BY
    CASE
        WHEN object_id % 50 = 0 THEN 'zero'
        WHEN object_id % 50 = 1 THEN 'one'
        WHEN object_id % 50 = 2 THEN 'two'
        WHEN object_id % 50 = 3 THEN 'three'
        WHEN object_id % 50 = 4 THEN 'four'
        WHEN object_id % 50 = 5 THEN 'five'
        WHEN object_id % 50 = 6 THEN 'six'
        WHEN object_id % 50 = 7 THEN 'seven'
        WHEN object_id % 50 = 8 THEN 'eight'
        WHEN object_id % 50 = 9 THEN 'nine'
        WHEN object_id % 50 = 10 THEN 'ten'
        WHEN object_id % 50 = 11 THEN 'eleven'
        WHEN object_id % 50 = 12 THEN 'twelve'
        WHEN object_id % 50 = 13 THEN 'thirteen'
        WHEN object_id % 50 = 14 THEN 'fourteen'
        WHEN object_id % 50 = 15 THEN 'fifteen'
        WHEN object_id % 50 = 16 THEN 'sixteen'
        WHEN object_id % 50 = 17 THEN 'seventeen'
        WHEN object_id % 50 = 18 THEN 'eighteen'
        WHEN object_id % 50 = 19 THEN 'nineteen'
        WHEN object_id % 50 = 20 THEN 'twenty'
        ELSE 'other'
    END;
GO

-- -- standalone batch for AUDITSQL_GET_TRIGGER_HEADFOOT (string concatenation, dynamic SQL building)
-- DECLARE @sTable nvarchar(128) = N'R5PartnerProperties';
-- DECLARE @sTriggerName nvarchar(40) = N'UAU_R5PartnerProperties';
-- DECLARE @sTriggerType nvarchar(10) = N'UPDATE';
-- DECLARE @sTriggerHeadDeclare nvarchar(max);
-- DECLARE @sTriggerHeadCursor nvarchar(max);
-- DECLARE @sTriggerHeadFetch nvarchar(max);
-- DECLARE @sTriggerFoot nvarchar(max);
-- DECLARE @sTriggerDrop nvarchar(400);
-- DECLARE @sCRLF nvarchar(4);
-- DECLARE @sColDeclareList nvarchar(max);
-- DECLARE @sColSelectList nvarchar(max);
-- DECLARE @sColFetchList nvarchar(max);

-- SET NOCOUNT ON;
-- SET @sColDeclareList = N'  declare @vNEW_PNP_Partner nvarchar(128)' + nchar(13) + nchar(10);
-- SET @sColSelectList = N'select PNP_Partner from R5PartnerProperties';
-- SET @sColFetchList = N'@vNEW_PNP_Partner';
-- SET @sCRLF = nchar(13) + nchar(10);

-- /*Build trigger header*/
-- SET @sTriggerHeadDeclare = N'create trigger ' + @sTriggerName + @sCRLF +
-- 	N'on ' + @sTable + @sCRLF +
-- 	N'for ' + @sTriggerType + @sCRLF +
-- 	N'as begin' + @sCRLF +
-- 	N'  declare @sCheckresult nvarchar(4)' + @sCRLF +
-- 	N'  declare @nReturn int' + @sCRLF +
-- 	N'  declare @sOldColVal nvarchar(250)' + @sCRLF +
-- 	N'  declare @sNewColVal nvarchar(250)' + @sCRLF +
-- 	N'  declare @sPKVal nvarchar(45)' + @sCRLF +
-- 	N'  declare @sSKVal nvarchar(180)' + @sCRLF +
-- 	@sColDeclareList + @sCRLF;

-- SET @sTriggerHeadCursor = N'  if @@ROWCOUNT > 0' + @sCRLF +
-- 	N'    begin' + @sCRLF +
-- 	N'      SET NOCOUNT ON' + @sCRLF +
-- 	N'      declare c_audit cursor local for ' + @sColSelectList + @sCRLF;

-- SET @sTriggerHeadFetch = N'      open c_audit' + @sCRLF +
-- 	N'      fetch next from c_audit into ' + @sColFetchList + @sCRLF +
-- 	N'      while @@FETCH_STATUS = 0' + @sCRLF +
-- 	N'        begin' + @sCRLF;

-- /*Build trigger footer*/
-- SET @sTriggerFoot = N'          fetch next from c_audit into ' + @sColFetchList + @sCRLF +
-- 	N'        end' + @sCRLF +
-- 	N'      close c_audit' + @sCRLF +
-- 	N'      deallocate c_audit' + @sCRLF +
-- 	N'    end' + @sCRLF +
-- 	N'    return' + @sCRLF +
-- 	N'end' + @sCRLF;

-- /*Build trigger drop statement*/
-- SET @sTriggerDrop = N'if exists (select NAME from SYSOBJECTS' + @sCRLF +
-- 	N'where NAME = ''' + @sTriggerName + ''' and TYPE = ''TR'')' + @sCRLF +
-- 	N'drop trigger ' + @sTriggerName + @sCRLF;
-- GO

-- -- standalone batch for BLANKOUT_SETUP_CHANGE (UPDATE + INSERT with subquery)
-- DECLARE @partner nvarchar(128) = N'SOME_PARTNER';
-- DECLARE @xpath nvarchar(256) = N'/some/xpath';
-- DECLARE @enabled nvarchar(1) = N'+';
-- DECLARE @sEnabled nvarchar(1);

-- IF @partner != '*' AND (ltrim(rtrim(@enabled)) = '+' OR ltrim(rtrim(@enabled)) = '-') BEGIN
-- 	SET @sEnabled = ltrim(rtrim(@enabled));
-- 	UPDATE P5INTERFACEBLANKOUT SET IBO_ENABLED = @sEnabled
-- 	WHERE IBO_PARTNER = @partner AND IBO_MESSAGE = 'OTA_HOTELRESNOTIFRQ' AND IBO_PATH = @xpath;

-- 	INSERT INTO P5INTERFACEBLANKOUT(IBO_PARTNER, IBO_MESSAGE, IBO_PATH, IBO_ENABLED)
-- 	SELECT b.PNR_CODE, a.IBO_MESSAGE, a.IBO_PATH, @sEnabled
-- 	FROM P5INTERFACEBLANKOUT a
-- 	JOIN R5PARTNERS b ON b.PNR_CODE = @partner
-- 	WHERE a.IBO_PARTNER = '*' AND a.IBO_MESSAGE = 'OTA_HOTELRESNOTIFRQ' AND a.IBO_PATH = @xpath
-- 	AND NOT EXISTS (SELECT 1 FROM P5INTERFACEBLANKOUT c WHERE c.IBO_PARTNER = @partner AND c.IBO_MESSAGE = a.IBO_MESSAGE AND c.IBO_PATH = @xpath);
-- END
-- GO

-- -- standalone batch for BLANKOUT_SETUP_COPY (INSERT with JOIN and NOT EXISTS)
-- DECLARE @partner nvarchar(128) = N'SOME_PARTNER';

-- INSERT INTO P5INTERFACEBLANKOUT(IBO_PARTNER, IBO_MESSAGE, IBO_PATH, IBO_ENABLED)
-- SELECT b.PNR_CODE, a.IBO_MESSAGE, a.IBO_PATH, a.IBO_ENABLED
-- FROM P5INTERFACEBLANKOUT a
-- JOIN R5PARTNERS b ON b.PNR_CODE = @partner
-- WHERE a.IBO_PARTNER = '*' AND a.IBO_MESSAGE = 'OTA_HOTELRESNOTIFRQ'
-- AND NOT EXISTS (SELECT 1 FROM P5INTERFACEBLANKOUT c WHERE c.IBO_PARTNER = @partner AND c.IBO_MESSAGE = a.IBO_MESSAGE AND c.IBO_PATH = a.IBO_PATH);
-- GO

-- -- standalone batch for BLANKOUT_SETUP_DELETE (DELETE with multiple conditions)
-- DECLARE @partner nvarchar(128) = N'SOME_PARTNER';

-- DELETE FROM P5INTERFACEBLANKOUT
-- WHERE IBO_PARTNER = @partner AND IBO_MESSAGE = 'OTA_HOTELRESNOTIFRQ' AND IBO_PARTNER != '*';
-- GO

-- -- standalone batch for CLEANUP_REPORTDATA (TRY/CATCH with DML)
-- BEGIN TRY
-- 	DELETE FROM P5TAXINVTRANSACTIONS WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH
-- GO

-- -- standalone batch for CLEANUP_SYSTEMDATA (multiple TRY/CATCH blocks)
-- BEGIN TRY
-- 	DELETE FROM P5TAXINVTRANSACTIONS WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH

-- BEGIN TRY
-- 	DELETE FROM P5TAXINVTEMPDETAILS WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH

-- BEGIN TRY
-- 	DELETE FROM P5TAXINVDETAILS WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH

-- BEGIN TRY
-- 	DELETE FROM P5TAXINVTEMPSUMMARY WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH

-- BEGIN TRY
-- 	DELETE FROM P5TAXINVSUMMARY WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH

-- BEGIN TRY
-- 	DELETE FROM P5TAXINVGROUPHEADER WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH

-- BEGIN TRY
-- 	DELETE FROM P5TAXINVHEADER WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH

-- BEGIN TRY
-- 	DELETE FROM P5TAXINVOICES WHERE 1=0;
-- END TRY
-- BEGIN CATCH
-- END CATCH
-- GO

-- -- standalone batch for CreateTableDDLs (complex SELECT INTO, temp tables, system catalog queries)
-- DECLARE @sTable_Name SYSNAME = N'R5PartnerProperties';
-- DECLARE @Schema_Name SYSNAME;
-- DECLARE @sStr VARCHAR(MAX);

-- SET NOCOUNT ON;

-- SELECT @Schema_Name = SCHEMA_NAME(schema_id)
-- FROM sys.objects
-- WHERE name = @sTable_Name;

-- IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE ID = OBJECT_ID('tempdb..#Constraints')) DROP TABLE #Constraints;
-- IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE ID = OBJECT_ID('tempdb..#ShowFields')) DROP TABLE #ShowFields;

-- CREATE TABLE #Constraints (ID INT IDENTITY, Constraint_Type VARCHAR(100), SQL VARCHAR(8000), Column_Name SYSNAME DEFAULT '');

-- SELECT
-- 	DatabaseName = DB_NAME(),
-- 	TableOwner = TABLE_SCHEMA,
-- 	TableName = TABLE_NAME,
-- 	FieldName = COLUMN_NAME,
-- 	ColumnPosition = CAST(ORDINAL_POSITION AS INT),
-- 	ColumnDefaultValue = COLUMN_DEFAULT,
-- 	IsNullable = CASE WHEN c.IS_NULLABLE = 'YES' THEN 1 ELSE 0 END,
-- 	DataType = DATA_TYPE,
-- 	MaxLength = CAST(CHARACTER_MAXIMUM_LENGTH AS INT),
-- 	NumericPrecision = CAST(NUMERIC_PRECISION AS INT),
-- 	NumericScale = CAST(NUMERIC_SCALE AS INT),
-- 	DomainName = DOMAIN_NAME,
-- 	FieldListingName = COLUMN_NAME + ','
-- INTO #ShowFields
-- FROM INFORMATION_SCHEMA.COLUMNS c
-- WHERE c.TABLE_NAME = @sTable_Name
-- ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- SELECT @sStr = 'CREATE TABLE ' + QUOTENAME(@Schema_Name) + '.' + QUOTENAME(@sTable_Name) + '(...)';

-- INSERT INTO #Constraints (Constraint_Type, SQL)
-- VALUES ('CREATE_TABLE', @sStr);

-- /* Insert into final table */
-- INSERT INTO p5archivetablesddl(atd_tablename, atd_lineid, atd_constrainttype, atd_ddlsql, atd_columnname)
-- SELECT @sTable_Name, ID, Constraint_Type, SQL, Column_Name
-- FROM #Constraints
-- ORDER BY ID;



-- =====================================================
-- Additional batch tests for ad-hoc cache POC
-- Each GO-separated batch is a distinct cache entry
-- =====================================================

-- Test: Simple arithmetic and WHERE clause
SELECT 2 + 3 WHERE 2 > 4;
GO

-- Test: Multiple column expressions with aliases
SELECT 
    1 + 1 AS two,
    2 * 3 AS six,
    10 / 2 AS five,
    'hello' + ' ' + 'world' AS greeting;
GO

-- Test: Subquery in WHERE with EXISTS
SELECT name, object_id 
FROM sys.objects 
WHERE EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE columns.object_id = objects.object_id 
    AND column_id <= 3
)
AND type = 'U';
GO

-- Test: UNION ALL with multiple branches
SELECT 'table' AS obj_type, name FROM sys.tables WHERE schema_id = 1
UNION ALL
SELECT 'view' AS obj_type, name FROM sys.views WHERE schema_id = 1
UNION ALL
SELECT 'proc' AS obj_type, name FROM sys.procedures WHERE schema_id = 1;
GO

-- Test: Variable declarations and control flow (WHILE loop)
DECLARE @i int = 0;
DECLARE @sum int = 0;
WHILE @i < 10
BEGIN
    SET @sum = @sum + @i;
    SET @i = @i + 1;
END
SELECT @sum AS total;
GO

-- Test: IF/ELSE branching
DECLARE @val int = 42;
IF @val > 100
    SELECT 'large' AS category;
ELSE IF @val > 10
    SELECT 'medium' AS category;
ELSE
    SELECT 'small' AS category;
GO

-- Test: TRY/CATCH error handling
BEGIN TRY
    SELECT 1/0 AS will_fail;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS err_msg, ERROR_NUMBER() AS err_num;
END CATCH
GO

-- Test: Nested subqueries with aggregation
SELECT 
    t.name AS table_name,
    (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id = t.object_id) AS col_count,
    (SELECT COUNT(*) FROM sys.indexes i WHERE i.object_id = t.object_id) AS idx_count
FROM sys.tables t
WHERE t.schema_id = SCHEMA_ID('dbo');
GO

-- Test: COALESCE, NULLIF, IIF functions
SELECT 
    COALESCE(NULL, NULL, 'fallback') AS coal_result,
    NULLIF(1, 1) AS nullif_result,
    IIF(1 > 0, 'yes', 'no') AS iif_result,
    ISNULL(NULL, 'default') AS isnull_result;
GO

-- Test: String functions
SELECT 
    LEN('hello world') AS str_len,
    UPPER('hello') AS upper_val,
    LOWER('WORLD') AS lower_val,
    SUBSTRING('abcdefgh', 3, 4) AS sub_str,
    REPLACE('hello world', 'world', 'earth') AS replaced,
    CHARINDEX('lo', 'hello world') AS char_idx,
    LEFT('abcdef', 3) AS left_val,
    RIGHT('abcdef', 3) AS right_val;
GO

-- Test: Date functions
SELECT 
    GETDATE() AS now_dt,
    DATEADD(day, 7, GETDATE()) AS next_week,
    DATEDIFF(day, '2020-01-01', GETDATE()) AS days_since,
    YEAR(GETDATE()) AS cur_year,
    MONTH(GETDATE()) AS cur_month,
    DAY(GETDATE()) AS cur_day;
GO

-- Test: CAST and CONVERT
SELECT 
    CAST(123 AS varchar(10)) AS int_to_str,
    CAST('456' AS int) AS str_to_int,
    CAST(3.14159 AS decimal(5,2)) AS rounded,
    CONVERT(varchar, GETDATE(), 120) AS date_str;
GO

-- Test: Window functions (ROW_NUMBER, RANK)
SELECT 
    name,
    object_id,
    ROW_NUMBER() OVER (ORDER BY name) AS row_num,
    RANK() OVER (ORDER BY type) AS type_rank,
    DENSE_RANK() OVER (ORDER BY schema_id) AS schema_drank
FROM sys.objects
WHERE type IN ('U', 'V', 'P');
GO

-- Test: CTE (Common Table Expression)
;WITH numbered_objects AS (
    SELECT name, type, schema_id,
           ROW_NUMBER() OVER (PARTITION BY type ORDER BY name) AS rn
    FROM sys.objects
    WHERE schema_id = 1
)
SELECT name, type, rn
FROM numbered_objects
WHERE rn <= 5;
GO

-- Test: PIVOT-style conditional aggregation
SELECT 
    type,
    COUNT(*) AS total,
    SUM(CASE WHEN schema_id = 1 THEN 1 ELSE 0 END) AS in_dbo,
    SUM(CASE WHEN schema_id != 1 THEN 1 ELSE 0 END) AS not_dbo,
    MAX(name) AS last_name,
    MIN(name) AS first_name
FROM sys.objects
GROUP BY type
HAVING COUNT(*) > 1;
GO

-- Test: Multiple variable assignments with SET
DECLARE @a int, @b int, @c int, @d varchar(100);
SET @a = 10;
SET @b = 20;
SET @c = @a + @b;
SET @d = 'Result: ' + CAST(@c AS varchar(10));
SELECT @a AS a, @b AS b, @c AS c, @d AS d;
GO

-- Test: CASE expression in ORDER BY
SELECT name, type, create_date
FROM sys.objects
WHERE type IN ('U', 'V', 'P', 'FN')
ORDER BY 
    CASE type 
        WHEN 'U' THEN 1 
        WHEN 'V' THEN 2 
        WHEN 'P' THEN 3 
        ELSE 4 
    END,
    name;
GO

-- Test: Large IN list
SELECT name, object_id
FROM sys.objects
WHERE object_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 
                    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
                    31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
                    41, 42, 43, 44, 45, 46, 47, 48, 49, 50);
GO

-- Test: TOP with ORDER BY and OFFSET-FETCH equivalent
SELECT TOP 10 name, object_id, type
FROM sys.objects
ORDER BY object_id DESC;
GO

-- Test: Multiple JOINs
SELECT 
    o.name AS object_name,
    c.name AS column_name,
    t.name AS type_name,
    c.max_length,
    c.is_nullable
FROM sys.objects o
INNER JOIN sys.columns c ON o.object_id = c.object_id
INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
WHERE o.type = 'U'
AND c.column_id <= 5;
GO

-- =====================================================
-- End of additional batch tests
-- =====================================================

SET BABELFISH_SHOWPLAN_ALL OFF
GO

SELECT set_config('babelfishpg_tsql.enable_adhoc_antlr_parse_cache', 'off', false);
GO

-- SET statistics time off
-- go

-- PRINT 'Complete.';
-- GO

-- -- Cleanup: drop stub tables
-- GO
-- DROP TABLE R5PartnerProperties;
-- -- DROP TABLE P5INTERFACEBLANKOUT;
-- -- DROP TABLE R5PARTNERS;
-- -- DROP TABLE P5TAXINVTRANSACTIONS;
-- -- DROP TABLE P5TAXINVTEMPDETAILS;
-- -- DROP TABLE P5TAXINVDETAILS;
-- -- DROP TABLE P5TAXINVTEMPSUMMARY;
-- -- DROP TABLE P5TAXINVSUMMARY;
-- -- DROP TABLE P5TAXINVGROUPHEADER;
-- -- DROP TABLE P5TAXINVHEADER;
-- -- DROP TABLE P5TAXINVOICES;
-- -- DROP TABLE p5archivetablesddl;
-- GO
