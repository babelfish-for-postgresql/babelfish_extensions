-- Tests for colon_colon syntax
select geometry::STGeomFromText('POINT (1 2)', 0)
go

select sys.geometry::STGeomFromText('POINT (1 2)', 0)
go

select [sys].[geometry]::STGeomFromText('POINT (1 2)', 0)
go

select geography::STGeomFromText('POINT (1 2)', 4326)
go

select sys.geography::STGeomFromText('POINT (1 2)', 4326)
go

select [sys].[geography]::STGeomFromText('POINT (1 2)', 4326)
go

select [geography]::STGeomFromText('POINT (1 2)', 4326)
go

select [geometry]::STGeomFromText('POINT (1 2)', 0)
go

select (geography)::STGeomFromText('POINT (1 2)', 4326)
go

select (geometry)::STGeomFromText('POINT (1 2)', 0)
go

select "geography"::STGeomFromText('POINT (1 2)', 4326)
go

select "geometry"::STGeomFromText('POINT (1 2)', 0)
go

select xml::XmlColumn.value('/', 'varchar') from babel_5987_colon_colon_t1
go

select geometry::GeomColumn.STAsText() from babel_5987_colon_colon_t1
go

select geography::GeogColumn.STAsText() from babel_5987_colon_colon_t1
go

select XmlColumn::xml.value('/', 'varchar') from babel_5987_colon_colon_t1
go

select GeomColumn::geometry.STAsText() from babel_5987_colon_colon_t1
go

select GeogColumn::geography.STAsText() from babel_5987_colon_colon_t1
go

select geometry::STGeomFromText('POINT (1 2)', 0).STAsText()
go

select geography::STGeomFromText('POINT (1 2)', 4326).STAsText()
go

-- HierarchyId is not supported
select hierarchyid::GETROOT()
go

select geometry::NonExistentMethod()
go

select geography::NonExistentMethod()
go

select xml::NonExistentMethod()
go

select int::NonExistentMethod()
go

select geometry::[NonExistentMethod]()
go

select geography::[NonExistentMethod]()
go

select xml::[NonExistentMethod]()
go

select int::[NonExistentMethod]()
go

select geometry::NonExistentMethodField
go

select geography::NonExistentMethodField
go

select xml::NonExistentMethodField
go

select int::NonExistentMethodField
go

select geometry::[NonExistentMethodField]
go

select geography::[NonExistentMethodField]
go

select xml::[NonExistentMethodField]
go

select int::[NonExistentMethodField]
go

select geometry::NonExistentMethod().AnotherNonExistentMethod()
go

select geography::NonExistentMethod().AnotherNonExistentMethod()
go

select xml::NonExistentMethod().AnotherNonExistentMethod()
go

select int::NonExistentMethod().AnotherNonExistentMethod()
go

select geometry::NonExistentMethodField.AnotherNonExistentField
go

select geography::NonExistentMethodField.AnotherNonExistentField
go

select xml::NonExistentMethodField.AnotherNonExistentField
go

select int::NonExistentMethodField.AnotherNonExistentField
go

select geometry::NonExistentMethod().AnotherNonExistentField
go

select geography::NonExistentMethod().AnotherNonExistentField
go

select xml::NonExistentMethod().AnotherNonExistentField
go

select int::NonExistentMethod().AnotherNonExistentField
go

select geometry::NonExistentMethodField.AnotherNonExistentMethod()
go

select geography::NonExistentMethodField.AnotherNonExistentMethod()
go

select xml::NonExistentMethodField.AnotherNonExistentMethod()
go

select int::NonExistentMethodField.AnotherNonExistentMethod()
go

select babel_5987_xmlUDT::NonExistentMethod()
go

select babel_5987_geometryUDT::STGeomFromText('POINT (1 2)', 0)
go

select babel_5987_geographyUDT::STGeomFromText('POINT (1 2)', 4326)
go

SET QUOTED_IDENTIFIER OFF
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

select "geography"::STGeomFromText('POINT (1 2)', 4326)
go

select "geometry"::STGeomFromText('POINT (1 2)', 0)
go

SET QUOTED_IDENTIFIER ON
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

select geometry   ::STGeomFromText('Point(47.65100 -22.34900 32.546000  54.56300)', 1000000000 )
go

-- dependent objects
EXEC babel_5987_colon_colon_dep_proc1
GO

EXEC babel_5987_colon_colon_dep_proc2
GO

EXEC babel_5987_colon_colon_dep_proc3
GO

SELECT babel_5987_colon_colon_dep_func_1()
GO

SELECT babel_5987_colon_colon_dep_func_2()
GO

SELECT babel_5987_colon_colon_dep_func_3()
GO

SELECT babel_5987_colon_colon_dep_func_4()
GO

SELECT babel_5987_colon_colon_dep_func_5()
GO

SELECT * FROM babel_5987_colon_colon_dep_view1
GO

SELECT * FROM babel_5987_colon_colon_dep_view2
GO

SELECT * FROM babel_5987_colon_colon_dep_view3
GO
