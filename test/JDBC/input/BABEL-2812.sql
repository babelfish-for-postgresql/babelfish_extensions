declare @refreshTime varchar(20) = '17:30:00'
declare @yyyymmdd    varchar(20) = '20211212'
select CONVERT(datetime,@refreshTime,14) + @yyyymmdd as NextTime
go

declare @refreshTime datetime = '17:30:00'
declare @yyyymmdd    datetime = '20211212'
select  @refreshTime + @yyyymmdd as NextTime
go

declare @refreshTime datetime = '17:30:00'
declare @yyyymmdd    datetime = '20211212'
SELECT @yyyymmdd - @refreshTime
go


declare @refreshTime datetime = '17:30:00'
declare @yyyymmdd    datetime = '20211212'
SELECT DATEADD(day ,DATEDIFF(day, 0, @yyyymmdd) ,@refreshTime) as NextTime;
go
