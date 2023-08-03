SELECT SMALLDATETIMEFROMPARTS ( 1899, 12, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 1899, 01, 01, 00, 00 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 1900, 12, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 1900, 1, 1, 00, 00 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, 00, NULL ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, NULL, 23 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, NULL, 00, 23  ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078, NULL, 01, 00, 23 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( NULL, 1, 01, 00, 13 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( NULL,NULL, NULL, NULL, NULL ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 1899, 6, 30, 23, 59 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 1900, 13, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2079, 12, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2080, 1 , 1 , 00 , 0 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078, 12, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 13, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2079, 1, 1, 00,      00 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2079, 1, 1, 00, '     00' ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078, 00, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 0, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 01, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 31, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 32, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 0, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 00, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, 23, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, 24, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, 00, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, -01, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, -00, 59 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, -00, 60 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, -00, 00 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, -00, 0 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, -00, -1 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 01, -00, -01 ) AS Result
go

SELECT SMALLDATETIMEFROMPARTS ( '2078', 1, 01, 00, 22) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ('2078','1','01','00','22' ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078.03, 1, 01, 00, 22 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078.45, 1, 01, 00, 22 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078.60, 1, 01, 00, 22 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078.60, 1.0, 0.1, 0.0, 2.2 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1.0, 2, 0, 2 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 2, 0.0, 2 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2078, 1, 2, 0, 2.0 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( cast(2078 as varchar), cast(1 as numeric), cast(2 as bigint), cast(0 as float), cast(2 as real) ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( cast(0x12 as int), 1, 2, 0, 2.0 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( cast(0x123 as int), 1, 2, 0, 2.0 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 1017*2,2*5, 4*5, 2*11, 14*2*2 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( cast(0x7D0 as int), 1, 2, 0, 2.0 ) AS Result
GO

SELECT SMALLDATETIMEFROMPARTS ( 2079, 1, 1, 00, 2.2 ) AS Result
GO
