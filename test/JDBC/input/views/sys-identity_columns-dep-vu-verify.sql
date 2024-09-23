USE master
go

-- should give single row as output
EXEC sys_identity_columns_dep_vu_prepare_p1
go

EXEC sys_identity_columns_dep_vu_prepare_p2
go

SELECT * FROM sys_identity_columns_dep_vu_prepare_f1()
go

SELECT * FROM sys_identity_columns_dep_vu_prepare_f2()
go

USE sys_identity_columns_dep_vu_prepare_db1
go

-- should not be visible here
SELECT * FROM sys_identity_columns_dep_vu_prepare_v1
go

SELECT * FROM sys_identity_columns_dep_vu_prepare_v2
go
