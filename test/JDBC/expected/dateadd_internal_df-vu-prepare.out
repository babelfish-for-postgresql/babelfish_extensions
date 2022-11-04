CREATE VIEW dateadd_internal_df_view_vu_prepare AS
SELECT dateadd_internal_df('minute',-70,cast('2016-12-26 00:30:05.523456+8' as DATETIMEOFFSET))
GO

CREATE PROC dateadd_internal_df_proc_vu_prepare AS
SELECT dateadd_internal_df('minute',-70,cast('2016-12-26 00:30:05.523456+8' as DATETIMEOFFSET))
GO

CREATE FUNCTION dateadd_internal_df_func_vu_prepare()
RETURNS sys.DATETIMEOFFSET
AS
BEGIN
    RETURN dateadd_internal_df('minute',-70,cast('2016-12-26 00:30:05.523456+8' as DATETIMEOFFSET))
END
GO
