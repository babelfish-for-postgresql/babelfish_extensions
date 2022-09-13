USE sys_tables_vu_prepare_db1
GO

SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'sys_tables_vu_prepare_t1';
GO

SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%sys_tables_vu_prepare_t1%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'sys_tables_vu_prepare_t1';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('sys_tables_vu_prepare_t1');
GO

select count(*) from sys.objects where parent_object_id = object_id('sys_tables_vu_prepare_t1') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('sys_tables_vu_prepare_t1') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

USE master;
GO

#table sys_tables_vu_prepare_t1 should not be visible in master database.
SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'sys_tables_vu_prepare_t1';
GO

#column rand_col1 should not be visible here
SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

#default constrain on sys_tables_vu_prepare_t1 should not be visible here
SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%sys_tables_vu_prepare_t1%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'sys_tables_vu_prepare_t1';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('sys_tables_vu_prepare_t1');
GO

select count(*) from sys.objects where parent_object_id = object_id('sys_tables_vu_prepare_t1') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('sys_tables_vu_prepare_t1') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'sys_tables_vu_prepare_t2';
GO

SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%sys_tables_vu_prepare_t2%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'sys_tables_vu_prepare_t2';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('sys_tables_vu_prepare_t2');
GO

select count(*) from sys.objects where parent_object_id = object_id('sys_tables_vu_prepare_t2') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('sys_tables_vu_prepare_t2') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

USE sys_tables_vu_prepare_db1
GO

#table sys_tables_vu_prepare_t2 should not be visible in sys_tables_vu_prepare_db1 database.
SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'sys_tables_vu_prepare_t2';
GO

#column rand_col2 should not be visible here
SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

#default constrain on sys_tables_vu_prepare_t2 should not be visible here
SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%sys_tables_vu_prepare_t2%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'sys_tables_vu_prepare_t2';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('sys_tables_vu_prepare_t2');
GO

select count(*) from sys.objects where parent_object_id = object_id('sys_tables_vu_prepare_t2') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('sys_tables_vu_prepare_t2') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO
