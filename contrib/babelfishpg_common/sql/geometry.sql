CREATE OR REPLACE FUNCTION sys.geometryin(cstring)
    RETURNS sys.GEOMETRY
    AS '$libdir/postgis-3', 'LWGEOM_in'
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
CREATE CAST (point AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(point);

CREATE OR REPLACE FUNCTION cust_stgeomfromtext(text, integer)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','LWGEOM_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.stgeomfromtext(text, integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		srid integer;
	BEGIN
		srid := $2;
		IF srid >= 0 AND srid <= 999999 THEN
			-- Call the underlying function after preprocessing
			RETURN (SELECT cust_stgeomfromtext($1, $2));
		ELSE
			RAISE EXCEPTION 'SRID value should be between 0 and 999999';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOMETRY)
	RETURNS TEXT
	AS '$libdir/postgis-3','LWGEOM_asText'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOMETRY)
	RETURNS text
	AS '$libdir/postgis-3','LWGEOM_to_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(bytea)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','LWGEOM_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOMETRY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_to_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(text)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','parse_WKT_lwgeom'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (text AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(text) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS text) WITH FUNCTION sys.text(sys.GEOMETRY) AS IMPLICIT;
CREATE CAST (bytea AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(bytea) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS bytea) WITH FUNCTION sys.bytea(sys.GEOMETRY) AS IMPLICIT;

-- Availability: 3.2.0 current supported in APG
CREATE OR REPLACE FUNCTION cust_Point(float8, float8, srid integer)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3', 'ST_Point'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.Point(float8, float8, srid integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		srid integer;
	BEGIN
		srid := $3;
		IF srid >= 0 AND srid <= 999999 THEN
			-- Call the underlying function after preprocessing
			RETURN (SELECT cust_Point($1, $2, $3));
		ELSE
			RAISE EXCEPTION 'SRID value should be between 0 and 999999';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOMETRY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_asBinary'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STPointFromText(text, integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		srid integer;
	BEGIN
		srid := $2;
		IF srid >= 0 AND srid <= 999999 THEN
			-- Call the underlying function after preprocessing
			RETURN (SELECT cust_stgeomfromtext($1, $2));
		ELSE
			RAISE EXCEPTION 'SRID value should be between 0 and 999999';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Minimum distance. 2D only.
CREATE OR REPLACE FUNCTION sys.STDistance(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3', 'ST_Distance'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.stx(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_x_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.sty(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_y_point'
	LANGUAGE 'c' IMMUTABLE STRICT;
	