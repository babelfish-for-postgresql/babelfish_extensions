USE babel_sp_columns_vu_prepare_mydb1
GO

drop table babel_sp_columns_vu_prepare_t_int
drop table babel_sp_columns_vu_prepare_t_text
drop table babel_sp_columns_vu_prepare_t_time
drop table babel_sp_columns_vu_prepare_t_money
drop table babel_sp_columns_vu_prepare_bytea
GO

USE master
GO
DROP DATABASE babel_sp_columns_vu_prepare_mydb1
GO