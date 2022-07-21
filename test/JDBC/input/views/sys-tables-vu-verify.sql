USE db1_sys_tables
GO

SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_name1_sys_tables';
GO

SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name1_sys_tables%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'rand_name1_sys_tables';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('rand_name1_sys_tables');
GO

select count(*) from sys.objects where parent_object_id = object_id('rand_name1_sys_tables') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('rand_name1_sys_tables') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

USE master;
GO

#table rand_name1_sys_tables should not be visible in master database.
SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_name1_sys_tables';
GO

#column rand_col1 should not be visible here
SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

#default constrain on rand_name1_sys_tables should not be visible here
SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name1_sys_tables%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'rand_name1_sys_tables';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('rand_name1_sys_tables');
GO

select count(*) from sys.objects where parent_object_id = object_id('rand_name1_sys_tables') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('rand_name1_sys_tables') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_name2_sys_tables';
GO

SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name2_sys_tables%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'rand_name2_sys_tables';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('rand_name2_sys_tables');
GO

select count(*) from sys.objects where parent_object_id = object_id('rand_name2_sys_tables') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('rand_name2_sys_tables') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

USE db1_sys_tables
GO

#table rand_name2_sys_tables should not be visible in db1_sys_tables database.
SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_name2_sys_tables';
GO

#column rand_col2 should not be visible here
SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

#default constrain on rand_name2_sys_tables should not be visible here
SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name2_sys_tables%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'rand_name2_sys_tables';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('rand_name2_sys_tables');
GO

select count(*) from sys.objects where parent_object_id = object_id('rand_name2_sys_tables') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('rand_name2_sys_tables') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO
