-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
--STGeomType

--Geometry
CREATE OR REPLACE FUNCTION sys.STGeometryType(geom sys.GEOMETRY)
	RETURNS sys.NVARCHAR(4000)
	AS $$
	DECLARE
		geom_type text;
	BEGIN
		IF STIsValid(geom) = 0 THEN
			RAISE EXCEPTION 'This operation cannot be completed because the instance is not valid';
		END IF;
		
		geom_type := sys.ST_GeometryType(geom);
		
		IF geom_type LIKE 'ST\_%' ESCAPE '\' THEN
			RETURN substr(geom_type, 4);
		END IF;

		RAISE EXCEPTION 'Unexpected geometry type format: %. Expected ST_* prefix.', geom_type;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

--Geography

CREATE OR REPLACE FUNCTION sys.STGeometryType(geog sys.GEOGRAPHY)
	RETURNS sys.NVARCHAR(4000)
	AS $$
	DECLARE
		geom_type text;
	BEGIN
        IF STIsValid(geog) = 0 THEN
            RAISE EXCEPTION 'This operation cannot be completed because the instance is not valid';
        END IF;
		geom_type := sys.ST_GeometryType(geog);
		
		IF geom_type LIKE 'ST\_%' ESCAPE '\' THEN
			RETURN substr(geom_type, 4);
		END IF;
		
	    RAISE EXCEPTION 'Unexpected geometry type format: %. Expected ST_* prefix.', geom_type;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;