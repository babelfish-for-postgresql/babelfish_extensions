-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

--STNumPoints
-- geometry

CREATE OR REPLACE FUNCTION sys.STNumPoints(geom sys.GEOMETRY)
    RETURNS integer
    AS $$
    DECLARE
        geom_type text;
    BEGIN
        IF STIsValid(geom) = 0 THEN
            RAISE EXCEPTION 'The geometry instance is not valid';
        ELSIF STIsEmpty(geom) = 1 THEN
            RETURN 0;
        END IF;
        
        geom_type := ST_GeometryType(geom);
        
        IF geom_type = 'ST_Point' THEN
            RETURN 1;
        ELSIF geom_type IN ('ST_LineString', 'ST_Polygon', 'ST_MultiLineString', 'ST_MultiPolygon') THEN
            RETURN sys.STNumPoints_helper(geom);
        ELSE
            RETURN NULL;
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
			RAISE EXCEPTION 'The geography instance is not valid. Use MakeValid() to convert to valid geography.';
		ELSIF sys.STIsEmpty(geog) = 1 THEN
			RETURN 0;
		ELSE
			RETURN sys.STNumPoints_geography_helper(geog);
		END IF;
	END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STNumPoints_geography_helper(sys.GEOGRAPHY)
    RETURNS integer
    AS '$libdir/postgis-3', 'LWGEOM_npoints'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;