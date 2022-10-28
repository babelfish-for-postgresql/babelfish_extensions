DROP VIEW babel_2877_vu_prepare_view1;
GO

DROP VIEW babel_2877_vu_prepare_view2;
GO

DROP VIEW babel_2877_vu_prepare_view3;
GO

DROP FUNCTION IF EXISTS babel_2877_vu_prepare_func1;
GO

DROP FUNCTION IF EXISTS babel_2877_vu_prepare_func2;
GO

DROP FUNCTION IF EXISTS babel_2877_vu_prepare_func3;
GO

DROP PROCEDURE IF EXISTS babel_2877_vu_prepare_proc1;
GO

DROP PROCEDURE IF EXISTS babel_2877_vu_prepare_proc2;
GO

DROP PROCEDURE IF EXISTS babel_2877_vu_prepare_proc3;
GO

DROP FUNCTION IF EXISTS babel_2877_vu_prepare_func_ansinullon_qidon;
GO

DROP FUNCTION IF EXISTS babel_2877_vu_prepare_func_ansinulloff_qidon;
GO

DROP FUNCTION IF EXISTS babel_2877_vu_prepare_func_ansinulloff_qidoff;
GO

DROP FUNCTION IF EXISTS babel_2877_vu_prepare_func_ansinullon_qidoff;
GO

-- babelfish_function_ext entry should have been removed after dropping all these functions/procedure
SELECT * FROM sys.babelfish_function_ext WHERE funcname LIKE 'babel_2877_vu_prepare%';
GO