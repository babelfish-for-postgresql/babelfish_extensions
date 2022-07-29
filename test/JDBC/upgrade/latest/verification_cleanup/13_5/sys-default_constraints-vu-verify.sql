SELECT definition FROM sys.default_constraints where name LIKE '%sys_default_definitions%' ORDER BY name;
GO

SELECT COUNT(*) FROM sys.default_constraints;

ALTER TABLE sys_default_definitions_vu_prepare ADD CONSTRAINT default_column_a_varchar DEFAULT 'ab' FOR column_a
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.default_constraints');
GO

EXEC sys_default_definitions_vu_prepare_proc;
GO

SELECT * FROM sys_default_definitions_vu_prepare_func();
GO

SELECT * FROM sys_default_definitions_vu_prepare_view;
GO