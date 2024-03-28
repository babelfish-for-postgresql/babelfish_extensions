-- CHAR
-- default style
CREATE VIEW babel_4461_char_vu_prepare_view1 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE)) result
GO

-- different style
CREATE VIEW babel_4461_char_vu_prepare_view11 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105) result
GO

CREATE VIEW babel_4461_char_vu_prepare_view12 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 12) result
GO

-- default style
CREATE VIEW babel_4461_char_vu_prepare_view2 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result
GO

-- different style
CREATE VIEW babel_4461_char_vu_prepare_view22 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20) result
GO

-- default style
CREATE VIEW babel_4461_char_vu_prepare_view3 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME)) result
GO

-- different style
CREATE VIEW babel_4461_char_vu_prepare_view31 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 105) result
GO

CREATE VIEW babel_4461_char_vu_prepare_view32 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 12) result
GO

-- default style
CREATE PROCEDURE babel_4461_char_vu_prepare_proc1 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE))  result
GO

-- different style
CREATE PROCEDURE babel_4461_char_vu_prepare_proc11 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105)  result
GO

-- different style
CREATE PROCEDURE babel_4461_char_vu_prepare_proc12 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 12)  result
GO

-- default style
CREATE PROCEDURE babel_4461_char_vu_prepare_proc2 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result
GO

-- different style
CREATE PROCEDURE babel_4461_char_vu_prepare_proc22 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20)  result
GO

-- default style
CREATE PROCEDURE babel_4461_char_vu_prepare_proc3 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME))  result
GO

-- different style
CREATE PROCEDURE babel_4461_char_vu_prepare_proc31 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 105)  result
GO

-- different style
CREATE PROCEDURE babel_4461_char_vu_prepare_proc32 AS
SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 12)  result
GO

-- default style
CREATE FUNCTION babel_4461_char_vu_prepare_func1()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE))  result)
GO

-- different style
CREATE FUNCTION babel_4461_char_vu_prepare_func11()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105)  result)
GO

-- different style
CREATE FUNCTION babel_4461_char_vu_prepare_func12()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 12)  result)
GO

-- different style
CREATE FUNCTION babel_4461_char_vu_prepare_func2()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result)
GO

-- different style
CREATE FUNCTION babel_4461_char_vu_prepare_func22()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20)  result)
GO

-- default style
CREATE FUNCTION babel_4461_char_vu_prepare_func3()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME))  result)
GO

-- different style
CREATE FUNCTION babel_4461_char_vu_prepare_func31()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 105)  result)
GO

-- different style
CREATE FUNCTION babel_4461_char_vu_prepare_func32()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 12)  result)
GO

-- to verify that is returning expected the default style
CREATE VIEW babel_4461_char_vu_prepare_view4 AS
SELECT CASE 
       WHEN CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE)) =  CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 20)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4461_char_vu_prepare_view5 AS
SELECT CASE 
       WHEN CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as TIME)) =  CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 25)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4461_char_vu_prepare_view6 AS
SELECT CASE 
       WHEN CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME)) =  CONVERT(CHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 0)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4461_char_vu_prepare_view7 AS
SELECT CASE 
       WHEN CONVERT(CHAR(10), CAST('1.0001' as float)) =  CONVERT(CHAR(10), CAST('1.0001' as float), 0)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4461_char_vu_prepare_view8 AS
SELECT CASE 
       WHEN CONVERT(CHAR(10), CAST('1.0001' as sys.money)) =  CONVERT(CHAR(10), CAST('1.0001' as sys.money), 0)
       THEN 'true'
       else 'false'
       END  result
GO

-- NCHAR
-- default style
CREATE VIEW babel_4461_nchar_vu_prepare_view1 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE)) result
GO

-- different style
CREATE VIEW babel_4461_nchar_vu_prepare_view11 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105) result
GO

CREATE VIEW babel_4461_nchar_vu_prepare_view12 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 12) result
GO

-- default style
CREATE VIEW babel_4461_nchar_vu_prepare_view2 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result
GO

-- different style
CREATE VIEW babel_4461_nchar_vu_prepare_view22 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20) result
GO

-- default style
CREATE VIEW babel_4461_nchar_vu_prepare_view3 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME)) result
GO

-- different style
CREATE VIEW babel_4461_nchar_vu_prepare_view31 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 105) result
GO

CREATE VIEW babel_4461_nchar_vu_prepare_view32 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 12) result
GO

-- default style
CREATE PROCEDURE babel_4461_nchar_vu_prepare_proc1 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE))  result
GO

-- different style
CREATE PROCEDURE babel_4461_nchar_vu_prepare_proc11 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105)  result
GO

-- different style
CREATE PROCEDURE babel_4461_nchar_vu_prepare_proc12 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 12)  result
GO

-- default style
CREATE PROCEDURE babel_4461_nchar_vu_prepare_proc2 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result
GO

-- different style
CREATE PROCEDURE babel_4461_nchar_vu_prepare_proc22 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20)  result
GO

-- default style
CREATE PROCEDURE babel_4461_nchar_vu_prepare_proc3 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME))  result
GO

-- different style
CREATE PROCEDURE babel_4461_nchar_vu_prepare_proc31 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 105)  result
GO

-- different style
CREATE PROCEDURE babel_4461_nchar_vu_prepare_proc32 AS
SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 12)  result
GO

-- default style
CREATE FUNCTION babel_4461_nchar_vu_prepare_func1()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE))  result)
GO

-- different style
CREATE FUNCTION babel_4461_nchar_vu_prepare_func11()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 105)  result)
GO

-- different style
CREATE FUNCTION babel_4461_nchar_vu_prepare_func12()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 12)  result)
GO

-- different style
CREATE FUNCTION babel_4461_nchar_vu_prepare_func2()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))  result)
GO

-- different style
CREATE FUNCTION babel_4461_nchar_vu_prepare_func22()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 20)  result)
GO

-- default style
CREATE FUNCTION babel_4461_nchar_vu_prepare_func3()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME))  result)
GO

-- different style
CREATE FUNCTION babel_4461_nchar_vu_prepare_func31()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 105)  result)
GO

-- different style
CREATE FUNCTION babel_4461_nchar_vu_prepare_func32()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 12)  result)
GO

-- to verify that is returning expected the default style
CREATE VIEW babel_4461_nchar_vu_prepare_view4 AS
SELECT CASE 
       WHEN CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE)) =  CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 20)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4461_nchar_vu_prepare_view5 AS
SELECT CASE 
       WHEN CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME)) =  CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 25)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4461_nchar_vu_prepare_view6 AS
SELECT CASE 
       WHEN CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME)) =  CONVERT(NCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 0)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4461_nchar_vu_prepare_view7 AS
SELECT CASE 
       WHEN CONVERT(NCHAR(10), CAST('1.0001' as float)) =  CONVERT(NCHAR(10), CAST('1.0001' as float), 0)
       THEN 'true'
       else 'false'
       END  result
GO

CREATE VIEW babel_4461_nchar_vu_prepare_view8 AS
SELECT CASE 
       WHEN CONVERT(NCHAR(10), CAST('1.0001' as sys.money)) =  CONVERT(NCHAR(10), CAST('1.0001' as sys.money), 0)
       THEN 'true'
       else 'false'
       END  result
GO