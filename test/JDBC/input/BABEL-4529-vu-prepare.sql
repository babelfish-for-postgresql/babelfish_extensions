CREATE VIEW babel_4529_stats
AS 
SELECT stats_generation_method_desc FROM sys.stats
GO

CREATE VIEW babel_4529_dm_exec_connections
AS 
SELECT local_net_address, client_net_address, endpoint_id  FROM sys.dm_exec_connections where local_net_address = 'test_address_4529';
GO

CREATE VIEW babel_4529_syscolumns
AS
SELECT printfmt FROM sys.syscolumns where name = 'test_name_4529'
GO

CREATE VIEW babel_4529_system_objects
AS
SELECT * FROM sys.system_objects where name='test_key_constraints'
GO

CREATE VIEW babel_4529_xml_indexes
AS
SELECT secondary_type FROM sys.xml_indexes
GO

CREATE VIEW babel_4529_sysforeignkeys
AS
SELECT * FROM sys.sysforeignkeys where fkeyid IS NULL
GO

CREATE VIEW babel_4529_data_spaces
AS
SELECT type FROM sys.data_spaces where type='FG'
GO

CREATE VIEW babel_4529_sysprocesses
AS
SELECT * FROM sys.sysprocesses WHERE loginname = 'test_name_4529'
GO

CREATE VIEW babel_4529_key_constraints
AS
SELECT type FROM sys.key_constraints where parent_object_id IS NULL
GO

CREATE VIEW babel_4529_foreign_keys
AS
SELECT type FROM sys.foreign_keys where name = 'test_name_4529'
GO

CREATE VIEW babel_4529_sysviews
AS
SELECT name, type, type_desc, create_date, modify_date, is_ms_shipped, is_published, is_schema_published, with_check_option, is_date_correlation_view, is_tracked_by_cdc, object_id, schema_id FROM sys.views where name = 'test_name_4529'
GO

CREATE VIEW babel_4529_systables
AS
SELECT type FROM sys.tables where name = 'test_name_4529'
GO

CREATE VIEW babel_4529_default_constraints
AS
SELECT type FROM sys.default_constraints where name = 'test_name_4529'
GO

CREATE VIEW babel_4529_check_constraints
AS
SELECT type FROM sys.check_constraints where name = 'test_name_4529'
GO

CREATE VIEW babel_4529_types
AS
SELECT name, collation_name, precision, scale, is_user_defined, is_assembly_type, is_table_type, default_object_id, rule_object_id, system_type_id, user_type_id, schema_id FROM sys.types where name = 'test_name_4529'
GO

CREATE VIEW babel_4529_sp_sproc_columns_view
AS
SELECT precision, scale FROM sys.sp_sproc_columns_view where PROCEDURE_QUALIFIER = 'test_name_4529'
GO

CREATE VIEW babel_4529_systypes
AS
SELECT prec FROM sys.systypes where name = 'test_name_4529'
GO
