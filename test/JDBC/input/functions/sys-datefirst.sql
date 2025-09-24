-- Default value
SELECT @@DATEFIRST
GO

SELECT * FROM sys.datefirst()
GO

SET datefirst 3
GO

SELECT @@datefirst
GO

SELECT sys.datefirst()
GO


-- Integral Value
-- inbound value (1-7)
SET datefirst 2
GO
SELECT @@datefirst
GO

SET DATEFIRST 3
GO
SELECT @@DATEFIRST
GO

SET DATEFIRST 4
GO
SELECT @@datefirst
GO

DECLARE @i INT = 5
SET DATEFIRST @i
GO
SELECT @@DATEFIRST
GO

SET DATEFIRST 6
GO
SELECT @@DATEFIRST
GO

-- edge point values 
declare @i int = 1
SET datefirst @i
GO
SELECT @@datefirst
GO

SET datefirst 7
GO
SELECT @@DATEFIRST
GO

-- out of bound values
SET DATEFIRST 8
GO
-- Invalid value not updated
SELECT @@DATEFIRST
GO

SET DATEFIRST 23
GO
-- Invalid value not updated
SELECT @@DATEFIRST
GO

SET DATEFIRST 0
GO
-- Invalid value not updated
SELECT @@DATEFIRST
GO

DECLARE @i INT = -4
SET DATEFIRST @i
GO
-- Invalid value not updated
SELECT @@DATEFIRST
GO

SET DATEFIRST -55
GO
-- Invalid value not updated
SELECT @@DATEFIRST
GO



-- Non Integral Value
-- inbound values
SET DATEFIRST 3.5
GO

SET datefirst 5.68
GO

SET DATEFIRST 1.23
GO

SET DATEFIRST 6.999
GO

-- edge point values
SET DATEFIRST 1.00
GO
SELECT @@DATEFIRST
GO

SET DATEFIRST 7.00
GO
SELECT @@DATEFIRST
GO

-- out of bound values
SET DATEFIRST 7.01
GO

SET DATEFIRST 59.0974
GO

SET DATEFIRST 0.99
GO

SET DATEFIRST -2.34
GO

SET DATEFIRST -65.045
GO

-- arbitrary values
SET DATEFIRST 'one'
GO

SET DATEFIRST '4'
GO

SET DATEFIRST "three"
GO

SET DATEFIRST "2"
GO

SET DATEFIRST NULL
GO

-- should throw integer parameter required error
DECLARE @i decimal(10,2) = 2.35
SET DATEFIRST @i
GO

SELECT @@DATEFIRST
GO

DECLARE @i varchar = '4'
SET DATEFIRST @i
GO

SELECT @@DATEFIRST
GO
