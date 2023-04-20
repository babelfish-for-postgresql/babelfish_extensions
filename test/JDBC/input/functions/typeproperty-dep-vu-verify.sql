SELECT * FROM typeproperty_vu_prepare_dep_view
GO

EXEC typeproperty_vu_prepare_dep_proc
GO

SELECT * FROM typeproperty_vu_prepare_dep_func()
GO
