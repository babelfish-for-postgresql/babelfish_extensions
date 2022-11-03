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

DROP FUNCTION IF EXISTS [BABEL-2877-vu-prepare_FUNC_ANSI_NULLON_QIDON];
GO

DROP FUNCTION IF EXISTS [BABEL-2877-vu-prepare_FUNC_ANSI_NULLOFF_QIDON];
GO

DROP FUNCTION IF EXISTS [BABEL-2877-vu-prepare_FUNC_ANSI_NULLOFF_QIDOFF];
GO

DROP FUNCTION IF EXISTS [BABEL-2877-vu-prepare_FUNC_ANSI_NULLON_QIDOFF];
GO

-- babelfish_function_ext entry should have been removed after dropping all these functions/procedure
SELECT * FROM sys.babelfish_function_ext WHERE funcname LIKE 'babel_2877_vu_prepare%';
GO