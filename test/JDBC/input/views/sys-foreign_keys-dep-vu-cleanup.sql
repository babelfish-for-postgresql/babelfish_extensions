USE sys_foreign_keys_dep_vu_prepare_db1;
GO

drop procedure if exists sys_foreign_keys_dep_vu_prepare_p1
GO

drop function if exists sys_foreign_keys_dep_vu_prepare_f1
GO

drop view if exists sys_foreign_keys_dep_vu_prepare_v1
GO

drop table sys_foreign_keys_dep_vu_prepare_fk_2
GO

drop table sys_foreign_keys_dep_vu_prepare_fk_1
GO

USE master
GO

drop DATABASE sys_foreign_keys_dep_vu_prepare_db1
GO