-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

--STIntersects
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
        AS '$libdir/postgis-3','ST_Intersects'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STDimension
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

CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STIsClosed
CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS $$
        DECLARE
                geom_type text;
        BEGIN
                -- Check if the geography is empty
                IF STIsEmpty(geom) = 1 THEN
                        RETURN 0;
                END IF;
                -- Get the geography type
                geom_type := ST_GeometryType(geom); 
                -- Check if any figures of the geography instance are points
                IF geom_type = 'ST_Point' OR geom_type = 'ST_MultiPoint' THEN
                        RETURN 0;
                END IF; 
       
                RETURN sys.STIsClosed_helper(geom);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed_helper(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STDisjoint
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS $$
        DECLARE
                intersection_empty BOOLEAN;
        BEGIN
	        --Check if the SRIDs do not match
                IF sys.STSrid(geom1) != sys.STSrid(geom2) THEN
                        RETURN NULL;
                ELSE
                        -- Check if the intersection is empty       
                        IF STIntersects(geom1, geom2) = 0 THEN
                                RETURN 1::sys.BIT;  
                        ELSE
                                RETURN sys.STDisjoint_helper($1, $2);
                        END IF;
                END IF;
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','disjoint'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STIntersects
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

--STDimension
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

CREATE OR REPLACE FUNCTION sys.STIsEmpty(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isempty'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsValid(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','isvalid'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STIsClosed
CREATE OR REPLACE FUNCTION sys.STIsClosed(geom sys.GEOMETRY)
        RETURNS sys.BIT
        AS $$
        DECLARE
                geom_type text;
        BEGIN
                -- Check if the geometry is empty
                IF STIsEmpty(geom) = 1 THEN
                        RETURN 0;
                END IF;
                -- Get the geometry type
                geom_type := ST_GeometryType(geom); 
                -- Check if any figures of the geometry instance are points
                IF geom_type = 'ST_Point' OR geom_type = 'ST_MultiPoint' THEN
                        RETURN 0;
                END IF; 
       
                RETURN sys.STIsClosed_helper(geom);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed_helper(sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

--STDisjoint
CREATE OR REPLACE FUNCTION sys.STDisjoint(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS $$
        DECLARE
                intersection_empty BOOLEAN;
        BEGIN
	        --Check if the SRIDs do not match
                IF sys.STSrid(geom1) != sys.STSrid(geom2) THEN
                        RETURN NULL;
                ELSE
                        -- Check if the intersection is empty       
                        IF STIntersects(geom1, geom2) = 0 THEN
                                RETURN 1::sys.BIT;  
                        ELSE
                                RETURN sys.STDisjoint_helper($1, $2);
                        END IF;
                END IF;
        END;
        $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','disjoint'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;