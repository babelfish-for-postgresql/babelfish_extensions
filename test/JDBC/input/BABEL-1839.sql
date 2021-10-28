SELECT 
	current_setting('babelfishpg_tsql.quoted_identifier', true), 
	current_setting('babelfishpg_tsql.nocount', true), 
	current_setting('babelfishpg_tsql.concat_null_yields_null', true);
GO

SET NOCOUNT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER OFF;
GO

SELECT 
	current_setting('babelfishpg_tsql.quoted_identifier', true), 
	current_setting('babelfishpg_tsql.nocount', true), 
	current_setting('babelfishpg_tsql.concat_null_yields_null', true);
GO

-- error expected
SET NOCOUNT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER, NOTHING ON;
GO

-- value shall not change
SELECT 
	current_setting('babelfishpg_tsql.quoted_identifier', true), 
	current_setting('babelfishpg_tsql.nocount', true), 
	current_setting('babelfishpg_tsql.concat_null_yields_null', true);
GO

-- error expected 2
SET NOCOUNT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER, LANGUAGE ON;
GO

-- value shall not change
SELECT 
	current_setting('babelfishpg_tsql.quoted_identifier', true), 
	current_setting('babelfishpg_tsql.nocount', true), 
	current_setting('babelfishpg_tsql.concat_null_yields_null', true);
GO
