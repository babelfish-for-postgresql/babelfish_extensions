USE sys_foreign_keys_dep_vu_prepare_db1;
GO

exec sys_foreign_keys_dep_vu_prepare_p1
GO

select * from sys_foreign_keys_dep_vu_prepare_f1()
GO

select * from sys_foreign_keys_dep_vu_prepare_v1
GO