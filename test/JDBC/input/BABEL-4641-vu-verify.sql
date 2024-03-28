-- CHAR
-- customer case
SELECT convert(char(6),CAST('2023-02-03 19:08:35.527' as sys.DATETIME),12) as FDate
GO

SELECT * FROM babel_4461_char_vu_prepare_view1
GO

SELECT * FROM babel_4461_char_vu_prepare_view11
GO

SELECT * FROM babel_4461_char_vu_prepare_view2
GO

SELECT * FROM babel_4461_char_vu_prepare_view22
GO

EXEC babel_4461_char_vu_prepare_proc1
GO

EXEC babel_4461_char_vu_prepare_proc11
GO

EXEC babel_4461_char_vu_prepare_proc2
GO

EXEC babel_4461_char_vu_prepare_proc22
GO

-- error should not have been thrown, should be fixed under BABEL-4561
SELECT * FROM babel_4461_char_vu_prepare_func1()
GO

-- error should not have been thrown, should be fixed under BABEL-4561
SELECT * FROM babel_4461_char_vu_prepare_func11()
GO

-- error should not have been thrown, should be fixed under BABEL-4561
SELECT * FROM babel_4461_char_vu_prepare_func2()
GO

-- error should not have been thrown, should be fixed under BABEL-4561
SELECT * FROM babel_4461_char_vu_prepare_func22()
GO

SELECT * FROM babel_4461_char_vu_prepare_view3
GO

SELECT * FROM babel_4461_char_vu_prepare_view4
GO

SELECT * FROM babel_4461_char_vu_prepare_view5
GO

SELECT * FROM babel_4461_char_vu_prepare_view6
GO

SELECT * FROM babel_4461_char_vu_prepare_view7
GO

-- NCHAR
-- customer case
SELECT convert(nchar(6),CAST('2023-02-03 19:08:35.527' as sys.DATETIME),12) as FDate
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view1
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view11
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view2
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view22
GO

EXEC babel_4461_nchar_vu_prepare_proc1
GO

EXEC babel_4461_nchar_vu_prepare_proc11
GO

EXEC babel_4461_nchar_vu_prepare_proc2
GO

EXEC babel_4461_nchar_vu_prepare_proc22
GO

-- error should not have been thrown, should be fixed under BABEL-4561
SELECT * FROM babel_4461_nchar_vu_prepare_func1()
GO

-- error should not have been thrown, should be fixed under BABEL-4561
SELECT * FROM babel_4461_nchar_vu_prepare_func11()
GO

-- error should not have been thrown, should be fixed under BABEL-4561
SELECT * FROM babel_4461_nchar_vu_prepare_func2()
GO

-- error should not have been thrown, should be fixed under BABEL-4561
SELECT * FROM babel_4461_nchar_vu_prepare_func22()
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view3
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view4
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view5
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view6
GO

SELECT * FROM babel_4461_nchar_vu_prepare_view7
GO
