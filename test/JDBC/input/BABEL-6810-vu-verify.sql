-- EXEC a table-valued function with a named argument, via a procedure and
-- directly at batch level
EXEC babel_6810_vu_prepare_call_variant 'test'
GO

EXEC babel_6810_vu_prepare_call_nvarchar 'test'
GO

EXEC babel_6810_vu_prepare_tvf_nvarchar @customerRef = 'batch_level'
GO

-- EXEC a table-valued function with a positional argument
EXEC babel_6810_vu_prepare_call_positional 'test'
GO

-- Invoke the table-valued function the supported way, via SELECT
SELECT CAST(Address AS NVARCHAR(50)) AS addr FROM babel_6810_vu_prepare_tvf_nvarchar('direct_ok')
GO

-- Named-argument procedure call
EXEC babel_6810_vu_prepare_add @a = 3, @b = 4
GO

-- Named-argument procedure call with an OUTPUT parameter
DECLARE @res INT
EXEC babel_6810_vu_prepare_out @x = 5, @y = @res OUTPUT
SELECT @res AS out_value
GO

-- Named-argument procedure call relying on a default, and supplying all args
EXEC babel_6810_vu_prepare_def @a = 1
GO

EXEC babel_6810_vu_prepare_def @a = 1, @b = 2
GO
