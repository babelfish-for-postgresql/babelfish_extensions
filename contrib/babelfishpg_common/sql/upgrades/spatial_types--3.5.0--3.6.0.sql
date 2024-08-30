-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------
CREATE OR REPLACE FUNCTION sys.STArea(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','ST_Area'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STSrid(sys.GEOMETRY)
	RETURNS integer
	AS '$libdir/postgis-3','LWGEOM_get_srid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
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

CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS $$
	DECLARE
	BEGIN
		IF STSrid(geom1) != STSrid(geom2) THEN
			RETURN NULL;
		ELSE
			Return sys.STContains_helper($1,$2);
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
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

CREATE OR REPLACE FUNCTION sys.ST_NotEquals(leftarg sys.GEOMETRY, rightarg sys.GEOMETRY)
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

CREATE OR REPLACE FUNCTION sys.STContains_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','within'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STEquals_helper(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','ST_Equals'
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

CREATE OR REPLACE FUNCTION sys.ST_Equals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
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

CREATE OR REPLACE FUNCTION sys.STEquals_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','ST_Equals'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STContains_helper(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','within'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

