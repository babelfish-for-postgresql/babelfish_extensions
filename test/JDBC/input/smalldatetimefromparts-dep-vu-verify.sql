SELECT * FROM smalldatetimefromparts_vu_prepare_v1
GO

SELECT * FROM smalldatetimefromparts_vu_prepare_v2
GO

EXEC smalldatetimefromparts_vu_prepare_p1
GO
 
EXEC smalldatetimefromparts_vu_prepare_p2
GO

SELECT smalldatetimefromparts_vu_prepare_f1()
GO
 
SELECT smalldatetimefromparts_vu_prepare_f2()
GO
