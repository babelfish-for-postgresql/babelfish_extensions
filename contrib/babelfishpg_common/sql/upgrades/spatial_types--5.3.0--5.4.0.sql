-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

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

DROP CAST IF EXISTS (sys.GEOGRAPHY AS sys.bpchar);

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.GeographyAsTextbp_helper(sys.GEOGRAPHY) RENAME TO geographyastextbp_helper_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geographyastextbp_helper_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.GeographyAsTextbp_helper(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.bpchar
	AS 'babelfishpg_common', 'geometry_asbpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

DO $$    
DECLARE	
    exception_message text;	
BEGIN	
	ALTER FUNCTION sys.bpchar(sys.GEOGRAPHY) RENAME TO bpchar_geog_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN	
    GET STACKED DIAGNOSTICS	
    exception_message = MESSAGE_TEXT;	
    RAISE WARNING '%', exception_message;	
END;	
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bpchar_geog_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.bpchar
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.GeographyAsTextbp_helper(sys.Geography__STFlipCoordinates($1), $2, $3));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	CREATE CAST (sys.GEOGRAPHY AS sys.bpchar) WITH FUNCTION sys.bpchar(sys.GEOGRAPHY, integer, boolean);
EXCEPTION WHEN duplicate_object THEN
	-- Silently ignore if cast already exists
END;
$$;

DROP CAST IF EXISTS (sys.GEOGRAPHY AS sys.varchar);

DO $$    
DECLARE	
    exception_message text;	
BEGIN	
	ALTER FUNCTION sys.varchar(sys.GEOGRAPHY) RENAME TO varchar_geog_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN	
    GET STACKED DIAGNOSTICS	
    exception_message = MESSAGE_TEXT;	
    RAISE WARNING '%', exception_message;	
END;	
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'varchar_geog_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.varchar
	AS $$
	DECLARE
		str_notation sys.varchar;
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		str_notation := (SELECT sys.GeographyAsTextvar_helper(sys.Geography__STFlipCoordinates($1)));
		IF pg_catalog.length(str_notation) + 4 > $2 AND $2 != -1 THEN
			RAISE EXCEPTION 'There is insufficient result space to convert a geography value to varchar/nvarchar.';
		END IF;
		RETURN str_notation;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	CREATE CAST (sys.GEOGRAPHY AS sys.varchar) WITH FUNCTION sys.varchar(sys.GEOGRAPHY, integer, boolean);
EXCEPTION WHEN duplicate_object THEN
	-- Silently ignore if cast already exists
END;
$$;

DROP CAST IF EXISTS (sys.GEOGRAPHY AS sys.bbf_varbinary);

DO $$    
DECLARE	
    exception_message text;	
BEGIN	
	ALTER FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY) RENAME TO bbf_varbinary_geog_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN	
    GET STACKED DIAGNOSTICS	
    exception_message = MESSAGE_TEXT;	
    RAISE WARNING '%', exception_message;	
END;	
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_varbinary_geog_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.bbf_varbinary
	AS $$
	DECLARE
        byte bytea;
	BEGIN
		byte := (SELECT sys.bytea($1));
		IF pg_catalog.length(byte) + 4 > $2 AND $2 != -1 THEN
			RAISE EXCEPTION 'Error converting sys.geography to binary. The result would be truncated.';
		END IF;
		RETURN (SELECT CAST (byte AS sys.bbf_varbinary)); 
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	CREATE CAST (sys.GEOGRAPHY AS sys.bbf_varbinary) WITH FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY, integer, boolean);
EXCEPTION WHEN duplicate_object THEN
	-- Silently ignore if cast already exists
END;
$$;

CREATE OR REPLACE FUNCTION sys.bbf_binary(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.bbf_binary
	AS $$
	DECLARE
		byte bytea;
	BEGIN
		byte := (SELECT sys.bytea($1));
		IF pg_catalog.length(byte) + 4 = $2 THEN
			RETURN (SELECT CAST (byte AS sys.bbf_binary));
		ELSEIF pg_catalog.length(byte) + 4 > $2 THEN
			RAISE EXCEPTION 'Error converting sys.geography to binary. The result would be truncated.';
		ELSE
			RAISE EXCEPTION 'Error converting sys.geography to fixed length binary type. The result would be padded and cannot be converted back.';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	CREATE CAST (sys.GEOGRAPHY AS sys.bbf_binary) WITH FUNCTION sys.bbf_binary(sys.GEOGRAPHY, integer, boolean);
EXCEPTION WHEN duplicate_object THEN
	-- Silently ignore if cast already exists
END;
$$;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.Geography__stgeomfromtext(text, integer) RENAME TO geography__stgeomfromtext_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geography__stgeomfromtext_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.Geography__stgeomfromtext(sys.NVARCHAR, integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geography::STGeomFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		RETURN (SELECT sys.geogfromtext_helper($1::text, $2));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STAsText_common(sys.GEOGRAPHY) RENAME TO stastext_common_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stastext_common_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.STAsText_common(sys.GEOGRAPHY)
	RETURNS sys.NVARCHAR
	AS 'babelfishpg_common', 'st_as_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STAsText(sys.GEOGRAPHY) RENAME TO stastext_geog_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stastext_geog_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOGRAPHY)
	RETURNS sys.NVARCHAR
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.STAsText_common(sys.Geography__STFlipCoordinates($1)));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STAsBinary(sys.GEOGRAPHY) RENAME TO stasbinary_geog_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stasbinary_geog_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOGRAPHY)
	RETURNS sys.varbinary
	AS 'babelfishpg_common', 'st_as_binary_geography'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__Point(float8, float8, srid integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'geography_point'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.Geography__STPointFromText(text, integer) RENAME TO geography__stpointfromtext_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geography__stpointfromtext_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.Geography__STPointFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOGRAPHY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geography::STPointFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geogfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Point' THEN
			RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "POINT" at Position 1. The input has %', $1;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Z(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_z_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.M(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_m_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.geogfromtext_helper(text, integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'get_geography_from_text'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.Geometry__stgeomfromtext(text, integer) RENAME TO geometry__stgeomfromtext_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geometry__stgeomfromtext_deprecated_5_4_0');

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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STAsText(sys.GEOMETRY) RENAME TO stastext_geom_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stastext_geom_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOMETRY)
	RETURNS sys.NVARCHAR
	AS 'babelfishpg_common', 'st_as_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

DROP CAST IF EXISTS (sys.GEOMETRY AS sys.bpchar);

DO $$    
DECLARE	
    exception_message text;	
BEGIN	
	ALTER FUNCTION sys.bpchar(sys.GEOMETRY) RENAME TO bpchar_geom_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN	
    GET STACKED DIAGNOSTICS	
    exception_message = MESSAGE_TEXT;	
    RAISE WARNING '%', exception_message;	
END;	
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bpchar_geom_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOMETRY, integer, boolean)
	RETURNS sys.bpchar
	AS 'babelfishpg_common','geometry_asbpchar'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	CREATE CAST (sys.GEOMETRY AS sys.bpchar) WITH FUNCTION sys.bpchar(sys.GEOMETRY, integer, boolean);
EXCEPTION WHEN duplicate_object THEN
	-- Silently ignore if cast already exists
END;
$$;

DROP CAST IF EXISTS (sys.GEOMETRY AS sys.varchar);

DO $$    
DECLARE	
    exception_message text;	
BEGIN	
	ALTER FUNCTION sys.varchar(sys.GEOMETRY) RENAME TO varchar_geom_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN	
    GET STACKED DIAGNOSTICS	
    exception_message = MESSAGE_TEXT;	
    RAISE WARNING '%', exception_message;	
END;	
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'varchar_geom_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.varchar_helper(sys.GEOMETRY)
	RETURNS sys.varchar
	AS 'babelfishpg_common','geometry_astext'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

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

DO $$
BEGIN
	CREATE CAST (sys.GEOMETRY AS sys.varchar) WITH FUNCTION sys.varchar(sys.GEOMETRY, integer, boolean);
EXCEPTION WHEN duplicate_object THEN
	-- Silently ignore if cast already exists
END;
$$;

DROP CAST IF EXISTS (sys.GEOMETRY AS sys.bbf_varbinary);

DO $$    
DECLARE	
    exception_message text;	
BEGIN	
	ALTER FUNCTION sys.bbf_varbinary(sys.GEOMETRY) RENAME TO bbf_varbinary_geom_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN	
    GET STACKED DIAGNOSTICS	
    exception_message = MESSAGE_TEXT;	
    RAISE WARNING '%', exception_message;	
END;	
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_varbinary_geom_deprecated_5_4_0');

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

DO $$
BEGIN
	CREATE CAST (sys.GEOMETRY AS sys.bbf_varbinary) WITH FUNCTION sys.bbf_varbinary(sys.GEOMETRY, integer, boolean);
EXCEPTION WHEN duplicate_object THEN
	-- Silently ignore if cast already exists
END;
$$;

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

DO $$
BEGIN
	CREATE CAST (sys.GEOMETRY AS sys.bbf_binary) WITH FUNCTION sys.bbf_binary(sys.GEOMETRY, integer, boolean);
EXCEPTION WHEN duplicate_object THEN
	-- Silently ignore if cast already exists
END;
$$;

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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.Geometry__STPointFromText(text, integer) RENAME TO geometry__stpointfromtext_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'geometry__stpointfromtext_deprecated_5_4_0');

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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STAsBinary(sys.GEOMETRY) RENAME TO stasbinary_geom_deprecated_5_4_0;

EXCEPTION WHEN undefined_function THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stasbinary_geom_deprecated_5_4_0');

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOMETRY)
	RETURNS sys.varbinary
	AS 'babelfishpg_common', 'st_as_binary_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Z(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_z_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.M(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_m_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.geomfromtext_helper(text, integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'get_geometry_from_text'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

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

CREATE OR REPLACE FUNCTION sys.Geography__STLineFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOGRAPHY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geography::STLineFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geogfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_LineString' THEN
			RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "LINESTRING" at Position 1. The input has %', $1;		
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

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

CREATE OR REPLACE FUNCTION sys.STArea_helper(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','ST_Area'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STArea(geom sys.GEOGRAPHY)
	RETURNS float8
	AS $$
	BEGIN
		IF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		ELSE
			RETURN sys.STArea_helper(geom);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom2) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		ELSE
			Return sys.STEquals_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom2) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		ELSE
			Return sys.STContains_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOGRAPHY)
	RETURNS integer
	AS $$ 
	BEGIN
		IF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		-- Check if the geography is empty
		ELSEIF STIsEmpty(geom) = 1 THEN  
			RETURN -1;
		ELSE
			RETURN sys.STDimension_helper($1);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		--Check if the SRIDs do not match
		IF sys.STSrid(geom1) != sys.STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom2) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		ELSE 
			RETURN sys.STDisjoint_helper($1, $2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		--Check if the SRIDs do not match
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSEIF STIsValid(geom1) = 0 OR STIsValid(geom2) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		ELSE
			RETURN sys.STIntersects_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS $$
	DECLARE
		geom_type text;
	BEGIN
		-- Get the geography type
		geom_type := ST_GeometryType(geom); 
		-- Check if any figures of the geography instance are points
		IF geom_type = 'ST_Point' THEN
			RETURN 0;
		ELSIF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		END IF; 
   
		RETURN sys.STIsClosed_helper(geom);
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDistance(geog1 sys.GEOGRAPHY, geog2 sys.GEOGRAPHY)
	RETURNS float8
	AS $$
	BEGIN
		IF STSrid(geog1) != STSrid(geog2) THEN
			RETURN NULL;

		ELSEIF STIsEmpty(geog1) = 1 OR STIsEmpty(geog2) = 1  THEN
			RETURN NULL;

		ELSEIF STIsValid(geog1) = 0 OR STIsValid(geog2) = 0 THEN
			RAISE EXCEPTION 'The geography instance is not valid';
		ELSE
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
			RETURN (SELECT sys.STDistance_helper(sys.Geography__STFlipCoordinates($1), sys.Geography__STFlipCoordinates($2)));
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STArea_helper(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','ST_Area'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);
