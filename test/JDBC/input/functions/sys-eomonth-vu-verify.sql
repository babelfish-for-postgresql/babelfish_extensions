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


--Lowest Acceptable value 0001 beyond that it will throw an error.
SELECT EOMONTH ('0001-01-31')
GO

--Highest Acceptable value 9999 beyond that it will throw an error.
SELECT EOMONTH ('9999-12-31')
GO


--Checking for NULL it should return NULL.
SELECT EOMONTH (NULL)
GO

--Checking for NULL it should return NULL with 2 arguments.
SELECT EOMONTH (NULL,1)
GO

--Checking for NULL it should return NULL with 2 arguments.
SELECT EOMONTH (NULL,0)
GO

--Checking for NULL it should return NULL with 2 arguments.
SELECT EOMONTH (NULL,-1)
GO

--Checking for different month last date.
--Check if its leap year. If it is a leap year and the month is feb it will return 29 otherwise 28.
SELECT EOMONTH('1996-02-20')
GO

--Check if its leap year. If it is a leap year and the month is feb it will return 29 otherwise 28.
SELECT EOMONTH('1997-02-20')
GO

--Checking for Jan last date it should return last date as 31.
SELECT EOMONTH('1996-01-01')
GO

--Checking for April last date it should return last date as 30.
SELECT EOMONTH('1996-04-01')
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


--Checking valid date format for ‘YYYY/MM/DD’ with offest.
SELECT EOMONTH ('1996/01/20',30)
GO

--Checking valid date format for YYYY/MON/DD’ with offest.
SELECT EOMONTH ('1996/JAN/20',-30)
GO

--Checking valid date format for ‘MM/DD/YYYY’ with offest.
SELECT EOMONTH ('02/20/1996',100)
GO

--Checking valid date format for ‘MM/DD/YY’ with offest.
SELECT EOMONTH ('1/20/96',1200)
GO
