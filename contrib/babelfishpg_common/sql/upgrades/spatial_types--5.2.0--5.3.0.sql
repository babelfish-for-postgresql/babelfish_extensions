-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

------------------------------------------------------------------------------
---- Add changes here --------------------------------------------------------
------------------------------------------------------------------------------

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

-- Functions removed which are no longer in use
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.stgeomfromtext_helper(text, integer) RENAME TO stgeomfromtext_helper_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stgeomfromtext_helper_deprecated_5_3_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.stgeogfromtext_helper(text, integer) RENAME TO stgeogfromtext_helper_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'stgeogfromtext_helper_deprecated_5_3_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.GEOMETRY_helper(bytea) RENAME TO GEOMETRY_helper_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'GEOMETRY_helper_deprecated_5_3_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.GEOGRAPHY_helper(bytea) RENAME TO GEOGRAPHY_helper_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'GEOGRAPHY_helper_deprecated_5_3_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.bytea_helper(sys.GEOMETRY) RENAME TO bytea_helper_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bytea_helper_deprecated_5_3_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.bytea_helper(sys.GEOGRAPHY) RENAME TO bytea_helperg_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bytea_helperg_deprecated_5_3_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.get_valid_srids() RENAME TO get_valid_srids_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'get_valid_srids_deprecated_5_3_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.GeogPoint_helper(float8, float8, srid integer) RENAME TO GeogPoint_helper_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'GeogPoint_helper_deprecated_5_3_0');


DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.STAsBinary_helper(sys.GEOGRAPHY) RENAME TO STAsBinary_helper_deprecated_5_3_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'STAsBinary_helper_deprecated_5_3_0');

-- STDimension
-- Retrieves spatial dimension
CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOGRAPHY)
        RETURNS integer
        AS $$ 
        BEGIN
	        -- Check if the geography is empty
                IF STIsEmpty(geom) = 1 THEN  
                        RETURN -1;
                END IF;
                RETURN sys.STDimension_helper($1);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDimension_helper(sys.GEOGRAPHY)
        RETURNS integer
        AS '$libdir/postgis-3','LWGEOM_dimension'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STDisjoint
-- Checks if two geometries have no points in common
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS $$
        BEGIN
	        -- Check if the SRIDs do not match
                IF sys.STSrid(geom1) != sys.STSrid(geom2) THEN
                        RETURN NULL;
                END IF;
                RETURN sys.STDisjoint_helper($1, $2);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','disjoint'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STIntersects
-- Checks if two geometries spatially intersect
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS $$
        BEGIN
	        -- Check if the SRIDs do not match
                IF STSrid(geom1) != STSrid(geom2) THEN
                        RETURN NULL;
                ELSE
                        RETURN sys.STIntersects_helper($1,$2);
                END IF;
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.STIntersects_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','ST_Intersects'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STIsEmpty
-- Checks if geometry is empty
CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STIsValid
-- Checks if geometry is valid 
CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STIsClosed
-- Checks if geometry is closed
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
                END IF; 
       
                RETURN sys.STIsClosed_helper(geom);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed_helper(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STDimension
-- Retrieves spatial dimension
CREATE OR REPLACE FUNCTION sys.STDimension(geom sys.GEOMETRY)
        RETURNS integer
        AS $$ 
        BEGIN
	        -- Check if the geometry is empty
                IF STIsEmpty(geom) = 1 THEN  
                        RETURN -1;
                END IF;
                RETURN sys.STDimension_helper($1);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDimension_helper(sys.GEOMETRY)
        RETURNS integer
        AS '$libdir/postgis-3','LWGEOM_dimension'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STDisjoint
-- Checks if two geometries have no points in common
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS $$
        BEGIN
	        -- Check if the SRIDs do not match
                IF sys.STSrid(geom1) != sys.STSrid(geom2) THEN
                        RETURN NULL;
                END IF;
                RETURN sys.STDisjoint_helper($1, $2);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','disjoint'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- STIntersects
-- Checks if two geometries spatially intersect
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS $$
        BEGIN
	        -- Check if the SRIDs do not match
                IF STSrid(geom1) != STSrid(geom2) THEN
                        RETURN NULL;
                ELSE
                        RETURN sys.STIntersects_helper($1,$2);
                END IF;
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.STIntersects_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','ST_Intersects'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

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
                END IF; 
       
                RETURN sys.STIsClosed_helper(geom);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed_helper(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Functions migrated from SQL  to C
CREATE OR REPLACE FUNCTION sys.Geometry__stgeomfromtext(text, integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'get_geometry_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__stgeomfromtext(text, integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'get_geography_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOMETRY)
	RETURNS TEXT
	AS 'babelfishpg_common', 'st_as_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOGRAPHY)
	RETURNS TEXT
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.STAsText_common(sys.Geography__STFlipCoordinates($1)));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOMETRY(bytea)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common','geometry_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;	

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(bytea)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common','geography_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOMETRY)
	RETURNS bytea
	AS 'babelfishpg_common','bytea_from_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOGRAPHY)
	RETURNS bytea
	AS 'babelfishpg_common','bytea_from_geography'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOMETRY)
	RETURNS bytea
	AS 'babelfishpg_common', 'st_as_binary_geometry'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOGRAPHY)
	RETURNS bytea
	AS 'babelfishpg_common', 'st_as_binary_geography'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geometry__STPointFromText(text, integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOMETRY;
	BEGIN
		geom = (SELECT sys.geomfromtext_helper($1, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Point' THEN
			RETURN geom;
		ELSE
			RAISE EXCEPTION '% is not supported', Geomtype;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geomfromtext_helper(text, integer)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'get_geometry_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STPointFromText(text, integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOGRAPHY;
	BEGIN
		geom = (SELECT sys.geogfromtext_helper($1, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Point' THEN
			RETURN geom;
		ELSE
			RAISE EXCEPTION '% is not supported', Geomtype;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geogfromtext_helper(text, integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'get_geography_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__Point(float8, float8, srid integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'geography_point'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.charTogeomhelper(sys.bpchar)
	RETURNS sys.GEOMETRY
	AS 'babelfishpg_common', 'charTogeom'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.charTogeoghelper(sys.bpchar)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'charTogeog'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Modified functions
CREATE OR REPLACE FUNCTION sys.STDistance(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS float8
	AS $$
	BEGIN
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSE
			Return sys.STDistance_helper($1,$2);
		END IF;
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

		ELSE
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
			RETURN (SELECT sys.STDistance_helper(sys.Geography__STFlipCoordinates($1), sys.Geography__STFlipCoordinates($2)));
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOGRAPHY)
	RETURNS sys.bpchar
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.GeographyAsTextbp_helper(sys.Geography__STFlipCoordinates($1)));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOMETRY)
	RETURNS sys.bpchar
	AS 'babelfishpg_common','geometry_astext'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOGRAPHY)
	RETURNS sys.varchar
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.GeographyAsTextvar_helper(sys.Geography__STFlipCoordinates($1)));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOMETRY)
	RETURNS sys.varchar
	AS 'babelfishpg_common','geometry_astext'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- New functions
CREATE OR REPLACE FUNCTION sys.STDistance_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3', 'ST_Distance'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText_common(sys.GEOGRAPHY)
	RETURNS TEXT
	AS 'babelfishpg_common', 'st_as_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GeographyAsTextbp_helper(sys.GEOGRAPHY)
	RETURNS sys.bpchar
	AS 'babelfishpg_common', 'geometry_astext'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GeographyAsTextvar_helper(sys.GEOGRAPHY)
	RETURNS sys.varchar
	AS 'babelfishpg_common', 'geometry_astext'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);