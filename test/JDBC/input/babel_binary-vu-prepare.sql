CREATE TABLE BABEL_5597_binary_test_table (
    fixedlen_col BINARY(50), 
    maxlen_col BINARY(8000)
)
GO

INSERT INTO BABEL_5597_binary_test_table (fixedlen_col, maxlen_col) VALUES 
    (0x, 0x), 
    (NULL, NULL), 
    (0x0, 0x0), 
    (0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF), 
    (0x0123, 0x0123)
GO

CREATE VIEW BABEL_5597_binary_test_view1 AS 
SELECT 
    CAST(t1.fixedlen_col + t1.fixedlen_col as BINARY(100)) as fixed_fixed_addition
FROM BABEL_5597_binary_test_table t1
ORDER BY fixed_fixed_addition;
GO

CREATE VIEW BABEL_5597_binary_test_view2 AS 
SELECT
    CAST(t1.maxlen_col + t1.fixedlen_col as BINARY(8000)) as max_fixed_addition,
    CAST(t1.fixedlen_col + t1.maxlen_col as BINARY(8000)) as fixed_max_addition, 
    CAST(t1.maxlen_col + t1.maxlen_col as BINARY(8000)) as max_max_addition
FROM BABEL_5597_binary_test_table t1
ORDER BY max_fixed_addition, fixed_max_addition, max_max_addition;
GO

CREATE VIEW BABEL_5597_binary_test_view3 AS 
SELECT 
    CAST(t1.fixedlen_col + t2.fixedlen_col as BINARY(100)) as fixed_fixed_addition
FROM BABEL_5597_binary_test_table t1
CROSS JOIN BABEL_5597_binary_test_table t2
ORDER BY fixed_fixed_addition;
GO

CREATE VIEW BABEL_5597_binary_test_view4 AS 
SELECT
    CAST(t1.maxlen_col + t2.fixedlen_col as BINARY(8000)) as max_fixed_addition,
    CAST(t1.fixedlen_col + t2.maxlen_col as BINARY(8000)) as fixed_max_addition, 
    CAST(t1.maxlen_col + t2.maxlen_col as BINARY(8000)) as max_max_addition
FROM BABEL_5597_binary_test_table t1
CROSS JOIN BABEL_5597_binary_test_table t2
ORDER BY max_fixed_addition, fixed_max_addition, max_max_addition;
GO

CREATE VIEW BABEL_5597_binary_test_view5 AS
SELECT 
    CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as BINARY(10)) as BINARY(8000)) as max_fixed_result,
    CAST(CAST(NULL as BINARY(100)) + CAST(0x0 as BINARY(100)) as BINARY(200)) as fixed_fixed_result,
    CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as BINARY(8000)) as BINARY(8000)) as max_max_result
GO

CREATE VIEW BABEL_5597_binary_test_view6 AS
SELECT 
    CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as BINARY(100)) as BINARY(8000)) as max_fixed_result,
    CAST(CAST(NULL as BINARY(100)) + CAST(NULL as BINARY(100)) as BINARY(200)) as fixed_fixed_result,
    CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as max_max_result
GO

CREATE VIEW BABEL_5597_binary_test_view7 AS
SELECT 
    CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as BINARY(10)) as BINARY(30)) as max_fixed_result,
    CAST(CAST(0x098765 as BINARY(10)) + CAST(0x012345 as BINARY(10)) as BINARY(20)) as fixed_fixed_result,
    CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as BINARY(20)) as BINARY(40)) as max_max_result
GO

CREATE VIEW BABEL_5597_binary_test_view8 AS
SELECT 
    CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as BINARY(10)) as BINARY(30)) as max_fixed_result,
    CAST(CAST(0x as BINARY(10)) + CAST(0x098765 as BINARY(10)) as BINARY(20)) as fixed_fixed_result,
    CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as BINARY(20)) as BINARY(40)) as max_max_result
GO

CREATE TABLE BABEL_5597_mixed_test_table (
    binary_fixed BINARY(20),
    binary_max BINARY(8000),
    varbinary_fixed VARBINARY(20),
    varbinary_max VARBINARY(MAX)
)
GO

INSERT INTO BABEL_5597_mixed_test_table VALUES 
    (0x, 0x, 0x, 0x),
    (NULL, NULL, NULL, NULL),
    (0x0, 0x0, 0x0, 0x0),
    (0xFFFFFFFFFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFFFFFFFFFF,
     0xFFFFFFFFFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFFFFFFFFFF),
    (0x0123, 0x0123, 0x0123, 0x0123)
GO

CREATE VIEW BABEL_5597_mixed_test_view1 AS 
SELECT 
    CAST(t1.binary_fixed + t1.varbinary_fixed as VARBINARY(40)) as binary_varbinary_fixed_addition,
    CAST(t1.varbinary_fixed + t1.binary_fixed as VARBINARY(40)) as varbinary_binary_fixed_addition
FROM BABEL_5597_mixed_test_table t1
ORDER BY binary_varbinary_fixed_addition, varbinary_binary_fixed_addition;
GO

CREATE VIEW BABEL_5597_mixed_test_view2 AS 
SELECT
    CAST(t1.binary_max + t1.varbinary_fixed as VARBINARY(MAX)) as binary_max_varbinary_fixed_addition,
    CAST(t1.varbinary_fixed + t1.binary_max as VARBINARY(MAX)) as varbinary_fixed_binary_max_addition,
    CAST(t1.binary_fixed + t1.varbinary_max as VARBINARY(MAX)) as binary_fixed_varbinary_max_addition,
    CAST(t1.varbinary_max + t1.binary_fixed as VARBINARY(MAX)) as varbinary_max_binary_fixed_addition,
    CAST(t1.binary_max + t1.varbinary_max as VARBINARY(MAX)) as binary_max_varbinary_max_addition,
    CAST(t1.varbinary_max + t1.binary_max as VARBINARY(MAX)) as varbinary_max_binary_max_addition
FROM BABEL_5597_mixed_test_table t1
ORDER BY binary_max_varbinary_fixed_addition, 
         varbinary_fixed_binary_max_addition,
         binary_fixed_varbinary_max_addition, 
         varbinary_max_binary_fixed_addition,
         binary_max_varbinary_max_addition, 
         varbinary_max_binary_max_addition;
GO

CREATE VIEW BABEL_5597_mixed_test_view3 AS 
SELECT 
    CAST(t1.binary_fixed + t2.varbinary_fixed as VARBINARY(40)) as binary_varbinary_fixed_addition,
    CAST(t1.varbinary_fixed + t2.binary_fixed as VARBINARY(40)) as varbinary_binary_fixed_addition
FROM BABEL_5597_mixed_test_table t1
CROSS JOIN BABEL_5597_mixed_test_table t2
ORDER BY binary_varbinary_fixed_addition, varbinary_binary_fixed_addition;
GO

CREATE VIEW BABEL_5597_mixed_test_view4 AS 
SELECT
    CAST(t1.binary_max + t2.varbinary_fixed as VARBINARY(MAX)) as binary_max_varbinary_fixed_addition,
    CAST(t1.varbinary_fixed + t2.binary_max as VARBINARY(MAX)) as varbinary_fixed_binary_max_addition,
    CAST(t1.binary_fixed + t2.varbinary_max as VARBINARY(MAX)) as binary_fixed_varbinary_max_addition,
    CAST(t1.varbinary_max + t2.binary_fixed as VARBINARY(MAX)) as varbinary_max_binary_fixed_addition,
    CAST(t1.binary_max + t2.varbinary_max as VARBINARY(MAX)) as binary_max_varbinary_max_addition,
    CAST(t1.varbinary_max + t2.binary_max as VARBINARY(MAX)) as varbinary_max_binary_max_addition
FROM BABEL_5597_mixed_test_table t1
CROSS JOIN BABEL_5597_mixed_test_table t2
ORDER BY binary_max_varbinary_fixed_addition,
         varbinary_fixed_binary_max_addition,
         binary_fixed_varbinary_max_addition,
         varbinary_max_binary_fixed_addition,
         binary_max_varbinary_max_addition,
         varbinary_max_binary_max_addition;
GO

CREATE VIEW BABEL_5597_mixed_test_view5 AS
SELECT 
    CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as VARBINARY(100)) as VARBINARY(MAX)) as binary_max_varbinary_fixed_result,
    CAST(CAST(0x0 as VARBINARY(100)) + CAST(NULL as BINARY(8000)) as VARBINARY(MAX)) as varbinary_fixed_binary_max_result,
    CAST(CAST(NULL as BINARY(100)) + CAST(0x0 as VARBINARY(100)) as VARBINARY(200)) as binary_varbinary_fixed_result,
    CAST(CAST(0x0 as VARBINARY(100)) + CAST(NULL as BINARY(100)) as VARBINARY(200)) as varbinary_binary_fixed_result,
    CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as VARBINARY(MAX)) as VARBINARY(MAX)) as binary_max_varbinary_max_result,
    CAST(CAST(0x0 as VARBINARY(MAX)) + CAST(NULL as BINARY(8000)) as VARBINARY(MAX)) as varbinary_max_binary_max_result
GO

CREATE VIEW BABEL_5597_mixed_test_view6 AS
SELECT 
    CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as VARBINARY(100)) as VARBINARY(MAX)) as binary_max_varbinary_fixed_result,
    CAST(CAST(NULL as VARBINARY(100)) + CAST(NULL as BINARY(8000)) as VARBINARY(MAX)) as varbinary_fixed_binary_max_result,
    CAST(CAST(NULL as BINARY(100)) + CAST(NULL as VARBINARY(100)) as VARBINARY(200)) as binary_varbinary_fixed_result,
    CAST(CAST(NULL as VARBINARY(100)) + CAST(NULL as BINARY(100)) as VARBINARY(200)) as varbinary_binary_fixed_result,
    CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as VARBINARY(MAX)) as VARBINARY(MAX)) as binary_max_varbinary_max_result,
    CAST(CAST(NULL as VARBINARY(MAX)) + CAST(NULL as BINARY(8000)) as VARBINARY(MAX)) as varbinary_max_binary_max_result
GO

CREATE VIEW BABEL_5597_mixed_test_view7 AS
SELECT 
    CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as VARBINARY(10)) as VARBINARY(MAX)) as binary_max_varbinary_fixed_result,
    CAST(CAST(0x012345 as VARBINARY(10)) + CAST(0x098765 as BINARY(20)) as VARBINARY(MAX)) as varbinary_fixed_binary_max_result,
    CAST(CAST(0x098765 as BINARY(10)) + CAST(0x012345 as VARBINARY(10)) as VARBINARY(20)) as binary_varbinary_fixed_result,
    CAST(CAST(0x012345 as VARBINARY(10)) + CAST(0x098765 as BINARY(10)) as VARBINARY(20)) as varbinary_binary_fixed_result,
    CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as VARBINARY(MAX)) as VARBINARY(MAX)) as binary_max_varbinary_max_result,
    CAST(CAST(0x012345 as VARBINARY(MAX)) + CAST(0x098765 as BINARY(20)) as VARBINARY(MAX)) as varbinary_max_binary_max_result
GO

CREATE VIEW BABEL_5597_mixed_test_view8 AS
SELECT 
    CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as VARBINARY(10)) as VARBINARY(MAX)) as binary_max_varbinary_fixed_result,
    CAST(CAST(0x098765 as VARBINARY(10)) + CAST(0x as BINARY(20)) as VARBINARY(MAX)) as varbinary_fixed_binary_max_result,
    CAST(CAST(0x as BINARY(10)) + CAST(0x098765 as VARBINARY(10)) as VARBINARY(20)) as binary_varbinary_fixed_result,
    CAST(CAST(0x098765 as VARBINARY(10)) + CAST(0x as BINARY(10)) as VARBINARY(20)) as varbinary_binary_fixed_result,
    CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as VARBINARY(MAX)) as VARBINARY(MAX)) as binary_max_varbinary_max_result,
    CAST(CAST(0x098765 as VARBINARY(MAX)) + CAST(0x as BINARY(20)) as VARBINARY(MAX)) as varbinary_max_binary_max_result
GO

-- Testing with functions
CREATE FUNCTION BABEL_5597_binary_test_func1()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(t1.fixedlen_col + t1.fixedlen_col as BINARY(100)) as fixed_fixed_addition
    FROM BABEL_5597_binary_test_table t1
    ORDER BY fixed_fixed_addition
);
GO

CREATE FUNCTION BABEL_5597_binary_test_func2()
RETURNS TABLE
AS
RETURN (
    SELECT
        CAST(t1.maxlen_col + t1.fixedlen_col as BINARY(8000)) as max_fixed_addition,
        CAST(t1.fixedlen_col + t1.maxlen_col as BINARY(8000)) as fixed_max_addition,
        CAST(t1.maxlen_col + t1.maxlen_col as BINARY(8000)) as max_max_addition
    FROM BABEL_5597_binary_test_table t1
    ORDER BY max_fixed_addition, fixed_max_addition, max_max_addition
);
GO

CREATE FUNCTION BABEL_5597_binary_test_func3()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(t1.fixedlen_col + t2.fixedlen_col as BINARY(100)) as fixed_fixed_addition
    FROM BABEL_5597_binary_test_table t1
    CROSS JOIN BABEL_5597_binary_test_table t2
    ORDER BY fixed_fixed_addition
);
GO

CREATE FUNCTION BABEL_5597_binary_test_func4()
RETURNS TABLE
AS
RETURN (
    SELECT
        CAST(t1.maxlen_col + t2.fixedlen_col as BINARY(8000)) as max_fixed_addition,
        CAST(t1.fixedlen_col + t2.maxlen_col as BINARY(8000)) as fixed_max_addition,
        CAST(t1.maxlen_col + t2.maxlen_col as BINARY(8000)) as max_max_addition
    FROM BABEL_5597_binary_test_table t1
    CROSS JOIN BABEL_5597_binary_test_table t2
    ORDER BY max_fixed_addition, fixed_max_addition, max_max_addition
);
GO

CREATE FUNCTION BABEL_5597_binary_test_func5()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as BINARY(100)) as BINARY(8000)) as max_fixed_result,
        CAST(CAST(NULL as BINARY(100)) + CAST(0x0 as BINARY(100)) as BINARY(200)) as fixed_fixed_result,
        CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as BINARY(8000)) as BINARY(8000)) as max_max_result
);
GO

CREATE FUNCTION BABEL_5597_binary_test_func6()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as BINARY(100)) as BINARY(8000)) as max_fixed_result,
        CAST(CAST(NULL as BINARY(100)) + CAST(NULL as BINARY(100)) as BINARY(200)) as fixed_fixed_result,
        CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as max_max_result
);
GO

CREATE FUNCTION BABEL_5597_binary_test_func7()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as BINARY(10)) as BINARY(30)) as max_fixed_result,
        CAST(CAST(0x098765 as BINARY(10)) + CAST(0x012345 as BINARY(10)) as BINARY(20)) as fixed_fixed_result,
        CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as BINARY(20)) as BINARY(40)) as max_max_result
);
GO

CREATE FUNCTION BABEL_5597_binary_test_func8()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as BINARY(10)) as BINARY(30)) as max_fixed_result,
        CAST(CAST(0x as BINARY(10)) + CAST(0x098765 as BINARY(10)) as BINARY(20)) as fixed_fixed_result,
        CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as BINARY(20)) as BINARY(40)) as max_max_result
);
GO

CREATE FUNCTION BABEL_5597_binary_test_func9
(
    @max_input1 BINARY(20),
    @fixed_input BINARY(10),
    @max_input2 BINARY(20)
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(@max_input1 + @fixed_input as BINARY(30)) as max_fixed_result,
        CAST(@fixed_input + @fixed_input as BINARY(20)) as fixed_fixed_result,
        CAST(@max_input1 + @max_input2 as BINARY(40)) as max_max_result
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func1()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(t1.binary_fixed + t1.varbinary_fixed as BINARY(200)) as binary_varbinary_fixed_addition,
        CAST(t1.varbinary_fixed + t1.binary_fixed as BINARY(200)) as varbinary_binary_fixed_addition
    FROM BABEL_5597_mixed_test_table t1
    ORDER BY binary_varbinary_fixed_addition, varbinary_binary_fixed_addition
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func2()
RETURNS TABLE
AS
RETURN (
    SELECT
        CAST(t1.binary_max + t1.varbinary_fixed as BINARY(8000)) as binary_max_varbinary_fixed_addition,
        CAST(t1.varbinary_fixed + t1.binary_max as BINARY(8000)) as varbinary_fixed_binary_max_addition,
        CAST(t1.binary_fixed + t1.varbinary_max as BINARY(8000)) as binary_fixed_varbinary_max_addition,
        CAST(t1.varbinary_max + t1.binary_fixed as BINARY(8000)) as varbinary_max_binary_fixed_addition,
        CAST(t1.binary_max + t1.varbinary_max as BINARY(8000)) as binary_max_varbinary_max_addition,
        CAST(t1.varbinary_max + t1.binary_max as BINARY(8000)) as varbinary_max_binary_max_addition
    FROM BABEL_5597_mixed_test_table t1
    ORDER BY binary_max_varbinary_fixed_addition, 
             varbinary_fixed_binary_max_addition,
             binary_fixed_varbinary_max_addition,
             varbinary_max_binary_fixed_addition,
             binary_max_varbinary_max_addition,
             varbinary_max_binary_max_addition
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func3()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(t1.binary_fixed + t2.varbinary_fixed as BINARY(200)) as binary_varbinary_fixed_addition,
        CAST(t1.varbinary_fixed + t2.binary_fixed as BINARY(200)) as varbinary_binary_fixed_addition
    FROM BABEL_5597_mixed_test_table t1
    CROSS JOIN BABEL_5597_mixed_test_table t2
    ORDER BY binary_varbinary_fixed_addition, varbinary_binary_fixed_addition
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func4()
RETURNS TABLE
AS
RETURN (
    SELECT
        CAST(t1.binary_max + t2.varbinary_fixed as BINARY(8000)) as binary_max_varbinary_fixed_addition,
        CAST(t1.varbinary_fixed + t2.binary_max as BINARY(8000)) as varbinary_fixed_binary_max_addition,
        CAST(t1.binary_fixed + t2.varbinary_max as BINARY(8000)) as binary_fixed_varbinary_max_addition,
        CAST(t1.varbinary_max + t2.binary_fixed as BINARY(8000)) as varbinary_max_binary_fixed_addition,
        CAST(t1.binary_max + t2.varbinary_max as BINARY(8000)) as binary_max_varbinary_max_addition,
        CAST(t1.varbinary_max + t2.binary_max as BINARY(8000)) as varbinary_max_binary_max_addition
    FROM BABEL_5597_mixed_test_table t1
    CROSS JOIN BABEL_5597_mixed_test_table t2
    ORDER BY binary_max_varbinary_fixed_addition,
             varbinary_fixed_binary_max_addition,
             binary_fixed_varbinary_max_addition,
             varbinary_max_binary_fixed_addition,
             binary_max_varbinary_max_addition,
             varbinary_max_binary_max_addition
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func5()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as VARBINARY(100)) as BINARY(8000)) as binary_max_varbinary_fixed_result,
        CAST(CAST(0x0 as VARBINARY(100)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as varbinary_fixed_binary_max_result,
        CAST(CAST(NULL as BINARY(100)) + CAST(0x0 as VARBINARY(100)) as BINARY(200)) as binary_varbinary_fixed_result,
        CAST(CAST(0x0 as VARBINARY(100)) + CAST(NULL as BINARY(100)) as BINARY(200)) as varbinary_binary_fixed_result,
        CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as VARBINARY(MAX)) as BINARY(8000)) as binary_max_varbinary_max_result,
        CAST(CAST(0x0 as VARBINARY(MAX)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as varbinary_max_binary_max_result
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func6()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as VARBINARY(100)) as BINARY(8000)) as binary_max_varbinary_fixed_result,
        CAST(CAST(NULL as VARBINARY(100)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as varbinary_fixed_binary_max_result,
        CAST(CAST(NULL as BINARY(100)) + CAST(NULL as VARBINARY(100)) as BINARY(200)) as binary_varbinary_fixed_result,
        CAST(CAST(NULL as VARBINARY(100)) + CAST(NULL as BINARY(100)) as BINARY(200)) as varbinary_binary_fixed_result,
        CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as VARBINARY(MAX)) as BINARY(8000)) as binary_max_varbinary_max_result,
        CAST(CAST(NULL as VARBINARY(MAX)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as varbinary_max_binary_max_result
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func7()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as VARBINARY(10)) as BINARY(30)) as binary_max_varbinary_fixed_result,
        CAST(CAST(0x012345 as VARBINARY(10)) + CAST(0x098765 as BINARY(20)) as BINARY(30)) as varbinary_fixed_binary_max_result,
        CAST(CAST(0x098765 as BINARY(10)) + CAST(0x012345 as VARBINARY(10)) as BINARY(20)) as binary_varbinary_fixed_result,
        CAST(CAST(0x012345 as VARBINARY(10)) + CAST(0x098765 as BINARY(10)) as BINARY(20)) as varbinary_binary_fixed_result,
        CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as VARBINARY(MAX)) as BINARY(30)) as binary_max_varbinary_max_result,
        CAST(CAST(0x012345 as VARBINARY(MAX)) + CAST(0x098765 as BINARY(20)) as BINARY(30)) as varbinary_max_binary_max_result
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func8()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as VARBINARY(10)) as BINARY(30)) as binary_max_varbinary_fixed_result,
        CAST(CAST(0x098765 as VARBINARY(10)) + CAST(0x as BINARY(20)) as BINARY(30)) as varbinary_fixed_binary_max_result,
        CAST(CAST(0x as BINARY(10)) + CAST(0x098765 as VARBINARY(10)) as BINARY(20)) as binary_varbinary_fixed_result,
        CAST(CAST(0x098765 as VARBINARY(10)) + CAST(0x as BINARY(10)) as BINARY(20)) as varbinary_binary_fixed_result,
        CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as VARBINARY(MAX)) as BINARY(30)) as binary_max_varbinary_max_result,
        CAST(CAST(0x098765 as VARBINARY(MAX)) + CAST(0x as BINARY(20)) as BINARY(30)) as varbinary_max_binary_max_result
);
GO

CREATE FUNCTION BABEL_5597_mixed_test_func9
(
    @binary_max BINARY(20),
    @binary_fixed BINARY(10),
    @varbinary_fixed VARBINARY(10),
    @varbinary_max VARBINARY(MAX)
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(@binary_max + @varbinary_fixed as BINARY(30)) as binary_max_varbinary_fixed_result,
        CAST(@varbinary_fixed + @binary_max as BINARY(30)) as varbinary_fixed_binary_max_result,
        CAST(@binary_fixed + @varbinary_max as BINARY(30)) as binary_fixed_varbinary_max_result,
        CAST(@varbinary_max + @binary_fixed as BINARY(30)) as varbinary_max_binary_fixed_result
);
GO

-- Procedures testing combinations
CREATE PROCEDURE BABEL_5597_binary_test_proc1
AS
BEGIN
    SELECT 
        CAST(t1.maxlen_col + t1.fixedlen_col as BINARY(8000)) as max_fixed_addition,
        CAST(t1.fixedlen_col + t1.fixedlen_col as BINARY(200)) as fixed_fixed_addition,
        CAST(t1.maxlen_col + t1.maxlen_col as BINARY(8000)) as max_max_addition,
        CAST(t1.fixedlen_col + t1.maxlen_col as BINARY(8000)) as fixed_max_addition
    FROM BABEL_5597_binary_test_table t1
    ORDER BY max_fixed_addition, 
             fixed_fixed_addition, 
             max_max_addition,
             fixed_max_addition;
END;
GO

CREATE PROCEDURE BABEL_5597_binary_test_proc2
AS
BEGIN
    SELECT 
        CAST(t1.maxlen_col + t2.fixedlen_col as BINARY(8000)) as max_fixed_addition,
        CAST(t1.fixedlen_col + t2.fixedlen_col as BINARY(200)) as fixed_fixed_addition,
        CAST(t1.maxlen_col + t2.maxlen_col as BINARY(8000)) as max_max_addition,
        CAST(t1.fixedlen_col + t2.maxlen_col as BINARY(8000)) as fixed_max_addition
    FROM BABEL_5597_binary_test_table t1 
    CROSS JOIN BABEL_5597_binary_test_table t2
    ORDER BY max_fixed_addition, 
             fixed_fixed_addition, 
             max_max_addition,
             fixed_max_addition;
END;
GO

CREATE PROCEDURE BABEL_5597_binary_test_proc3
AS
BEGIN
    SELECT 
        CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as BINARY(100)) as BINARY(8000)) as max_fixed_result,
        CAST(CAST(NULL as BINARY(100)) + CAST(0x0 as BINARY(100)) as BINARY(8000)) as fixed_fixed_result,
        CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as BINARY(8000)) as BINARY(8000)) as max_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_binary_test_proc4
AS
BEGIN
    SELECT 
        CAST(NULL as BINARY(8000)) + CAST(NULL as BINARY(100)) as max_fixed_result,
        CAST(NULL as BINARY(100)) + CAST(NULL as BINARY(100)) as fixed_fixed_result,
        CAST(NULL as BINARY(8000)) + CAST(NULL as BINARY(8000)) as max_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_binary_test_proc5
AS
BEGIN
    SELECT 
        CAST(0x098765 as BINARY(20)) + CAST(0x012345 as BINARY(10)) as max_fixed_result,
        CAST(0x098765 as BINARY(10)) + CAST(0x012345 as BINARY(10)) as fixed_fixed_result,
        CAST(0x098765 as BINARY(20)) + CAST(0x012345 as BINARY(20)) as max_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_binary_test_proc6
AS
BEGIN
    SELECT 
        CAST(0x as BINARY(20)) + CAST(0x098765 as BINARY(10)) as max_fixed_result,
        CAST(0x as BINARY(10)) + CAST(0x098765 as BINARY(10)) as fixed_fixed_result,
        CAST(0x as BINARY(20)) + CAST(0x098765 as BINARY(20)) as max_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_binary_test_proc7
(
    @max_input1 BINARY(20),
    @fixed_input BINARY(10),
    @max_input2 BINARY(20)
)
AS
BEGIN
    SELECT 
        @max_input1 + @fixed_input as max_fixed_result,
        @fixed_input + @fixed_input as fixed_fixed_result,
        @max_input1 + @max_input2 as max_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_mixed_test_proc1
AS
BEGIN
    SELECT 
        CAST(t1.binary_fixed + t1.varbinary_fixed as BINARY(200)) as binary_varbinary_fixed_addition,
        CAST(t1.varbinary_fixed + t1.binary_fixed as BINARY(200)) as varbinary_binary_fixed_addition
    FROM BABEL_5597_mixed_test_table t1
    ORDER BY binary_varbinary_fixed_addition, varbinary_binary_fixed_addition;
END;
GO

CREATE PROCEDURE BABEL_5597_mixed_test_proc2
AS
BEGIN
    SELECT 
        CAST(t1.binary_max + t1.varbinary_fixed as BINARY(8000)) as binary_max_varbinary_fixed_addition,
        CAST(t1.varbinary_fixed + t1.binary_max as BINARY(8000)) as varbinary_fixed_binary_max_addition,
        CAST(t1.binary_fixed + t1.varbinary_max as BINARY(8000)) as binary_fixed_varbinary_max_addition,
        CAST(t1.varbinary_max + t1.binary_fixed as BINARY(8000)) as varbinary_max_binary_fixed_addition,
        CAST(t1.binary_max + t1.varbinary_max as BINARY(8000)) as binary_max_varbinary_max_addition,
        CAST(t1.varbinary_max + t1.binary_max as BINARY(8000)) as varbinary_max_binary_max_addition
    FROM BABEL_5597_mixed_test_table t1
    ORDER BY binary_max_varbinary_fixed_addition, varbinary_fixed_binary_max_addition,
            binary_fixed_varbinary_max_addition, varbinary_max_binary_fixed_addition,
            binary_max_varbinary_max_addition, varbinary_max_binary_max_addition;
END;
GO

CREATE PROCEDURE BABEL_5597_mixed_test_proc3
AS
BEGIN
    SELECT 
        CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as VARBINARY(100)) as BINARY(8000)) as binary_max_varbinary_fixed_result,
        CAST(CAST(0x0 as VARBINARY(100)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as varbinary_fixed_binary_max_result,
        CAST(CAST(NULL as BINARY(100)) + CAST(0x0 as VARBINARY(100)) as BINARY(200)) as binary_varbinary_fixed_result,
        CAST(CAST(0x0 as VARBINARY(100)) + CAST(NULL as BINARY(100)) as BINARY(200)) as varbinary_binary_fixed_result,
        CAST(CAST(NULL as BINARY(8000)) + CAST(0x0 as VARBINARY(MAX)) as BINARY(8000)) as binary_max_varbinary_max_result,
        CAST(CAST(0x0 as VARBINARY(MAX)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as varbinary_max_binary_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_mixed_test_proc4
AS
BEGIN
    SELECT 
        CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as VARBINARY(100)) as BINARY(8000)) as binary_max_varbinary_fixed_result,
        CAST(CAST(NULL as VARBINARY(100)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as varbinary_fixed_binary_max_result,
        CAST(CAST(NULL as BINARY(100)) + CAST(NULL as VARBINARY(100)) as BINARY(200)) as binary_varbinary_fixed_result,
        CAST(CAST(NULL as VARBINARY(100)) + CAST(NULL as BINARY(100)) as BINARY(200)) as varbinary_binary_fixed_result,
        CAST(CAST(NULL as BINARY(8000)) + CAST(NULL as VARBINARY(MAX)) as BINARY(8000)) as binary_max_varbinary_max_result,
        CAST(CAST(NULL as VARBINARY(MAX)) + CAST(NULL as BINARY(8000)) as BINARY(8000)) as varbinary_max_binary_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_mixed_test_proc5
AS
BEGIN
    SELECT 
        CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as VARBINARY(10)) as BINARY(30)) as binary_max_varbinary_fixed_result,
        CAST(CAST(0x012345 as VARBINARY(10)) + CAST(0x098765 as BINARY(20)) as BINARY(30)) as varbinary_fixed_binary_max_result,
        CAST(CAST(0x098765 as BINARY(10)) + CAST(0x012345 as VARBINARY(10)) as BINARY(20)) as binary_varbinary_fixed_result,
        CAST(CAST(0x012345 as VARBINARY(10)) + CAST(0x098765 as BINARY(10)) as BINARY(20)) as varbinary_binary_fixed_result,
        CAST(CAST(0x098765 as BINARY(20)) + CAST(0x012345 as VARBINARY(MAX)) as BINARY(30)) as binary_max_varbinary_max_result,
        CAST(CAST(0x012345 as VARBINARY(MAX)) + CAST(0x098765 as BINARY(20)) as BINARY(30)) as varbinary_max_binary_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_mixed_test_proc6
AS
BEGIN
    SELECT 
        CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as VARBINARY(10)) as BINARY(30)) as binary_max_varbinary_fixed_result,
        CAST(CAST(0x098765 as VARBINARY(10)) + CAST(0x as BINARY(20)) as BINARY(30)) as varbinary_fixed_binary_max_result,
        CAST(CAST(0x as BINARY(10)) + CAST(0x098765 as VARBINARY(10)) as BINARY(20)) as binary_varbinary_fixed_result,
        CAST(CAST(0x098765 as VARBINARY(10)) + CAST(0x as BINARY(10)) as BINARY(20)) as varbinary_binary_fixed_result,
        CAST(CAST(0x as BINARY(20)) + CAST(0x098765 as VARBINARY(MAX)) as BINARY(30)) as binary_max_varbinary_max_result,
        CAST(CAST(0x098765 as VARBINARY(MAX)) + CAST(0x as BINARY(20)) as BINARY(30)) as varbinary_max_binary_max_result;
END;
GO

CREATE PROCEDURE BABEL_5597_mixed_test_proc7
(
    @binary_max BINARY(20),
    @binary_fixed BINARY(10),
    @varbinary_fixed VARBINARY(10),
    @varbinary_max VARBINARY(MAX)
)
AS
BEGIN
    SELECT 
        CAST(@binary_max + @varbinary_fixed as BINARY(30)) as binary_max_varbinary_fixed_result,
        CAST(@varbinary_fixed + @binary_max as BINARY(30)) as varbinary_fixed_binary_max_result,
        CAST(@binary_fixed + @varbinary_max as BINARY(30)) as binary_fixed_varbinary_max_result,
        CAST(@varbinary_max + @binary_fixed as BINARY(30)) as varbinary_max_binary_fixed_result;
END;
GO

--Testing with UDTs
CREATE TYPE FIXEDLEN_BINARY FROM BINARY(5)
GO

CREATE TYPE MAXLEN_BINARY FROM BINARY(8000)
GO

CREATE TYPE FIXEDLEN_VARBINARY FROM VARBINARY(5)
GO

CREATE TYPE MAXLEN_VARBINARY FROM VARBINARY(max)
GO

-- Tables and Indexes
CREATE TABLE BABEL_5597_binary_test (
    id int,
    binary_col binary(5)
);
GO

INSERT INTO BABEL_5597_binary_test (id, binary_col)
SELECT 
    generate_series(1, 100000),
    CAST(0x0000000100 as binary(5))
;
GO

INSERT INTO BABEL_5597_binary_test (id, binary_col) VALUES
(100003, 0x0000000049), 
(100001, 0x0000000050),  
(100002, 0x0000000150); 
GO

-- Create index
CREATE INDEX BABEL_5597_binary_ind ON BABEL_5597_binary_test (binary_col);
GO

CREATE TABLE abc11(
    A int, 
    B INT DEFAULT ( CAST(trunc(2.4) as INT4))
)
GO

INSERT into abc11 (a) VALUES (1)
GO