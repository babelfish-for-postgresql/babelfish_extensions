-- [BABEL-2826] Support TIMEFROMPARTS Transact-SQL function
CREATE VIEW timefromparts_vu_prepare_v1 AS (SELECT TIMEFROMPARTS ( 23, 59, 59, 0, 0));
GO

CREATE VIEW timefromparts_vu_prepare_v2 AS (SELECT TIMEFROMPARTS ( 23, 59, 59, 456, 5));
GO

-- error expected, fractional part should not be larger than scale
CREATE PROCEDURE timefromparts_vu_prepare_p1 AS (SELECT TIMEFROMPARTS ( 23, 59, 59, 5678, 3));
GO

-- error expected, scale > 7
CREATE FUNCTION timefromparts_vu_prepare_f1()
RETURNS TIME AS
BEGIN
RETURN (SELECT TIMEFROMPARTS ( 23, 59, 59, 52, 8));
END
GO
