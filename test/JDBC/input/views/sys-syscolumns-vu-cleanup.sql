use sys_syscolumns_vu_prepare_db1;
go

-- Cleanup
DROP FUNCTION OidToDataType
DROP FUNCTION OidToObject
DROP FUNCTION OidToCollation
DROP PROCEDURE syscolumns_demo_proc1
DROP PROCEDURE syscolumns_demo_proc2
DROP TABLE sys_syscolumns_vu_prepare_t1
GO

use master;
go

drop database sys_syscolumns_vu_prepare_db1;
go

DROP PROCEDURE syscolumns_demo_proc3
go
