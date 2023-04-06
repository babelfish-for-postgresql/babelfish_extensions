-- [BABEL-1627, 2827] Support DATETIME2FROMPARTS Transact-SQL function
CREATE VIEW datetime2fromparts_vu_prepare_v1 AS (select DATETIME2FROMPARTS(1962, 16, 1, 14, 64, 48, 59, 5 ));
GO

CREATE VIEW datetime2fromparts_vu_prepare_v2 AS (select DATETIME2FROMPARTS(20008, 8, 32, 34, 23, 78, 45, 8 ));
GO

CREATE VIEW datetime2fromparts_vu_prepare_v3 AS (select DATETIME2FROMPARTS(1980, 11, 25, 22, 09, 58, 671, 4 ));
GO

CREATE PROCEDURE datetime2fromparts_vu_prepare_p1 AS (select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 1 ));
GO

CREATE PROCEDURE datetime2fromparts_vu_prepare_p2 AS (select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 2 ));
GO

CREATE PROCEDURE datetime2fromparts_vu_prepare_p3 AS (select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 3 ));
GO

CREATE PROCEDURE datetime2fromparts_vu_prepare_p4 AS (select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 4 ));
GO

CREATE FUNCTION datetime2fromparts_vu_prepare_f1()
RETURNS DATETIME2 AS
BEGIN
RETURN (select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 5 ));
END
GO

CREATE FUNCTION datetime2fromparts_vu_prepare_f2()
RETURNS DATETIME2 AS
BEGIN
RETURN (select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 6 ));
END
GO
