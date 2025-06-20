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

CREATE TABLE TestSpatialFunction_YourTableTemp ( ID INT PRIMARY KEY, PointColumn geometry ); 
GO

INSERT INTO TestSpatialFunction_YourTableTemp (ID, PointColumn) VALUES (1, geometry::Point(3.0, 4.0, 4326)), (2, geometry::Point(5.0, 6.0, 4326)), (3, geometry::Point(3.0, 4.0, 0));
GO

SELECT TestSpatialFunction_YourTableTemp.PointColumn.STSrid from TestSpatialFunction_YourTableTemp
GO

select PointColumn.STSrid from TestSpatialFunction_YourTableTemp
GO

select .PointColumn.STSrid from TestSpatialFunction_YourTableTemp
GO

select .TestSpatialFunction_YourTableTemp.PointColumn.STSrid from TestSpatialFunction_YourTableTemp
GO

select dbo.TestSpatialFunction_YourTableTemp.PointColumn.STSrid from TestSpatialFunction_YourTableTemp
GO

drop table TestSpatialFunction_YourTableTemp
GO

drop table GEOSPATIALPOINTEMPTYdt
GO

drop table t5548;
go