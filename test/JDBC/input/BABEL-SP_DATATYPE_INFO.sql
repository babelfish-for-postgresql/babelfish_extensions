exec sp_datatype_info_100 @data_type = 1
go

exec sp_datatype_info @data_type = 2
go

-- Failed query in BABEL-2448
EXEC sys.sp_datatype_info_100 1, @odbcver = 2
go
