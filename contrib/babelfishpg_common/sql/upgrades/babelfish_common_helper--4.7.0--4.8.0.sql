------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '5.4.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Operator class for numeric_ops to incorporate various operator between numeric and fixeddecimal for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'numeric_fixeddecimal_cmp_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.numeric_fixeddecimal_cmp_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (numeric, sys.fixeddecimal),
            OPERATOR 2 sys.<= (numeric, sys.fixeddecimal),
            OPERATOR 3 sys.= (numeric, sys.fixeddecimal),
            OPERATOR 4 sys.>= (numeric, sys.fixeddecimal),
            OPERATOR 5 sys.> (numeric, sys.fixeddecimal),
            FUNCTION 1 sys.numeric_fixeddecimal_cmp(numeric, sys.fixeddecimal);
    END IF;
END $$;


-- Operator class for numeric_ops to incorporate various operator between fixeddecimal and numeric for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'fixeddecimal_numeric_cmp_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.fixeddecimal_numeric_cmp_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (sys.fixeddecimal, numeric),
            OPERATOR 2 sys.<= (sys.fixeddecimal, numeric),
            OPERATOR 3 sys.= (sys.fixeddecimal, numeric),
            OPERATOR 4 sys.>= (sys.fixeddecimal, numeric),
            OPERATOR 5 sys.> (sys.fixeddecimal, numeric),
            FUNCTION 1 sys.fixeddecimal_numeric_cmp(sys.fixeddecimal, numeric);
    END IF;
END $$;

CREATE OR REPLACE FUNCTION sys.decimal2decimal(sys.DECIMAL, integer)
RETURNS sys.DECIMAL
AS 'numeric'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE 
    sys_oid Oid;
    decimal_oid Oid;
BEGIN
  sys_oid := (SELECT oid FROM pg_namespace WHERE pg_namespace.nspname ='sys');
  decimal_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='decimal' AND pg_type.typnamespace = sys_oid);
  IF (SELECT COUNT(*) FROM pg_cast WHERE pg_cast.castsource = decimal_oid AND pg_cast.casttarget = decimal_oid) = 0 THEN
      CREATE CAST (sys.DECIMAL AS sys.DECIMAL)
      WITH FUNCTION sys.decimal2decimal(sys.DECIMAL, integer) AS IMPLICIT;
  END IF;
END $$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
