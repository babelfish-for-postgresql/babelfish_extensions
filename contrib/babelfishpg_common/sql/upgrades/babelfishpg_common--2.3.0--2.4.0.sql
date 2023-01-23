-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.4.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

/* set sys functions as STABLE */
ALTER FUNCTION sys._round_fixeddecimal_to_int8(In arg sys.fixeddecimal) STABLE;
ALTER FUNCTION sys._round_fixeddecimal_to_int4(In arg sys.fixeddecimal) STABLE;
ALTER FUNCTION sys._round_fixeddecimal_to_int2(In arg sys.fixeddecimal) STABLE;
ALTER FUNCTION sys._trunc_numeric_to_int8(In arg numeric) STABLE;
ALTER FUNCTION sys._trunc_numeric_to_int4(In arg numeric) STABLE;
ALTER FUNCTION sys._trunc_numeric_to_int2(In arg numeric) STABLE;
ALTER FUNCTION sys.CHAR(x in int) STABLE;
ALTER FUNCTION sys.babelfish_concat_wrapper(leftarg text, rightarg text) STABLE;
ALTER FUNCTION sys.babelfish_concat_wrapper_outer(leftarg text, rightarg text) STABLE;
ALTER FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.varchar) STABLE;
ALTER FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.nvarchar) STABLE;
ALTER FUNCTION sys.babelfish_concat_wrapper(leftarg sys.bpchar, rightarg sys.bpchar) STABLE;
ALTER FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nchar, rightarg sys.nchar) STABLE;
ALTER FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.nvarchar) STABLE;
ALTER FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.varchar) STABLE;
ALTER FUNCTION sys.tinyintxor(leftarg sys.tinyint, rightarg sys.tinyint) STABLE;
ALTER FUNCTION sys.int2xor(leftarg int2, rightarg int2) STABLE;
ALTER FUNCTION sys.intxor(leftarg int4, rightarg int4) STABLE;
ALTER FUNCTION sys.int8xor(leftarg int8, rightarg int8) STABLE;
ALTER FUNCTION sys.bitxor(leftarg pg_catalog.bit, rightarg pg_catalog.bit) STABLE;
ALTER FUNCTION sys.newid() STABLE;
ALTER FUNCTION sys.NEWSEQUENTIALID() STABLE;
ALTER FUNCTION sys.babelfish_typecode_list() STABLE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);