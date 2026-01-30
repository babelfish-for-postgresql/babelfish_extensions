-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
-- STLength
CREATE OR REPLACE FUNCTION sys.STLength(geom sys.GEOMETRY)
    RETURNS float8
    AS $$
	DECLARE
	    geom_type text;
	BEGIN
		IF sys.STIsEmpty(geom)=1 THEN
		    RETURN 0;
		END IF;

		geom_type := sys.ST_GeometryType(geom);
		-- Polygon types - use ST_Perimeter (sum of all ring lengths)
		IF geom_type IN ('ST_Polygon', 'ST_MultiPolygon') THEN
		     RETURN sys.STPerimeter_helper(geom);
		ELSE 
		    RETURN sys.STLength_helper(geom);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STLength_helper(geom sys.GEOMETRY)
    RETURNS float8
    AS '$libdir/postgis-3', 'LWGEOM_length2d_linestring'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STPerimeter_helper(sys.GEOMETRY)
    RETURNS float8
    AS '$libdir/postgis-3','LWGEOM_perimeter2d_poly'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STLength(geom sys.GEOGRAPHY)
    RETURNS float8
    AS $$
    DECLARE
        geom_type text;
    BEGIN
        -- EMPTY → 0
        IF sys.STIsEmpty(geom) = 1 THEN
            RETURN 0;
        END IF;

        IF sys.STIsValid(geom) = 0 THEN
            RAISE EXCEPTION 'The geography instance is not valid';
        END IF;
    -- Get the geometry type
        geom_type := sys.ST_GeometryType(geom);
  
     -- Polygon types - use ST_Perimeter (sum of all ring lengths)
        IF geom_type IN ('ST_Polygon', 'ST_MultiPolygon') THEN
            RETURN sys.STPerimeter_helper(sys.Geography__STFlipCoordinates(geom));
        ELSE 
            RETURN sys.STLength_helper(sys.Geography__STFlipCoordinates(geom));
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STLength_helper(geom sys.GEOGRAPHY)
     RETURNS float8
     AS '$libdir/postgis-3', 'geography_length'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STPerimeter_helper(geom sys.GEOGRAPHY)
    RETURNS float8
    AS '$libdir/postgis-3', 'geography_perimeter'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;