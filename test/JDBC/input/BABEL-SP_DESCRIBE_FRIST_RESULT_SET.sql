create table t1(a int)
go

-- no result
exec sys.sp_describe_first_result_set 'insert into t1 values(1)', NULL, 0
go

-- shows column info of 'a'
exec sp_describe_first_result_set 'select * from t1'
go

-- should be empty because the queries above are not executed
select * from t1
go

drop table t1
go
