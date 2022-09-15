USE master
go

EXEC sys_identity_columns_dep_vu_prepare_p1
go

SELECT * FROM sys_identity_columns_dep_vu_prepare_f1()
go

USE sys_identity_columns_dep_vu_prepare_db1
go

-- should not be visible here
SELECT * FROM sys_identity_columns_dep_vu_prepare_v1
go
