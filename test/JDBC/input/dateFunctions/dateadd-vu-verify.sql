exec dateadd_p1
GO

exec dateadd_p2
GO

exec dateadd_p3
GO

exec dateadd_p4
GO

exec dateadd_p5
GO

exec dateadd_p6
GO

exec dateadd_p7
GO

exec dateadd_p8
GO

exec dateadd_p9
GO

exec dateadd_p10
GO

begin transaction
go

SELECT dateadd(fakeoption, 2, cast('1900-01-01' as date));
go

if (@@trancount > 0) select cast('compile time error' as text) else select cast('runtime error' as text)
GO

if (@@trancount > 0) rollback tran
GO

begin transaction
go

SELECT dateadd(day, 2, cast('01:01:21' as time));
go

if (@@trancount > 0) select cast('compile time error' as text) else select cast('runtime error' as text)
GO

if (@@trancount > 0) rollback tran
GO

begin transaction
go

SELECT DATEADD(YY,-300,getdate());
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

begin transaction
go

SELECT DATEADD(year,-300000000,cast('1900-01-01' as datetime));
go

if (@@trancount > 0) select cast('compile time error' as text) else select cast('runtime error' as text)
GO

if (@@trancount > 0) rollback tran
GO

