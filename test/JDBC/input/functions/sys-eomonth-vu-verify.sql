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

--Checking for NULL it should return NULL with 2 arguments.
SELECT EOMONTH (NULL,NULL)
GO

--Checking if the 1st argument is date and 2nd argument is NULL it should still return the value for that month last date.
SELECT EOMONTH ('1996-01-01',NULL)
GO

--BC test cases
--In this test case we are checking if a year is a bc year it should throw an error for BC years.
SELECT EOMONTH('4713-11-24 BC')
GO

--In this test case we are checking if it’s the last date of BC it should throw a BC error. After this date the date change to AD.
SELECT EOMONTH('0001-12-31 BC')
GO

--In this test case we are checking if it’s the last date of BC. If we add an offset 1 it will give the value as its not a BC year anymore
SELECT EOMONTH('0001-12-31 BC',1)
GO

--In this test case we are checking if it’s the last value of AD and if we add an offset of -1 it 
--should return an error “Adding a value to a 'date' column caused an overflow.“ because the given input year was not in BC it was AD.
SELECT EOMONTH('0001-01-01',-1)
GO

--In this test case we are checking if the year is within T-SQL range and offset is 1 it
--should return an error “Adding a value to a 'date' column caused an overflow.“ because it was within T-SQL range after adding offset it crosses T-SQL range.
SELECT EOMONTH ('9999-12-31',1)
GO

--In this test case we are checking if the year is outside T-SQL range, it should return T-SQL compatibility error.
SELECT EOMONTH ('10000-01-01')
GO

--In this test case we are checking if the year is outside T-SQL range and offset is -1, so after adding offest its within the T-SQL range and it should return the value. 
SELECT EOMONTH ('10000-01-01',-1)
GO


--Checking the last date for every month
--Checking if it returns 31 as the last day for January.
SELECT EOMONTH('1996-01-01')
GO

--Checking if it returns 29 as the last day for February for leap year. 
SELECT EOMONTH('1996-02-20')
GO

--Checking if it returns 28 as the last date for February for non-leap year. 
SELECT EOMONTH('1997-02-20')
GO

--Checking if it returns 31 as the last day for March.
SELECT EOMONTH ('1996-03-20')
GO

--Checking if it returns 30 as the last day for April.
SELECT EOMONTH('1996-04-01')
GO

--Checking if it returns 31 as the last day for May.
SELECT EOMONTH ('1996-05-20')
GO

--Checking if it returns 30 as the last day for June.
SELECT EOMONTH ('1996-06-20')
GO

--Checking if it returns 31 as the last day for July.
SELECT EOMONTH ('1996-07-20')
GO

--Checking if it returns 31 as the last day for August.
SELECT EOMONTH ('1996-08-20')
GO

--Checking if it returns 30 as the last day for September.
SELECT EOMONTH ('1996-09-20')
GO

--Checking if it returns 31 as the last day for October.
SELECT EOMONTH ('1996-10-20')
GO

--Checking if it returns 30 as the last day for November.
SELECT EOMONTH ('1996-11-20')
GO

--Checking if it returns 31 as the last day for December.
SELECT EOMONTH ('1996-12-20')
GO


--If the given offest is 12 and the month is 1, it should increase the year by 1 and month should be January.
SELECT EOMONTH ('1996-01-01',12)
GO

--If the given offest is -12 and the month is 1, it should decrease the year by 1 and month should be January.
SELECT EOMONTH ('1996-01-01',-12)
GO

--If the given offest is 0, it should just return that month last date.
SELECT EOMONTH ('1996-01-01',0)
GO

--If the given is 11 and the month is 1, it should return last day of December.
SELECT EOMONTH ('1996-01-01',11)
GO

--If the given offest is -1 and the month is 1, it should decrease the year by 1 and month should be December. 
SELECT EOMONTH ('1996-01-01',-1)
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
