-- Show all BABELFISH Gucs
EXEC sp_babelfish_configure '%'
GO

-- Default value is on
SELECT CURRENT_SETTING('babelfishpg_tsql.explain_costs')
GO

-- Explain Gucs can set to on or off
EXEC sp_babelfish_configure 'babelfishpg_tsql.explain_costs','off'
GO

-- Should set to off
SELECT CURRENT_SETTING('babelfishpg_tsql.explain_costs')
GO

-- Should set all Gucs to default value
EXEC sp_babelfish_configure '%','default'
GO

-- Default value is on
SELECT CURRENT_SETTING('babelfishpg_tsql.explain_costs')
GO

-- Should throw error when trying to set to arbirary value
EXEC sp_babelfish_configure 'babelfishpg_tsql.explain_costs','eee'
GO

-- Set all escape hatch to strict
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_%', 'strict';
GO

-- All escape hatch set to strict
SELECT name,setting FROM pg_catalog.pg_settings WHERE name collate "C" like 'babelfishpg_tsql.escape_%'
GO

-- Set all escape hatch to ignore 
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_%', 'ignore';
GO

-- All escape hatch set to ignore
SELECT name,setting FROM pg_catalog.pg_settings WHERE name collate "C" like 'babelfishpg_tsql.escape_%'
GO

-- Set all escape hatch to strict
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_%', 'strict'
GO

-- Set all Gucs that vartype is enum and enumvals has ignore option to 'ignore'
EXEC sp_babelfish_configure '%','ignore'
GO

-- All Gucs that vartype is enum and enumvals has ignore option is 'ignore'
SELECT name, setting  FROM pg_catalog.pg_settings WHERE name collate "C" like 'babelfishpg_tsql.%' AND vartype = 'enum'
GO

-- Set all Gucs back to default value
EXEC sp_babelfish_configure '%','ignore'
GO
