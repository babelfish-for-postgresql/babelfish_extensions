CREATE PROCEDURE babel_4881_proc_3
AS
BEGIN
    SELECT 'before setting GUC in nest level 3', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst');
    SET NOCOUNT ON
    SET DATEFIRST 7
    SET QUOTED_IDENTIFIER OFF
    SELECT 'after setting GUC in nest level 3', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst');
END
GO

CREATE PROCEDURE babel_4881_proc_2
AS
BEGIN
    SELECT 'before setting GUC in nest level 2', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst');
    SET NOCOUNT OFF
    SET DATEFIRST 4
    SET QUOTED_IDENTIFIER ON
    SELECT 'after setting GUC in nest level 2', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst');
    EXEC babel_4881_proc_3
    SELECT 'end nest level 2', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst');
END
GO

CREATE PROCEDURE babel_4881_proc_1
AS
BEGIN
    SELECT 'before setting GUC in nest level 1', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst');
    SET NOCOUNT ON
    SET DATEFIRST 2
    SET QUOTED_IDENTIFIER OFF
    SELECT 'after setting GUC in nest level 1', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst');
    EXEC babel_4881_proc_2
    SELECT 'end nest level 1', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst');
END
GO

EXEC babel_4881_proc_1
GO

DROP PROCEDURE babel_4881_proc_1, babel_4881_proc_2, babel_4881_proc_3
GO