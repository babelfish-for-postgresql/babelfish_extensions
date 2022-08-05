create table BABEL_EXTENDEDPROPERTY_vu_t1 (a int)
go

create view BABEL_EXTENDEDPROPERTY_vu_v1 as select * FROM fn_listextendedproperty(NULL, 'schema', N'dbo', 'table', N't1', NULL, NULL);
go

CREATE FUNCTION BABEL_EXTENDEDPROPERTY_vu_f1 (@t VARCHAR(30))
RETURNS TABLE AS
RETURN SELECT * FROM fn_listextendedproperty(NULL, 'schema', N'dbo', 'table', @t, NULL, NULL);
go

create proc BABEL_EXTENDEDPROPERTY_vu_p1
AS
SELECT * FROM fn_listextendedproperty(NULL, 'schema', N'dbo', 'table', N'BABEL_EXTENDEDPROPERTY_vu_t1', NULL, NULL);
go
