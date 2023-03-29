SELECT pg_get_functiondef(cast('babel_2877_vu_prepare_func1' as regproc));
GO

SELECT pg_get_functiondef(cast('babel_2877_vu_prepare_func2' as regproc));
GO

SELECT pg_get_functiondef(cast('babel_2877_vu_prepare_func3' as regproc));
GO

SELECT pg_get_functiondef(cast('babel_2877_vu_prepare_proc1' as regproc));
GO

SELECT pg_get_functiondef(cast('babel_2877_vu_prepare_proc2' as regproc));
GO

SELECT pg_get_functiondef(cast('babel_2877_vu_prepare_proc3' as regproc));
GO

SELECT * FROM babel_2877_vu_prepare_func1(10); -- should fail, required argument @c not supplied
GO

SELECT * FROM babel_2877_vu_prepare_func1(10, 'abc', $5);
GO

SELECT * FROM babel_2877_vu_prepare_func2();
GO

SELECT * FROM babel_2877_vu_prepare_func3(); -- should fail, all parameters are required
GO

SELECT * FROM babel_2877_vu_prepare_func3(10, 'abc', $5, 1.2);
GO

SELECT * FROM babel_2877_vu_prepare_view1;
GO

SELECT * FROM babel_2877_vu_prepare_view2;
GO

SELECT * FROM babel_2877_vu_prepare_view3;
GO

EXEC babel_2877_vu_prepare_proc1; -- should fail, required arguments @a and @d not supplied
GO

EXEC babel_2877_vu_prepare_proc1 10; -- should fail, required argument @d not supplied
GO

EXEC babel_2877_vu_prepare_proc1 @d=40; -- should fail, required argument @a not supplied
GO

EXEC babel_2877_vu_prepare_proc1 @a = 10, @d = 1.8;
GO

EXEC babel_2877_vu_prepare_proc1 @a = 10, @b = 20, @c = 30, @d = 40;
GO

EXEC babel_2877_vu_prepare_proc2;
GO

EXEC babel_2877_vu_prepare_proc2 @d = 1.5;
GO

EXEC babel_2877_vu_prepare_proc3; -- should fail, all parameters are required
GO

EXEC babel_2877_vu_prepare_proc3 10, 'def', $10, 1.8; -- should fail, all parameters are required
GO

-- babelfish_function_ext table should have entry for all the above functions and procedures
SELECT nspname,
		funcname,
		funcsignature,
		default_positions
FROM sys.babelfish_function_ext
	WHERE funcname LIKE 'babel_2877_vu_prepare%'
	AND funcname NOT LIKE '%ansi%' ORDER BY funcname;
GO

SELECT orig_name,
	CASE flag_validity & 1
		WHEN 0
			THEN NULL
		ELSE
			CASE flag_values & 1
				WHEN 0
					THEN 0
				ELSE 1
			END
	END AS ansi_null,
	CASE flag_validity & 2
		WHEN 0
			THEN NULL
		ELSE
			CASE flag_values & 2
				WHEN 0
					THEN 0
				ELSE 1
			END
	END AS quoted_identifier
FROM sys.babelfish_function_ext WHERE funcname LIKE 'babel-2877-vu-prepare%' ORDER BY funcname;
GO
