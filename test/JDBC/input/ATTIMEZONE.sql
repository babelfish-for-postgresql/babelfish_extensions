Select convert(datetimeoffset,'2022-10-29 20:01:00.000') AT TIME ZONE NULL
Go

Select NULL AT TIME ZONE 'Eastern Standard Time'
Go

Select convert(datetime,'2022-10-29 20:01:00.000') AT TIME ZONE NULL
GO

Select convert(datetime,'2022-10-29 20:01:00.000') AT TIME ZONE 'NULL'
GO

Select NULL AT TIME ZONE NULL
Go

Select NULL AT TIME ZONE 'NULL'
GO

Select 'NULL' AT TIME ZONE NULL
GO

Select 'NULL' AT TIME ZONE 'NULL'
GO

Select convert(datetime,'2022-10-29 20:01:00.000') AT TIME ZONE 'Eastern Standard Time' AT TIME ZONE 'Central Standard Time'
Go

Select '2022-10-29 20:01:00.000' AT TIME ZONE convert(datetime,'2022-10-29 20:01:00.000')
Go

Select convert(datetimeoffset,'2022-10-29 20:01:00.000') AT TIME ZONE 23
Go

Select convert(datetimeoffset,'2022-10-29 20:01:00.000') AT TIME ZONE convert(int,23)
Go

Select '2022-10-29 20:01:00.000' AT TIME ZONE 'Eastern Standard Time'
Go

Select convert(datetime2,'2002-01-01 02:01:00.000 +00:00') AT TIME ZONE 'eAstern stAnDard tIMe'
GO

Select convert(datetimeoffset,'2022-10-29 20:01:00.0000000 -05:00') AT TIME ZONE 'Eastern  Standard  Time'
GO

Select convert(datetimeoffset,'2022-10-29 20:01:00.0000000 -05:00') AT TIME ZONE 'Eastern Standard Time '
GO

Select convert(datetime2,'2002-01-01 02:01:00.000 +00:00') AT TIME ZONE 'dgycgwycgqd'
GO

DECLARE @lvDate DATETIME, @lvDateUTC DATETIME
SET @lvDate = '2021-01-01'
SET @lvDateUTC = @lvDate AT TIME ZONE  'US Eastern Standard Time' AT TIME ZONE 'UTC'
SELECT @lvDate, @lvDateUTC
GO

Select convert(datetime2,'2002-01-01 02:01:00.000 +00:00') aT TiMe ZoNE 'Eastern Standard Time'
GO

Select convert(datetime2,'2002-01-01 02:01:00.000 +00:00') aT   TiMe   ZoNE 'Eastern Standard Time'
GO

DROP TABLE IF EXISTS test
Create table test( a datetime)
insert into test(a) values(cast('1999-02-16' as datetime))
GO
DECLARE @testzone nvarchar(128) = 'Central European Standard Time';
Select a AT TIME ZONE @testzone from test
GO

DROP TABLE IF EXISTS test
GO

Select convert(smalldatetime,'2022-10-29 20:01:24.426') AT TIME ZONE 'Eastern Standard Time'
GO

Select convert(time,' 20:01:24.426') AT TIME ZONE 'Eastern Standard Time'
GO

Select convert(date,'2022-10-29')  AT TIME ZONE 'Eastern Standard Time'
GO

Select 123  AT TIME ZONE 'Eastern Standard Time'
GO

--Test covering all timezones

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'afghanistan standard time' AS 'afghanistan standard time';
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'alaskan standard time' AS 'alaskan standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'aleutian standard time' AS 'aleutian standard time'; 	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'altai standard time' AS 'altai standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'arab standard time' AS 'arab standard time' ;
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'arabian standard time' AS 'arabian standard time'; 	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'arabic standard time' AS 'arabic standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'argentina standard time' AS 'argentina standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'astrakhan standard time' AS 'astrakhan standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'atlantic standard time' AS 'atlantic standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'aus central standard time' AS 'aus central standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'aus central w. standard time' AS 'aus central w. standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'aus eastern standard time' AS 'aus eastern standard time' ;
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'azerbaijan standard time' AS 'azerbaijan standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'azores standard time' AS 'azores standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'bahia standard time' AS 'bahia standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'bangladesh standard time' AS 'bangladesh standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'belarus standard time' AS 'belarus standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'bougainville standard time' AS 'bougainville standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'canada central standard time' AS 'canada central standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'cape verde standard time' AS 'cape verde standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'caucasus standard time' AS 'caucasus standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'cen. australia standard time' AS 'cen. australia standard time' ;
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'central america standard time' AS 'central america standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'central asia standard time' AS 'central asia standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'central europe standard time' AS 'central europe standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'central european standard time' AS 'central european standard time' ; 	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'central pacific standard time' AS 'central pacific standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'central standard time' AS 'central standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'central standard time (mexico)' AS 'central standard time (mexico)' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'chatham islands standard time' AS 'chatham islands standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'china standard time' AS 'china standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'Cuba standard time' AS 'Cuba standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'dateline standard time' AS 'dateline standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'e. africa standard time' AS 'e. africa standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'e. australia standard time' AS 'e. australia standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'e. europe standard time' AS 'e. europe standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'e. south america standard time' AS 'e. south america standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'easter island standard time' AS 'easter island standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'eastern standard time' AS 'eastern standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'eastern standard time (mexico)' AS 'eastern standard time (mexico)' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'egypt standard time' AS 'egypt standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'ekaterinburg standard time' AS 'ekaterinburg standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'fiji standard time' AS 'fiji standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'fle standard time' AS 'fle standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'georgian standard time' AS 'georgian standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'gmt standard time' AS 'gmt standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'greenland standard time' AS 'greenland standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'greenwich standard time' AS 'greenwich standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'gtb standard time' AS 'gtb standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'haiti standard time' AS 'haiti standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'hawaiian standard time' AS 'hawaiian standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'india standard time' AS 'india standard time' ;
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'iran standard time' AS 'iran standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'israel standard time' AS 'israel standard time' ; 	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'jordan standard time' AS 'jordan standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'kaliningrad standard time' AS 'kaliningrad standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'kamchatka standard time' AS 'kamchatka standard time' ;		
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'korea standard time' AS 'korea standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'libya standard time' AS 'libya standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'line islands standard time' AS 'line islands standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'lord howe standard time' AS 'lord howe standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'magadan standard time' AS 'magadan standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'magallanes standard time' AS 'magallanes standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'marquesas standard time' AS 'marquesas standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'mauritius standard time' AS 'mauritius standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'mid-atlantic standard time' AS 'mid-atlantic standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'middle east standard time' AS 'middle east standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'montevideo standard time' AS 'montevideo standard time' ;
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'morocco standard time' AS 'morocco standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'mountain standard time' AS 'mountain standard time' ;		
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'mountain standard time (mexico)' AS 'mountain standard time (mexico)' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'myanmar standard time' AS 'myanmar standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'n. central asia standard time' AS 'n. central asia standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'namibia standard time' AS 'namibia standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'nepal standard time' AS 'nepal standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'new zealand standard time' AS 'new zealand standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'newfoundland standard time' AS 'newfoundland standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'norfolk standard time' AS 'norfolk standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'north asia east standard time' AS 'north asia east standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'north asia standard time' AS 'north asia standard time' ;
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'omsk standard time' AS 'omsk standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'pacific sa standard time' AS 'pacific sa standard time' ;
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'pacific standard time' AS 'pacific standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'pacific standard time (mexico)' AS 'pacific standard time (mexico)' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'paraguay standard time' AS 'paraguay standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'qyzylorda standard time' AS 'qyzylorda standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'romance standard time' AS 'romance standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'russia time zone 3' AS 'russia time zone 3' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'russia time zone 11' AS 'russia time zone 11' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'Russian standard time' AS 'Russian standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'sa eastern standard time' AS 'sa eastern standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'sa pacific standard time' AS 'sa pacific standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'sa western standard time' AS 'sa western standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'saint pierre standard time' AS 'saint pierre standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'samoa standard time' AS 'samoa standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'sao tome standard time' AS 'sao tome standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'saratov standard time' AS 'saratov standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'se asia standard time' AS 'se asia standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'singapore standard time' AS 'singapore standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'south africa standard time' AS 'south africa standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'south sudan standard time' AS 'south sudan standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'sri Lanka standard time' AS 'sri Lanka standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'sudan standard time' AS 'sudan standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'syria standard time' AS 'syria standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'taipei standard time' AS 'taipei standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'tasmania standard time' AS 'tasmania standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'tocantins standard time' AS 'tocantins standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'tokyo standard time' AS 'tokyo standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'tomsk standard time' AS 'tomsk standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'tonga standard time' AS 'tonga standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'transbaikal standard time' AS 'transbaikal standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'turkey standard time' AS 'turkey standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'turks and caicos standard time' AS 'turks and caicos standard time' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'ulaanbaatar standard time' AS 'ulaanbaatar standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'us eastern standard time' AS 'us eastern standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'us mountain standard time' AS 'us mountain standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'utc' AS 'utc' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'utc+12' AS 'utc+12' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'utc+13' AS 'utc+13' ; 	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'utc-02' AS 'utc-02' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'utc-08' AS 'utc-08' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'utc-09' AS 'utc-09' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'utc-11' AS 'utc-11' ;
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'venezuela standard time' AS 'venezuela standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'vladivostok standard time' AS 'vladivostok standard time' ;
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'volgograd standard time' AS 'volgograd standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'w. australia standard time' AS 'w. australia standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'w. central africa standard time' AS 'w. central africa standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'w. europe standard time' AS 'w. europe standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'w. mongolia standard time' AS 'w. mongolia standard time' ;	
GO

Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'west asia standard time' AS 'west asia standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'west bank standard time' AS 'west bank standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'west pacific standard time' AS 'west pacific standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'yakutsk standard time' AS 'yakutsk standard time' ;	
GO
	
Select convert(datetimeoffset,'2023-09-15 20:01:00.0000000 -05:00') AT TIME ZONE 'yukon standard time' AS 'yukon standard time' ;	
GO

	  