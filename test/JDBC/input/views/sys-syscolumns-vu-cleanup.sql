use sys_syscolumns_vu_prepare_db1;
go

-- Cleanup
DROP FUNCTION OidToDataType
DROP FUNCTION OidToObject
DROP FUNCTION OidToCollation
DROP PROCEDURE sys_syscolumns_vu_prepare_proc1
DROP PROCEDURE sys_syscolumns_vu_prepare_proc2
DROP TABLE sys_syscolumns_vu_prepare_t1
GO

use master;
go

drop database sys_syscolumns_vu_prepare_db1;
go

DROP PROCEDURE sys_syscolumns_vu_prepare_proc3
go
