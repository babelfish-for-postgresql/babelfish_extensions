-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

-- STArea 
CREATE OR REPLACE FUNCTION sys.STArea(sys.GEOMETRY)
	RETURNS float8
	AS '$libdir/postgis-3','ST_Area'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- STEqual
CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','ST_Equals'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- STContains
CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOMETRY, geom2 sys.GEOMETRY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','within'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- STArea 
CREATE OR REPLACE FUNCTION sys.STArea(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','ST_Area'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- STEqual
CREATE OR REPLACE FUNCTION sys.STEquals(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','ST_Equals'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- STContains
CREATE OR REPLACE FUNCTION sys.STContains(geom1 sys.GEOGRAPHY, geom2 sys.GEOGRAPHY)
	RETURNS sys.BIT
	AS '$libdir/postgis-3','within'
	LANGUAGE 'c' IMMUTABLE STRICT;