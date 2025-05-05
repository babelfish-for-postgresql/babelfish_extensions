CREATE OR REPLACE FUNCTION sys.geographyin(cstring, oid, integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common','geography_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographyout(sys.GEOGRAPHY)
    RETURNS cstring
    AS '$libdir/postgis-3','geography_out'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographytypmodin(cstring[])
    RETURNS integer
    AS '$libdir/postgis-3','geometry_typmod_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographytypmodout(integer)
    RETURNS cstring
    AS '$libdir/postgis-3','postgis_typmod_out'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographyrecv(internal, oid, integer)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3','geography_recv'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.geographysend(sys.GEOGRAPHY)
    RETURNS bytea
    AS '$libdir/postgis-3','geography_send'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographyanalyze(internal)
    RETURNS bool
    AS '$libdir/postgis-3','gserialized_analyze_nd'
    LANGUAGE 'c' VOLATILE STRICT;  


CREATE TYPE sys.GEOGRAPHY (
    INTERNALLENGTH = variable,
    INPUT          = sys.geographyin,
    OUTPUT         = sys.geographyout,
    RECEIVE        = sys.geographyrecv,
    SEND           = sys.geographysend,
    TYPMOD_IN      = sys.geographytypmodin,
    TYPMOD_OUT     = sys.geographytypmodout,
    DELIMITER      = ':', 
    ANALYZE        = sys.geographyanalyze,
    STORAGE        = main, 
    ALIGNMENT      = double
);

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','geography_enforce_typmod'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.GEOGRAPHY AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.GEOGRAPHY, integer, boolean) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(bytea)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common','geography_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOGRAPHY)
	RETURNS bytea
	AS 'babelfishpg_common','bytea_from_geography'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;	

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bbf_varbinary)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
        varBin bytea;
	BEGIN
		varBin := (SELECT CAST ($1 AS bytea));
		-- Call the underlying function after preprocessing
		RETURN (SELECT sys.GEOGRAPHY(varBin));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY)
	RETURNS sys.bbf_varbinary
	AS $$
	DECLARE
        byte bytea;
	BEGIN
		byte := (SELECT sys.bytea($1));
		RETURN (SELECT CAST (byte AS sys.bbf_varbinary)); 
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bbf_binary)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
        varBin sys.bbf_varbinary;
	BEGIN
		varBin := (SELECT CAST ($1 AS sys.bbf_varbinary));
		-- Call the underlying function after preprocessing
		RETURN (SELECT sys.GEOGRAPHY(varBin)); 
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOGRAPHY)
	RETURNS text
	AS $$
	BEGIN
		RAISE EXCEPTION 'Explicit Conversion from data type sys.Geography to Text is not allowed.';
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(text, integer, boolean)
	RETURNS sys.GEOGRAPHY
	AS $$
	BEGIN
		IF $3 = true THEN
			RAISE EXCEPTION 'Explicit Conversion from data type Text to sys.Geography is not allowed.';
		ELSE
			RAISE EXCEPTION 'Implicit Conversion from data type Text to sys.Geography is not allowed.';
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

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bpchar)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		geog sys.GEOGRAPHY;
	BEGIN
		geog := (SELECT sys.charTogeoghelper($1));
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.Geography__STFlipCoordinates(geog));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

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

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.varchar)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		geog sys.GEOGRAPHY;
	BEGIN
		geog := (SELECT sys.charTogeoghelper($1));
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.Geography__STFlipCoordinates(geog));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (text AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(text, integer, boolean) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS text) WITH FUNCTION sys.text(sys.GEOGRAPHY);
CREATE CAST (sys.bpchar AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bpchar) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.bpchar) WITH FUNCTION sys.bpchar(sys.GEOGRAPHY);
CREATE CAST (sys.varchar AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.varchar) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.varchar) WITH FUNCTION sys.varchar(sys.GEOGRAPHY);
CREATE CAST (sys.bbf_binary AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bbf_binary) AS IMPLICIT;
CREATE CAST (bytea AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(bytea) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS bytea) WITH FUNCTION sys.bytea(sys.GEOGRAPHY);
CREATE CAST (sys.bbf_varbinary AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bbf_varbinary) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.bbf_varbinary) WITH FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY);

-- This Function Flips the Coordinates of the Point (x, y) -> (y, x)
CREATE OR REPLACE FUNCTION sys.Geography__STFlipCoordinates(sys.GEOGRAPHY)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3', 'ST_FlipCoordinates'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__stgeomfromtext(text, integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'get_geography_from_text'
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

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOGRAPHY)
	RETURNS bytea
	AS 'babelfishpg_common', 'st_as_binary_geography'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__Point(float8, float8, srid integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'geography_point'
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

CREATE OR REPLACE FUNCTION sys.ST_GeometryType(sys.GEOGRAPHY)
	RETURNS text
	AS '$libdir/postgis-3', 'geometry_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_zmflag(sys.GEOGRAPHY)
	RETURNS smallint
	AS '$libdir/postgis-3', 'LWGEOM_zmflag'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STArea(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','ST_Area'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STSrid(sys.GEOGRAPHY)
	RETURNS integer
	AS '$libdir/postgis-3','LWGEOM_get_srid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS $$
	BEGIN
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
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
		ELSE
			Return sys.STContains_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE  OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
	RETURNS boolean
	AS $$
	DECLARE
		Result integer;
	BEGIN
		Result := STEquals(leftarg,rightarg);
		IF Result IS NULL THEN
			RETURN false;
		END IF;
		RETURN Result;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.ST_Equals,
    COMMUTATOR = =,
    RESTRICT = eqsel
);

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
	RETURNS boolean
	AS $$
	DECLARE
		Result integer;
	BEGIN
		Result := STEquals(leftarg,rightarg);
		IF Result IS NULL THEN
			RETURN true;
		END IF;
		RETURN 1 - Result;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<> (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.ST_NotEquals,
    COMMUTATOR = <>
);

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

-- STDisjoint
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

-- STIntersects
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

-- Minimum distance
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

CREATE OR REPLACE FUNCTION sys.long(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_y_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.lat(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_x_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.ST_Transform(sys.GEOGRAPHY, integer)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','transform'
	LANGUAGE 'c' IMMUTABLE STRICT;

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

-- Helper functions for main T-SQL functions
CREATE OR REPLACE FUNCTION sys.STEquals_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','ST_Equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STContains_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','within'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDimension_helper(sys.GEOGRAPHY)
        RETURNS integer
        AS '$libdir/postgis-3','LWGEOM_dimension'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIntersects_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','ST_Intersects'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDisjoint_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','disjoint'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STIsClosed_helper(sys.GEOGRAPHY)
        RETURNS sys.BIT
        AS '$libdir/postgis-3','LWGEOM_isclosed'
        LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText_helper(sys.GEOGRAPHY)
	RETURNS TEXT
	AS '$libdir/postgis-3','LWGEOM_asText'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.STAsText_common(sys.GEOGRAPHY)
	RETURNS TEXT
	AS 'babelfishpg_common', 'st_as_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDistance_helper(geog1 sys.GEOGRAPHY, geog2 sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3', 'LWGEOM_distance_ellipsoid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpcharToGeography_helper(sys.bpchar, integer)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','LWGEOM_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.charTogeoghelper(sys.bpchar)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'charTogeog'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GeographyAsTextbp_helper(sys.GEOGRAPHY)
	RETURNS sys.bpchar
	AS 'babelfishpg_common', 'geometry_astext'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GeographyAsTextvar_helper(sys.GEOGRAPHY)
	RETURNS sys.varchar
	AS 'babelfishpg_common', 'geometry_astext'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geogfromtext_helper(text, integer)
	RETURNS sys.GEOGRAPHY
	AS 'babelfishpg_common', 'get_geography_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;
