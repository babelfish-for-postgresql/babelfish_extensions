-- Drop Views
DROP VIEW IF EXISTS dbo.RoundMultipleTypesView;
GO
DROP VIEW IF EXISTS dbo.TestRoundView;
GO
DROP VIEW IF EXISTS dbo.RoundDemoView;
GO

-- Drop Functions
DROP FUNCTION IF EXISTS dbo.RoundMultipleTypes;
GO
DROP FUNCTION IF EXISTS dbo.RoundFloat;
GO
DROP FUNCTION IF EXISTS dbo.RoundDecimal;
GO

-- Drop Tables
DROP TABLE IF EXISTS TestRound;
GO

-- Drop any remaining test tables that might have been created during testing
DROP TABLE IF EXISTS RoundTestTable;
GO
