-- Basic Alter View
CREATE OR ALTER VIEW alter_v1 AS SELECT a, b FROM alter_t;
GO
SELECT * FROM alter_v1;
GO

CREATE OR ALTER VIEW alter_v2 AS SELECT a, b, c, d, e, f FROM alter_t;
GO
SELECT * FROM alter_v2;
GO

-- Alter View with Additional Columns
CREATE OR ALTER VIEW alter_v3 AS SELECT a, b, c FROM alter_t;
GO
SELECT * FROM alter_v3;
GO

-- Alter View with Less Columns
CREATE OR ALTER VIEW alter_v4 AS SELECT a FROM alter_t;
GO
SELECT * FROM alter_v4;
GO

-- Alter View with Different Column Order
CREATE OR ALTER VIEW alter_v5 AS SELECT c, b, a FROM alter_t;
GO
SELECT * FROM alter_v5;
GO

-- Alter View with Column Aliases
CREATE OR ALTER VIEW alter_v6 AS SELECT a AS col1, b AS col2, c AS col3 FROM alter_t;
GO
SELECT * FROM alter_v6;
GO

-- Alter View with Complex Query
CREATE OR ALTER VIEW alter_v7 AS SELECT a, b, c, (SELECT COUNT(*) FROM alter_t) AS cnt FROM alter_t;
GO
SELECT * FROM alter_v7;
GO

-- Alter View with Join
CREATE OR ALTER VIEW alter_v8 AS SELECT alter_t1.a, alter_t1.b, alter_t2.d FROM alter_t1 JOIN alter_t2 ON alter_t1.b = alter_t2.d;
GO
SELECT * FROM alter_v8;
GO

-- Alter View with Subquery
CREATE OR ALTER VIEW alter_v9 AS SELECT a, b, (SELECT MAX(d) FROM alter_t) AS max_d FROM alter_t;
GO
SELECT * FROM alter_v9;
GO

-- Alter View with Aggregation
CREATE OR ALTER VIEW alter_v10 AS SELECT a, b, SUM(d) AS total_d FROM alter_t GROUP BY a, b ORDER BY a DESC, b DESC;
GO
SELECT * FROM alter_v10;
GO

-- Alter View with Window Function
CREATE OR ALTER VIEW alter_v11 AS SELECT a, b, ROW_NUMBER() OVER (PARTITION BY a ORDER BY b) AS row_num FROM alter_t;
GO
SELECT * FROM alter_v11;
GO

-- Alter View with Case Statement
CREATE OR ALTER VIEW alter_v12 AS SELECT a, b, CASE WHEN d > 10 THEN 'High' ELSE 'Low' END AS d_category FROM alter_t;
GO
SELECT * FROM alter_v12;
GO

-- Alter View with Multiple Joins
CREATE OR ALTER VIEW alter_v13 AS SELECT alter_t1.a, alter_t1.b, alter_t2.d, alter_t3.f FROM alter_t1 JOIN alter_t2 ON alter_t1.b = alter_t2.d JOIN alter_t3 ON alter_t2.c = alter_t3.e;
GO
SELECT * FROM alter_v13;;
GO

-- Alter View with Nested Subqueries
CREATE OR ALTER VIEW alter_v14 AS SELECT a, b, (SELECT MAX(d) FROM (SELECT d FROM alter_t WHERE d > 5) sub) AS max_d FROM alter_t;
GO
SELECT * FROM alter_v14;
GO

-- Alter View with Union
CREATE OR ALTER VIEW alter_v15 AS SELECT a, b FROM alter_t UNION SELECT a, b FROM alter_t1 ORDER BY a DESC, b ASC;
GO
SELECT * FROM alter_v15;
GO

-- Alter View with Intersect
CREATE OR ALTER VIEW alter_v16 AS SELECT a, b FROM alter_t INTERSECT SELECT a, b FROM alter_t1 ORDER BY a, b ASC;
GO
SELECT * FROM alter_v16;
GO

-- Alter View with Except
CREATE OR ALTER VIEW alter_v17 AS SELECT a, b FROM alter_t EXCEPT SELECT a, b FROM alter_t1 ORDER BY a, b ASC;
GO
SELECT * FROM alter_v17;
GO

-- Drop and create with same name
Drop view alter_v1;
GO

CREATE OR ALTER VIEW alter_v1 AS SELECT a, b FROM alter_t;
GO

-- Create view with existing object name [Error]
CREATE VIEW alter_v1 AS SELECT a, b FROM alter_t;
GO

-- Error as dependent view exists
Drop table alter_t;
GO

-- Alter non-exisitng view [Error]
Alter view non_existent_view AS SELECT a, b FROM alter_t;
GO

GRANT SELECT on alter_t TO guest;
GO
-- Alter View with Schema name (Checking views with same name in different schemas)
CREATE OR ALTER VIEW guest.alter_v1 AS SELECT a, b, c FROM alter_t;
GO
SELECT * FROM guest.alter_v1;
GO

ALTER VIEW guest.alter_v1 AS SELECT a FROM alter_t;
GO
SELECT * FROM guest.alter_v1;
GO

SELECT * FROM dbo.alter_v1;
GO

-- Alter View having dependent view [Error]
ALTER VIEW alter_v24 AS SELECT a,b FROM alter_t;
GO

SELECT * FROM alter_v24;
GO

-- Verify dependent view after Alter on underlying view fails
SELECT * FROM alter_v25;
GO

-- Change int to bigint
ALTER VIEW alter_v7 AS SELECT CAST(a AS bigint) AS a, b, c, d, e FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Change varchar to nvarchar
ALTER VIEW alter_v7 AS SELECT a, CAST(b AS nvarchar(20)) AS b, c, d, e FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Change nvarchar to binary
ALTER VIEW alter_v7 as select CAST(b AS binary) AS invalid_binary FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Change nvarchar to varbinary
ALTER VIEW alter_v8 as select CAST(b AS varbinary) AS b FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Change decimal precision
ALTER VIEW alter_v7 AS SELECT a, b, CAST(c AS decimal(15,4)) AS c, d, e FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Change datetime to smalldatetime
ALTER VIEW alter_v7 AS SELECT a, b, c, CAST(d AS smalldatetime) AS d, e FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Type Conversion with Computations
ALTER VIEW alter_v7 AS
SELECT 
    CAST(a * 1.5 AS decimal(10,2)) AS computed_a,
    CAST(CAST(a AS float) * c AS decimal(15,4)) AS mult_result,
    CAST(DATEADD(day, a, d) AS datetime2) AS computed_date,
    CAST(CONCAT(b, e) AS nvarchar(50)) AS concat_string
FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Type Conversion with Aggregations
ALTER VIEW alter_v7 AS
SELECT 
    CAST(SUM(a) AS decimal(15,2)) AS sum_a,
    CAST(AVG(c) AS float) AS avg_c,
    CAST(MAX(d) AS date) AS max_date,
    CAST(COUNT(*) AS bigint) AS row_count
FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Error Cases for type conversions

-- Change decimal to date [Error]
ALTER VIEW alter_v7 AS SELECT a, b, CAST(c AS date) AS c, d, e FROM alter_t4;
GO

-- Change decimal to binary [Error]
ALTER VIEW alter_v7 AS SELECT a, b, CAST(c AS binary) AS c, d, e FROM alter_t4;
GO

-- Change decimal to varbinary [Error]
ALTER VIEW alter_v7 AS SELECT a, b, CAST(c AS varbinary) AS c, d, e FROM alter_t4;
GO

-- Change varchar to date [Error]
ALTER VIEW alter_v7 as select CAST(b AS date) AS invalid_date FROM alter_t4;
GO
SELECT * FROM alter_v7;
GO

-- Alter View with a Long Select Statement
CREATE OR ALTER VIEW alter_v5 AS
SELECT alter_t.a, alter_t.b, alter_t.c, alter_t.d, alter_t1.b AS t1_b, alter_t2.d AS t2_d, alter_t3.f AS alter_t3_f
FROM alter_t
JOIN alter_t1 ON alter_t.a = alter_t1.a
JOIN alter_t2 ON alter_t.a = alter_t2.c
JOIN alter_t3 ON alter_t.a = alter_t3.e
WHERE alter_t.a IN (SELECT a FROM alter_t WHERE d > 5)
AND alter_t.b IN (SELECT b FROM alter_t1 WHERE b LIKE 'f%')
AND alter_t.c IN (SELECT c FROM alter_t WHERE c IS NOT NULL)
AND alter_t.d IN (SELECT d FROM alter_t WHERE d BETWEEN 1 AND 10)
ORDER BY alter_t.a, alter_t.b, alter_t.c, alter_t.d, alter_t1.b, alter_t2.d, alter_t3.f;
GO
SELECT * FROM alter_v5;
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Test Case: Transaction - begin, alter, rollback
--                        - expect alter to not go through
BEGIN TRANSACTION;
GO

CREATE OR ALTER view alter_v23 as select a,b from alter_t;
GO

ROLLBACK;
GO

-- Error as the transaction was rolled back                   
SELECT * FROM alter_v23;
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------
BEGIN TRANSACTION;
GO

CREATE OR ALTER view alter_v10 as select a,b from alter_t;
GO

COMMIT;
GO

SELECT * FROM alter_v10;
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Test Case: Complex Transaction - begin, alter, rollback
BEGIN TRANSACTION;
GO

-- Perform the view alteration
CREATE OR ALTER VIEW alter_v21 AS SELECT a, b FROM alter_t;
GO

DROP TABLE non_existent_table; -- This will cause an error
GO

-- Perform another view alteration
CREATE OR ALTER VIEW alter_v22 AS SELECT a, b,c FROM alter_t;
GO

-- Commit the outer transaction
COMMIT;
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * from alter_v22;
GO

SELECT * FROM alter_v21;
GO

-- Ensure no orphaned entries left behind
-- Check pg and bbf catalogs
SELECT dbid, schema_name, object_name, definition, flag_validity, flag_values FROM babelfish_view_def WHERE object_name = 'alter_v9';
GO

SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION FROM information_schema.views WHERE TABLE_NAME = 'alter_v9';
GO

SELECT dbid, schema_name, object_name, definition, flag_validity, flag_values FROM babelfish_view_def WHERE object_name = 'alter_v10';
GO

SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION FROM information_schema.views WHERE TABLE_NAME = 'alter_v10';
GO

SELECT dbid, schema_name, object_name, definition, flag_validity, flag_values FROM babelfish_view_def WHERE object_name = 'alter_v21';
GO

SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION FROM information_schema.views WHERE TABLE_NAME = 'alter_v21';
GO

SELECT dbid, schema_name, object_name, definition, flag_validity, flag_values FROM babelfish_view_def WHERE object_name = 'alter_v22';
GO

SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION FROM information_schema.views WHERE TABLE_NAME = 'alter_v22';
GO

-- Replacing view definitons from 'ALTER' to 'CREATE'

--test comment
CREATE or alter view alter_v18
AS -- test
    select 1
GO


create view alter_v19 as select 1
GO

alter  --test comment
    view alter_v19
as --test
    select 2
GO

-- definiton will get replaced to 'CREATE VIEW'
create view alter_v20 as select 1
GO

alter 
/*
 * test comment 1
 */
-- test comment 2
view alter_v20 as select 3
GO

SELECT dbid, schema_name, object_name, definition, flag_validity, flag_values FROM babelfish_view_def WHERE object_name = 'alter_v18';
GO

SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION FROM information_schema.views WHERE TABLE_NAME = 'alter_v18';
GO

SELECT dbid, schema_name, object_name, definition, flag_validity, flag_values FROM babelfish_view_def WHERE object_name = 'alter_v19';
GO

SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION FROM information_schema.views WHERE TABLE_NAME = 'alter_v19';
GO

SELECT dbid, schema_name, object_name, definition, flag_validity, flag_values FROM babelfish_view_def WHERE object_name = 'alter_v20';
GO

SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION FROM information_schema.views WHERE TABLE_NAME = 'alter_v20';
GO