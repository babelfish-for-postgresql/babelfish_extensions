-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
--parse
--Geometry 
CREATE OR REPLACE FUNCTION sys.Geometry__Parse(geometry_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOMETRY
    AS $$
    BEGIN
	    IF UPPER(geometry_tagged_text::text) = 'NULL' THEN
            RETURN NULL;
        END IF;
        RETURN sys.geomfromtext_helper(geometry_tagged_text::text, 0);
    END;
    $$ LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

--Geography

CREATE OR REPLACE FUNCTION sys.Geography__Parse(geography_tagged_text sys.NVARCHAR)
    RETURNS sys.GEOGRAPHY
    AS $$
    BEGIN
	    IF UPPER(geography_tagged_text::text) = 'NULL' THEN
            RETURN NULL;
        END IF;
        RETURN sys.geogfromtext_helper(geography_tagged_text::text, 4326);
    END;
    $$ LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;
