-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
--STDimension
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

--STDisjoint
-- Checks if two geometries have no points in common
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS $$
        BEGIN
	        --Check if the SRIDs do not match
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

--STIntersects
-- Checks if two geometries spatially intersect
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS $$
        BEGIN
	        --Check if the SRIDs do not match
                IF STSrid(geom1) != STSrid(geom2) THEN
                        RETURN NULL;
                ELSE
                        RETURN sys.STIntersects_helper($1,$2);
                END IF;
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.STIntersects_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','geography_intersects'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STIsEmpty
-- Checks if geometry is empty
CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STIsValid
-- Checks if geometry is valid 
CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STIsClosed
-- Checks if geometry is closed
CREATE OR REPLACE FUNCTION sys.STIsClosed(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STDimension
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

--STDisjoint
-- Checks if two geometries have no points in common
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS $$
        BEGIN
	        --Check if the SRIDs do not match
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

--STIntersects
-- Checks if two geometries spatially intersect
CREATE OR REPLACE FUNCTION sys.STIntersects(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS $$
        BEGIN
	        --Check if the SRIDs do not match
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

--STIsEmpty
-- Checks if geometry is empty
CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STIsValid
-- Checks if geometry is valid 
CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STIsClosed
-- Checks if geometry is closed
CREATE OR REPLACE FUNCTION sys.STIsClosed(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;