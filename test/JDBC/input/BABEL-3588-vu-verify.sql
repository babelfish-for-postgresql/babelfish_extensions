-- Default value is on
SELECT CURRENT_SETTING('babelfishpg_tsql.explain_costs')
GO

-- Explain Gucs can set to on or off
EXEC sp_babelfish_configure 'babelfishpg_tsql.explain_costs','off','server'
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

-- Should throw an error
EXEC sp_babelfish_configure '%', 'on'
GO

-- Set all escape hatch to strict
EXEC sp_babelfish_configure '%', 'strict', 'server';
GO
select count(*) FROM pg_catalog.pg_settings WHERE name collate "C" like 'babelfishpg_tsql.escape_%' and setting collate "C" != 'strict';
GO

-- Set all escape hatch to ignore
EXEC sp_babelfish_configure '%', 'ignore', 'server';
GO
select count(*) FROM pg_catalog.pg_settings WHERE name collate "C" like 'babelfishpg_tsql.escape_%' and setting collate "C" != 'ignore';
GO

-- Set all GUCs back to default values
EXEC sp_babelfish_configure '%', 'default', 'server'
GO
