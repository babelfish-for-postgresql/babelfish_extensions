SELECT * FROM objectproperty_vu_prepare_dep_view
GO

EXEC objectproperty_vu_prepare_dep_proc
GO

SELECT * FROM objectproperty_vu_prepare_dep_func()
GO
