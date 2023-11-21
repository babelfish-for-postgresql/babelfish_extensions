SELECT * FROM datediff_big_vu_prepare_v1
GO

SELECT * FROM datediff_big_vu_prepare_v2
GO

SELECT * FROM datediff_big_vu_prepare_v3
GO

SELECT * FROM datediff_big_vu_prepare_v4
GO

SELECT * FROM datediff_big_vu_prepare_v5
GO

SELECT * FROM datediff_big_vu_prepare_v6
GO

SELECT * FROM datediff_big_vu_prepare_v7
GO

SELECT * FROM datediff_big_vu_prepare_v8
GO

SELECT * FROM datediff_big_vu_prepare_v9
GO

SELECT * FROM datediff_big_vu_prepare_v10
GO

SELECT * FROM datediff_big_vu_prepare_v11
GO

SELECT * FROM datediff_big_vu_prepare_v13
GO

EXEC datediff_big_vu_prepare_p1
GO

EXEC datediff_big_vu_prepare_p2
GO

EXEC datediff_big_vu_prepare_p3
GO

EXEC datediff_big_vu_prepare_p4
GO

EXEC datediff_big_vu_prepare_p5
GO

EXEC datediff_big_vu_prepare_p6
GO

EXEC datediff_big_vu_prepare_p7
GO

EXEC datediff_big_vu_prepare_p8
GO

EXEC datediff_big_vu_prepare_p9
GO

EXEC datediff_big_vu_prepare_p10
GO

EXEC datediff_big_vu_prepare_p11
GO

EXEC datediff_big_vu_prepare_p12
GO

EXEC datediff_big_vu_prepare_p13
GO

begin transaction
go

SELECT DATEDIFF_BIG(fakeoption, cast('2023-01-01 01:01:20.98' as datetime), cast('2023-01-01 01:01:20.98' as datetime))
go

if (@@trancount > 0) select cast('compile time error' as text) else select cast('runtime error' as text)
GO

if (@@trancount > 0) rollback tran
GO

begin transaction
go

SELECT DATEDIFF_BIG(nanosecond, cast('1900-01-01 01:01:20.98' as datetime), cast('3000-01-01 01:01:20.98' as datetime))
go

if (@@trancount > 0) select cast('compile time error' as text) else select cast('runtime error' as text)
GO

if (@@trancount > 0) rollback tran
GO

begin transaction
go

SELECT DATEADD(YY,-30000000, cast('1900-01-01' as datetime));
go

if (@@trancount > 0) select cast('compile time error' as text) else select cast('runtime error' as text)
GO

if (@@trancount > 0) rollback tran
GO