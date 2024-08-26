-------------------------------------------------------
---- Include changes related to varchar cast here ----
-------------------------------------------------------

CREATE OR REPLACE FUNCTION sys.varchar2time(sys.VARCHAR, INT4)
RETURNS pg_catalog.TIME
AS 'babelfishpg_common', 'varchar2time'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
 
CREATE CAST (sys.VARCHAR AS pg_catalog.TIME)
WITH FUNCTION sys.varchar2time(sys.VARCHAR, INT4) AS IMPLICIT;