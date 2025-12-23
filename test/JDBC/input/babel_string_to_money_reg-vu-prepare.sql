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
    DECLARE @c money=CHAR(44), @b money=CHAR(92), @z money='\0', @e money=CHAR(43);
    SELECT 'comma' AS name, @c AS val UNION ALL
    SELECT 'backslash', @b UNION ALL
    SELECT 'backslash_zero', @z UNION ALL
    SELECT 'plus', @e;
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
