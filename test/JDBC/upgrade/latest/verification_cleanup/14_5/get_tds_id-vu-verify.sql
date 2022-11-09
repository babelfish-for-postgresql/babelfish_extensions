EXEC get_tds_id_proc;
GO

SELECT get_tds_id_func('timestamp') as rv;
GO

SELECT get_tds_id_func('random') as rv;
GO

-- for minor version upgrade this view will use previous version of the get_tds_id function
SELECT  * FROM get_tds_id_view;
GO
