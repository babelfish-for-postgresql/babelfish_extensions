exec sp_describe_first_result_set N'select * from babel_3000_vu_prepare_var'
go

exec sp_describe_first_result_set N'select * from babel_3000_vu_prepare_dates'
go

exec sp_describe_first_result_set N'select * from dbo.babel_3000_vu_prepare_nums'
go

exec sp_describe_first_result_set N'select * from isc_udt'
go

exec sp_describe_first_result_set N'select * from master..babel_3000_vu_prepare_num_identity'
go

-- no result testing
exec sp_describe_first_result_set N'insert into babel_3000_vu_prepare_t1 values(1)', NULL, 0
go

exec sp_describe_first_result_set
go

exec sp_describe_first_result_set N''
go

-- cross schema testing
exec sp_describe_first_result_set N'select * from babel_3000_vu_prepare_s1.babel_3000_vu_prepare_nums'
go

use babel_3000_vu_prepare_db1
go

exec sp_describe_first_result_set N'select * from babel_3000_vu_prepare_nums'
go