-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

--STNumPoints
-- geometry

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