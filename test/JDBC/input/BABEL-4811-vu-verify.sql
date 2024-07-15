-- test SPACE function
select SPACE(NULL);
GO

select SPACE(2);
GO

select LEN(SPACE(5));
GO

select DATALENGTH(SPACE(5));
GO

select SPACE(-10);
GO

select SPACE(0);
GO

select LEN(SPACE(-10));
GO

select DATALENGTH(SPACE(-10));
GO

select LEN(SPACE(0));
GO

select DATALENGTH(SPACE(0));
GO

select * from babel_4811_vu_prepare_f1(5);
GO

select * from babel_4811_vu_prepare_f1(-10);
GO

select * from babel_4811_vu_prepare_f1(0);
GO

EXEC babel_4811_vu_prepare_p1 @number = 5;
GO

EXEC babel_4811_vu_prepare_p1 @number = -10;
GO

EXEC babel_4811_vu_prepare_p1 @number = 0;
GO

select * from babel_4811_vu_prepare_v1;
GO

select * from babel_4811_vu_prepare_v2;
GO

select * from babel_4811_vu_prepare_v3;
GO
