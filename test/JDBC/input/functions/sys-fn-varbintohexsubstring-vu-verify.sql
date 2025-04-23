SELECT * FROM fn_varbintohexsubstring_vu_prepare_view
GO

EXEC fn_varbintohexsubstring_vu_prepare_proc
GO

SELECT * FROM fn_varbintohexsubstring_vu_prepare_func()
GO
