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
CREATE CAST (point AS sys.GEOMETRY) WITH FUNCTION sys.GEOMETRY(point);

CREATE OR REPLACE FUNCTION sys.Geometry__stgeomfromtext(sys.NVARCHAR, integer)
	RETURNS sys.GEOMETRY
	AS $$
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geometry::STGeomFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		RETURN (SELECT sys.geomfromtext_helper($1::text, $2));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOMETRY)
	RETURNS sys.NVARCHAR
	AS 'babelfishpg_common', 'st_as_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOMETRY)
	RETURNS text
	AS $$
	BEGIN
		RAISE EXCEPTION 'Explicit Conversion from data type sys.Geometry to Text is not allowed.';
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOMETRY, integer, boolean)
	RETURNS sys.bpchar
	AS 'babelfishpg_common','geometry_asbpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bpchar)
	RETURNS sys.GEOMETRY
	AS $$
	BEGIN
		RETURN (SELECT sys.charTogeomhelper($1));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOMETRY, integer, boolean)
	RETURNS sys.varchar
	AS $$
	DECLARE
		str_notation sys.varchar;
	BEGIN
		str_notation := (SELECT sys.varchar_helper($1));
		IF pg_catalog.length(str_notation) + 4 > $2 AND $2 != -1 THEN
			RAISE EXCEPTION 'There is insufficient result space to convert a geometry value to varchar/nvarchar.';
		END IF;
		RETURN str_notation;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.varchar)
	RETURNS sys.GEOMETRY
	AS $$
	BEGIN
		RETURN (SELECT sys.charTogeomhelper($1));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

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
    AS $$
    DECLARE
        varBin bytea;
    BEGIN
        varBin := (SELECT CAST ($1 AS bytea));
        -- Call the underlying function after preprocessing
        RETURN (SELECT sys.GEOMETRY(varBin)); 
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOMETRY, integer, boolean)
    RETURNS sys.bbf_varbinary
    AS $$
    DECLARE
        byte bytea;
    BEGIN
        byte := (SELECT sys.bytea($1));
        IF pg_catalog.length(byte) + 4 > $2 AND $2 != -1 THEN
            RAISE EXCEPTION 'Error converting sys.geometry to binary. The result would be truncated.';
        END IF;
        RETURN (SELECT CAST (byte AS sys.bbf_varbinary)); 
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(sys.bbf_binary)
    RETURNS sys.GEOMETRY
    AS $$
    DECLARE
        varBin sys.bbf_varbinary;
    BEGIN
        varBin := (SELECT CAST ($1 AS sys.bbf_varbinary));
        -- Call the underlying function after preprocessing
        RETURN (SELECT sys.GEOMETRY(varBin)); 
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(text, integer, boolean)
	RETURNS sys.GEOMETRY
	AS $$
	BEGIN
		IF $3 = true THEN
			RAISE EXCEPTION 'Explicit Conversion from data type Text to sys.Geometry is not allowed.';
		ELSE
			RAISE EXCEPTION 'Implicit Conversion from data type Text to sys.Geometry is not allowed.';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_binary(sys.GEOMETRY, integer, boolean)
	RETURNS sys.bbf_binary
	AS $$
	DECLARE
		byte bytea;
	BEGIN
		byte := (SELECT sys.bytea($1));
		IF pg_catalog.length(byte) + 4 = $2 THEN
			RETURN (SELECT CAST (byte AS sys.bbf_binary));
		ELSEIF pg_catalog.length(byte) + 4 > $2 THEN
			RAISE EXCEPTION 'Error converting sys.geometry to binary. The result would be truncated.';
		ELSE
			RAISE EXCEPTION 'Error converting sys.geometry to fixed length binary type. The result would be padded and cannot be converted back.';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

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
	AS $$
	BEGIN
		IF $1 is NULL THEN
			RAISE EXCEPTION '''geometry::Point'' failed because parameter 1 is not allowed to be null.';
		ELSEIF $2 is NULL THEN
			RAISE EXCEPTION '''geometry::Point'' failed because parameter 2 is not allowed to be null.';
		ELSEIF srid is NULL THEN
			RAISE EXCEPTION '''geometry::Point'' failed because parameter 3 is not allowed to be null.';
		ELSEIF srid >= 0 AND srid <= 999999 THEN
			-- Call the underlying function after preprocessing
			RETURN (SELECT sys.GeomPoint_helper($1, $2, $3));
		ELSE
			RAISE EXCEPTION 'SRID value should be between 0 and 999999';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOMETRY)
	RETURNS sys.varbinary
	AS 'babelfishpg_common', 'st_as_binary_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STPointFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOMETRY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geometry::STPointFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geomfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Point' THEN
				RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "POINT" at Position 1. The input has %', $1;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STLineFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOMETRY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geometry::STLineFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geomfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_LineString' THEN
				RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "LINESTRING" at Position 1. The input has %', $1;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STPolyFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOMETRY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geometry::STPolyFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geomfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Polygon' THEN
			RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "POLYGON" at Position 1. The input has %', $1;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STMPointFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOMETRY
    AS $$
    DECLARE
        Geomtype text;
        geom sys.GEOMETRY;
    BEGIN
        IF $2 IS NULL THEN
            RAISE EXCEPTION '''geometry::STMPointFromText'' failed because parameter 2 is not allowed to be null.';
        ELSIF $1 IS NULL THEN
            RETURN NULL;
        END IF;

        geom = sys.geomfromtext_helper($1, $2);
        Geomtype = sys.ST_GeometryType(geom);

        IF Geomtype = 'ST_MultiPoint' THEN
            RETURN geom;
        ELSE
            RAISE EXCEPTION 'Expected "MULTIPOINT" at position 1. The input has %', $1;
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STMPointFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOMETRY
    AS $$
    DECLARE
        Geomtype text;
        geom sys.GEOMETRY;
    BEGIN
        IF $2 IS NULL THEN
            RAISE EXCEPTION '''geometry::STMPointFromWKB'' failed because parameter 2 is not allowed to be null.';
        ELSIF $1 IS NULL THEN
            RETURN NULL;
        END IF;

        geom = sys.geomfromwkb_helper($1::bytea, $2);
        Geomtype = sys.ST_GeometryType(geom);

        IF Geomtype = 'ST_MultiPoint' THEN
            RETURN geom;
        ELSE
            RAISE EXCEPTION 'Expected "MULTIPOINT" at position 1. The input has %', Geomtype;
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;


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
	AS $$
	BEGIN
		IF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'The geometry instance is not valid';
		ELSE
			RETURN sys.STArea_helper(geom);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STSrid(sys.GEOMETRY)
	RETURNS integer
	AS '$libdir/postgis-3','LWGEOM_get_srid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom2) = 0 THEN
			RAISE EXCEPTION 'The geometry instance is not valid';
		ELSE
			Return sys.STEquals_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom2) = 0 THEN
			RAISE EXCEPTION 'The geometry instance is not valid';
		ELSE
			Return sys.STContains_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
	RETURNS boolean
	AS $$
	DECLARE
		Result integer;
	BEGIN
		Result := STEquals(leftarg,rightarg);
		IF Result IS NULL THEN
			RETURN false;
		END IF;
		RETURN Result;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.GEOMETRY,
    RIGHTARG = sys.GEOMETRY,
    FUNCTION = sys.ST_Equals,
    COMMUTATOR = =,
    RESTRICT = eqsel
);

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
	RETURNS boolean
	AS $$
	DECLARE
		Result integer;
	BEGIN
		Result := STEquals(leftarg,rightarg);
		IF Result IS NULL THEN
			RETURN true;
		END IF;
		RETURN 1 - Result;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

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
	AS $$ 
	BEGIN
		IF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'The geometry instance is not valid';
		-- Check if the geometry is empty
		ELSEIF STIsEmpty(geom) = 1 THEN  
			RETURN -1;
		ELSE
			RETURN sys.STDimension_helper($1);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
	
--STGeomType
CREATE OR REPLACE FUNCTION sys.STGeometryType(geom sys.GEOMETRY)
	RETURNS sys.NVARCHAR(4000)
	AS $$
	DECLARE
		geom_type text;
	BEGIN
		IF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'This operation cannot be completed because the instance is not valid';
		END IF;
		
		geom_type := sys.ST_GeometryType(geom);
		
		IF geom_type LIKE 'ST\_%' ESCAPE '\' THEN
			RETURN substr(geom_type, 4);
		END IF;
		
	 	RAISE EXCEPTION 'Unexpected geometry type format: %. Expected ST_* prefix.', geom_type;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

--MAKE VALID
CREATE OR REPLACE FUNCTION sys.MakeValid(geom sys.GEOMETRY)
	RETURNS sys.GEOMETRY
	AS $$
	BEGIN
    	IF sys.STIsEmpty(geom) = 1 THEN
        	RETURN geom;
    	ELSEIF sys.STIsValid(geom) = 1 THEN 
        	RETURN geom;
    	ELSE
    		RETURN sys.STMakeValid_helper(geom);
    	END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

--Parse
CREATE OR REPLACE FUNCTION sys.Geometry__Parse(geometry_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOMETRY
    AS $$
    BEGIN
	    IF UPPER(geometry_tagged_text COLLATE sys.DATABASE_DEFAULT) = 'NULL' THEN
            RETURN NULL;
        END IF;

        RETURN sys.geomfromtext_helper(geometry_tagged_text, 0);
    END;
    $$ LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

--STNumPoints
CREATE OR REPLACE FUNCTION sys.STNumPoints(geom sys.GEOMETRY)
    RETURNS integer
    AS $$
    BEGIN
        IF STIsValid(geom) = 0 THEN
            RAISE EXCEPTION 'The geometry instance is not valid';
        ELSE
            RETURN sys.STNumPoints_helper(geom);
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
	
-- STDisjoint
-- Checks if two geometries have no points in common
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		--Check if the SRIDs do not match
		IF sys.STSrid(geom1) != sys.STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom2) = 0 THEN
			RAISE EXCEPTION 'The geometry instance is not valid';
		ELSE 
			RETURN sys.STDisjoint_helper($1, $2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- STIntersects
-- Checks if two geometries spatially intersect
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		--Check if the SRIDs do not match
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom2) = 0 THEN
			RAISE EXCEPTION 'The geometry instance is not valid';
		ELSE
			RETURN sys.STIntersects_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE; 

-- STIsClosed
-- Checks if geometry is closed
CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOMETRY)
	RETURNS sys.BIT
	AS $$
	DECLARE
		geom_type text;
	BEGIN
		-- Get the geometry type
		geom_type := ST_GeometryType(geom); 
		-- Check if any figures of the geometry instance are points
		IF geom_type = 'ST_Point' THEN
			RETURN 0;
		ELSIF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'The geometry instance is not valid';
		END IF; 
   
		RETURN sys.STIsClosed_helper(geom);
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Minimum distance. 2D only.
CREATE OR REPLACE FUNCTION sys.STDistance(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS float8
	AS $$
	BEGIN
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsEmpty(geom1) = 1 OR STIsEmpty(geom1) = 1  THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom1) = 0 THEN
			RAISE EXCEPTION 'The geometry instance is not valid';
		ELSE
			Return sys.STDistance_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDistance_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3', 'ST_Distance'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_Expand(geom sys.GEOMETRY, distance float8)
    RETURNS sys.GEOMETRY
    AS '$libdir/postgis-3', 'LWGEOM_expand'
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE;

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
	AS $$
	DECLARE
		Zmflag smallint;
	BEGIN
		Zmflag = (SELECT sys.ST_Zmflag(geom));
		-- If Zmflag = 1, then the geometry has M values
		-- If Zmflag = 2, then the geometry has Z values
		-- If Zmflag = 3, then the geometry has Z and M values
		IF Zmflag = 2 OR Zmflag = 3 THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- HasM
-- Checks if a geometry instance has M coordinates (measure values)
-- Returns 1 if the geometry has M values, 0 otherwise
CREATE OR REPLACE FUNCTION sys.HasM(geom sys.GEOMETRY)
	RETURNS sys.BIT
	AS $$
	DECLARE
		Zmflag smallint;
	BEGIN
		Zmflag = (SELECT sys.ST_Zmflag(geom));
		-- If Zmflag = 1, then the geometry has M values
		-- If Zmflag = 2, then the geometry has Z values
		-- If Zmflag = 3, then the geometry has Z and M values
		IF Zmflag = 1 OR Zmflag = 3 THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Z
-- Returns the Z coordinate value for a point geometry instance
CREATE OR REPLACE FUNCTION sys.Z(geom sys.GEOMETRY)
	RETURNS float8
	AS $$
    DECLARE
        Geomtype text;
    BEGIN
		Geomtype := ST_GeometryType(geom); 

        IF Geomtype = 'ST_Point' THEN
            RETURN sys.Z_helper(geom);
        ELSE
			RETURN NULL;
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- M
-- Returns the M coordinate value (measure) for a point geometry instance 
CREATE OR REPLACE FUNCTION sys.M(geom sys.GEOMETRY)
	RETURNS float8
	AS $$
    DECLARE
        Geomtype text;
    BEGIN
		Geomtype := ST_GeometryType(geom); 

        IF Geomtype = 'ST_Point' THEN
            RETURN sys.M_helper(geom);
        ELSE
			RETURN NULL;
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- Helper functions for main T-SQL functions
CREATE OR REPLACE FUNCTION sys.STContains_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','within'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','ST_Equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDimension_helper(sys.GEOMETRY)
        RETURNS integer
        AS '$libdir/postgis-3','LWGEOM_dimension'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
		
CREATE OR REPLACE FUNCTION sys.STNumPoints_helper(sys.GEOMETRY)
    RETURNS integer
    AS '$libdir/postgis-3','LWGEOM_npoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STMakeValid_helper(sys.GEOMETRY)
        RETURNS sys.GEOMETRY
        AS '$libdir/postgis-3','ST_MakeValid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
		
CREATE OR REPLACE FUNCTION sys.STIntersects_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','ST_Intersects'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','disjoint'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed_helper(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GeomPoint_helper(float8, float8, srid integer)
	RETURNS sys.GEOMETRY
	AS '$libdir/postgis-3', 'ST_Point'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.charTogeomhelper(sys.bpchar)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'charTogeom'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geomfromtext_helper(text, integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'get_geometry_from_text'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varchar_helper(sys.GEOMETRY)
	RETURNS sys.varchar
	AS 'babelfishpg_common','geometry_astext'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
	
CREATE OR REPLACE FUNCTION sys.STArea_helper(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','ST_Area'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
	
CREATE OR REPLACE FUNCTION sys.Z_helper(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_z_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.M_helper(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_m_point'
	LANGUAGE 'c' IMMUTABLE STRICT;



-- box2df type for GiST internal storage
CREATE TYPE sys.box2df;

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
