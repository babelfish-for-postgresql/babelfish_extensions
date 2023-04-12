-- [BABEL-2826] Support TIMEFROMPARTS Transact-SQL function
select TIMEFROMPARTS(24, 23, 54, 35, 2 );
GO

select TIMEFROMPARTS(18, 63, 49, 75, 5 );
GO

select TIMEFROMPARTS(08, 39, 84, 589, 3 );
GO

SELECT * FROM timefromparts_vu_prepare_v1
GO
DROP VIEW timefromparts_vu_prepare_v1
GO

SELECT * FROM timefromparts_vu_prepare_v2
GO
DROP VIEW timefromparts_vu_prepare_v2
GO

EXEC timefromparts_vu_prepare_p1
GO
DROP PROCEDURE timefromparts_vu_prepare_p1
GO

SELECT timefromparts_vu_prepare_f1()
GO
DROP FUNCTION timefromparts_vu_prepare_f1()
GO
