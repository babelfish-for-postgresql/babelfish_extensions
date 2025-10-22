-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

CREATE OR REPLACE FUNCTION sys.Geometry__STPointFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOMETRY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geometry::STPointFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geomfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Point' THEN
				RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "POINT" at Position 1. The input has %', $1;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STPointFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOGRAPHY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geography::STPointFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geogfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Point' THEN
			RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "POINT" at Position 1. The input has %', $1;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
	