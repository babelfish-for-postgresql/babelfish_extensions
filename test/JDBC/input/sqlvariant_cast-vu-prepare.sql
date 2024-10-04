CREATE TABLE sqlvariant_cast_TestTable (
    IntCol INT,
    FloatCol FLOAT,
    VarcharCol VARCHAR(50),
    DateCol DATE
)
GO

CREATE TABLE sqlvariant_cast_VariantTable (
    Id INT PRIMARY KEY,
    Value SQL_VARIANT
)
GO
