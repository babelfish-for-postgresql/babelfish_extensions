use database babel_2701_vu_prepare_d1;
go

select object_name(object_id) from sys.objects where name = 'babel_2701_vu_prepare_t1';
GO

drop database database babel_2701_vu_prepare_d1;
go
