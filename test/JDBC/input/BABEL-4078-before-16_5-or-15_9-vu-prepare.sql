-- default style
CREATE VIEW babel_4078_vu_prepare_view1 AS
SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE)) result
GO

-- different style
CREATE VIEW babel_4078_vu_prepare_view11 AS
SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105) result
GO

-- default style
CREATE VIEW babel_4078_vu_prepare_view2 AS
SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result
GO

-- different style
CREATE VIEW babel_4078_vu_prepare_view22 AS
SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20) result
GO

-- default style
CREATE PROCEDURE babel_4078_vu_prepare_proc1 AS
SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE))  result
GO

-- different style
CREATE PROCEDURE babel_4078_vu_prepare_proc11 AS
SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105)  result
GO

-- default style
CREATE PROCEDURE babel_4078_vu_prepare_proc2 AS
SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result
GO

-- different style
CREATE PROCEDURE babel_4078_vu_prepare_proc22 AS
SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20)  result
GO

-- default style
CREATE FUNCTION babel_4078_vu_prepare_func1()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE))  result)
GO

-- different style
CREATE FUNCTION babel_4078_vu_prepare_func11()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105)  result)
GO

-- different style
CREATE FUNCTION babel_4078_vu_prepare_func2()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result)
GO

-- different style
CREATE FUNCTION babel_4078_vu_prepare_func22()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20)  result)
GO

-- to verify that is returning expected the default style
CREATE VIEW babel_4078_vu_prepare_view3 AS
SELECT CASE 
       WHEN CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE)) =  CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 20)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4078_vu_prepare_view4 AS
SELECT CASE 
       WHEN CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME)) =  CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 25)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4078_vu_prepare_view5 AS
SELECT CASE 
       WHEN CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME)) =  CONVERT(NVARCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 0)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4078_vu_prepare_view6 AS
SELECT CASE 
       WHEN CONVERT(NVARCHAR(10), CAST('1.0001' as float)) =  CONVERT(NVARCHAR(10), CAST('1.0001' as float), 0)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4078_vu_prepare_view7 AS
SELECT CASE 
       WHEN CONVERT(NVARCHAR(10), CAST('1.0001' as sys.money)) =  CONVERT(NVARCHAR(10), CAST('1.0001' as sys.money), 0)
       THEN 'true'
       else 'false'
       END  result
GO

