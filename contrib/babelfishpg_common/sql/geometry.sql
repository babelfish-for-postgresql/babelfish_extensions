CREATE OR REPLACE FUNCTION sys.geometryin(cstring)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'geometry_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometryout(sys.GEOMETRY)
	RETURNS cstring
	AS '$libdir/postgis-3','LWGEOM_out'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometrytypmodin(cstring[])
	RETURNS integer
	AS '$libdir/postgis-3','geometry_typmod_in'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometrytypmodout(integer)
	RETURNS cstring
	AS '$libdir/postgis-3','postgis_typmod_out'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometryanalyze(internal)
	RETURNS bool
	AS '$libdir/postgis-3', 'gserialized_analyze_nd'
	LANGUAGE 'c' VOLATILE STRICT;

CREATE OR REPLACE FUNCTION sys.geometryrecv(internal)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','LWGEOM_recv'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geometrysend(sys.GEOMETRY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_send'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.GEOMETRY (
	INTERNALLENGTH = variable,
	INPUT = sys.geometryin,
	OUTPUT = sys.geometryout,
	SEND = sys.geometrysend,
	RECEIVE = sys.geometryrecv,
	TYPMOD_IN = sys.geometrytypmodin,
	TYPMOD_OUT = sys.geometrytypmodout,
	DELIMITER = ':',
	ALIGNMENT = double,
	ANALYZE = sys.geometryanalyze,
	STORAGE = main
);


CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.GEOMETRY, integer, boolean)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','geometry_enforce_typmod'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.GEOMETRY AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(sys.GEOMETRY, integer, boolean) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(point)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','point_to_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.point(sys.GEOMETRY)
	RETURNS point
	AS '$libdir/postgis-3','geometry_to_point'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.GEOMETRY AS point) WITH FUNCTION sys.point(sys.GEOMETRY);
-- CREATE CAST (point AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(point);

CREATE OR REPLACE FUNCTION sys.Geometry__stgeomfromtext(sys.NVARCHAR, integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stgeomfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOMETRY)
	RETURNS sys.NVARCHAR
	AS 'babelfishpg_common', 'st_as_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOMETRY)
	RETURNS text
	AS 'babelfishpg_common', 'bbf_geom_to_text_error'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOMETRY, integer, boolean)
	RETURNS sys.bpchar
	AS 'babelfishpg_common','geometry_asbpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bpchar)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geom_from_bpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOMETRY, integer, boolean)
	RETURNS sys.varchar
	AS 'babelfishpg_common', 'bbf_geom_asvarchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.varchar)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geom_from_varchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(bytea)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common','geometry_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;	

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOMETRY)
	RETURNS bytea
	AS 'babelfishpg_common','bytea_from_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bbf_varbinary)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geom_from_varbinary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOMETRY, integer, boolean)
    RETURNS sys.bbf_varbinary
    AS 'babelfishpg_common', 'bbf_geom_to_varbinary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bbf_binary)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geom_from_binary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(text, integer, boolean)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_text_to_geom_error'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.bbf_binary(sys.GEOMETRY, integer, boolean)
	RETURNS sys.bbf_binary
	AS 'babelfishpg_common', 'bbf_geom_to_binary'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (text AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(text, integer, boolean) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS text) WITH FUNCTION sys.text(sys.GEOMETRY);
CREATE CAST (sys.bpchar AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(sys.bpchar) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS sys.bpchar) WITH FUNCTION sys.bpchar(sys.GEOMETRY, integer, boolean);
CREATE CAST (sys.varchar AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(sys.varchar) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS sys.varchar) WITH FUNCTION sys.varchar(sys.GEOMETRY, integer, boolean);
CREATE CAST (bytea AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(bytea) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS bytea) WITH FUNCTION sys.bytea(sys.GEOMETRY);
CREATE CAST (sys.bbf_varbinary AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(sys.bbf_varbinary) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS sys.bbf_varbinary) WITH FUNCTION sys.bbf_varbinary(sys.GEOMETRY, integer, boolean);
CREATE CAST (sys.bbf_binary AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(sys.bbf_binary) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS sys.bbf_binary) WITH FUNCTION sys.bbf_binary(sys.GEOMETRY, integer, boolean);

-- Availability: 3.2.0 current supported in APG
CREATE OR REPLACE FUNCTION sys.Geometry__Point(float8, float8, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_point'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOMETRY)
	RETURNS sys.varbinary
	AS 'babelfishpg_common', 'st_as_binary_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STPointFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stpointfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STLineFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stlinefromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.Geometry__STPolyFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stpolyfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STMPointFromText(sys.NVARCHAR, srid integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_geometry_stmpointfromtext'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STMPointFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geometry_stmpointfromwkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.geomfromwkb_helper(bytea, integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'get_geometry_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_GeometryType(sys.GEOMETRY)
	RETURNS text
	AS '$libdir/postgis-3', 'geometry_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_zmflag(sys.GEOMETRY)
	RETURNS smallint
	AS '$libdir/postgis-3', 'LWGEOM_zmflag'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STArea(geom sys.GEOMETRY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_st_area'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STSrid(sys.GEOMETRY)
	RETURNS integer
	AS '$libdir/postgis-3','LWGEOM_get_srid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_contains'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
	RETURNS boolean
	AS 'babelfishpg_common', 'bbf_geom_op_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.ST_Equals,
    COMMUTATOR = =,
    RESTRICT = eqsel
);

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
	RETURNS boolean
	AS 'babelfishpg_common', 'bbf_geom_op_not_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<> (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.ST_NotEquals,
    COMMUTATOR = <>
);

-- STDimension
-- Retrieves spatial dimension
CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOMETRY)
	RETURNS integer
	AS 'babelfishpg_common', 'bbf_st_dimension'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
	
--STGeomType
CREATE OR REPLACE FUNCTION sys.STGeometryType(geom sys.GEOMETRY)
	RETURNS sys.NVARCHAR(4000)
	AS 'babelfishpg_common', 'bbf_st_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
--MAKE VALID
CREATE OR REPLACE FUNCTION sys.MakeValid(geom sys.GEOMETRY)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'bbf_st_makevalid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--Parse
CREATE OR REPLACE FUNCTION sys.Geometry__Parse(geometry_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geometry_parse'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STNumPoints
CREATE OR REPLACE FUNCTION sys.STNumPoints(geom sys.GEOMETRY)
    RETURNS integer
    AS 'babelfishpg_common', 'bbf_st_numpoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
	
-- STDisjoint
-- Checks if two geometries have no points in common
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_disjoint'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STIntersects
-- Checks if two geometries spatially intersect
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_intersects'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STIsClosed
-- Checks if geometry is closed
CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_st_isclosed'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Minimum distance. 2D only.
CREATE OR REPLACE FUNCTION sys.STDistance(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_st_distance'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.stx(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_x_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.sty(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_y_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- STIsEmpty
-- Checks if geometry is empty
CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STIsValid
-- Checks if geometry is valid 
CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- HasZ
-- Checks if a geometry instance has Z coordinates
-- Returns 1 if the geometry has Z values, 0 otherwise
CREATE OR REPLACE FUNCTION sys.HasZ(geom sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_hasz'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- HasM
-- Checks if a geometry instance has M coordinates (measure values)
-- Returns 1 if the geometry has M values, 0 otherwise
CREATE OR REPLACE FUNCTION sys.HasM(geom sys.GEOMETRY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_hasm'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
-- Z
-- Returns the Z coordinate value for a point geometry instance
CREATE OR REPLACE FUNCTION sys.Z(geom sys.GEOMETRY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_z'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- M
-- Returns the M coordinate value (measure) for a point geometry instance
CREATE OR REPLACE FUNCTION sys.M(geom sys.GEOMETRY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_m'
	LANGUAGE 'c' IMMUTABLE STRICT;


