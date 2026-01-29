-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
CREATE OR REPLACE FUNCTION sys.Reduce(tolerance float8, geom sys.GEOMETRY)
    RETURNS sys.GEOMETRY
    AS $$
    BEGIN
        --NULL GEOMETRY ->NULL
        IF geom IS NULL THEN
            RETURN NULL;
        ELSEIF tolerance IS NULL THEN
                RAISE EXCEPTION 'tolerance is not allowed to be null';
        ELSEIF tolerance < 0 THEN 
                 RAISE EXCEPTION 'tolerance must be greater than or equal to zero';
        ELSEIF sys.STIsEmpty(geom) = 1 THEN
                RETURN geom;
        ELSEIF sys.STIsValid(geom) = 0 THEN
                RAISE EXCEPTION 'The geometry instance is not valid';
        ELSE 
            RETURN sys.STReduce_helper(geom, tolerance);
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STReduce_helper(geom sys.GEOMETRY, tolerance float8)
    RETURNS sys.GEOMETRY
    AS '$libdir/postgis-3', 'LWGEOM_simplify2d'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

    --GEOGRAPHY 
    
CREATE OR REPLACE FUNCTION sys.Reduce(tolerance float8, geom sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS $$ 
    BEGIN
        IF geom IS NULL THEN
            RETURN NULL;
        ELSEIF tolerance IS NULL THEN
            RAISE EXCEPTION 'tolerance is not allowed to be null';
		ELSEIF STIsEmpty(geom) = 1 THEN  
            RETURN geom;
        ELSEIF STIsValid(geom) = 0 THEN
            RAISE EXCEPTION 'The geography instance is not valid';
        ELSEIF tolerance < 0 THEN
            RAISE EXCEPTION 'Tolerance cannot be negative';
        ELSE
            RETURN sys.Reduce_helper(geom, tolerance);
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Reduce_helper(geog sys.GEOGRAPHY, tolerance float8)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
    	centroid_lat float8;
    	meters_per_degree float8;
    	tolerance_degrees float8;
    	centroid_geog sys.GEOGRAPHY;
		result_geog sys.GEOGRAPHY;
	BEGIN
    	centroid_geog := sys.STCentroid_helper(geog);

		IF centroid_geog IS NULL THEN
            RETURN geog;
        END IF;

    	centroid_lat := sys.lat(centroid_geog);
		 
        IF centroid_lat IS NULL THEN
            centroid_lat := 0;
        END IF;
    
    	meters_per_degree := 111320.0 * COS(RADIANS(centroid_lat));
    
    	IF meters_per_degree < 1 THEN
       		meters_per_degree := 111320.0;
    	END IF;

    	tolerance_degrees := tolerance / meters_per_degree;
    
		result_geog := sys.geography_simplify_internal(geog, tolerance_degrees);

		IF result_geog IS NULL THEN
    		RETURN geog;
    	END IF;
	   
		RETURN result_geog;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

    
CREATE OR REPLACE FUNCTION sys.geography_simplify_internal(geog sys.GEOGRAPHY, tolerance_degrees float8)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3', 'LWGEOM_simplify2d'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STCentroid_helper(sys.GEOGRAPHY)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3', 'geography_centroid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
