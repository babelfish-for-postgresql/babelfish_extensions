use sys_key_constraints_dep_vu_prepare_db1
GO

exec sys_key_constraints_dep_vu_prepare_p1
GO

select * from sys_key_constraints_dep_vu_prepare_f1()
GO

use master
GO

select * from sys_key_constraints_dep_vu_prepare_v1
GO
