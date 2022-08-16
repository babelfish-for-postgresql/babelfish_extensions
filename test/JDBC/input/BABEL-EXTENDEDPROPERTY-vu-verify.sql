-- For now, will always return empty result set because sys.extended_properties 
-- is always empty before the support of sp_[add/drop/update]extendedproperty (BABEL-280)
select * FROM fn_listextendedproperty('COLUMN', 'schema', N'dbo', 'table', N'BABEL_EXTENDEDPROPERTY_vu_t1', 'column', N'a');
go

select * FROM fn_listextendedproperty(NULL, 'schema', N'dbo', 'table', N'BABEL_EXTENDEDPROPERTY_vu_t1', NULL, NULL);
go

-- Failed query in BABEL-1784
exec [sys].sp_columns_100 N't23',N'dbo',NULL,NULL,@ODBCVer=3,@fUsePattern=1;
go

select * from BABEL_EXTENDEDPROPERTY_vu_v1
go

drop view BABEL_EXTENDEDPROPERTY_vu_v1
go

select * from BABEL_EXTENDEDPROPERTY_vu_f1(N'BABEL_EXTENDEDPROPERTY_vu_t1')
go

drop function BABEL_EXTENDEDPROPERTY_vu_f1
go

exec BABEL_EXTENDEDPROPERTY_vu_p1
go

drop proc BABEL_EXTENDEDPROPERTY_vu_p1
go

drop table BABEL_EXTENDEDPROPERTY_vu_t1
go
