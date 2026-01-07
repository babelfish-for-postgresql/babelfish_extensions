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

SELECT * FROM dateadd_v1
GO

SELECT * FROM dateadd_v2
GO

SELECT * FROM dateadd_v3
GO

SELECT * FROM dateadd_v4
GO

SELECT * FROM dateadd_v5
GO

SELECT * FROM dateadd_v6
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

SELECT ID, UdtTime, DATEADD (HOUR, 1, UdtTime) AS UDTTIME FROM UdtTable
GO

SELECT ID, UdtTime, DATEADD (MINUTE, 1, UdtTime) AS UDTTIME FROM UdtTable
GO

SELECT ID, UdtTime, DATEADD (MILLISECOND, 1, UdtTime) AS UDTTIME FROM UdtTable
GO

SELECT ID, UdtTime, DATEADD (HOUR, 1, UdtTime) AS UDTTIME FROM UdtTable
GO

SELECT ID, UdtDate, DATEADD (MONTH, 5, UdtDate) AS UDTDATE FROM UdtTable
GO

SELECT ID, UdtDatetime, DATEADD (YEAR, 2, UdtDatetime) AS UDTDATETIME FROM UdtTable
GO

SELECT ID, UdtDatetime2, DATEADD (WEEK, 15, UdtDatetime2) AS UDTDATETIME2 FROM UdtTable
GO

SELECT ID, UdtTimestamp, DATEADD (DAY, 2, UdtTimestamp) AS UDTTIMESTAMP FROM UdtTable
GO

SELECT ID, UdtTimestamp, DATEADD (MONTH, 45, UdtTimestamp) AS UDTTIMESTAMP FROM UdtTable
GO

SELECT ID, UdtTimestamp, DATEADD (SECOND, 464, UdtTimestamp) AS UDTTIMESTAMP FROM UdtTable
GO

SELECT ID, UdtSmalldatetime, DATEADD (YEAR, 9, UdtSmalldatetime) AS UDTSMALLDATETIME FROM UdtTable
GO

SELECT ID, UdtDatetimeOffset, DATEADD (DAY, 0, UdtDatetimeOffset) AS UDTDATETIMEOFFSET FROM UdtTable
GO
 
SELECT ID, UdtDatetimeOffset, DATEADD (MONTH, 15, UdtDatetimeOffset) AS UDTDATETIMEOFFSET FROM UdtTable
GO
 
SELECT ID, UdtDatetimeOffset, DATEADD (WEEK, 2, UdtDatetimeOffset) AS UDTDATETIMEOFFSET FROM UdtTable
GO
 
SELECT ID, UdtDatetimeOffset, DATEADD (SECOND, 459, UdtDatetimeOffset) AS UDTDATETIMEOFFSET FROM UdtTable
GO