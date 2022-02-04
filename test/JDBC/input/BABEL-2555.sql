-- default is strict
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_unique_constraint', true);
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
GO

SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_unique_constraint', true);
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'default';
GO

-- should be changed to strict
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_unique_constraint', true);
GO

-- default is ignore
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_schemabinding_function', true);
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_function', 'strict';
GO

SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_schemabinding_function', true);
GO

-- default is strict
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_storage_on_partition', true);
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_storage_on_partition', 'ignore';
GO

SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_storage_on_partition', true);
GO

EXEC sp_babelfish_configure '%', 'default';
GO

-- should be changed to ignore
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_schemabinding_function', true);
GO

-- should be changed to strict
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_storage_on_partition', true);
GO

-- default is ignore
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_schemabinding_function', 'strict', 'server';
GO

SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_schemabinding_function', true);
GO

-- default is strict
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_storage_on_partition', 'ignore', 'server';
GO

SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_storage_on_partition', true);
GO

-- default is strict
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
GO

SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_unique_constraint', true);
GO

EXEC sp_babelfish_configure '%', 'default', 'server';
GO

-- should be changed to ignore
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_schemabinding_function', true);
GO

-- should be changed to strict
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_storage_on_partition', true);
GO

-- should be changed to strict
SELECT CURRENT_SETTING('babelfishpg_tsql.escape_hatch_unique_constraint', true);
GO
