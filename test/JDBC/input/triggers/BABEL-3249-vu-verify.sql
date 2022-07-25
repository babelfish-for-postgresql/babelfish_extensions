DELETE FROM babel_3249_vu_prepare_TAB WHERE C1 = 1;
GO

SELECT PRONAME FROM PG_PROC WHERE PRONAME = 'babel_3249_vu_prepare_trig_for'
GO

SELECT PRONAME FROM PG_PROC WHERE PRONAME = 'babel_3249_vu_prepare_trig_after'
GO
