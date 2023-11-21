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

CREATE OR REPLACE FUNCTION sys.Geometry__stgeomfromtext(text, integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		srid integer;
		Geomtype text;
		geom sys.GEOMETRY; 
	BEGIN
		srid := $2;
		IF srid >= 0 AND srid <= 999999 THEN
			-- Call the underlying function after preprocessing
			geom = (SELECT sys.stgeomfromtext_helper($1, $2));
			Geomtype = (SELECT sys.ST_GeometryType(geom));
			IF Geomtype = 'ST_Point' THEN
				IF (SELECT sys.ST_Zmflag(geom)) = 1 OR (SELECT sys.ST_Zmflag(geom)) = 2 OR (SELECT sys.ST_Zmflag(geom)) = 3 THEN
					RAISE EXCEPTION 'Unsupported flags';
				ELSE
					RETURN geom;
				END IF;
			ELSE
				RAISE EXCEPTION '% is not supported', Geomtype;
			END IF;
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
    AS $$
    DECLARE
        len integer;
        varBin bytea;
		geomType bytea;
		srid integer;
		byte_position integer := 6;
		coord_NaN bytea := E'\\x000000000000f87f';
		input_coord bytea;
		isNaN integer = 0;
        newVarBin bytea;
    BEGIN
        varBin := $1;
        len := LENGTH(varBin);
        IF len >= 22 THEN
			-- We are preprocessing it by removing 2 constant Geometry Type bytes -> 01 0c (for 2-D Point Type)
			-- Then adding 5 Bytes -> 01 (little endianess) + 4 Bytes (Geometry Type)
			srid := (get_byte(varBin, 3) << 24) | (get_byte(varBin, 2) << 16) | (get_byte(varBin, 1) << 8) | get_byte(varBin, 0);
			WHILE byte_position < len LOOP
				-- Get the coordinate to check if it is NaN
				input_coord := substring(varBin from byte_position + 1 for 8);
				IF encode(input_coord, 'hex') = encode(coord_NaN, 'hex') THEN
					isNaN := 1;
				END IF;
				byte_position := byte_position + 8;
			END LOOP;
			geomType := substring(varBin from 5 for 2);
            varBin := substring(varBin from 1 for 4) || substring(varBin from 7);
			IF srid >= 0 AND srid <= 999999 AND isNaN = 0 THEN
				IF encode(geomType, 'hex') = encode(E'\\x010c', 'hex') THEN
					newVarBin := E'\\x0101000020' || varBin;
				ELSE
					RAISE EXCEPTION 'Unsupported geometry type';
				END IF;
			ELSE
				RAISE EXCEPTION 'Error converting data type varbinary to geometry.';
			END IF;
            -- Call the underlying function after preprocessing
            RETURN (SELECT sys.GEOMETRY_helper(newVarBin)); 
        ELSE
            RAISE EXCEPTION 'Invalid Geometry';
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOMETRY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_to_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bbf_varbinary)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
        varBin bytea;
	BEGIN
		varBin := (SELECT CAST ($1 AS bytea));
		-- Call the underlying function after preprocessing
		RETURN (SELECT CAST (varBin AS GEOMETRY)); 
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOMETRY)
	RETURNS sys.bbf_varbinary
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
CREATE CAST (sys.bbf_varbinary AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(sys.bbf_varbinary) AS IMPLICIT;
CREATE CAST (sys.GEOMETRY AS sys.bbf_varbinary) WITH FUNCTION sys.bbf_varbinary(sys.GEOMETRY) AS IMPLICIT;

-- Availability: 3.2.0 current supported in APG
CREATE OR REPLACE FUNCTION sys.Geometry__Point(float8, float8, srid integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		srid integer;
	BEGIN
		srid := $3;
		IF srid >= 0 AND srid <= 999999 THEN
			-- Call the underlying function after preprocessing
			RETURN (SELECT sys.GeomPoint_helper($1, $2, $3));
		ELSE
			RAISE EXCEPTION 'SRID value should be between 0 and 999999';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOMETRY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_asBinary'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STPointFromText(text, integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		srid integer;
		Geomtype text;
		geom sys.GEOMETRY;
	BEGIN
		srid := $2;
		IF srid >= 0 AND srid <= 999999 THEN
			-- Call the underlying function after preprocessing
			geom = (SELECT sys.stgeomfromtext_helper($1, $2));
			Geomtype = (SELECT sys.ST_GeometryType(geom));
			IF Geomtype = 'ST_Point' THEN
				IF (SELECT sys.ST_Zmflag(geom)) = 1 OR (SELECT sys.ST_Zmflag(geom)) = 2 OR (SELECT sys.ST_Zmflag(geom)) = 3 THEN
					RAISE EXCEPTION 'Unsupported flags';
				ELSE
					RETURN geom;
				END IF;
			ELSE
				RAISE EXCEPTION '% is not supported', Geomtype;
			END IF;
		ELSE
			RAISE EXCEPTION 'SRID value should be between 0 and 999999';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_GeometryType(sys.GEOMETRY)
	RETURNS text
	AS '$libdir/postgis-3', 'geometry_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_zmflag(sys.GEOMETRY)
	RETURNS smallint
	AS '$libdir/postgis-3', 'LWGEOM_zmflag'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

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

-- Helper functions for main T-SQL functions
CREATE OR REPLACE FUNCTION sys.stgeomfromtext_helper(text, integer)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','LWGEOM_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GeomPoint_helper(float8, float8, srid integer)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3', 'ST_Point'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.GEOMETRY_helper(bytea)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3','LWGEOM_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

