-- Prepare: sql_variant type resolution tests
-- Create a table with sql_variant column for table-based tests

CREATE TABLE babel_case_sqlvariant_t1 (
    id int,
    sv_col sql_variant,
    bit_col bit,
    int_col int,
    vc_col varchar(50),
    float_col float
)
GO

INSERT INTO babel_case_sqlvariant_t1 VALUES (1, CAST(1 AS sql_variant), 1, 100, 'hello', 3.14)
GO

INSERT INTO babel_case_sqlvariant_t1 VALUES (2, CAST(NULL AS sql_variant), 0, 200, 'world', 2.71)
GO

-- View using CASE with sql_variant from table column
CREATE VIEW babel_case_sqlvariant_v1 AS
SELECT id,
   CASE WHEN id = 1 THEN sv_col ELSE CAST(0 AS bit) END AS case_result
FROM babel_case_sqlvariant_t1
GO

-- View using CASE with sql_variant in middle WHEN
CREATE VIEW babel_case_sqlvariant_v2 AS
SELECT id,
   CASE id
      WHEN 1 THEN CAST(0 AS bit)
      WHEN 2 THEN CAST(1 AS sql_variant)
      ELSE CAST(100 AS int)
   END AS case_result
FROM babel_case_sqlvariant_t1
GO
