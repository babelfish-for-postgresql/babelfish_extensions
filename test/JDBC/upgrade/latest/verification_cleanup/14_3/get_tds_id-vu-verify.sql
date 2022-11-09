EXEC get_tds_id_proc;
GO

SELECT get_tds_id_func('timestamp') as rv;
GO

SELECT get_tds_id_func('random') as rv;
GO

-- this view will execute previous version of the function 
SELECT  * FROM get_tds_id_view;
GO
