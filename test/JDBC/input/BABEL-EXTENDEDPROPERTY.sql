create table t1 (a int)
go

-- For now, will always return empty result set because sys.extended_properties 
-- is always empty before the support of sp_[add/drop/update]extendedproperty (BABEL-280)
select * FROM fn_listextendedproperty('COLUMN', 'schema', N'dbo', 'table', N't1', 'column', N'a');
go

select * FROM fn_listextendedproperty(NULL, 'schema', N'dbo', 'table', N't1', NULL, NULL);
go

-- Failed query in BABEL-1784
exec [sys].sp_columns_100 N't23',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go

drop table t1
go
