--Adding tests to select_cast_test

-- 1. Casting query over a column of table

INSERT INTO sqlvariant_cast_TestTable (IntCol, FloatCol, VarcharCol, DateCol)
VALUES (123, 3.14, 'Hello', '2023-05-01')
GO

SELECT IntCol, CAST(IntCol AS VARCHAR(10)) AS IntToVarchar
FROM sqlvariant_cast_TestTable
GO

SELECT FloatCol, CAST(FloatCol AS INT) AS FloatToInt
FROM sqlvariant_cast_TestTable
GO

SELECT DateCol, CAST(DateCol AS VARCHAR(10)) AS DateToVarchar
FROM sqlvariant_cast_TestTable
GO

DROP TABLE IF EXISTS sqlvariant_cast_TestTable;
GO
-- 2. Casting query over a column of table with Multiple cast
CREATE TABLE sqlvariant_cast_TestTable (
    IntCol INT,
    FloatCol FLOAT,
    VarcharCol VARCHAR(50)
)
GO

INSERT INTO sqlvariant_cast_TestTable (IntCol, FloatCol)
VALUES (123, 3.14)
GO

SELECT
    CAST(CAST(IntCol AS FLOAT) AS VARCHAR(10)) AS IntToFloatToVarchar,
    CAST(CAST(FloatCol AS INT) AS VARCHAR(10)) AS FloatToIntToVarchar
FROM sqlvariant_cast_TestTable
GO
DROP TABLE IF EXISTS sqlvariant_cast_TestTable;
GO

-- 3. Casting query over a column of table with SQL_VARIENT datatype

INSERT INTO sqlvariant_cast_VariantTable (Id, Value)
VALUES
    (1, 'Hello'),
    (2, 123.45),
    (3, CAST('2023-05-01' AS DATE));
GO

-- Check the base data type of the sql_variant values
SELECT
    Id,
    Value,
    SQL_VARIANT_PROPERTY(Value, 'BaseType') AS BaseType
FROM sqlvariant_cast_VariantTable;
GO

-- Convert sql_variant values to specific data types
SELECT
    Id,
    CAST(Value AS VARCHAR(50)) AS VarcharValue
FROM sqlvariant_cast_VariantTable;
GO
DROP TABLE IF EXISTS sqlvariant_cast_VariantTable;
GO

-- 4. User defined data-type
CREATE TYPE sqlvariant_type from NVARCHAR(100)
GO
Select CAST(CAST('2023-05-01' AS sqlvariant_type) AS sqlvariant_type)
go
DROP TYPE IF EXISTS sqlvariant_type;
go

-- 5. User defined data-type with multiple cast
CREATE TYPE sqlvariant_type from SQL_VARIANT;
GO
Select CAST(CAST(CAST('2023-05-01' AS sqlvariant_type) AS sqlvariant_type) AS VARCHAR(2))
go
DROP TYPE IF EXISTS sqlvariant_type;
go
