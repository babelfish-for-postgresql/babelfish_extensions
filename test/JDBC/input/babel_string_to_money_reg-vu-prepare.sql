CREATE FUNCTION dbo.fn_tests_moneydecl()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        CAST(CHAR(9) AS money) AS tab_val,
        CAST(CHAR(160) AS money) AS nbsp_val  
);
GO

CREATE VIEW dbo.vw_test_money_whitespace AS
SELECT 
    CAST(' ' AS money) AS space_val,
    CAST(CHAR(9) AS money) AS tab_val,
    CAST(CHAR(10) AS money) AS lf_val,
    CAST(CHAR(13) AS money) AS cr_val,
    CAST(CHAR(160) AS money) AS nbsp_val;
GO

CREATE PROCEDURE dbo.sp_test_money_special
AS
BEGIN
    DECLARE @c money = CHAR(44), @b money = CHAR(92);

    DECLARE @results TABLE (
        id INT,
        name VARCHAR(20),
        val money
    );

    INSERT INTO @results (id, name, val) VALUES (1, 'comma', @c);
    INSERT INTO @results (id, name, val) VALUES (2, 'backslash', @b);

    SELECT name, val FROM @results ORDER BY id;
END;
GO

CREATE VIEW dbo.vw_test_money_currency AS
SELECT 
    CAST('$' AS money) AS dollar,
    CAST(CHAR(162) AS money) AS cent,
    CAST(CHAR(163) AS money) AS pound,
    CAST(CHAR(165) AS money) AS yen;
GO

CREATE FUNCTION dbo.fn_money_chars()
RETURNS TABLE
AS
RETURN (
    SELECT 
        CAST(CHAR(36) AS money) AS dollar,
        CAST(CHAR(44) AS money) AS comma,
        CAST(CHAR(49) AS money) AS one
);
GO

CREATE PROCEDURE dbo.sp_test_money_digits
AS
BEGIN
    SELECT name, val FROM (
        SELECT 1 AS seq, 'char_48 (0)' AS name, CAST(CHAR(48) AS money) AS val UNION ALL
        SELECT 2, 'char_49 (1)', CAST(CHAR(49) AS money) UNION ALL
        SELECT 3, 'char_50 (2)', CAST(CHAR(50) AS money) UNION ALL
        SELECT 4, 'char_51 (3)', CAST(CHAR(51) AS money) UNION ALL
        SELECT 5, 'char_52 (4)', CAST(CHAR(52) AS money) UNION ALL
        SELECT 6, 'char_53 (5)', CAST(CHAR(53) AS money) UNION ALL
        SELECT 7, 'char_54 (6)', CAST(CHAR(54) AS money) UNION ALL
        SELECT 8, 'char_55 (7)', CAST(CHAR(55) AS money) UNION ALL
        SELECT 9, 'char_56 (8)', CAST(CHAR(56) AS money) UNION ALL
        SELECT 10, 'char_57 (9)', CAST(CHAR(57) AS money)
    ) AS results
    ORDER BY seq;
END;
GO