CREATE TABLE babel_varbinary_test_table1 (
    fixedlen_col VARBINARY(100), 
    maxlen_col VARBINARY(MAX)
)
GO

INSERT INTO babel_varbinary_test_table1 (fixedlen_col, maxlen_col) VALUES 
    (0x, 0x), 
    (NULL, NULL), 
    (0x0, 0x0), 
    (0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF), 
    (0x0123, 0x0123)
GO

CREATE VIEW babel_varbinary_test_view1 AS 
SELECT 
    t1.maxlen_col + t1.fixedlen_col as max_fixed_addition,
    t1.fixedlen_col + t1.fixedlen_col as fixed_fixed_addition,
    t1.maxlen_col + t1.maxlen_col as max_max_addition
FROM babel_varbinary_test_table1 t1
ORDER BY max_fixed_addition, fixed_fixed_addition, max_max_addition;
GO

CREATE VIEW babel_varbinary_test_view2 AS 
SELECT 
    t1.maxlen_col + t2.fixedlen_col as max_fixed_addition,
    t1.fixedlen_col + t2.fixedlen_col as fixed_fixed_addition,
    t1.maxlen_col + t2.maxlen_col as max_max_addition
FROM babel_varbinary_test_table1 t1 
CROSS JOIN babel_varbinary_test_table1 t2
ORDER BY max_fixed_addition, fixed_fixed_addition, max_max_addition;
GO

CREATE VIEW babel_varbinary_test_view3 AS
SELECT 
    CAST(NULL as VARBINARY(MAX)) + CAST(0x0 as VARBINARY(100)) as max_fixed_result,
    CAST(NULL as VARBINARY(100)) + CAST(0x0 as VARBINARY(100)) as fixed_fixed_result,
    CAST(NULL as VARBINARY(MAX)) + CAST(0x0 as VARBINARY(MAX)) as max_max_result
GO

CREATE VIEW babel_varbinary_test_view4 AS
SELECT 
    CAST(NULL as VARBINARY(MAX)) + CAST(NULL as VARBINARY(100)) as max_fixed_result,
    CAST(NULL as VARBINARY(100)) + CAST(NULL as VARBINARY(100)) as fixed_fixed_result,
    CAST(NULL as VARBINARY(MAX)) + CAST(NULL as VARBINARY(MAX)) as max_max_result
GO

CREATE VIEW babel_varbinary_test_view5 AS
SELECT 
    CAST(0x098765 as VARBINARY(MAX)) + CAST(0x012345 as VARBINARY(100)) as max_fixed_result,
    CAST(0x098765 as VARBINARY(100)) + CAST(0x012345 as VARBINARY(100)) as fixed_fixed_result,
    CAST(0x098765 as VARBINARY(MAX)) + CAST(0x012345 as VARBINARY(MAX)) as max_max_result
GO

CREATE VIEW babel_varbinary_test_view6 AS
SELECT 
    CAST(0x as VARBINARY(MAX)) + CAST(0x098765 as VARBINARY(100)) as max_fixed_result,
    CAST(0x as VARBINARY(100)) + CAST(0x098765 as VARBINARY(100)) as fixed_fixed_result,
    CAST(0x as VARBINARY(MAX)) + CAST(0x098765 as VARBINARY(MAX)) as max_max_result
GO

-- Functions testing combinations
CREATE FUNCTION babel_varbinary_test_func1()
RETURNS TABLE
AS
RETURN (
    SELECT 
        t1.maxlen_col + t1.fixedlen_col as max_fixed_addition,
        t1.fixedlen_col + t1.fixedlen_col as fixed_fixed_addition,
        t1.maxlen_col + t1.maxlen_col as max_max_addition
    FROM babel_varbinary_test_table1 t1
    ORDER BY max_fixed_addition, fixed_fixed_addition, max_max_addition
);
GO

CREATE FUNCTION babel_varbinary_test_func2()
RETURNS TABLE
AS
RETURN (
    SELECT 
        t1.maxlen_col + t2.fixedlen_col as max_fixed_addition,
        t1.fixedlen_col + t2.fixedlen_col as fixed_fixed_addition,
        t1.maxlen_col + t2.maxlen_col as max_max_addition
    FROM babel_varbinary_test_table1 t1 
    CROSS JOIN babel_varbinary_test_table1 t2
    ORDER BY max_fixed_addition, fixed_fixed_addition, max_max_addition
);
GO

CREATE FUNCTION babel_varbinary_test_func3()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(NULL as VARBINARY(MAX)) + CAST(0x0 as VARBINARY(100)) as max_fixed_result,
        CAST(NULL as VARBINARY(100)) + CAST(0x0 as VARBINARY(100)) as fixed_fixed_result,
        CAST(NULL as VARBINARY(MAX)) + CAST(0x0 as VARBINARY(MAX)) as max_max_result
);
GO

CREATE FUNCTION babel_varbinary_test_func4()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(NULL as VARBINARY(MAX)) + CAST(NULL as VARBINARY(100)) as max_fixed_result,
        CAST(NULL as VARBINARY(100)) + CAST(NULL as VARBINARY(100)) as fixed_fixed_result,
        CAST(NULL as VARBINARY(MAX)) + CAST(NULL as VARBINARY(MAX)) as max_max_result
);
GO

CREATE FUNCTION babel_varbinary_test_func5()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(0x098765 as VARBINARY(MAX)) + CAST(0x012345 as VARBINARY(100)) as max_fixed_result,
        CAST(0x098765 as VARBINARY(100)) + CAST(0x012345 as VARBINARY(100)) as fixed_fixed_result,
        CAST(0x098765 as VARBINARY(MAX)) + CAST(0x012345 as VARBINARY(MAX)) as max_max_result
);
GO

CREATE FUNCTION babel_varbinary_test_func6()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(0x as VARBINARY(MAX)) + CAST(0x098765 as VARBINARY(100)) as max_fixed_result,
        CAST(0x as VARBINARY(100)) + CAST(0x098765 as VARBINARY(100)) as fixed_fixed_result,
        CAST(0x as VARBINARY(MAX)) + CAST(0x098765 as VARBINARY(MAX)) as max_max_result
);
GO

CREATE FUNCTION babel_varbinary_test_func7
(
    @max_input1 VARBINARY(MAX),
    @fixed_input VARBINARY(100),
    @max_input2 VARBINARY(MAX)
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        @max_input1 + @fixed_input as max_fixed_result,
        @fixed_input + @fixed_input as fixed_fixed_result,
        @max_input1 + @max_input2 as max_max_result
);
GO

-- Procedures testing combinations
CREATE PROCEDURE babel_varbinary_test_proc1
AS
BEGIN
    SELECT 
        t1.maxlen_col + t1.fixedlen_col as max_fixed_addition,
        t1.fixedlen_col + t1.fixedlen_col as fixed_fixed_addition,
        t1.maxlen_col + t1.maxlen_col as max_max_addition
    FROM babel_varbinary_test_table1 t1
    ORDER BY max_fixed_addition, fixed_fixed_addition, max_max_addition;
END;
GO

CREATE PROCEDURE babel_varbinary_test_proc2
AS
BEGIN
    SELECT 
        t1.maxlen_col + t2.fixedlen_col as max_fixed_addition,
        t1.fixedlen_col + t2.fixedlen_col as fixed_fixed_addition,
        t1.maxlen_col + t2.maxlen_col as max_max_addition
    FROM babel_varbinary_test_table1 t1 
    CROSS JOIN babel_varbinary_test_table1 t2
    ORDER BY max_fixed_addition, fixed_fixed_addition, max_max_addition;
END;
GO

CREATE PROCEDURE babel_varbinary_test_proc3
AS
BEGIN
    SELECT 
        CAST(NULL as VARBINARY(MAX)) + CAST(0x0 as VARBINARY(100)) as max_fixed_result,
        CAST(NULL as VARBINARY(100)) + CAST(0x0 as VARBINARY(100)) as fixed_fixed_result,
        CAST(NULL as VARBINARY(MAX)) + CAST(0x0 as VARBINARY(MAX)) as max_max_result;
END;
GO

CREATE PROCEDURE babel_varbinary_test_proc4
AS
BEGIN
    SELECT 
        CAST(NULL as VARBINARY(MAX)) + CAST(NULL as VARBINARY(100)) as max_fixed_result,
        CAST(NULL as VARBINARY(100)) + CAST(NULL as VARBINARY(100)) as fixed_fixed_result,
        CAST(NULL as VARBINARY(MAX)) + CAST(NULL as VARBINARY(MAX)) as max_max_result;
END;
GO

CREATE PROCEDURE babel_varbinary_test_proc5
AS
BEGIN
    SELECT 
        CAST(0x098765 as VARBINARY(MAX)) + CAST(0x012345 as VARBINARY(100)) as max_fixed_result,
        CAST(0x098765 as VARBINARY(100)) + CAST(0x012345 as VARBINARY(100)) as fixed_fixed_result,
        CAST(0x098765 as VARBINARY(MAX)) + CAST(0x012345 as VARBINARY(MAX)) as max_max_result;
END;
GO

CREATE PROCEDURE babel_varbinary_test_proc6
AS
BEGIN
    SELECT 
        CAST(0x as VARBINARY(MAX)) + CAST(0x098765 as VARBINARY(100)) as max_fixed_result,
        CAST(0x as VARBINARY(100)) + CAST(0x098765 as VARBINARY(100)) as fixed_fixed_result,
        CAST(0x as VARBINARY(MAX)) + CAST(0x098765 as VARBINARY(MAX)) as max_max_result;
END;
GO

CREATE PROCEDURE babel_varbinary_test_proc7
(
    @max_input1 VARBINARY(MAX),
    @fixed_input VARBINARY(100),
    @max_input2 VARBINARY(MAX)
)
AS
BEGIN
    SELECT 
        @max_input1 + @fixed_input as max_fixed_result,
        @fixed_input + @fixed_input as fixed_fixed_result,
        @max_input1 + @max_input2 as max_max_result;
END;
GO

CREATE TABLE babel_varbinary_test_table2 (varbinary_col varbinary(100))
GO

INSERT INTO babel_varbinary_test_table2 (varbinary_col) SELECT CAST(0x1 AS VARBINARY) FROM generate_series(1, 3);
GO

INSERT INTO babel_varbinary_test_table2 (varbinary_col) SELECT CAST(0x4 AS VARBINARY) FROM generate_series(1, 3000000);
GO

INSERT INTO babel_varbinary_test_table2 (varbinary_col) SELECT CAST(0x8 AS VARBINARY) FROM generate_series(1, 3);
GO

CREATE INDEX babel_varbinary_test_ind ON babel_varbinary_test_table2 (varbinary_col ASC);
GO
