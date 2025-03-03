SELECT * FROM loginproperty_vu_prepare_view
GO

EXEC loginproperty_vu_prepare_proc
GO

SELECT * FROM loginproperty_vu_prepare_func()
GO
