------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '5.0.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION  sys.smalldatetime_date_cmp(sys.SMALLDATETIME, date)
RETURNS INT4
AS 'timestamp_cmp_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION  sys.date_smalldatetime_cmp(date, sys.SMALLDATETIME)
RETURNS INT4
AS 'date_cmp_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

-- Operator class for smalldatetime_ops to incorporate various operator between smalldatetime and date for Index scan
DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid WHERE opc.opcname = 'smalldatetime_date_ops' AND opc.opcnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'sys') AND opf.opfname = 'smalldatetime_ops') THEN
CREATE OPERATOR CLASS sys.smalldatetime_date_ops
FOR TYPE sys.SMALLDATETIME USING btree FAMILY smalldatetime_ops AS
    OPERATOR    1   sys.<  (sys.SMALLDATETIME, date),
    OPERATOR    2   sys.<= (sys.SMALLDATETIME, date),
    OPERATOR    3   sys.=  (sys.SMALLDATETIME, date),
    OPERATOR    4   sys.>= (sys.SMALLDATETIME, date),
    OPERATOR    5   sys.>  (sys.SMALLDATETIME, date),
    FUNCTION    1   sys.smalldatetime_date_cmp(sys.SMALLDATETIME, date);
END IF;
END $$;

-- Operator class for smalldatetime_ops to incorporate various operator between date and smalldatetime for Index scan
DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid WHERE opc.opcname = 'date_smalldatetime_ops' AND opc.opcnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'sys') AND opf.opfname = 'smalldatetime_ops') THEN
CREATE OPERATOR CLASS sys.date_smalldatetime_ops
FOR TYPE sys.SMALLDATETIME USING btree FAMILY smalldatetime_ops AS
    OPERATOR    1   sys.<  (date, sys.SMALLDATETIME),
    OPERATOR    2   sys.<= (date, sys.SMALLDATETIME),
    OPERATOR    3   sys.=  (date, sys.SMALLDATETIME),
    OPERATOR    4   sys.>= (date, sys.SMALLDATETIME),
    OPERATOR    5   sys.>  (date, sys.SMALLDATETIME),
    FUNCTION    1   sys.date_smalldatetime_cmp(date, sys.SMALLDATETIME);
END IF;
END $$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
