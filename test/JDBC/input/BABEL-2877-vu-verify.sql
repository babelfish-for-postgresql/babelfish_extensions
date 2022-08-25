SELECT pg_get_functiondef(cast('babel_2877_vu_prepare_func1' as regproc));
GO

SELECT pg_get_functiondef(cast('babel_2877_vu_prepare_proc1' as regproc));
GO

SELECT * FROM babel_2877_vu_prepare_func1(10); -- should fail, required argument @c not supplied
GO

SELECT * FROM babel_2877_vu_prepare_func1(10, 20, 30, 40);
GO

SELECT * FROM babel_2877_vu_prepare_view1;
GO

EXEC babel_2877_vu_prepare_proc1; -- should fail, required arguments @a and @d not supplied
GO

EXEC babel_2877_vu_prepare_proc1 10; -- should fail, required argument @d not supplied
GO

EXEC babel_2877_vu_prepare_proc1 @d=40; -- should fail, required argument @a not supplied
GO

EXEC babel_2877_vu_prepare_proc1 @a = 10, @d = 40;
GO

EXEC babel_2877_vu_prepare_proc1 @a = 10, @b = 20, @c = 30, @d = 40;
GO