EXEC get_tds_id_proc;
GO

SELECT get_tds_id_func('timestamp') as rv;
GO

SELECT get_tds_id_func('random') as rv;
GO

SELECT  * FROM get_tds_id_view;
GO
