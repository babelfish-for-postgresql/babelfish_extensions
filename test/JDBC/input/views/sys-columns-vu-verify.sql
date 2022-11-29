-- sla 10000
-- Tests for sys.columns catalog view
-- Test precision and scale for all numeric datatypes
select name, column_id, precision, scale from sys.columns where object_id=OBJECT_ID('t1_sys_syscolumns') order by name;
go

-- Test identity and computed columns
select name, column_id, is_identity, is_computed from sys.columns where object_id=OBJECT_ID('t2_sys_syscolumns') order by name;
go

-- Test ansi padded columns
select name, column_id, is_ansi_padded from sys.columns where object_id=OBJECT_ID('t3_sys_syscolumns') order by name;
go

-- Test collation name
select name, column_id, collation_name from sys.columns where object_id=OBJECT_ID('t4_sys_syscolumns') order by name;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

select name,max_length,precision,scale from sys.columns where object_id = OBJECT_ID('sys_columns_vu_prepare_test_columns') order by name;
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

select name,max_length,precision,scale from sys.columns where object_id = OBJECT_ID('t5_sys_syscolumns') order by name;
GO

select count(*) from sys.columns where object_id = OBJECT_ID('t6_sys_syscolumns') and system_type_id <> user_type_id
GO

select object_name(system_type_id), object_name(user_type_id) from sys.columns where object_id = OBJECT_ID('t6_sys_syscolumns') order by object_name(user_type_id);
GO

select name, max_length from sys.columns where object_id = OBJECT_ID('sys_columns_vu_prepare_babel_2947') order by name;
GO
