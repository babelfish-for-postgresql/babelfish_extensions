-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
--geometry
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

--geography 
CREATE OR REPLACE FUNCTION sys.MakeValid(geog sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS $$ 
    BEGIN
        IF geog IS NULL THEN
            RETURN NULL;
        ELSEIF sys.STIsEmpty(geog) = 1 THEN  
            RETURN geog;
        ELSEIF sys.STIsValid(geog) = 1 THEN
            RETURN geog;
        ELSE
            RETURN sys.makevalid_helper(geog);
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.makevalid_helper(geog sys.GEOGRAPHY)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3', 'ST_MakeValid'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;