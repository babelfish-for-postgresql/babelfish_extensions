-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
--STGeomType

--Geometry
CREATE OR REPLACE FUNCTION sys.STGeometryType(geom sys.GEOMETRY)
	RETURNS sys.NVARCHAR
	AS $$
	DECLARE
		geom_type text;
	BEGIN
		IF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'This operation cannot be completed because the instance is not valid';
		END IF;
		
		geom_type := sys.ST_GeometryType(geom);
		
		-- Strip 'ST_' prefix to match SQL Server naming
		IF geom_type LIKE 'ST_%' THEN
			RETURN substr(geom_type, 4);
		END IF;
		
		RETURN geom_type;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

--Geography

CREATE OR REPLACE FUNCTION sys.STGeometryType(geog sys.GEOGRAPHY)
	RETURNS sys.NVARCHAR
	AS $$
	DECLARE
		geom_type text;
	BEGIN
        IF STIsValid(geog) = 0 THEN
            RAISE EXCEPTION 'This operation cannot be completed because the instance is not valid';
        END IF;
		geom_type := sys.ST_GeometryType(geog);
		
		IF geom_type LIKE 'ST_%' THEN
			RETURN substr(geom_type, 4);
		END IF;
		
		RETURN geom_type;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;