-- 123
exec datediff_p1
GO

-- -30
exec datediff_p2
GO

-- -120
exec datediff_p3
GO

-- 24
exec datediff_p4
GO

-- 105
exec datediff_p5
GO

-- -10957
exec datediff_p6
GO

-- -262963
exec datediff_p7
GO

-- -15777780
exec datediff_p8
GO

-- 157885200
exec datediff_p9
GO

-- 32400000
exec datediff_p10
GO

-- 1200000000
exec datediff_p11
GO

-- overflow
exec datediff_p12
GO

-- 1200000000000
exec datediff_p13
GO

-- 15
exec datediff_p14
GO

exec datediff_p15
GO

exec datediff_p16
GO

begin transaction
go

SELECT DATEDIFF(fakeoption, cast('2023-01-01 01:01:20.98' as datetime), cast('2023-01-01 01:01:20.98' as datetime))
go

if (@@trancount > 0) select cast('compile time error' as text) else select cast('runtime error' as text)
GO

if (@@trancount > 0) rollback tran
GO

begin transaction
go

SELECT DATEDIFF(nanosecond, cast('1900-01-01 01:01:20.98' as datetime), cast('2023-01-01 01:01:20.98' as datetime))
go

if (@@trancount > 0) select cast('compile time error' as text) else select cast('runtime error' as text)
GO

if (@@trancount > 0) rollback tran
GO
