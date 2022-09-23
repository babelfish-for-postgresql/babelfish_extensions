use master
go

drop table sys_sp_pkeys_vu_prepare_t1
go
drop table sys_sp_pkeys_vu_prepare_t2
go
drop table sys_sp_pkeys_vu_prepare_t3
go
drop table sys_sp_pkeys_vu_prepare_t4
go

use sys_sp_pkeys_vu_prepare_db1
go

drop table sys_sp_pkeys_vu_prepare_t1
go
drop table sys_sp_pkeys_vu_prepare_t2
go
drop table sys_sp_pkeys_vu_prepare_t3
go
drop table sys_sp_pkeys_vu_prepare_t4
go

use master
go
drop database sys_sp_pkeys_vu_prepare_db1
go