EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
GO

SET ANSI_DEFAULTS ON;
GO

-- Test invalid setting
SET ANSI_DEFAULTS OFF;
GO

-- Test ANSI_DEFAULTS can be set to OFF when ESCAPE_HATCH_SESSION_SETTINGS = 'ignore'
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO
SET ANSI_DEFAULTS OFF;
GO

-- expect OFF
SELECT CURRENT_SETTING('babelfishpg_tsql.ansi_nulls', true);
GO
-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.ansi_warnings', true);
GO
-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.ansi_null_dflt_on', true);
GO
-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.ansi_padding', true);
GO
-- expect OFF
SELECT CURRENT_SETTING('babelfishpg_tsql.implicit_transactions', true);
GO
-- expect OFF
SELECT CURRENT_SETTING('babelfishpg_tsql.quoted_identifier', true);
GO

SET ANSI_DEFAULTS ON;
GO

-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.ansi_nulls', true);
GO
-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.ansi_warnings', true);
GO
-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.ansi_null_dflt_on', true);
GO
-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.ansi_padding', true);
GO
-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.implicit_transactions', true);
GO
-- expect ON
SELECT CURRENT_SETTING('babelfishpg_tsql.quoted_identifier', true);
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO
