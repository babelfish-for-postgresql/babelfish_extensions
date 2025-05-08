-- Function
-- Defaults at different positions
CREATE FUNCTION babel_2877_vu_prepare_func1 (@a int, @b varchar(10) = 'abc', @c money, @d float = 1.2)
RETURNS varchar(100) AS
BEGIN
	RETURN CAST(@a AS varchar(10)) + @b + CAST(@c AS varchar(10)) + CAST(@d AS varchar(10));
END
GO

-- All parameters with defaults
CREATE FUNCTION babel_2877_vu_prepare_func2 (@a int = 10, @b varchar(10) = 'abc', @c money = $5, @d float = 1.2)
RETURNS varchar(100) AS
BEGIN
	RETURN CAST(@a AS varchar(10)) + @b + CAST(@c AS varchar(10)) + CAST(@d AS varchar(10));
END
GO

-- No defaults
CREATE FUNCTION babel_2877_vu_prepare_func3 (@a int, @b varchar(10), @c money, @d float)
RETURNS varchar(100) AS
BEGIN
	RETURN CAST(@a AS varchar(10)) + @b + CAST(@c AS varchar(10)) + CAST(@d AS varchar(10));
END
GO

-- Procedure
-- Defaults at different positions
CREATE PROCEDURE babel_2877_vu_prepare_proc1 (@a int, @b varchar(10) = 'abc', @c money = $5, @d float)
AS
BEGIN
	SELECT @a, @b, @c, @d;
END
GO

-- All parameters with defaults
CREATE PROCEDURE babel_2877_vu_prepare_proc2 (@a int = 10, @b varchar(10) = 'abc', @c money = $5, @d float = 1.2)
AS
BEGIN
	SELECT @a, @b, @c, @d;
END
GO

-- No defaults
CREATE PROCEDURE babel_2877_vu_prepare_proc3 (@a int, @b varchar(10), @c money, @d float)
AS
BEGIN
	SELECT @a, @b, @c, @d;
END
GO

-- Views
CREATE VIEW babel_2877_vu_prepare_view1 AS SELECT babel_2877_vu_prepare_func1(20, 'def', $5);
GO

CREATE VIEW babel_2877_vu_prepare_view2 AS SELECT babel_2877_vu_prepare_func2();
GO

CREATE VIEW babel_2877_vu_prepare_view3 AS SELECT babel_2877_vu_prepare_func1(20, 'def', $10, 1.8);
GO

-- CASE: Check for session properties like ANSI_NULLS and QUOTED_IDENTIFIER
-- ANSI_NULLS - Last bit from left in flag_values
-- QUOTED_IDENTIFIER - Second last bit from left in flag_values
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [BABEL-2877-vu-prepare_FUNC_ANSI_NULLON_QIDON] (@a int)
RETURNS INT AS BEGIN RETURN 1; END;
GO

SET ANSI_NULLS OFF;
GO

CREATE FUNCTION [BABEL-2877-vu-prepare_FUNC_ANSI_NULLOFF_QIDON] (@a int)
RETURNS INT AS BEGIN RETURN 1; END;
GO

SET QUOTED_IDENTIFIER OFF;
GO

CREATE FUNCTION [BABEL-2877-vu-prepare_FUNC_ANSI_NULLOFF_QIDOFF] (@a int)
RETURNS INT AS BEGIN RETURN 1; END;
GO

SET ANSI_NULLS ON;
GO

CREATE FUNCTION [BABEL-2877-vu-prepare_FUNC_ANSI_NULLON_QIDOFF] (@a int)
RETURNS INT AS BEGIN RETURN 1; END;
GO

-- reset session properties
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE SCHEMA [BABEL-2877-vu-prepare_FUNC_Schema]
GO

CREATE SCHEMA [BABEL-2877-vu-prepare Schema . WITH .. DOTS]
GO

-- Function name which is prefix of schema name
CREATE FUNCTION [BABEL-2877-vu-prepare_FUNC_Schema]  .  [BABEL-2877-vu-prepare_FUNC] (@a int)
RETURNS INT AS BEGIN RETURN 1; END;
GO

CREATE FUNCTION [BABEL-2877-vu-prepare Schema . WITH .. DOTS]  .  [BABEL-2877-vu-prepare Function . WITH .. DOTS] (@a int)
RETURNS INT AS BEGIN RETURN 1; END;
GO
