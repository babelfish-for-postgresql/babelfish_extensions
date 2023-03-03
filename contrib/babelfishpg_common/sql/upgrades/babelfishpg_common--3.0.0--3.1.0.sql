-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '3.1.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.bigint_avg(INTERNAL)
RETURNS BIGINT
AS 'babelfishpg_common', 'bigint_avg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4int2_avg(pg_catalog._int8)
RETURNS INT
AS 'babelfishpg_common', 'int4int2_avg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.avg(TINYINT)(
SFUNC = int2_avg_accum,
FINALFUNC = int4int2_avg,
STYPE = _int8,
COMBINEFUNC = int4_avg_combine,
PARALLEL = SAFE,
INITCOND='{0,0}'
);

CREATE OR REPLACE AGGREGATE sys.avg(SMALLINT)(
SFUNC = int2_avg_accum,
FINALFUNC = int4int2_avg,
STYPE = _int8,
COMBINEFUNC = int4_avg_combine,
PARALLEL = SAFE,
INITCOND='{0,0}'
);

CREATE OR REPLACE AGGREGATE sys.avg(INT)(
SFUNC = int4_avg_accum,
FINALFUNC = int4int2_avg,
STYPE = _int8,
COMBINEFUNC = int4_avg_combine,
PARALLEL = SAFE,
INITCOND='{0,0}'
);

CREATE OR REPLACE AGGREGATE sys.avg(BIGINT) (
SFUNC = int8_avg_accum,
FINALFUNC = bigint_avg,
STYPE = INTERNAL,
COMBINEFUNC = int8_avg_combine,
SERIALFUNC = int8_avg_serialize,
DESERIALFUNC = int8_avg_deserialize,
PARALLEL = SAFE
);

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

alter OPERATOR sys.= (sys.bbf_binary, sys.bbf_binary) 
set (
    RESTRICT = eqsel
);

alter OPERATOR sys.= (sys.bbf_varbinary, sys.bbf_varbinary) 
set (
    RESTRICT = eqsel
);

create or replace function get_bbf_binary_ops_count(opffamily varchar) returns int as $$
    begin
        return (select count(*) FROM pg_am am, pg_opfamily opf, pg_amop amop WHERE 
            opf.opfmethod = am.oid AND amop.amopfamily = opf.oid and opf.opfname = opffamily);
    end; 
$$ LANGUAGE plpgsql;

DO $$
    DECLARE bbf_binary_ops_c INT:=(select * from get_bbf_binary_ops_count('bbf_binary_ops'));
BEGIN
    IF bbf_binary_ops_c = 5 then
        CREATE OR REPLACE FUNCTION sys.binary_varbinary_eq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean
        AS 'babelfishpg_common', 'varbinary_eq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.bbf_binary_varbinary_cmp(sys.bbf_binary, sys.bbf_varbinary)
        RETURNS int
        AS 'babelfishpg_common', 'varbinary_cmp'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OPERATOR sys.= (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_eq,
            COMMUTATOR = =,
            RESTRICT = eqsel
        );

        -- PG will create operator family when creating operator class for bbf_binary_ops
        -- when didn't assign a operator family when creating
        alter OPERATOR family bbf_binary_ops USING btree add
            OPERATOR 3 sys.= (sys.bbf_binary, sys.bbf_varbinary),
            FUNCTION 1 sys.bbf_binary_varbinary_cmp(sys.bbf_binary, sys.bbf_varbinary);

    else if bbf_binary_ops_c = 6 THEN
            raise notice 'operator of bbf_binary_ops is installed';
        else 
            raise exception 'wrong operator numbers in bbf_binary_ops';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
    DECLARE bbf_varbinary_ops_c INT:=(select * from get_bbf_binary_ops_count('bbf_varbinary_ops'));
BEGIN
    IF bbf_varbinary_ops_c = 5 then
        CREATE OR REPLACE FUNCTION sys.varbinary_binary_eq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean
        AS 'babelfishpg_common', 'varbinary_eq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.bbf_varbinary_binary_cmp(sys.bbf_varbinary, sys.bbf_binary)
        RETURNS int
        AS 'babelfishpg_common', 'varbinary_cmp'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OPERATOR sys.= (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_eq,
            COMMUTATOR = =,
            RESTRICT = eqsel
        );

        alter OPERATOR family bbf_varbinary_ops USING btree add
            OPERATOR 3 sys.= (sys.bbf_varbinary, sys.bbf_binary),
            FUNCTION 1 sys.bbf_varbinary_binary_cmp(sys.bbf_varbinary, sys.bbf_binary);
    else if bbf_varbinary_ops_c = 6 THEN
            raise notice 'operator of bbf_binary_ops is installed';
        else 
            raise exception 'wrong operator numbers in bbf_binary_ops';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

drop function get_bbf_binary_ops_count(varchar);

CREATE CAST (NUMERIC AS sys.BIT)
WITH FUNCTION sys.numeric_bit (NUMERIC) AS IMPLICIT;


-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
