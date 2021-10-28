-- Setting language to anything other than "us_english" will throw an error in strict mode
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
GO

SET LANGUAGE Italian
GO

SET LANGUAGE us_english
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO

SET LANGUAGE Italian
GO

SET LANGUAGE us_english
GO
