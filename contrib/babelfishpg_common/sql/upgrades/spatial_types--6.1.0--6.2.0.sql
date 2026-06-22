-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

--Geometry

--STMLineFromText
CREATE OR REPLACE FUNCTION sys.Geometry__STMLineFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'geometry_mlinestring_from_text'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

--STMLineFromWKB
CREATE OR REPLACE FUNCTION sys.Geometry__STMLineFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOMETRY
    AS 'babelfishpg_common', 'geometry_mlinestring_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

--Geography

--STMLineFromText
CREATE OR REPLACE FUNCTION sys.Geography__STMLineFromText(sys.NVARCHAR, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'geography_mlinestring_from_text'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

--STMLineFromWKB
CREATE OR REPLACE FUNCTION sys.Geography__STMLineFromWKB(sys.VARBINARY, srid integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common', 'geography_mlinestring_from_wkb'
    LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;
