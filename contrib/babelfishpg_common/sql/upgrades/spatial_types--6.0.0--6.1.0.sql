-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
--Geometry

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

CREATE OR REPLACE FUNCTION sys.STMakeValid_helper(sys.GEOMETRY)
        RETURNS sys.GEOMETRY
        AS '$libdir/postgis-3','ST_MakeValid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--Geography 

CREATE OR REPLACE FUNCTION sys.MakeValid(geog sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS $$ 
    BEGIN
        IF sys.STIsEmpty(geog) = 1 THEN  
            RETURN geog;
        ELSEIF sys.STIsValid(geog) = 1 THEN
            RETURN geog;
        ELSE
            RETURN sys.makevalid_helper(geog);
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.makevalid_helper(geog sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3', 'ST_MakeValid'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STNumPoints
-- Geometry

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

CREATE OR REPLACE FUNCTION sys.STNumPoints_helper(sys.GEOMETRY)
    RETURNS integer
    AS '$libdir/postgis-3','LWGEOM_npoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Geography

CREATE OR REPLACE FUNCTION sys.STNumPoints(geog sys.GEOGRAPHY)
	RETURNS integer
	AS $$
	BEGIN
		IF sys.STIsValid(geog) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		ELSE
			RETURN sys.STNumPoints_helper(geog);
		END IF;
	END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STNumPoints_helper(sys.GEOGRAPHY)
    RETURNS integer
    AS '$libdir/postgis-3', 'LWGEOM_npoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
    
--parse
--Geometry 

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

--Geography

CREATE OR REPLACE FUNCTION sys.Geography__Parse(geography_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOGRAPHY
    AS $$
    BEGIN
        IF UPPER(geography_tagged_text COLLATE sys.DATABASE_DEFAULT) = 'NULL' THEN
            RETURN NULL;
        END IF;

        RETURN sys.geogfromtext_helper(geography_tagged_text, 4326);
    END;
    $$ LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

--STGeomType
--Geometry

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

--Geography

CREATE OR REPLACE FUNCTION sys.STGeometryType(geog sys.GEOGRAPHY)
	RETURNS sys.NVARCHAR(4000)
	AS $$
	DECLARE
		geom_type text;
	BEGIN
        IF STIsValid(geog) = 0 THEN
            RAISE EXCEPTION 'This operation cannot be completed because the instance is not valid';
        END IF;
		geom_type := sys.ST_GeometryType(geog);
		
		IF geom_type LIKE 'ST\_%' ESCAPE '\' THEN
			RETURN substr(geom_type, 4);
		END IF;
		
	    RAISE EXCEPTION 'Unexpected geometry type format: %. Expected ST_* prefix.', geom_type;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

--STMPointFromText
--Geometry

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

--STMPointFromText
--Geography 

CREATE OR REPLACE FUNCTION sys.Geography__STMPointFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOGRAPHY
    AS $$
    DECLARE
        Geomtype text;
        geog sys.GEOGRAPHY;
    BEGIN
        IF $2 IS NULL THEN
            RAISE EXCEPTION '''geography::STMPointFromText'' failed because parameter 2 is not allowed to be null.';
        ELSIF $1 IS NULL THEN
            RETURN NULL;
        END IF;

        geog = sys.geogfromtext_helper($1, $2);
        Geomtype = sys.ST_GeometryType(geog);

        IF Geomtype = 'ST_MultiPoint' THEN
            RETURN geog;
        ELSE
            RAISE EXCEPTION 'Expected "MULTIPOINT" at position 1. The input has %', $1;
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

--STMPointFromWKB
--Geography

CREATE OR REPLACE FUNCTION sys.Geography__STMPointFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOGRAPHY
    AS $$
    DECLARE
        Geomtype text;
        geog sys.GEOGRAPHY;
    BEGIN
        IF $2 IS NULL THEN
            RAISE EXCEPTION '''geography::STMPointFromWKB'' failed because parameter 2 is not allowed to be null.';
        ELSIF $1 IS NULL THEN
            RETURN NULL;
        END IF;

        geog = sys.geogfromwkb_helper($1::bytea, $2);
        Geomtype = sys.ST_GeometryType(geog);

        IF Geomtype = 'ST_MultiPoint' THEN
            RETURN geog;
        ELSE
            RAISE EXCEPTION 'Expected "MULTIPOINT" at position 1. The input has %', Geomtype;
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geogfromwkb_helper(bytea, integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'get_geography_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

--Geometry

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
