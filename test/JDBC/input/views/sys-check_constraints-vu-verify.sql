SELECT name FROM sys.check_constraints WHERE NAME IN ('sys_check_constraints_vu_prepare_t1_sck_date_col_check')
GO

SELECT definition FROM sys.check_constraints where name LIKE '%sys_check_constraints_vu_prepare_t2%' ORDER BY definition;
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.check_constraints');
GO