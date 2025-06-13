use master;
go

create table t5548(a int);
insert into t5548 values (1);
go

select .a from t5548
go

select dbo..a from t5548
go

select ...a from t5548
GO

select ..a from t5548
go

select .t5548.a from t5548;
GO

select ..t5548.a from t5548;
go

select .dbo.t5548.a from t5548;
GO

CREATE TABLE GEOSPATIALPOINTEMPTYdt (geom geometry, geog geography);
GO

select .GEOSPATIALPOINTEMPTYdt.geom.STAsText() from GEOSPATIALPOINTEMPTYdt
GO

select ..geom.STAsText() from GEOSPATIALPOINTEMPTYdt
GO

select dbo.GEOSPATIALPOINTEMPTYdt.geom.STAsText() from GEOSPATIALPOINTEMPTYdt
GO

drop table GEOSPATIALPOINTEMPTYdt
GO

drop table t5548;
go