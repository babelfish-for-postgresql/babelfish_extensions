SELECT * FROM has_perms_by_name_dep_vu_prepare_view
GO

EXEC has_perms_by_name_dep_vu_prepare_proc
GO

SELECT * FROM has_perms_by_name_dep_vu_prepare_func()
GO

