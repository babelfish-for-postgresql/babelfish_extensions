SELECT * FROM EOMONTH_EndOfMonthView ORDER BY DateValue ASC;
GO

EXEC GetEndOfMonthDate_EOMONTH 1;
GO

SELECT * FROM EOMONTH_EndOfNextMonthView ORDER BY DateValue ASC;
GO

EXEC GetEndOfNextMonthDate_EOMONTH 1;
GO

--Edge case testing:
--when offset is positive edge cases where yyyy can go upto 9999 after that it will throw an error.
SELECT EOMONTH ('2023-05-10',95719)
GO

--when offset is positive edge cases where yyyy can go upto 9999 after that it will throw an error.
SELECT EOMONTH ('2023-05-10',95720)
GO

--when offset is negative edge cases where yyyy can go upto 0000 after that it will throw an error.
SELECT EOMONTH ('2023-05-10',-24268)
GO

--when offset is negative edge cases where yyyy can go upto 0000 after that it will throw an error.
SELECT EOMONTH ('2023-05-10',-24269)
GO

--EOMONTH with explicit datetime type
DECLARE @date DATETIME = '12/1/2011';  
SELECT EOMONTH ( @date ) AS Result;  
GO

--EOMONTH with explicit datetime type and offset
DECLARE @date DATETIME = '12/1/2011';  
SELECT EOMONTH ( @date , 2) AS Result;  
GO

--EOMONTH with string parameter and implicit conversion
DECLARE @date VARCHAR(255) = '12/1/2011';  
SELECT EOMONTH ( @date ) AS Result;  
GO

--EOMONTH with string parameter and implicit conversion and offsets
DECLARE @date VARCHAR(255) = '12/1/2011';  
SELECT EOMONTH ( @date , -2) AS Result;  
GO

--Some of the date formats which are accepted by date datatype.
--Checking when separator is ‘-’ 
--Checking valid date format for ‘YYYY-MM-DD’.
SELECT EOMONTH ('1996-01-20')
GO

--Checking valid date format for YYYY-MON-DD’.
SELECT EOMONTH ('1996-JAN-20')
GO

--Checking valid date format for ‘MM-DD-YYYY’.
SELECT EOMONTH ('01-20-1996')
GO

--Checking valid date format for ‘MM-DD-YY’.
SELECT EOMONTH ('1-20-96')
GO


--Checking when separator is ‘/’ 
--Checking valid date format for ‘YYYY/MM/DD’.
SELECT EOMONTH ('1996/01/20',30)
GO

--Checking valid date format for YYYY/MON/DD’.
SELECT EOMONTH ('1996/JAN/20',-30)
GO

--Checking valid date format for ‘MM/DD/YYYY’.
SELECT EOMONTH ('02/20/1996',100)
GO

--Checking valid date format for ‘MM/DD/YY’.
SELECT EOMONTH ('1/20/96',1200)
GO

--Checking when separator is ‘.’
--Checking valid date format for ‘YYYY.MM.DD’.
SELECT EOMONTH ('1996.01.20',0)
GO

--Checking valid date format for YYYY.MON.DD’.
SELECT EOMONTH ('1996.JAN.20',10)
GO

--Checking valid date format for ‘MM.DD.YYYY’.
SELECT EOMONTH ('02.20.1996')
GO

--Checking valid date format for ‘MM.DD.YY’.
SELECT EOMONTH ('1.20.96')
GO

--Checking valid date format for ‘Month DD YYYY’.
SELECT EOMONTH ('JAN 20 1996')
GO

--Checking valid date format for ‘Month DD YY’.
SELECT EOMONTH ('JAN 20 96')
GO

--Checking valid date format for ‘Month DD, YYYY’.
SELECT EOMONTH ('JAN 20, 1996')
GO

--Checking valid date format for ‘Month DD, YY’.
SELECT EOMONTH ('JAN 20, 96')
GO

--Checking valid date format for ‘DD Month YYYY’.
SELECT EOMONTH ('20 JAN 1996')
GO

--Checking valid date format for ‘DD Month YY’.
SELECT EOMONTH ('20 JAN 96')
GO

--Checking valid date format for ‘DD Month YYYY’.
SELECT EOMONTH ('20 JAN, 1996')
GO

--Checking valid date format for ‘DD Month YY’.
SELECT EOMONTH ('20 JAN, 96')
GO

--Checking valid date format for ‘YYYYMMDD’.
SELECT EOMONTH ('19960120')
GO

--Checking valid date format for ‘YYMMDD’.
SELECT EOMONTH ('960120')
GO

--Checking for NULL it should return NULL
SELECT EOMONTH (NULL)
GO