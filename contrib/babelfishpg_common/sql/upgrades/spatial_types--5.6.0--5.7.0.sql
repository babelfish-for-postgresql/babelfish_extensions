-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

-- =============================================================
-- GEOMETRY
-- =============================================================

-- Predicates
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_st_intersects'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_st_contains'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_st_equals'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_st_disjoint'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDistance(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
    RETURNS float8
    AS 'babelfishpg_common', 'bbf_st_distance'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Unary functions
CREATE OR REPLACE FUNCTION sys.STArea(geom sys.GEOMETRY)
    RETURNS float8
    AS 'babelfishpg_common', 'bbf_st_area'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STNumPoints(geom sys.GEOMETRY)
    RETURNS integer
    AS 'babelfishpg_common', 'bbf_st_numpoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOMETRY)
    RETURNS integer
    AS 'babelfishpg_common', 'bbf_st_dimension'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOMETRY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_st_isclosed'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.MakeValid(geom sys.GEOMETRY)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_st_makevalid'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STGeometryType(geom sys.GEOMETRY)
    RETURNS sys.NVARCHAR(4000)
    AS 'babelfishpg_common', 'bbf_st_geometrytype'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.HasZ(geom sys.GEOMETRY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_hasz'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.HasM(geom sys.GEOMETRY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_hasm'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Z(geom sys.GEOMETRY)
    RETURNS float8
    AS 'babelfishpg_common', 'bbf_z'
    LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.M(geom sys.GEOMETRY)
    RETURNS float8
    AS 'babelfishpg_common', 'bbf_m'
    LANGUAGE 'c' IMMUTABLE STRICT;

-- Constructors
CREATE OR REPLACE FUNCTION sys.Geometry__Parse(geometry_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geometry_parse'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__Point(float8, float8, srid integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geometry_point'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__stgeomfromtext(sys.NVARCHAR, integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_geometry_stgeomfromtext'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

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

-- Operator wrappers
CREATE OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
    RETURNS boolean
    AS 'babelfishpg_common', 'bbf_geom_op_equals'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
    RETURNS boolean
    AS 'babelfishpg_common', 'bbf_geom_op_not_equals'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Cast functions
CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOMETRY, integer, boolean)
    RETURNS sys.bpchar
    AS 'babelfishpg_common', 'geometry_asbpchar'
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

CREATE OR REPLACE FUNCTION sys.bbf_binary(sys.GEOMETRY, integer, boolean)
    RETURNS sys.bbf_binary
    AS 'babelfishpg_common', 'bbf_geom_to_binary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOMETRY)
    RETURNS text
    AS 'babelfishpg_common', 'bbf_geom_to_text_error'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(text, integer, boolean)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'bbf_text_to_geom_error'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;


-- =============================================================
-- GEOGRAPHY
-- =============================================================

-- Predicates
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_geog_intersects'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_geog_contains'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_geog_equals'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_geog_disjoint'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDistance(geog1 sys.GEOGRAPHY, geog2 sys.GEOGRAPHY)
    RETURNS float8
    AS 'babelfishpg_common', 'bbf_geog_distance'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Unary functions
CREATE OR REPLACE FUNCTION sys.STArea(geom sys.GEOGRAPHY)
    RETURNS float8
    AS 'babelfishpg_common', 'bbf_geog_area'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STNumPoints(geog sys.GEOGRAPHY)
    RETURNS integer
    AS 'babelfishpg_common', 'bbf_geog_numpoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOGRAPHY)
    RETURNS integer
    AS 'babelfishpg_common', 'bbf_geog_dimension'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOGRAPHY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_geog_isclosed'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.MakeValid(geog sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geog_makevalid'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STGeometryType(geog sys.GEOGRAPHY)
    RETURNS sys.NVARCHAR(4000)
    AS 'babelfishpg_common', 'bbf_st_geometrytype'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.HasZ(geog sys.GEOGRAPHY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_hasz'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.HasM(geog sys.GEOGRAPHY)
    RETURNS sys.BIT
    AS 'babelfishpg_common', 'bbf_hasm'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Z(geom sys.GEOGRAPHY)
    RETURNS float8
    AS 'babelfishpg_common', 'bbf_z'
    LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.M(geom sys.GEOGRAPHY)
    RETURNS float8
    AS 'babelfishpg_common', 'bbf_m'
    LANGUAGE 'c' IMMUTABLE STRICT;

-- Constructors
CREATE OR REPLACE FUNCTION sys.Geography__Parse(geography_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_parse'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__stgeomfromtext(sys.NVARCHAR, integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_stgeomfromtext'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STPointFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_stpointfromtext'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STLineFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_stlinefromtext'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STPolyFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_stpolyfromtext'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STMPointFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_stmpointfromtext'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STMPointFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_stmpointfromwkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

-- Operator wrappers
CREATE OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
    RETURNS boolean
    AS 'babelfishpg_common', 'bbf_geog_op_equals'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
    RETURNS boolean
    AS 'babelfishpg_common', 'bbf_geog_op_not_equals'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Display + cast functions
CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOGRAPHY)
    RETURNS sys.NVARCHAR
    AS 'babelfishpg_common', 'bbf_geog_astext'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOGRAPHY, integer, boolean)
    RETURNS sys.bpchar
    AS 'babelfishpg_common', 'bbf_geog_asbpchar'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bpchar)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geog_from_bpchar'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOGRAPHY, integer, boolean)
    RETURNS sys.varchar
    AS 'babelfishpg_common', 'bbf_geog_asvarchar'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.varchar)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geog_from_varchar'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bbf_varbinary)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geog_from_varbinary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY, integer, boolean)
    RETURNS sys.bbf_varbinary
    AS 'babelfishpg_common', 'bbf_geog_to_varbinary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bbf_binary)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geog_from_binary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_binary(sys.GEOGRAPHY, integer, boolean)
    RETURNS sys.bbf_binary
    AS 'babelfishpg_common', 'bbf_geog_to_binary'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOGRAPHY)
    RETURNS text
    AS 'babelfishpg_common', 'bbf_geog_to_text_error'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(text, integer, boolean)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_text_to_geog_error'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
