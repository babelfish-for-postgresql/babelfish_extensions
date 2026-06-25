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


CREATE TYPE sys.GEOGRAPHY (
    INTERNALLENGTH = variable,
    INPUT          = sys.geographyin,
    OUTPUT         = sys.geographyout,
    RECEIVE        = sys.geographyrecv,
    SEND           = sys.geographysend,
    TYPMOD_IN      = sys.geographytypmodin,
    TYPMOD_OUT     = sys.geographytypmodout,
    DELIMITER      = ':', 
    ANALYZE        = sys.geographyanalyze,
    STORAGE        = main, 
    ALIGNMENT      = double
);

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','geography_enforce_typmod'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE CAST (sys.GEOGRAPHY AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.GEOGRAPHY, integer, boolean) AS IMPLICIT;

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

CREATE CAST (text AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(text, integer, boolean) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS text) WITH FUNCTION sys.text(sys.GEOGRAPHY);
CREATE CAST (sys.bpchar AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bpchar) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.bpchar) WITH FUNCTION sys.bpchar(sys.GEOGRAPHY, integer, boolean);
CREATE CAST (sys.varchar AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.varchar) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.varchar) WITH FUNCTION sys.varchar(sys.GEOGRAPHY, integer, boolean);
CREATE CAST (sys.bbf_binary AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bbf_binary) AS IMPLICIT;
CREATE CAST (bytea AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(bytea) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS bytea) WITH FUNCTION sys.bytea(sys.GEOGRAPHY);
CREATE CAST (sys.bbf_varbinary AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bbf_varbinary) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.bbf_varbinary) WITH FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY, integer, boolean);
CREATE CAST (sys.GEOGRAPHY AS sys.bbf_binary) WITH FUNCTION sys.bbf_binary(sys.GEOGRAPHY, integer, boolean);

-- This Function Flips the Coordinates of the Point (x, y) -> (y, x)
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

CREATE OR REPLACE FUNCTION sys.Geography__STMLineFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'geography_mlinestring_from_text'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STMLineFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'geography_mlinestring_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

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

CREATE OPERATOR sys.= (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.ST_Equals,
    COMMUTATOR = =,
    RESTRICT = eqsel
);

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
	RETURNS boolean
	AS 'babelfishpg_common', 'bbf_geog_op_not_equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OPERATOR sys.<> (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.ST_NotEquals,
    COMMUTATOR = <>
);

-- STDimension
-- Retrieves spatial dimension
CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOGRAPHY)
	RETURNS integer
	AS 'babelfishpg_common', 'bbf_geog_dimension'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

--MAKEVALID
CREATE OR REPLACE FUNCTION sys.MakeValid(geog sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geog_makevalid'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

--STNumPoints
CREATE OR REPLACE FUNCTION sys.STNumPoints(geog sys.GEOGRAPHY)
	RETURNS integer
	AS 'babelfishpg_common', 'bbf_geog_numpoints'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

--Parse
CREATE OR REPLACE FUNCTION sys.Geography__Parse(geography_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'bbf_geography_parse'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;
--STGeomType
CREATE OR REPLACE FUNCTION sys.STGeometryType(geog sys.GEOGRAPHY)
	RETURNS sys.NVARCHAR(4000)
	AS 'babelfishpg_common', 'bbf_st_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;
-- STDisjoint
-- Checks if two geometries have no points in common
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_geog_disjoint'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

-- STIntersects
-- Checks if two geometries spatially intersect
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_geog_intersects'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_geog_isclosed'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

-- Minimum distance
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

-- STIsEmpty
-- Checks if geometry is empty
CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

-- STIsValid
-- Checks if geometry is valid 
CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;


-- HasZ
-- Checks if a geography instance has Z coordinates
-- Returns 1 if the geography has Z values, 0 otherwise
CREATE OR REPLACE FUNCTION sys.HasZ(geog sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_hasz'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

-- HasM
-- Checks if a geography instance has M coordinates (measure values)
-- Returns 1 if the geography has M values, 0 otherwise
CREATE OR REPLACE FUNCTION sys.HasM(geog sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS 'babelfishpg_common', 'bbf_hasm'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE COST 100;

-- Z
-- Returns the Z coordinate value for a point geography instance
CREATE OR REPLACE FUNCTION sys.Z(geom sys.GEOGRAPHY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_z'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- M
-- Returns the M coordinate value (measure) for a point geography instance
CREATE OR REPLACE FUNCTION sys.M(geom sys.GEOGRAPHY)
	RETURNS float8
	AS 'babelfishpg_common', 'bbf_m'
	LANGUAGE 'c' IMMUTABLE STRICT;

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
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overlaps,
    COMMUTATOR = &&,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.~ (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_contains,
    COMMUTATOR = @,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.@ (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
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
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_same,
    COMMUTATOR = ~=,
    RESTRICT = sys.geography_gist_sel,
    JOIN = sys.geography_gist_joinsel
);

CREATE OPERATOR sys.<-> (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
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
-- Retained helper functions (BABEL-6444)
-- These inner helpers are no longer called by the native-C wrappers above,
-- but are kept as catalog objects so a fresh install matches an instance
-- upgraded from a prior release (where these functions already exist).
-- Do not remove without also dropping them in the upgrade path.
-- =============================================================

CREATE OR REPLACE FUNCTION sys.bpcharToGeography_helper(sys.bpchar, integer)
 RETURNS sys.GEOGRAPHY
 AS '$libdir/postgis-3','LWGEOM_from_text'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.charTogeoghelper(sys.bpchar)
 RETURNS sys.GEOGRAPHY
 AS 'babelfishpg_common', 'charTogeog'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geogfromtext_helper(text, integer)
 RETURNS sys.GEOGRAPHY
 AS 'babelfishpg_common', 'get_geography_from_text'
 LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GeographyAsTextbp_helper(sys.GEOGRAPHY, integer, boolean)
 RETURNS sys.bpchar
 AS 'babelfishpg_common', 'geometry_asbpchar'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GeographyAsTextvar_helper(sys.GEOGRAPHY)
 RETURNS sys.varchar
 AS 'babelfishpg_common', 'geometry_astext'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.makevalid_helper(geog sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3', 'ST_MakeValid'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.M_helper(sys.GEOGRAPHY)
 RETURNS float8
 AS '$libdir/postgis-3','LWGEOM_m_point'
 LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.STArea_helper(sys.GEOGRAPHY)
 RETURNS float8
 AS '$libdir/postgis-3','ST_Area'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText_common(sys.GEOGRAPHY)
 RETURNS sys.NVARCHAR
 AS 'babelfishpg_common', 'st_as_text'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText_helper(sys.GEOGRAPHY)
 RETURNS TEXT
 AS '$libdir/postgis-3','LWGEOM_asText'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STContains_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
 RETURNS sys.BIT
 AS '$libdir/postgis-3','within'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDimension_helper(sys.GEOGRAPHY)
        RETURNS integer
        AS '$libdir/postgis-3','LWGEOM_dimension'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','disjoint'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDistance_helper(geog1 sys.GEOGRAPHY, geog2 sys.GEOGRAPHY)
 RETURNS float8
 AS '$libdir/postgis-3', 'LWGEOM_distance_ellipsoid'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
 RETURNS sys.BIT
 AS '$libdir/postgis-3','ST_Equals'
 LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIntersects_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','ST_Intersects'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed_helper(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STNumPoints_helper(sys.GEOGRAPHY)
    RETURNS integer
    AS '$libdir/postgis-3', 'LWGEOM_npoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Z_helper(sys.GEOGRAPHY)
 RETURNS float8
 AS '$libdir/postgis-3','LWGEOM_z_point'
 LANGUAGE 'c' IMMUTABLE STRICT;
