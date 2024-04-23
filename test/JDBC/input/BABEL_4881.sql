CREATE PROCEDURE babel_4881_proc_3
AS
BEGIN
    SELECT 'before setting GUC in nest level 3', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst'), current_setting('babelfishpg_tsql.rowcount');
    SET NOCOUNT ON
    SET QUOTED_IDENTIFIER OFF;
    SET DATEFIRST 7
    SELECT 'after setting GUC in nest level 3', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst'), current_setting('babelfishpg_tsql.rowcount');
END
GO

CREATE PROCEDURE babel_4881_proc_2
AS
BEGIN
    SELECT 'before setting GUC in nest level 2', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst'), current_setting('babelfishpg_tsql.rowcount');
    SET NOCOUNT OFF
    SET QUOTED_IDENTIFIER ON;
    SET ROWCOUNT 1000;
    SELECT 'after setting GUC in nest level 2', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst'), current_setting('babelfishpg_tsql.rowcount');
    EXEC babel_4881_proc_3
    SELECT 'end nest level 2', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst'), current_setting('babelfishpg_tsql.rowcount');
END
GO

CREATE PROCEDURE babel_4881_proc_1
AS
BEGIN
    SELECT 'before setting GUC in nest level 1', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst'), current_setting('babelfishpg_tsql.rowcount');
    SET NOCOUNT ON
    SET QUOTED_IDENTIFIER OFF
    SET DATEFIRST 4
    SELECT 'after setting GUC in nest level 1', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst'), current_setting('babelfishpg_tsql.rowcount');
    EXEC babel_4881_proc_2
    SELECT 'end nest level 1', current_setting('babelfishpg_tsql.nocount'), current_setting('babelfishpg_tsql.quoted_identifier'), current_setting('babelfishpg_tsql.datefirst'), current_setting('babelfishpg_tsql.rowcount');
END
GO

SET ROWCOUNT 999;
SET DATEFIRST 2;
SELECT 'DATEFIRST BEFORE EXEC ===>', current_setting('babelfishpg_tsql.datefirst')
SELECT 'ROWCOUNT BEFORE EXEC ===>', current_setting('babelfishpg_tsql.rowcount')
GO
EXEC babel_4881_proc_1
GO
SELECT 'DATEFIRST AFTER EXEC ===>', current_setting('babelfishpg_tsql.datefirst')
SELECT 'ROWCOUNT BEFORE EXEC ===>', current_setting('babelfishpg_tsql.rowcount')
GO
DROP PROCEDURE babel_4881_proc_1, babel_4881_proc_2, babel_4881_proc_3
GO