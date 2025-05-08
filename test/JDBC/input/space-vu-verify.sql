-- test SPACE function
SELECT SPACE(NULL);
GO

SELECT SPACE(2);
GO

SELECT LEN(SPACE(5));
GO

SELECT DATALENGTH(SPACE(5));
GO

SELECT SPACE(-10);
GO

SELECT SPACE(0);
GO

SELECT LEN(SPACE(-10));
GO

SELECT DATALENGTH(SPACE(-10));
GO

SELECT LEN(SPACE(0));
GO

SELECT DATALENGTH(SPACE(0));
GO

-- INT_MAX
SELECT datalength(SPACE(2147483647))
GO

-- INT_MAX/2
SELECT datalength(SPACE(1073741823))
GO

-- INT_MIN
SELECT datalength(SPACE(-2147483648))
GO

SELECT dbo.babel_4811_vu_prepare_f1(5);
GO

SELECT dbo.babel_4811_vu_prepare_f1(-10);
GO

SELECT dbo.babel_4811_vu_prepare_f1(0);
GO

SELECT dbo.babel_4811_vu_prepare_f2(5);
GO

SELECT dbo.babel_4811_vu_prepare_f2(-10);
GO

SELECT dbo.babel_4811_vu_prepare_f2(0);
GO

SELECT * from babel_4811_vu_prepare_f3();
GO

EXEC babel_4811_vu_prepare_p1 @number = 5;
GO

EXEC babel_4811_vu_prepare_p1 @number = -10;
GO

EXEC babel_4811_vu_prepare_p1 @number = 0;
GO

EXEC babel_4811_vu_prepare_p2 @number = 5;
GO

EXEC babel_4811_vu_prepare_p2 @number = -10;
GO

EXEC babel_4811_vu_prepare_p2 @number = 0;
GO

SELECT * from babel_4811_vu_prepare_v1;
GO

SELECT * from babel_4811_vu_prepare_v2;
GO

SELECT * from babel_4811_vu_prepare_v3;
GO

SELECT * from babel_4811_vu_prepare_v4;
GO

SELECT * from babel_4811_vu_prepare_v5;
GO

SELECT * from babel_4811_vu_prepare_v6;
GO

SELECT * from babel_4811_vu_prepare_v7;
GO

SELECT * from babel_4811_vu_prepare_v8;
GO

SELECT * from babel_4811_vu_prepare_v9;
GO
