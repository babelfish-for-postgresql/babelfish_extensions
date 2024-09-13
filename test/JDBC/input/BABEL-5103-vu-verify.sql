SELECT CASE 1
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 2
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 3
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 4
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 5
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 6
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 1
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 2
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 3
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 4
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 5
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 6
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
   WHEN 5 THEN COL5
   WHEN 6 THEN COL6
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 1
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 2
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 3
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 4
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 1
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 2
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 3
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 4
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
   WHEN 3 THEN COL3
   WHEN 4 THEN COL4
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 2
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
END AS RESULT FROM BABEL_5103_T1
GO

SELECT CASE 2
   WHEN 1 THEN COL1 
   WHEN 2 THEN COL2
END AS RESULT FROM BABEL_5103_V1
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char' AS NVARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST('char1' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST('char1' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST('char1' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST('char1' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS Char(100))
   WHEN 2 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS CHAR(100))
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NCHAR(100))
   WHEN 2 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NCHAR(100))
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS TEXT)
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char' AS NVARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST('char1' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST('char1' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST('char1' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST('char1' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS Char(100))
   WHEN 3 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS CHAR(100))
   WHEN 3 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS TEXT)
   WHEN 3 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
END AS RESULT
GO


SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS Char(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
   WHEN 3 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

-- Combination of two with null
SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS Char(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS Char(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS CHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

-- Combination of two with null
SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS Char(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS CHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST(N'登録カード–標準' AS NCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST('char1' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST('char1' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS CHAR(100))
   WHEN 2 THEN CAST('char1' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS Char(100))
   WHEN 2 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS CHAR(100))
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS NCHAR(100))
   WHEN 2 THEN CAST('char1' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS NCHAR(100))
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST('char0' AS TEXT)
   WHEN 2 THEN CAST('char1' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS Char(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS CHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS NCHAR(100))
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'بطاقة التسجيل - قياسية' AS TEXT)
   WHEN 2 THEN CAST(N'بطاقة التسجيل - قياسية' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS CHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS Char(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS CHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS NCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS NCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 2
   WHEN 1 THEN CAST(N'登録カード–標準' AS TEXT)
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS VARCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS Char(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS CHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS NCHAR(100))
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN CAST('char0' AS TEXT)
   WHEN 2 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS Char(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS CHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS TEXT)
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS CHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS Char(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS CHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN 'abc'
   WHEN 2 THEN CAST('char0' AS TEXT)
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS VARCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS CHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NCHAR(100))
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS Char(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS CHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 1
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS TEXT)
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NVARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS CHAR(100))
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS VARCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS Char(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS CHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS TEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS NCHAR(100))
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO

SELECT CASE 3
   WHEN 1 THEN N'登録カード–標準'
   WHEN 2 THEN CAST('char0' AS TEXT)
   WHEN 3 THEN CAST(N'登録カード–標準' AS NTEXT)
END AS RESULT
GO