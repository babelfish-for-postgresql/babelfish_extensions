SELECT seed_value, increment_value, last_value FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns');
go

SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns');
go

USE sys_identity_columns_db1
go

-- should not be visible here
SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns');
go