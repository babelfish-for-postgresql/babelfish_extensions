-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
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
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overlaps,
    COMMUTATOR = &&,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.~ (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_contains,
    COMMUTATOR = @,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.@ (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_within,
    COMMUTATOR = ~,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.<< (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_left
);

CREATE OPERATOR sys.&< (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overleft
);

CREATE OPERATOR sys.>> (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_right
);

CREATE OPERATOR sys.&> (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overright
);

CREATE OPERATOR sys.|>> (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_above
);

CREATE OPERATOR sys.|&> (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overabove
);

CREATE OPERATOR sys.<<| (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_below
);

CREATE OPERATOR sys.&<| (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_overbelow
);

CREATE OPERATOR sys.~= (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.geometry_same,
    COMMUTATOR = ~=,
    RESTRICT = sys.gserialized_gist_sel_2d,
    JOIN = sys.gserialized_gist_joinsel_2d
);

CREATE OPERATOR sys.<-> (
    LEFTARG = sys.GEOMETRY, RIGHTARG = sys.GEOMETRY,
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
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_left
);

CREATE OPERATOR sys.&< (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overleft
);

CREATE OPERATOR sys.>> (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_right
);

CREATE OPERATOR sys.&> (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overright
);

CREATE OPERATOR sys.|>> (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_above
);

CREATE OPERATOR sys.|&> (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overabove
);

CREATE OPERATOR sys.<<| (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_below
);

CREATE OPERATOR sys.&<| (
    LEFTARG = sys.GEOGRAPHY, RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.geography_overbelow
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


