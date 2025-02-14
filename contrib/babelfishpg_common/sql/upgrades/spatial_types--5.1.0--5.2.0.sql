-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
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

CREATE OR REPLACE FUNCTION sys.Geography__STPointFromText(text, integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		srid integer;
		Geomtype text;
		geom sys.GEOGRAPHY;
		valid_srids integer[];
		lat float8;
		Zmflag smallint;
	BEGIN
		-- Call the function to retrieve the valid SRIDs
		SELECT sys.get_valid_srids() INTO valid_srids;
		srid := $2;
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		geom = (SELECT sys.stgeogfromtext_helper($1, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));
		Zmflag = (SELECT sys.ST_Zmflag(geom));
		IF Geomtype = 'ST_Point' THEN
			lat = (SELECT sys.lat(sys.Geography__STFlipCoordinates(sys.stgeogfromtext_helper($1, $2))));
			IF srid = ANY(valid_srids) AND ((lat >= -90.0 AND lat <= 90.0) OR lat is NULL) THEN
				-- Call the underlying function after preprocessing
				-- if the point instance has z flag only then Zmflag = 1
				-- if the point instance has m flag only then Zmflag = 2
				-- if the point instance has both z and m flags then Zmflag = 3
				IF Zmflag = 1 OR Zmflag = 2 OR Zmflag = 3 THEN
					RAISE EXCEPTION 'Unsupported flags';
				ELSE
					-- Here we are flipping the coordinates 
					-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
					RETURN (SELECT sys.Geography__STFlipCoordinates(geom));
				END IF;
			ELSEIF lat < -90.0 OR lat > 90.0 THEN
				RAISE EXCEPTION 'Latitude values must be between -90 and 90 degrees';
			ELSE
				RAISE EXCEPTION 'Inavalid SRID';
			END IF;
		ELSE
			RAISE EXCEPTION '% is not supported', Geomtype;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__stgeomfromtext(text, integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		srid integer;
		Geomtype text;
		geom sys.GEOGRAPHY;
		valid_srids integer[];
		lat float8;
		Zmflag smallint;
	BEGIN
		-- Call the function to retrieve the valid SRIDs
		SELECT sys.get_valid_srids() INTO valid_srids;
		srid := $2;
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		geom = (SELECT sys.stgeogfromtext_helper($1, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));
		Zmflag = (SELECT sys.ST_Zmflag(geom));
		IF Geomtype = 'ST_Point' THEN
			lat = (SELECT sys.lat(sys.Geography__STFlipCoordinates(sys.stgeogfromtext_helper($1, $2))));
			IF srid = ANY(valid_srids) AND ((lat >= -90.0 AND lat <= 90.0) OR lat is NULL) THEN
				-- Call the underlying function after preprocessing
				-- if the point instance has z flag only then Zmflag = 1
				-- if the point instance has m flag only then Zmflag = 2
				-- if the point instance has both z and m flags then Zmflag = 3
				IF Zmflag = 1 OR Zmflag = 2 OR Zmflag = 3 THEN
					RAISE EXCEPTION 'Unsupported flags';
				ELSE
					-- Here we are flipping the coordinates 
					-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
					RETURN (SELECT sys.Geography__STFlipCoordinates(geom));
				END IF;
			ELSEIF lat < -90.0 OR lat > 90.0 THEN
				RAISE EXCEPTION 'Latitude values must be between -90 and 90 degrees';
			ELSE
				RAISE EXCEPTION 'Inavalid SRID';
			END IF;
		ELSE
			RAISE EXCEPTION '% is not supported', Geomtype;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.charTogeoghelper(sys.bpchar)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		Geomtype text;
		geog sys.GEOGRAPHY;
		lat float8;
		Zmflag smallint;
	BEGIN
		geog = (SELECT sys.bpcharToGeography_helper($1, 4326));
		Geomtype = (SELECT sys.ST_GeometryType(geog));
		Zmflag = (SELECT sys.ST_Zmflag(geog));
		IF Geomtype = 'ST_Point' THEN
			lat = (SELECT sys.lat(sys.Geography__STFlipCoordinates(sys.stgeogfromtext_helper($1, 4326))));
			IF (lat >= -90.0 AND lat <= 90.0) OR lat is NULL THEN
				-- Call the underlying function after preprocessing
				-- if the point instance has z flag only then Zmflag = 1
				-- if the point instance has m flag only then Zmflag = 2
				-- if the point instance has both z and m flags then Zmflag = 3
				IF Zmflag = 1 OR Zmflag = 2 OR Zmflag = 3 THEN
					RAISE EXCEPTION 'Unsupported flags';
				ELSE
					RETURN geog;
				END IF;
			ELSEIF lat < -90.0 OR lat > 90.0 THEN
				RAISE EXCEPTION 'Latitude values must be between -90 and 90 degrees';
			END IF;
		ELSE
			RAISE EXCEPTION '% is not supported', Geomtype;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;