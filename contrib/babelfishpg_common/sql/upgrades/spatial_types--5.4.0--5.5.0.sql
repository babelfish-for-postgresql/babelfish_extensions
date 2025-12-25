-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

CREATE OR REPLACE FUNCTION sys.Geometry__STPolyFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOMETRY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOMETRY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geometry::STPolyFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geomfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Polygon' THEN
			RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "POLYGON" at Position 1. The input has %', $1;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STPolyFromText(sys.NVARCHAR,srid integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		Geomtype text;
		geom sys.GEOGRAPHY;
	BEGIN
		IF $2 IS NULL THEN
			RAISE EXCEPTION '''geography::STPolyFromText'' failed because parameter 2 is not allowed to be null.';
		ELSIF $1 IS NULL THEN
			RETURN NULL;
		END IF;
		geom = (SELECT sys.geogfromtext_helper($1::text, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));

		IF Geomtype = 'ST_Polygon' THEN
			RETURN geom;
		ELSE
			RAISE EXCEPTION 'Expected "POLYGON" at Position 1. The input has %', $1;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
