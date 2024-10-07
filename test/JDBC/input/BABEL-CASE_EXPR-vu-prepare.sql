CREATE TABLE BABEL_5103_T1(
    COL1 VARCHAR(2000) NOT NULL,
    COL2 AS CAST(COL1 AS NCHAR(2001)),
    COL3 AS CAST(COL1 AS VARCHAR(MAX)),
    COL4 AS CAST(COL1 AS NVARCHAR(2001)),
    COL5 AS CAST(COL1 AS TEXT),
    COL6 AS CAST(COL1 AS NTEXT)
)
GO

INSERT INTO BABEL_5103_T1 (COL1)
VALUES (N'Registration Card - Standard');
GO

INSERT INTO BABEL_5103_T1 (COL1)
VALUES (N'بطاقة التسجيل - قياسية');
GO

INSERT INTO BABEL_5103_T1 (COL1)
VALUES (N'登録カード–標準');
GO

CREATE VIEW BABEL_5103_V1 AS
SELECT COL1, COL2, COL3, COL4, COL5, COL6
FROM BABEL_5103_T1;
GO

CREATE VIEW  BABEL_5103_V2 AS 
SELECT CASE 3 
        WHEN 1 THEN N'登録カード–標準'
        WHEN 2 THEN CAST('char0' AS NVARCHAR(10))
        WHEN 3 THEN CAST(N'登録カード–標準' AS VARCHAR(10))
END AS RESULT
GO

CREATE FUNCTION BABEL_5103_F1(@ARG NVARCHAR(1001)) 
RETURNS NVARCHAR(1001)
AS
BEGIN 
    RETURN (
        CASE 
         WHEN @ARG = 'REGULAR' THEN 'REGULAR'
         WHEN @ARG = N'登録カード–標準' THEN N'登録カード–標準'
         WHEN @ARG = N'بطاقة التسجيل - قياسية'THEN N'بطاقة التسجيل - قياسية'
        END
    );
END;
GO