CREATE DATABASE db1;
GO

USE db1
GO

CREATE TABLE rand_name1(rand_col1 int DEFAULT 1, CHECK (rand_col1 > 0));
GO

SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_name1';
GO

SELECT COUNT(*) FROM sys.tables WHERE name = 'rand_name1' and type='U';
GO
SELECT COUNT(*) FROM sys.tables WHERE name = 'rand_name1' and type='u';
GO

SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name1%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'rand_name1';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('rand_name1');
GO

select count(*) from sys.objects where parent_object_id = object_id('rand_name1') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('rand_name1') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

USE master;
GO

#table rand_name1 should not be visible in master database.
SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_name1';
GO

#column rand_col1 should not be visible here
SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

#default constrain on rand_name1 should not be visible here
SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name1%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'rand_name1';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('rand_name1');
GO

select count(*) from sys.objects where parent_object_id = object_id('rand_name1') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('rand_name1') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col1';
GO

CREATE TABLE rand_name2(rand_col2 int DEFAULT 2, CHECK (rand_col2 > 0));
GO

SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_name2';
GO

SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name2%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'rand_name2';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('rand_name2');
GO

select count(*) from sys.objects where parent_object_id = object_id('rand_name2') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('rand_name2') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

USE db1
GO

#table rand_name2 should not be visible in db1 database.
SELECT COUNT(*) FROM sys.tables WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_name2';
GO

#column rand_col2 should not be visible here
SELECT COUNT(*) FROM sys.columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

#default constrain on rand_name2 should not be visible here
SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name2%';
GO

SELECT COUNT(*) FROM sys.objects WHERE type='U' and name COLLATE bbf_unicode_general_ci_as = 'rand_name2';
GO

select count(*) from sys.check_constraints where parent_object_id = object_id('rand_name2');
GO

select count(*) from sys.objects where parent_object_id = object_id('rand_name2') and type = 'C';
GO

select count(*) from sys.all_objects where parent_object_id = object_id('rand_name2') and type = 'C';
GO

SELECT COUNT(*) FROM sys.all_columns WHERE name COLLATE bbf_unicode_general_ci_as = 'rand_col2';
GO

DROP TABLE rand_name1;
GO

USE master;
GO

DROP DATABASE db1;
GO

DROP TABLE rand_name2;
GO
