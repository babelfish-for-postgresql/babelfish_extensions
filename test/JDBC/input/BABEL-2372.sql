-- Setting language to anything other than "us_english" will throw an error in strict mode
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
GO

SET LANGUAGE Italian
GO

SET LANGUAGE us_english
GO

declare @rc varchar(10) = 'Italian';
SET LANGUAGE @rc
go

declare @rc varchar(10) = 'us_english';
SET LANGUAGE @rc
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO

SET LANGUAGE Italian
GO

SET LANGUAGE us_english
GO


declare @rc varchar(10) = 'Italian';
SET LANGUAGE @rc
go

declare @rc varchar(10) = 'us_english';
SET LANGUAGE @rc
go


declare @rc varchar(10) = NULL;
SET LANGUAGE @rc
go

SET LANGUAGE NULL
go