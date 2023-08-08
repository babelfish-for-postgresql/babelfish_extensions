CREATE OR REPLACE FUNCTION sys.geographyin(cstring, oid, integer)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3','geography_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographyout(sys.GEOGRAPHY)
    RETURNS cstring
    AS '$libdir/postgis-3','geography_out'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographytypmodin(cstring[])
    RETURNS integer
    AS '$libdir/postgis-3','geometry_typmod_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographytypmodout(integer)
    RETURNS cstring
    AS '$libdir/postgis-3','postgis_typmod_out'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographyrecv(internal, oid, integer)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3','geography_recv'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.geographysend(sys.GEOGRAPHY)
    RETURNS bytea
    AS '$libdir/postgis-3','geography_send'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

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
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.GEOGRAPHY AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.GEOGRAPHY, integer, boolean) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(bytea)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','geography_from_binary'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOGRAPHY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_to_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (bytea AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(bytea) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS bytea) WITH FUNCTION sys.bytea(sys.GEOGRAPHY) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.GEOMETRY)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','geography_from_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.GEOMETRY AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.GEOMETRY) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.GEOGRAPHY)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','geometry_from_geography'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.GEOGRAPHY AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(sys.GEOGRAPHY) ;

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOGRAPHY)
	RETURNS TEXT
	AS '$libdir/postgis-3','LWGEOM_asText'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOGRAPHY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_asBinary'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

-- Minimum distance. 2D only.
CREATE OR REPLACE FUNCTION sys.STDistance(geog1 sys.GEOGRAPHY, geog2 sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3', 'ST_Distance'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.long(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_x_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.lat(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_y_point'
	LANGUAGE 'c' IMMUTABLE STRICT;  