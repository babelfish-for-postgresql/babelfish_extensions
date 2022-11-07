SELECT SYS.dateadd_internal_df('minute', -70, cast('2016-12-26 00:30:05.523456+8' as DATETIMEOFFSET))
GO

SELECT * FROM dateadd_internal_df_view_vu_prepare
GO

EXEC dateadd_internal_df_proc_vu_prepare
GO

SELECT dateadd_internal_df_func_vu_prepare()
GO

DROP VIEW dateadd_internal_df_view_vu_prepare
GO

DROP PROC dateadd_internal_df_proc_vu_prepare
GO

DROP FUNCTION dateadd_internal_df_func_vu_prepare
GO
