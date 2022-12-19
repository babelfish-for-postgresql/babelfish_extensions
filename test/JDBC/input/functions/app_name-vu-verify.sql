SELECT * FROM app_name_vu_prepare_v1
GO

EXEC app_name_vu_prepare_p1
GO

SELECT set_config('application_name', 'new_app_name', FALSE);
GO

SELECT * FROM app_name_vu_prepare_v1
GO

EXEC app_name_vu_prepare_p1
GO
