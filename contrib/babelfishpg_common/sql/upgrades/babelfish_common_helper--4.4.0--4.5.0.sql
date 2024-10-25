------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "4.5.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION  smalldatetime_date_cmp(sys.SMALLDATETIME, date)
RETURNS INT4
AS 'timestamp_cmp_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

ALTER OPERATOR FAMILY smalldatetime_ops USING btree ADD
    OPERATOR    1   <  (sys.SMALLDATETIME, date),
    OPERATOR    2   <= (sys.SMALLDATETIME, date),
    OPERATOR    3   =  (sys.SMALLDATETIME, date),
    OPERATOR    4   >= (sys.SMALLDATETIME, date),
    OPERATOR    5   >  (sys.SMALLDATETIME, date),
    FUNCTION    1   smalldatetime_date_cmp(sys.SMALLDATETIME, date);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
