use sys_syscolumns_vu_prepare_db1;
go

select name, sys_syscolumns_vu_prepare_OidToObject(id), sys_syscolumns_vu_prepare_OidToDataType(xtype), typestat, length from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by sys_syscolumns_vu_prepare_OidToObject(id) asc, name
GO

select colid, cdefault, domain, number from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by sys_syscolumns_vu_prepare_OidToObject(id) asc, name
GO

select sys_syscolumns_vu_prepare_OidToCollation(collationid), status, sys_syscolumns_vu_prepare_OidToDataType(type), prec, scale from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by sys_syscolumns_vu_prepare_OidToObject(id) asc, name
GO

select iscomputed, isoutparam, isnullable, collation from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by sys_syscolumns_vu_prepare_OidToObject(id) asc, name
GO

SELECT COUNT(*) FROM sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

use master;
go

SELECT COUNT(*) FROM sys.syscolumns where name = '@thirdparam'
go

-- should not be visible here
SELECT COUNT(*) FROM sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

use sys_syscolumns_vu_prepare_db1;
go

SELECT COUNT(*) FROM sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

-- should not be visible here
SELECT COUNT(*) FROM sys.syscolumns where name = '@thirdparam'
go
