-- [BABEL-1627, 2827] Support DATETIME2FROMPARTS Transact-SQL function
select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 0 );
GO

select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 7 );
GO

select DATETIME2FROMPARTS(2011, 8, 15, 14, 23, 44, 5, 8 );
GO

SELECT DATETIME2FROMPARTS ( 2010, 12, 31, 23, 59, 59, 0, 0 ) AS Result;
GO

SELECT * FROM datetime2fromparts_vu_prepare_v1
GO
DROP VIEW datetime2fromparts_vu_prepare_v1
GO

SELECT * FROM datetime2fromparts_vu_prepare_v2
GO
DROP VIEW datetime2fromparts_vu_prepare_v2
GO

SELECT * FROM datetime2fromparts_vu_prepare_v3
GO
DROP VIEW datetime2fromparts_vu_prepare_v3
GO

EXEC datetime2fromparts_vu_prepare_p1
GO
DROP PROCEDURE datetime2fromparts_vu_prepare_p1
GO

EXEC datetime2fromparts_vu_prepare_p2
GO
DROP PROCEDURE datetime2fromparts_vu_prepare_p2
GO

EXEC datetime2fromparts_vu_prepare_p3
GO
DROP PROCEDURE datetime2fromparts_vu_prepare_p3
GO

EXEC datetime2fromparts_vu_prepare_p4
GO
DROP PROCEDURE datetime2fromparts_vu_prepare_p4
GO

SELECT datetime2fromparts_vu_prepare_f1()
GO
DROP FUNCTION datetime2fromparts_vu_prepare_f1()
GO

SELECT datetime2fromparts_vu_prepare_f2()
GO
DROP FUNCTION datetime2fromparts_vu_prepare_f2()
GO
