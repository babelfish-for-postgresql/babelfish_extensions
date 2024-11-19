------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "4.5.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION  sys.smalldatetime_date_cmp(sys.SMALLDATETIME, date)
RETURNS INT4
AS 'timestamp_cmp_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

create or replace function get_bbf_smalldatetime_ops_count(opffamily varchar) returns int as $$
	begin
		return (select count(*) FROM pg_am am, pg_opfamily opf, pg_amop amop WHERE 
			opf.opfmethod = am.oid AND amop.amopfamily = opf.oid and opf.opfname = opffamily);
	end; 
$$ LANGUAGE plpgsql;

DO $$
    DECLARE bbf_smalldatetime_ops_c INT:=(select * from get_bbf_smalldatetime_ops_count('smalldatetime_ops'));
BEGIN
	IF bbf_smalldatetime_ops_c = 6 then
		-- PG will create operator family when creating operator class for bbf_smalldatetime_ops
		-- when didn't assign a operator family when creating
		ALTER OPERATOR FAMILY sys.smalldatetime_ops USING btree ADD
			OPERATOR    1   sys.<  (sys.SMALLDATETIME, date),
			OPERATOR    2   sys.<= (sys.SMALLDATETIME, date),
			OPERATOR    3   sys.=  (sys.SMALLDATETIME, date),
			OPERATOR    4   sys.>= (sys.SMALLDATETIME, date),
			OPERATOR    5   sys.>  (sys.SMALLDATETIME, date),
			FUNCTION    1   sys.smalldatetime_date_cmp(sys.SMALLDATETIME, date);
	else 
		if bbf_smalldatetime_ops_c = 11 THEN
			raise notice 'operator of bbf_smalldatetime_ops is installed';
		else 
			raise exception 'wrong operator numbers in bbf_smalldatetime_ops';
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;

drop function get_bbf_smalldatetime_ops_count(varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
