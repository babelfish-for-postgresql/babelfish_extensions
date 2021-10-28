SET blah ON;
GO

SET blahblah oh_yes;
GO

SET auto_commit_batch on; -- existing bbf GUC
GO

-- should fail even if escape_hatch_session_settings = 'ignore'
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO

SET blah ON;
GO

SET blahblah oh_yes;
GO

SET auto_commit_batch on; -- existing bbf GUC
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
GO
