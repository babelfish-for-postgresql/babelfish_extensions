CREATE VIEW babel_3938_vu_prepare_view1 AS
SELECT CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE))
GO

CREATE VIEW babel_3938_vu_prepare_view2 AS
SELECT CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))
GO

CREATE PROCEDURE babel_3938_vu_prepare_proc1 AS
SELECT CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE))
GO

CREATE PROCEDURE babel_3938_vu_prepare_proc2 AS
SELECT CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME))
GO

CREATE FUNCTION babel_3938_vu_prepare_func1()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE)))
GO

CREATE FUNCTION babel_3938_vu_prepare_func2()
RETURNS TABLE
AS
RETURN (SELECT CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME)))
GO

-- to verify that is returning expected the default style
CREATE VIEW babel_3938_vu_prepare_view3 AS
SELECT CASE 
       WHEN CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE)) =  CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as DATE), 20)
       THEN 'true'
       else 'false'
       END
GO

CREATE VIEW babel_3938_vu_prepare_view4 AS
SELECT CASE 
       WHEN CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME)) =  CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as TIME), 25)
       THEN 'true'
       else 'false'
       END
GO

CREATE VIEW babel_3938_vu_prepare_view5 AS
SELECT CASE 
       WHEN CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME)) =  CONVERT(VARCHAR(10), CAST('2023-02-03 19:08:35.527' as sys.DATETIME), 0)
       THEN 'true'
       else 'false'
       END
GO

CREATE VIEW babel_3938_vu_prepare_view6 AS
SELECT CASE 
       WHEN CONVERT(VARCHAR(10), CAST('1.0001' as float)) =  CONVERT(VARCHAR(10), CAST('1.0001' as float), 0)
       THEN 'true'
       else 'false'
       END
GO

CREATE VIEW babel_3938_vu_prepare_view7 AS
SELECT CASE 
       WHEN CONVERT(VARCHAR(10), CAST('1.0001' as sys.money)) =  CONVERT(VARCHAR(10), CAST('1.0001' as sys.money), 0)
       THEN 'true'
       else 'false'
       END
GO

