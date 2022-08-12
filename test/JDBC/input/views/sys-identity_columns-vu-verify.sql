SELECT seed_value, increment_value, last_value FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns_vu_prepare');
go

SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns_vu_prepare');
go

USE sys_identity_columns_vu_prepare_db1
go

-- should not be visible here
SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns_vu_prepare');
go