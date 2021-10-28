SET QUOTED_IDENTIFIER OFF
GO

--  should return literal
SELECT 'literal'
GO

-- should report that column "ident" does not exist
SELECT [ident]
GO

-- should return string
SELECT "string"
GO

-- should report error (double-quoted string literals cannot contain single-quotes while QUOTED_IDENTIFIER=OFF)
SELECT "f'oo"
GO

--------------------------------------------------------------------------------

SET QUOTED_IDENTIFIER ON
GO

--  should return literal
SELECT 'literal'
GO

-- should report that column "ident" does not exist
SELECT [ident]
GO

-- should report that column "ident" does not exist
SELECT "ident"
GO

-- should report that column "f'oo" does not exist
SELECT "f'oo"
GO
