-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------


-- =============================================================
-- GEOMETRY
-- =============================================================
CREATE OR REPLACE FUNCTION sys.geometryin(cstring)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'geometry_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geometryout(sys.GEOMETRY)
	RETURNS cstring
	AS '$libdir/postgis-3','LWGEOM_out'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geometrytypmodin(cstring[])
	RETURNS integer
	AS '$libdir/postgis-3','geometry_typmod_in'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geometrytypmodout(integer)
	RETURNS cstring
	AS '$libdir/postgis-3','postgis_typmod_out'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geometryanalyze(internal)
	RETURNS bool
	AS '$libdir/postgis-3', 'gserialized_analyze_nd'
	LANGUAGE 'c' VOLATILE STRICT;

CREATE OR REPLACE FUNCTION sys.geometryrecv(internal)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','LWGEOM_recv'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geometrysend(sys.GEOMETRY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_send'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.GEOMETRY, integer, boolean)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','geometry_enforce_typmod'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(point)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','point_to_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.point(sys.GEOMETRY)
	RETURNS point
	AS '$libdir/postgis-3','geometry_to_point'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geometry__stgeomfromtext(sys.NVARCHAR, integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stgeomfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOMETRY)
	RETURNS sys.NVARCHAR
	AS 'babelfishpg_common', 'st_as_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOMETRY)
	RETURNS text
	AS 'babelfishpg_common', 'bbf_geom_to_text_error'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOMETRY, integer, boolean)
	RETURNS sys.bpchar
	AS 'babelfishpg_common','geometry_asbpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bpchar)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geom_from_bpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOMETRY, integer, boolean)
	RETURNS sys.varchar
	AS 'babelfishpg_common', 'bbf_geom_asvarchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.varchar)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geom_from_varchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(bytea)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common','geometry_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOMETRY)
	RETURNS bytea
	AS 'babelfishpg_common','bytea_from_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bbf_varbinary)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geom_from_varbinary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOMETRY, integer, boolean)
    RETURNS sys.bbf_varbinary
    AS 'babelfishpg_common', 'bbf_geom_to_varbinary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bbf_binary)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geom_from_binary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(text, integer, boolean)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_text_to_geom_error'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;


CREATE OR REPLACE FUNCTION sys.bbf_binary(sys.GEOMETRY, integer, boolean)
	RETURNS sys.bbf_binary
	AS 'babelfishpg_common', 'bbf_geom_to_binary'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geometry__Point(float8, float8, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_point'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOMETRY)
	RETURNS sys.varbinary
	AS 'babelfishpg_common', 'st_as_binary_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geometry__STPointFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stpointfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geometry__STLineFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stlinefromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geometry__STPolyFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stpolyfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geometry__STMPointFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stmpointfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geometry__STMPointFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geometry_stmpointfromwkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geomfromwkb_helper(bytea, integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'get_geometry_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.ST_GeometryType(sys.GEOMETRY)
	RETURNS text
	AS '$libdir/postgis-3', 'geometry_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.ST_zmflag(sys.GEOMETRY)
	RETURNS smallint
	AS '$libdir/postgis-3', 'LWGEOM_zmflag'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STArea(geom sys.GEOMETRY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_st_area'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STSrid(sys.GEOMETRY)
	RETURNS integer
	AS '$libdir/postgis-3','LWGEOM_get_srid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_contains'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
	RETURNS boolean
	AS 'babelfishpg_common', 'bbf_geom_op_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
	RETURNS boolean
	AS 'babelfishpg_common', 'bbf_geom_op_not_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOMETRY)
	RETURNS integer
	AS 'babelfishpg_common', 'bbf_st_dimension'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STGeometryType(geom sys.GEOMETRY)
	RETURNS sys.NVARCHAR(4000)
	AS 'babelfishpg_common', 'bbf_st_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.MakeValid(geom sys.GEOMETRY)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_st_makevalid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geometry__Parse(geometry_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geometry_parse'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STNumPoints(geom sys.GEOMETRY)
    RETURNS integer
    AS 'babelfishpg_common', 'bbf_st_numpoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_disjoint'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_intersects'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_isclosed'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STDistance(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_st_distance'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.stx(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_x_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.sty(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_y_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.HasZ(geom sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_hasz'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.HasM(geom sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_hasm'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Z(geom sys.GEOMETRY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_z'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.M(geom sys.GEOMETRY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_m'
	LANGUAGE 'c' IMMUTABLE STRICT;


-- =============================================================
-- GEOGRAPHY
-- =============================================================
CREATE OR REPLACE FUNCTION sys.geographyin(cstring, oid, integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common','geography_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geographyout(sys.GEOGRAPHY)
    RETURNS cstring
    AS '$libdir/postgis-3','geography_out'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geographytypmodin(cstring[])
    RETURNS integer
    AS '$libdir/postgis-3','geometry_typmod_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geographytypmodout(integer)
    RETURNS cstring
    AS '$libdir/postgis-3','postgis_typmod_out'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geographyrecv(internal, oid, integer)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3','geography_recv'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geographysend(sys.GEOGRAPHY)
    RETURNS bytea
    AS '$libdir/postgis-3','geography_send'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geographyanalyze(internal)
    RETURNS bool
    AS '$libdir/postgis-3','gserialized_analyze_nd'
    LANGUAGE 'c' VOLATILE STRICT;  

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','geography_enforce_typmod'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(bytea)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common','geography_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOGRAPHY)
	RETURNS bytea
	AS 'babelfishpg_common','bytea_from_geography'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bbf_varbinary)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geog_from_varbinary'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.bbf_varbinary
	AS 'babelfishpg_common', 'bbf_geog_to_varbinary'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bbf_binary)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geog_from_binary'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOGRAPHY)
	RETURNS text
	AS 'babelfishpg_common', 'bbf_geog_to_text_error'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(text, integer, boolean)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_text_to_geog_error'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.bpchar
	AS 'babelfishpg_common', 'bbf_geog_asbpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bpchar)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geog_from_bpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.varchar
	AS 'babelfishpg_common', 'bbf_geog_asvarchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.varchar)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geog_from_varchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.bbf_binary(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.bbf_binary
	AS 'babelfishpg_common', 'bbf_geog_to_binary'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__STFlipCoordinates(sys.GEOGRAPHY)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3', 'ST_FlipCoordinates'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__stgeomfromtext(sys.NVARCHAR, integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geography_stgeomfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__STMPointFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geography_stmpointfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__STMPointFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_stmpointfromwkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.geogfromwkb_helper(bytea, integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'get_geography_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOGRAPHY)
    RETURNS sys.NVARCHAR
    AS 'babelfishpg_common', 'bbf_geog_astext'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOGRAPHY)
	RETURNS sys.varbinary
	AS 'babelfishpg_common', 'st_as_binary_geography'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__Point(float8, float8, srid integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'geography_point'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__STPointFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geography_stpointfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__STLineFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geography_stlinefromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__STPolyFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'bbf_geography_stpolyfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.ST_GeometryType(sys.GEOGRAPHY)
	RETURNS text
	AS '$libdir/postgis-3', 'geometry_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.ST_zmflag(sys.GEOGRAPHY)
	RETURNS smallint
	AS '$libdir/postgis-3', 'LWGEOM_zmflag'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STArea(geom sys.GEOGRAPHY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_geog_area'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STSrid(sys.GEOGRAPHY)
	RETURNS integer
	AS '$libdir/postgis-3','LWGEOM_get_srid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_geog_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_geog_contains'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
	RETURNS boolean
	AS 'babelfishpg_common', 'bbf_geog_op_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
	RETURNS boolean
	AS 'babelfishpg_common', 'bbf_geog_op_not_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOGRAPHY)
	RETURNS integer
	AS 'babelfishpg_common', 'bbf_geog_dimension'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.MakeValid(geog sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geog_makevalid'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STNumPoints(geog sys.GEOGRAPHY)
	RETURNS integer
	AS 'babelfishpg_common', 'bbf_geog_numpoints'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Geography__Parse(geography_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_parse'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STGeometryType(geog sys.GEOGRAPHY)
	RETURNS sys.NVARCHAR(4000)
	AS 'babelfishpg_common', 'bbf_st_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_geog_disjoint'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_geog_intersects'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_geog_isclosed'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STDistance(geog1 sys.GEOGRAPHY, geog2 sys.GEOGRAPHY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_geog_distance'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.long(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_y_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.lat(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_x_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.ST_Transform(sys.GEOGRAPHY, integer)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','transform'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.HasZ(geog sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_hasz'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.HasM(geog sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_hasm'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.Z(geom sys.GEOGRAPHY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_z'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.M(geom sys.GEOGRAPHY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_m'
	LANGUAGE 'c' IMMUTABLE STRICT;



--Geometry

--STMLineFromText
CREATE OR REPLACE FUNCTION sys.Geometry__STMLineFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'geometry_mlinestring_from_text'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

--STMLineFromWKB
CREATE OR REPLACE FUNCTION sys.Geometry__STMLineFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'geometry_mlinestring_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

--Geography

--STMLineFromText
CREATE OR REPLACE FUNCTION sys.Geography__STMLineFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'geography_mlinestring_from_text'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

--STMLineFromWKB
CREATE OR REPLACE FUNCTION sys.Geography__STMLineFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'geography_mlinestring_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;
CREATE TYPE sys.box2df;
--geometry


--ST_EXPAND
CREATE OR REPLACE FUNCTION sys.ST_Expand(geom sys.GEOMETRY, distance float8)
    RETURNS sys.GEOMETRY
    AS '$libdir/postgis-3', 'LWGEOM_expand'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

-- box2df type for GiST internal storage

CREATE OR REPLACE FUNCTION sys.box2df_in(cstring)
    RETURNS sys.box2df
    AS '$libdir/postgis-3', 'box2df_in'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.box2df_out(sys.box2df)
    RETURNS cstring
    AS '$libdir/postgis-3', 'box2df_out'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.box2df (
    internallength = 16,
    input = sys.box2df_in,
    output = sys.box2df_out,
    storage = plain,
    alignment = double
);

-- GiST support functions
CREATE OR REPLACE FUNCTION sys.geometry_gist_consistent_2d(internal, sys.GEOMETRY, smallint, oid, internal)
    RETURNS bool AS '$libdir/postgis-3', 'gserialized_gist_consistent_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_gist_compress_2d(internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_compress_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_gist_decompress_2d(internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_decompress_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_gist_penalty_2d(internal, internal, internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_penalty_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_gist_picksplit_2d(internal, internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_picksplit_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_gist_union_2d(bytea, internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_union_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_gist_same_2d(sys.GEOMETRY, sys.GEOMETRY, internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_same_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_gist_distance_2d(internal, sys.GEOMETRY, smallint, oid, internal)
    RETURNS float8 AS '$libdir/postgis-3', 'gserialized_gist_distance_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

-- Spatial operator functions
CREATE OR REPLACE FUNCTION sys.geometry_overlaps(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overlaps_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_contains(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_contains_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_within(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_within_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_left(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_left_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_overleft(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overleft_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_right(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_right_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_overright(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overright_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_above(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_above_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_overabove(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overabove_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_below(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_below_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_overbelow(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overbelow_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_same(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_same_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometry_distance_centroid(sys.GEOMETRY, sys.GEOMETRY)
    RETURNS float8 AS '$libdir/postgis-3', 'gserialized_distance_centroid_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

-- Selectivity estimation functions
CREATE OR REPLACE FUNCTION sys.gserialized_gist_sel_2d(internal, oid, internal, integer)
    RETURNS float8 AS '$libdir/postgis-3', 'gserialized_gist_sel_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.gserialized_gist_joinsel_2d(internal, oid, internal, smallint, internal)
    RETURNS float8 AS '$libdir/postgis-3', 'gserialized_gist_joinsel_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

-- Spatial operators
CREATE OPERATOR sys.&& (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overlaps,
    COMMUTATOR = &&,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.~ (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_contains,
    COMMUTATOR = @,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.@ (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_within,
    COMMUTATOR = ~,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.<< (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_left,
    COMMUTATOR = >>,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.&< (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overleft,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.>> (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_right,
    COMMUTATOR = <<,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.&> (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overright,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.|>> (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_above,
    COMMUTATOR = <<|,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.|&> (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overabove,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);
CREATE OPERATOR sys.<<| (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_below,
    COMMUTATOR = |>>,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.&<| (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overbelow,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.~= (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_same,
    COMMUTATOR = ~=,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.<-> (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_distance_centroid,
    COMMUTATOR = <->
);

-- GiST operator class
CREATE OPERATOR CLASS sys.gist_geometry_ops_2d
    DEFAULT FOR TYPE sys.GEOMETRY USING gist AS
    STORAGE sys.box2df,
    OPERATOR  1  sys.<<(sys.GEOMETRY, sys.GEOMETRY)  ,
    OPERATOR  2  sys.&<(sys.GEOMETRY, sys.GEOMETRY)  ,
    OPERATOR  3  sys.&&(sys.GEOMETRY, sys.GEOMETRY)  ,
    OPERATOR  4  sys.&>(sys.GEOMETRY, sys.GEOMETRY)  ,
    OPERATOR  5  sys.>>(sys.GEOMETRY, sys.GEOMETRY)  ,
    OPERATOR  6  sys.~=(sys.GEOMETRY, sys.GEOMETRY)  ,
    OPERATOR  7  sys.~(sys.GEOMETRY, sys.GEOMETRY)   ,
    OPERATOR  8  sys.@(sys.GEOMETRY, sys.GEOMETRY)   ,
    OPERATOR  9  sys.&<|(sys.GEOMETRY, sys.GEOMETRY) ,
    OPERATOR 10  sys.<<|(sys.GEOMETRY, sys.GEOMETRY) ,
    OPERATOR 11  sys.|>>(sys.GEOMETRY, sys.GEOMETRY) ,
    OPERATOR 12  sys.|&>(sys.GEOMETRY, sys.GEOMETRY) ,
    OPERATOR 13  sys.<->(sys.GEOMETRY, sys.GEOMETRY) FOR ORDER BY pg_catalog.float_ops,
    FUNCTION  1  sys.geometry_gist_consistent_2d(internal, sys.GEOMETRY, smallint, oid, internal),
    FUNCTION  2  sys.geometry_gist_union_2d(bytea, internal),
    FUNCTION  3  sys.geometry_gist_compress_2d(internal),
    FUNCTION  4  sys.geometry_gist_decompress_2d(internal),
    FUNCTION  5  sys.geometry_gist_penalty_2d(internal, internal, internal),
    FUNCTION  6  sys.geometry_gist_picksplit_2d(internal, internal),
    FUNCTION  7  sys.geometry_gist_same_2d(sys.GEOMETRY, sys.GEOMETRY, internal),
    FUNCTION  8  sys.geometry_gist_distance_2d(internal, sys.GEOMETRY, smallint, oid, internal);


--geography

--ST_EXPAND
CREATE OR REPLACE FUNCTION sys.ST_Expand(geog sys.GEOGRAPHY, distance float8)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3', 'LWGEOM_expand'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

-- GiST support for sys.GEOGRAPHY (spatial indexing)

-- GiST support functions
CREATE OR REPLACE FUNCTION sys.geography_gist_consistent(internal, sys.GEOGRAPHY, smallint, oid, internal)
    RETURNS bool AS '$libdir/postgis-3', 'gserialized_gist_consistent_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_gist_compress(internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_compress_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_gist_decompress(internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_decompress_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_gist_penalty(internal, internal, internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_penalty_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_gist_picksplit(internal, internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_picksplit_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_gist_union(bytea, internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_union_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_gist_same(sys.GEOGRAPHY, sys.GEOGRAPHY, internal)
    RETURNS internal AS '$libdir/postgis-3', 'gserialized_gist_same_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_gist_distance(internal, sys.GEOGRAPHY, smallint, oid, internal)
    RETURNS float8 AS '$libdir/postgis-3', 'gserialized_gist_distance_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

-- Spatial operator functions
CREATE OR REPLACE FUNCTION sys.geography_overlaps(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overlaps_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_contains(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_contains_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_within(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_within_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_left(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_left_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_overleft(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overleft_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_right(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_right_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_overright(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overright_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_above(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_above_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_overabove(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overabove_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_below(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_below_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_overbelow(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_overbelow_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_same(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS boolean AS '$libdir/postgis-3', 'gserialized_same_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_distance_centroid(sys.GEOGRAPHY, sys.GEOGRAPHY)
    RETURNS float8 AS '$libdir/postgis-3', 'gserialized_distance_centroid_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

-- Selectivity estimation functions
CREATE OR REPLACE FUNCTION sys.geography_gist_sel(internal, oid, internal, integer)
    RETURNS float8 AS '$libdir/postgis-3', 'gserialized_gist_sel_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geography_gist_joinsel(internal, oid, internal, smallint, internal)
    RETURNS float8 AS '$libdir/postgis-3', 'gserialized_gist_joinsel_2d'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

-- Spatial operators
CREATE OPERATOR sys.&& (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overlaps,
    COMMUTATOR = &&,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.~ (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_contains,
    COMMUTATOR = @,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.@ (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_within,
    COMMUTATOR = ~,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.<< (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_left,
    COMMUTATOR = >>,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.&< (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overleft,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.>> (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_right,
    COMMUTATOR = <<,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.&> (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overright,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.|>> (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_above,
    COMMUTATOR = <<|,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.|&> (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overabove,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.<<| (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_below,
    COMMUTATOR = |>>,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.&<| (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overbelow,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);
CREATE OPERATOR sys.~= (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_same,
    COMMUTATOR = ~=,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.<-> (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_distance_centroid,
    COMMUTATOR = <->
);

-- GiST operator class
CREATE OPERATOR CLASS sys.gist_geography_ops_2d
    DEFAULT FOR TYPE sys.GEOGRAPHY USING gist AS
    STORAGE sys.box2df,
    OPERATOR  1  sys.<<(sys.GEOGRAPHY, sys.GEOGRAPHY)  ,
    OPERATOR  2  sys.&<(sys.GEOGRAPHY, sys.GEOGRAPHY)  ,
    OPERATOR  3  sys.&&(sys.GEOGRAPHY, sys.GEOGRAPHY)  ,
    OPERATOR  4  sys.&>(sys.GEOGRAPHY, sys.GEOGRAPHY)  ,
    OPERATOR  5  sys.>>(sys.GEOGRAPHY, sys.GEOGRAPHY)  ,
    OPERATOR  6  sys.~=(sys.GEOGRAPHY, sys.GEOGRAPHY)  ,
    OPERATOR  7  sys.~(sys.GEOGRAPHY, sys.GEOGRAPHY)   ,
    OPERATOR  8  sys.@(sys.GEOGRAPHY, sys.GEOGRAPHY)   ,
    OPERATOR  9  sys.&<|(sys.GEOGRAPHY, sys.GEOGRAPHY) ,
    OPERATOR 10  sys.<<|(sys.GEOGRAPHY, sys.GEOGRAPHY) ,
    OPERATOR 11  sys.|>>(sys.GEOGRAPHY, sys.GEOGRAPHY) ,
    OPERATOR 12  sys.|&>(sys.GEOGRAPHY, sys.GEOGRAPHY) ,
    OPERATOR 13  sys.<->(sys.GEOGRAPHY, sys.GEOGRAPHY) FOR ORDER BY pg_catalog.float_ops,
    FUNCTION  1  sys.geography_gist_consistent(internal, sys.GEOGRAPHY, smallint, oid, internal),
    FUNCTION  2  sys.geography_gist_union(bytea, internal),
    FUNCTION  3  sys.geography_gist_compress(internal),
    FUNCTION  4  sys.geography_gist_decompress(internal),
    FUNCTION  5  sys.geography_gist_penalty(internal, internal, internal),
    FUNCTION  6  sys.geography_gist_picksplit(internal, internal),
    FUNCTION  7  sys.geography_gist_same(sys.GEOGRAPHY, sys.GEOGRAPHY, internal),
    FUNCTION  8  sys.geography_gist_distance(internal, sys.GEOGRAPHY, smallint, oid, internal);

-- =============================================================
-- BABEL-6444: drop spatial *_helper functions that were converted
-- to native C / inlined wrappers. On a fresh install these no longer
-- exist; drop them on upgrade so an upgraded instance matches a fresh
-- install (otherwise pg_dump and upgrade dependency checks diverge).
-- =============================================================

-- Drops an object if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script.
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN

    query1 := pg_catalog.format('alter extension babelfishpg_common drop %s %s.%s', object_type, schema_name, object_name);
    query2 := pg_catalog.format('drop %s %s.%s', object_type, schema_name, object_name);

    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when undefined_function then --if 'Deprecated function does not exist'
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.bpcharToGeography_helper(sys.bpchar, integer) RENAME TO bpchartogeography_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bpchartogeography_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.charTogeoghelper(sys.bpchar) RENAME TO chartogeoghelper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'chartogeoghelper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.charTogeomhelper(sys.bpchar) RENAME TO chartogeomhelper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'chartogeomhelper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.geogfromtext_helper(text, integer) RENAME TO geogfromtext_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geogfromtext_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.GeographyAsTextbp_helper(sys.GEOGRAPHY, integer, boolean) RENAME TO geographyastextbp_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geographyastextbp_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.GeographyAsTextvar_helper(sys.GEOGRAPHY) RENAME TO geographyastextvar_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geographyastextvar_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.geomfromtext_helper(text, integer) RENAME TO geomfromtext_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geomfromtext_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.GeomPoint_helper(float8, float8, integer) RENAME TO geompoint_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geompoint_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.M_helper(sys.GEOMETRY) RENAME TO m_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'm_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.M_helper(sys.GEOGRAPHY) RENAME TO m_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'm_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.makevalid_helper(sys.GEOGRAPHY) RENAME TO makevalid_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'makevalid_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STArea_helper(sys.GEOMETRY) RENAME TO starea_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'starea_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STArea_helper(sys.GEOGRAPHY) RENAME TO starea_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'starea_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STAsText_common(sys.GEOGRAPHY) RENAME TO stastext_common_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stastext_common_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STAsText_helper(sys.GEOGRAPHY) RENAME TO stastext_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stastext_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STContains_helper(sys.GEOMETRY, sys.GEOMETRY) RENAME TO stcontains_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stcontains_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STContains_helper(sys.GEOGRAPHY, sys.GEOGRAPHY) RENAME TO stcontains_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stcontains_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STDimension_helper(sys.GEOMETRY) RENAME TO stdimension_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stdimension_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STDimension_helper(sys.GEOGRAPHY) RENAME TO stdimension_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stdimension_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STDisjoint_helper(sys.GEOMETRY, sys.GEOMETRY) RENAME TO stdisjoint_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stdisjoint_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STDisjoint_helper(sys.GEOGRAPHY, sys.GEOGRAPHY) RENAME TO stdisjoint_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stdisjoint_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STDistance_helper(sys.GEOMETRY, sys.GEOMETRY) RENAME TO stdistance_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stdistance_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STDistance_helper(sys.GEOGRAPHY, sys.GEOGRAPHY) RENAME TO stdistance_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stdistance_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STEquals_helper(sys.GEOMETRY, sys.GEOMETRY) RENAME TO stequals_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stequals_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STEquals_helper(sys.GEOGRAPHY, sys.GEOGRAPHY) RENAME TO stequals_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stequals_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STIntersects_helper(sys.GEOMETRY, sys.GEOMETRY) RENAME TO stintersects_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stintersects_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STIntersects_helper(sys.GEOGRAPHY, sys.GEOGRAPHY) RENAME TO stintersects_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stintersects_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STIsClosed_helper(sys.GEOMETRY) RENAME TO stisclosed_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stisclosed_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STIsClosed_helper(sys.GEOGRAPHY) RENAME TO stisclosed_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stisclosed_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STMakeValid_helper(sys.GEOMETRY) RENAME TO stmakevalid_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stmakevalid_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STNumPoints_helper(sys.GEOMETRY) RENAME TO stnumpoints_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stnumpoints_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STNumPoints_helper(sys.GEOGRAPHY) RENAME TO stnumpoints_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stnumpoints_helper_geog_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.varchar_helper(sys.GEOMETRY) RENAME TO varchar_helper_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'varchar_helper_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.Z_helper(sys.GEOMETRY) RENAME TO z_helper_geom_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'z_helper_geom_deprecated_5_7_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.Z_helper(sys.GEOGRAPHY) RENAME TO z_helper_geog_deprecated_5_7_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'z_helper_geog_deprecated_5_7_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);
