-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.3.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops an object if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
    query2 := pg_catalog.format('drop %s %s.%s', object_type, schema_name, object_name);

    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.sp_tables_internal(
	in_table_name sys.nvarchar(384) = '',
	in_table_owner sys.nvarchar(384) = '', 
	in_table_qualifier sys.sysname = '',
	in_table_type sys.varchar(100) = '',
	in_fusepattern sys.bit = '1')
	RETURNS TABLE (
		out_table_qualifier sys.sysname,
		out_table_owner sys.sysname,
		out_table_name sys.sysname,
		out_table_type sys.varchar(32),
		out_remarks sys.varchar(254)
	)
	AS $$
		DECLARE opt_table sys.varchar(16) = '';
		DECLARE opt_view sys.varchar(16) = '';
		DECLARE cs_as_in_table_type varchar COLLATE "C" = in_table_type;
	BEGIN
		IF (SELECT count(*) FROM unnest(string_to_array(cs_as_in_table_type, ',')) WHERE upper(trim(unnest)) = '''TABLE''' OR upper(trim(unnest)) = '''''''TABLE''''''') >= 1 THEN
			opt_table = 'TABLE';
		END IF;
		IF (SELECT count(*) from unnest(string_to_array(cs_as_in_table_type, ',')) WHERE upper(trim(unnest)) = '''VIEW''' OR upper(trim(unnest)) = '''''''VIEW''''''') >= 1 THEN
			opt_view = 'VIEW';
		END IF;
		IF in_fusepattern = 1 THEN
			RETURN query
			SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			CAST(remarks AS sys.varchar(254)) AS REMARKS
			FROM sys.sp_tables_view
			WHERE ((SELECT coalesce(in_table_name,'')) = '' OR table_name LIKE in_table_name collate sys.bbf_unicode_general_ci_as)
			AND ((SELECT coalesce(in_table_owner,'')) = '' OR table_owner LIKE in_table_owner collate sys.bbf_unicode_general_ci_as)
			AND ((SELECT coalesce(in_table_qualifier,'')) = '' OR table_qualifier LIKE in_table_qualifier collate sys.bbf_unicode_general_ci_as)
			AND ((SELECT coalesce(cs_as_in_table_type,'')) = ''
			    OR table_type collate sys.bbf_unicode_general_ci_as = opt_table
			    OR table_type collate sys.bbf_unicode_general_ci_as= opt_view)
			ORDER BY table_qualifier, table_owner, table_name;
		ELSE 
			RETURN query
			SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			CAST(remarks AS sys.varchar(254)) AS REMARKS
			FROM sys.sp_tables_view
			WHERE ((SELECT coalesce(in_table_name,'')) = '' OR table_name = in_table_name collate sys.bbf_unicode_general_ci_as)
			AND ((SELECT coalesce(in_table_owner,'')) = '' OR table_owner = in_table_owner collate sys.bbf_unicode_general_ci_as)
			AND ((SELECT coalesce(in_table_qualifier,'')) = '' OR table_qualifier = in_table_qualifier collate sys.bbf_unicode_general_ci_as)
			AND ((SELECT coalesce(cs_as_in_table_type,'')) = ''
			    OR table_type = opt_table
			    OR table_type = opt_view)
			ORDER BY table_qualifier, table_owner, table_name;
		END IF;
	END;
$$
LANGUAGE plpgsql;

-- please add your SQL here
CREATE OR REPLACE FUNCTION sys.DATETIMEOFFSETFROMPARTS(IN p_year INTEGER,
                                                               IN p_month INTEGER,
                                                               IN p_day INTEGER,
                                                               IN p_hour INTEGER,
                                                               IN p_minute INTEGER,
                                                               IN p_seconds INTEGER,
                                                               IN p_fractions INTEGER,
                                                               IN p_hour_offset INTEGER,
                                                               IN p_minute_offset INTEGER,
                                                               IN p_precision NUMERIC)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    v_err_message SYS.VARCHAR;
    v_fractions SYS.VARCHAR;
    v_precision SMALLINT;
    v_calc_seconds NUMERIC; 
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
    v_string pg_catalog.text;
    v_sign pg_catalog.text;
BEGIN
    v_fractions := p_fractions::SYS.VARCHAR;
    IF p_precision IS NULL THEN
        RAISE EXCEPTION 'Scale argument is not valid. Valid expressions for data type datetimeoffset scale argument are integer constants and integer constant expressions.';
    END IF;
    IF p_year IS NULL OR p_month is NULL OR p_day IS NULL OR p_hour IS NULL OR p_minute IS NULL OR p_seconds IS NULL OR p_fractions IS NULL
            OR p_hour_offset IS NULL OR p_minute_offset is NULL THEN
        RETURN NULL;
    END IF;
    v_precision := p_precision::SMALLINT;

    IF (scale(p_precision) > 0) THEN
        RAISE most_specific_type_mismatch;

    -- Check if arguments are out of range
    ELSIF ((p_year NOT BETWEEN 1753 AND 9999) OR
        (p_month NOT BETWEEN 1 AND 12) OR
        (p_day NOT BETWEEN 1 AND 31) OR
        (p_hour NOT BETWEEN 0 AND 23) OR
        (p_minute NOT BETWEEN 0 AND 59) OR
        (p_seconds NOT BETWEEN 0 AND 59) OR
        (p_hour_offset NOT BETWEEN -14 AND 14) OR
        (p_minute_offset NOT BETWEEN -59 AND 59) OR
        (p_hour_offset * p_minute_offset < 0) OR
        (p_hour_offset = 14 AND p_minute_offset != 0) OR
        (p_hour_offset = -14 AND p_minute_offset != 0) OR
        (p_fractions != 0 AND char_length(v_fractions) > p_precision::SMALLINT))
    THEN
        RAISE invalid_datetime_format;
    ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
        RAISE numeric_value_out_of_range;
    END IF;
    v_calc_seconds := format('%s.%s',
                             p_seconds,
                             substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

    v_resdatetime := make_timestamp(p_year,
                                    p_month,
                                    p_day,
                                    p_hour,
                                    p_minute,
                                    v_calc_seconds);
    v_sign := (
        SELECT CASE
            WHEN (p_hour_offset) > 0
                THEN '+'
            WHEN (p_hour_offset) = 0 AND (p_minute_offset) >= 0
                THEN '+'    
            ELSE '-'
        END
    );
    v_string := CONCAT(v_resdatetime::pg_catalog.text,v_sign,abs(p_hour_offset)::SMALLINT::text,':',
                                                          abs(p_minute_offset)::SMALLINT::text);
    RETURN CAST(v_string AS sys.DATETIMEOFFSET);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type datetimeoffset scale argument are integer constants and integer constant expressions',
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';    
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type datetimeoffset, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := format('Specified scale % is invalid.', p_fractions),
                    DETAIL := format('Source value is out of %s data type range.', v_err_message),
                    HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.is_table_type(object_id oid) RETURNS bool AS
$BODY$
SELECT
  EXISTS(
    SELECT 1
    FROM pg_catalog.pg_type pt
    INNER JOIN pg_catalog.pg_depend dep
    ON pt.typrelid = dep.objid AND pt.oid = dep.refobjid
    join sys.schemas sch on pt.typnamespace = sch.schema_id
    JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE pt.typtype = 'c' AND dep.deptype = 'i' AND pt.typrelid = object_id AND pc.relkind = 'r'
    AND dep.classid = 'pg_catalog.pg_class'::regclass AND dep.refclassid = 'pg_catalog.pg_type'::regclass);
$BODY$
LANGUAGE SQL VOLATILE STRICT;

CREATE OR REPLACE PROCEDURE sys.sp_helpsrvrolemember("@srvrolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If server role is not specified, return info for all server roles
	IF @srvrolename IS NULL
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R'
		ORDER BY ServerRole, MemberName;
	END
	-- If a valid server role is specified, return its member info
	-- If the role is a SQL server predefined role (i.e. serveradmin), 
	-- do not raise an error even if it does not exist
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_login_ext
					WHERE (rolname = RTRIM(@srvrolename)
					OR lower(rolname) = lower(RTRIM(@srvrolename)))
					AND type = 'R')
					OR lower(RTRIM(@srvrolename)) IN (
					'serveradmin', 'setupadmin', 'securityadmin', 'processadmin',
					'dbcreator', 'diskadmin', 'bulkadmin')
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R'
		AND (Ext1.rolname = RTRIM(@srvrolename) OR lower(Ext1.rolname) = lower(RTRIM(@srvrolename)))
		ORDER BY ServerRole, MemberName;
	END
	-- If the specified server role is not valid
	ELSE
		RAISERROR('%s is not a known fixed role.', 16, 1, @srvrolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpsrvrolemember TO PUBLIC;

-- Need to add parameter for tsql_type_max_length_helper 
ALTER FUNCTION sys.tsql_type_max_length_helper RENAME TO tsql_type_max_length_helper_deprecated_in_2_3_0;

CREATE OR REPLACE FUNCTION sys.tsql_type_max_length_helper(IN type TEXT, IN typelen INT, IN typemod INT, IN for_sys_types boolean DEFAULT false, IN used_typmod_array boolean DEFAULT false)
RETURNS SMALLINT
AS $$
DECLARE
	max_length SMALLINT;
	precision INT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	-- unknown tsql type
	IF v_type IS NULL THEN
		RETURN CAST(typelen as SMALLINT);
	END IF;

	-- if using typmod_array from pg_proc.probin
	IF used_typmod_array THEN
		IF v_type = 'sysname' THEN
			RETURN 256;
		ELSIF (v_type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary', 'nchar', 'nvarchar'))
		THEN
			IF typemod < 0 THEN -- max value. 
				RETURN -1;
			ELSIF v_type in ('nchar', 'nvarchar') THEN
				RETURN (2 * typemod);
			ELSE
				RETURN typemod;
			END IF;
		END IF;
	END IF;
 
	IF typelen != -1 THEN
		CASE v_type 
		WHEN 'tinyint' THEN max_length = 1;
		WHEN 'date' THEN max_length = 3;
		WHEN 'smalldatetime' THEN max_length = 4;
		WHEN 'smallmoney' THEN max_length = 4;
		WHEN 'datetime2' THEN
			IF typemod = -1 THEN max_length = 8;
			ELSIF typemod <= 2 THEN max_length = 6;
			ELSIF typemod <= 4 THEN max_length = 7;
			ELSEIF typemod <= 7 THEN max_length = 8;
			-- typemod = 7 is not possible for datetime2 in Babel
			END IF;
		WHEN 'datetimeoffset' THEN
			IF typemod = -1 THEN max_length = 10;
			ELSIF typemod <= 2 THEN max_length = 8;
			ELSIF typemod <= 4 THEN max_length = 9;
			ELSIF typemod <= 7 THEN max_length = 10;
			-- typemod = 7 is not possible for datetimeoffset in Babel
			END IF;
		WHEN 'time' THEN
			IF typemod = -1 THEN max_length = 5;
			ELSIF typemod <= 2 THEN max_length = 3;
			ELSIF typemod <= 4 THEN max_length = 4;
			ELSIF typemod <= 7 THEN max_length = 5;
			END IF;
		WHEN 'timestamp' THEN max_length = 8;
		ELSE max_length = typelen;
		END CASE;
		RETURN max_length;
	END IF;

	IF typemod = -1 THEN
		CASE 
		WHEN v_type in ('image', 'text', 'ntext') THEN max_length = 16;
		WHEN v_type = 'sql_variant' THEN max_length = 8016;
		WHEN v_type in ('varbinary', 'varchar', 'nvarchar') THEN 
			IF for_sys_types THEN max_length = 8000;
			ELSE max_length = -1;
			END IF;
		WHEN v_type in ('binary', 'char', 'bpchar', 'nchar') THEN max_length = 8000;
		WHEN v_type in ('decimal', 'numeric') THEN max_length = 17;
		ELSE max_length = typemod;
		END CASE;
		RETURN max_length;
	END IF;

	CASE
	WHEN v_type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary') THEN max_length = typemod - 4;
	WHEN v_type in ('nchar', 'nvarchar') THEN max_length = (typemod - 4) * 2;
	WHEN v_type = 'sysname' THEN max_length = (typemod - 4) * 2;
	WHEN v_type in ('numeric', 'decimal') THEN
		precision = ((typemod - 4) >> 16) & 65535;
		IF precision >= 1 and precision <= 9 THEN max_length = 5;
		ELSIF precision <= 19 THEN max_length = 9;
		ELSIF precision <= 28 THEN max_length = 13;
		ELSIF precision <= 38 THEN max_length = 17;
	ELSE max_length = typelen;
	END IF;
	ELSE
		max_length = typemod;
	END CASE;
	RETURN max_length;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- The sys.table_types_internal view mimics the logic used in sys.is_table_type function
create or replace view sys.table_types_internal as
SELECT pt.typrelid
    FROM pg_catalog.pg_type pt
    INNER JOIN pg_catalog.pg_depend dep
    ON pt.typrelid = dep.objid
    INNER JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE 
    pt.typnamespace in (select schema_id from sys.schemas) 
    and (pt.typtype = 'c' AND dep.deptype = 'i'  AND pc.relkind = 'r')
;

-- re-creating objects to point to new tsql_type_max_length_helper

create or replace view sys.types As
with type_code_list as
(
    select distinct  pg_typname as pg_type_name, tsql_typname as tsql_type_name
    from sys.babelfish_typecode_list()
)
-- For System types
select 
  ti.tsql_type_name as name
  , t.oid as system_type_id
  , t.oid as user_type_id
  , s.oid as schema_id
  , cast(NULL as INT) as principal_id
  , sys.tsql_type_max_length_helper(ti.tsql_type_name, t.typlen, t.typtypmod, true) as max_length
  , cast(sys.tsql_type_precision_helper(ti.tsql_type_name, t.typtypmod) as int) as precision
  , cast(sys.tsql_type_scale_helper(ti.tsql_type_name, t.typtypmod, false) as int) as scale
  , CASE c.collname
    WHEN 'default' THEN default_collation_name
    ELSE  c.collname
    END as collation_name
  , case when typnotnull then 0 else 1 end as is_nullable
  , 0 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , 0 as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
inner join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
,cast(current_setting('babelfishpg_tsql.server_collation_name') as name) as default_collation_name
where
ti.tsql_type_name IS NOT NULL  
and pg_type_is_visible(t.oid)
and (s.nspname = 'pg_catalog' OR s.nspname = 'sys')
union all 
-- For User Defined Types
select cast(t.typname as text) as name
  , t.typbasetype as system_type_id
  , t.oid as user_type_id
  , t.typnamespace as schema_id
  , null::integer as principal_id
  , case when tt.typrelid is not null then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when tt.typrelid is not null then 0::smallint else cast(sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) as int) end as precision
  , case when tt.typrelid is not null then 0::smallint else cast(sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) as int) end as scale
  , CASE c.collname
    WHEN 'default' THEN default_collation_name
    ELSE  c.collname 
    END as collation_name
  , case when tt.typrelid is not null then 0
         else case when typnotnull then 0 else 1 end
    end
    as is_nullable
  -- CREATE TYPE ... FROM is implemented as CREATE DOMAIN in babel
  , 1 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , case when tt.typrelid is not null then 1 else 0 end as is_table_type
from pg_type t
join sys.schemas sch on t.typnamespace = sch.schema_id
left join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
left join sys.table_types_internal tt on t.typrelid = tt.typrelid
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
, cast(current_setting('babelfishpg_tsql.server_collation_name') as name) as default_collation_name
-- we want to show details of user defined datatypes created under babelfish database
where 
 ti.tsql_type_name IS NULL
and
  (
    -- show all user defined datatypes created under babelfish database except table types
    t.typtype = 'd'
    or
    -- only for table types
    tt.typrelid is not null  
  );
GRANT SELECT ON sys.types TO PUBLIC;

create or replace view sys.all_columns as
select CAST(c.oid as int) as object_id
  , CAST(a.attname as sys.sysname) as name
  , CAST(a.attnum as int) as column_id
  , CAST(t.oid as int) as system_type_id
  , CAST(t.oid as int) as user_type_id
  , CAST(sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod) as smallint) as max_length
  , CAST(case
      when a.atttypmod != -1 then 
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
      else 
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
    end as sys.tinyint) as precision
  , CAST(case
      when a.atttypmod != -1 THEN 
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
      else 
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
    end as sys.tinyint) as scale
  , CAST(coll.collname as sys.sysname) as collation_name
  , case when a.attnotnull then CAST(0 as sys.bit) else CAST(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_ansi_padded
  , CAST(0 as sys.bit) as is_rowguidcol
  , CAST(0 as sys.bit) as is_identity
  , CAST(0 as sys.bit) as is_computed
  , CAST(0 as sys.bit) as is_filestream
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as is_non_sql_subscribed
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_dts_replicated
  , CAST(0 as sys.bit) as is_xml_document
  , CAST(0 as int) as xml_collection_id
  , CAST(coalesce(d.oid, 0) as int) as default_object_id
  , CAST(coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as int) as rule_object_id
  , CAST(0 as sys.bit) as is_sparse
  , CAST(0 as sys.bit) as is_column_set
  , CAST(0 as sys.tinyint) as generated_always_type
  , CAST('NOT_APPLICABLE' as sys.nvarchar(60)) as generated_always_type_desc
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
where not a.attisdropped
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;

CALL babelfish_drop_deprecated_object('function', 'sys', 'tsql_type_max_length_helper_deprecated_in_2_3_0');

CREATE OR REPLACE VIEW sys.all_parameters
AS
SELECT
    CAST(ss.p_oid AS INT) AS object_id
  , CAST(COALESCE(ss.proargnames[(ss.x).n], '') AS sys.SYSNAME) AS name
  , CAST(
      CASE 
        WHEN is_out_scalar = 1 THEN 0 -- param_id = 0 for output of scalar function
        ELSE (ss.x).n
      END 
    AS INT) AS parameter_id
  -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
  -- This is because the IDs of system type values generated by
  -- Babelfish installation will exceed the size of TINYINT
  , CAST(st.system_type_id AS INT) AS system_type_id
  , CAST(st.user_type_id AS INT) AS user_type_id
  , CAST( 
      CASE
        WHEN st.is_table_type = 1 THEN -1 -- TVP case
        WHEN st.is_user_defined = 1 THEN st.max_length -- UDT case
        ELSE sys.tsql_type_max_length_helper(st.name, t.typlen, typmod, true, true)
      END
    AS smallint) AS max_length
  , CAST(
      CASE
        WHEN st.is_table_type = 1 THEN 0 -- TVP case
        WHEN st.is_user_defined = 1  THEN st.precision -- UDT case
        ELSE sys.tsql_type_precision_helper(st.name, typmod)
      END
    AS sys.tinyint) AS precision
  , CAST(
      CASE 
        WHEN st.is_table_type = 1 THEN 0 -- TVP case
        WHEN st.is_user_defined = 1  THEN st.scale
        ELSE sys.tsql_type_scale_helper(st.name, typmod,false)
      END
    AS sys.tinyint) AS scale
  , CAST(
      CASE
        WHEN is_out_scalar = 1 THEN 1 -- Output of a scalar function
        WHEN ss.proargmodes[(ss.x).n] in ('o', 'b', 't') THEN 1
        ELSE 0
      END 
    AS sys.bit) AS is_output
  , CAST(0 AS sys.bit) AS is_cursor_ref
  , CAST(0 AS sys.bit) AS has_default_value
  , CAST(0 AS sys.bit) AS is_xml_document
  , CAST(NULL AS sys.sql_variant) AS default_value
  , CAST(0 AS int) AS xml_collection_id
  , CAST(0 AS sys.bit) AS is_readonly
  , CAST(1 AS sys.bit) AS is_nullable
  , CAST(NULL AS int) AS encryption_type
  , CAST(NULL AS sys.nvarchar(64)) AS encryption_type_desc
  , CAST(NULL AS sys.sysname) AS encryption_algorithm_name
  , CAST(NULL AS int) AS column_encryption_key_id
  , CAST(NULL AS sys.sysname) AS column_encryption_key_database_name
FROM pg_type t
  INNER JOIN sys.types st ON st.user_type_id = t.oid
  INNER JOIN 
  (
    SELECT
      p.oid AS p_oid,
      p.proargnames,
      p.proargmodes,
      p.prokind,
      json_extract_path(CAST(p.probin as json), 'typmod_array') AS typmod_array,
      information_schema._pg_expandarray(
      COALESCE(p.proallargtypes,
        CASE 
          WHEN p.prokind = 'f' THEN (CAST( p.proargtypes AS oid[]) || p.prorettype) -- Adds return type if not present on proallargtypes
          ELSE CAST(p.proargtypes AS oid[])
        END
      )) AS x
    FROM pg_proc p
    WHERE (
      p.pronamespace in (select schema_id from sys.schemas union all select oid from pg_namespace where nspname = 'sys')
      AND (pg_has_role(p.proowner, 'USAGE') OR has_function_privilege(p.oid, 'EXECUTE'))
      AND p.probin like '{%typmod_array%}') -- Needs to have a typmod array in JSON format
  ) ss ON t.oid = (ss.x).x,
  COALESCE(pg_get_function_result(ss.p_oid), '') AS return_type,
  CAST(ss.typmod_array->>(ss.x).n-1 AS INT) AS typmod, 
  CAST(
    CASE
      WHEN ss.prokind = 'f' AND ss.proargnames[(ss.x).n] IS NULL THEN 1 -- checks if param is output of scalar function
      ELSE 0
    END 
  AS INT) AS is_out_scalar
WHERE ( -- If it's a Table function, we only want the inputs
      return_type NOT LIKE 'TABLE(%' OR 
      (return_type LIKE 'TABLE(%' AND ss.proargmodes[(ss.x).n] = 'i'));
GRANT SELECT ON sys.all_parameters TO PUBLIC;


-- TODO: BABEL-3127
CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF') THEN COALESCE(tsql_get_functiondef(ao.object_id), pg_get_functiondef(ao.object_id))
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      WHEN ao.type = 'TR' THEN NULL
      ELSE NULL
      END
    AS sys.nvarchar(4000)) AS definition  -- Object definition work in progress, will update definition with BABEL-3127 Jira.
  , CAST(1 as sys.bit)  AS uses_ansi_nulls
  , CAST(1 as sys.bit)  AS uses_quoted_identifier
  , CAST(0 as sys.bit)  AS is_schema_bound
  , CAST(0 as sys.bit)  AS uses_database_collation
  , CAST(0 as sys.bit)  AS is_recompiled
  , CAST(
      CASE WHEN ao.type IN ('P', 'FN', 'IN', 'TF', 'RF') THEN
        CASE WHEN p.proisstrict THEN 1
        ELSE 0 
        END
      ELSE 0
      END
    AS sys.bit) as null_on_null_input
  , null::integer as execute_as_principal_id
  , CAST(0 as sys.bit) as uses_native_compilation
  , CAST(ao.is_ms_shipped as INT) as is_ms_shipped
FROM sys.all_objects ao
LEFT OUTER JOIN sys.pg_namespace_ext nmext on ao.schema_id = nmext.oid
LEFT OUTER JOIN sys.babelfish_namespace_ext ext ON nmext.nspname = ext.nspname
LEFT OUTER JOIN sys.babelfish_view_def bvd 
 on (
      ext.orig_name = bvd.schema_name AND 
      ext.dbid = bvd.dbid AND
      ao.name = bvd.object_name 
   )
LEFT JOIN pg_proc p ON ao.object_id = CAST(p.oid AS INT)
WHERE ao.type in ('P', 'RF', 'V', 'TR', 'FN', 'IF', 'TF', 'R');
GRANT SELECT ON sys.all_sql_modules_internal TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.dateadd_internal_df(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate datetimeoffset) RETURNS datetimeoffset AS $$
BEGIN
	CASE datepart
	WHEN 'year' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(years => num);
	WHEN 'quarter' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(months => num * 3);
	WHEN 'month' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(months => num);
	WHEN 'dayofyear', 'y' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'day' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'week' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(weeks => num);
	WHEN 'weekday' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'hour' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(hours => num);
	WHEN 'minute' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(mins => num);
	WHEN 'second' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => num);
	WHEN 'millisecond' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => (num::numeric) * 0.001);
	WHEN 'microsecond' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => (num::numeric) * 0.000001);
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		RETURN startdate OPERATOR(sys.+) make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
	ELSE
		RAISE EXCEPTION '"%" is not a recognized dateadd option.', datepart;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd_internal(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT AS $$
BEGIN
    IF pg_typeof(startdate) = 'date'::regtype AND
		datepart IN ('hour', 'minute', 'second', 'millisecond', 'microsecond', 'nanosecond') THEN
		RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type date.', datepart;
	END IF;
    IF pg_typeof(startdate) = 'time'::regtype AND
		datepart IN ('year', 'quarter', 'month', 'doy', 'day', 'week', 'weekday') THEN
		RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type time.', datepart;
	END IF;

	CASE datepart
	WHEN 'year' THEN
		RETURN startdate + make_interval(years => num);
	WHEN 'quarter' THEN
		RETURN startdate + make_interval(months => num * 3);
	WHEN 'month' THEN
		RETURN startdate + make_interval(months => num);
	WHEN 'dayofyear', 'y' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'day' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'week' THEN
		RETURN startdate + make_interval(weeks => num);
	WHEN 'weekday' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'hour' THEN
		RETURN startdate + make_interval(hours => num);
	WHEN 'minute' THEN
		RETURN startdate + make_interval(mins => num);
	WHEN 'second' THEN
		RETURN startdate + make_interval(secs => num);
	WHEN 'millisecond' THEN
		RETURN startdate + make_interval(secs => (num::numeric) * 0.001);
	WHEN 'microsecond' THEN
        IF pg_typeof(startdate) = 'time'::regtype THEN
            RETURN startdate + make_interval(secs => (num::numeric) * 0.000001);
        ELSIF pg_typeof(startdate) = 'sys.datetime2'::regtype THEN
            RETURN startdate + make_interval(secs => (num::numeric) * 0.000001);
        ELSIF pg_typeof(startdate) = 'sys.smalldatetime'::regtype THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type smalldatetime.', datepart;
        ELSE
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type datetime.', datepart;
        END IF;
	WHEN 'nanosecond' THEN
        IF pg_typeof(startdate) = 'time'::regtype THEN
            RETURN startdate + make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
        ELSIF pg_typeof(startdate) = 'sys.datetime2'::regtype THEN
            RETURN startdate + make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
        ELSIF pg_typeof(startdate) = 'sys.smalldatetime'::regtype THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type smalldatetime.', datepart;
        ELSE
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type datetime.', datepart;
        END IF;
	ELSE
		RAISE EXCEPTION '''%'' is not a recognized dateadd option.', datepart;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION sys.format_datetime(IN value anyelement, IN format_pattern NVARCHAR,IN culture VARCHAR,  IN data_type VARCHAR DEFAULT '') RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'format_datetime' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.format_datetime(IN anyelement, IN NVARCHAR, IN VARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.format_numeric(IN value anyelement, IN format_pattern NVARCHAR,IN culture VARCHAR,  IN data_type VARCHAR DEFAULT '', IN e_position INT DEFAULT -1) RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'format_numeric' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.format_numeric(IN anyelement, IN NVARCHAR, IN VARCHAR, IN VARCHAR, IN INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.FORMAT(IN arg anyelement, IN p_format_pattern NVARCHAR, IN p_culture VARCHAR default 'en-us')
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    arg_type regtype;
    v_temp_integer INTEGER;
BEGIN
    arg_type := pg_typeof(arg);

    CASE
        WHEN arg_type IN ('time'::regtype ) THEN
            RETURN sys.format_datetime(arg, p_format_pattern, p_culture, 'time');

        WHEN arg_type IN ('date'::regtype, 'sys.datetime'::regtype, 'sys.smalldatetime'::regtype, 'sys.datetime2'::regtype ) THEN
            RETURN sys.format_datetime(arg::timestamp, p_format_pattern, p_culture);

        WHEN arg_type IN ('sys.tinyint'::regtype) THEN
            RETURN sys.format_numeric(arg::SMALLINT, p_format_pattern, p_culture, 'tinyint');

        WHEN arg_type IN ('smallint'::regtype) THEN
            RETURN sys.format_numeric(arg::SMALLINT, p_format_pattern, p_culture, 'smallint');

        WHEN arg_type IN ('integer'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'integer');

         WHEN arg_type IN ('bigint'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'bigint');

        WHEN arg_type IN ('numeric'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'numeric');

        WHEN arg_type IN ('sys.decimal'::regtype) THEN
            RETURN sys.format_numeric(arg::numeric, p_format_pattern, p_culture, 'numeric');

        WHEN arg_type IN ('real'::regtype) THEN
            IF(p_format_pattern LIKE 'R%') THEN
                v_temp_integer := length(nullif((regexp_matches(arg::real::text, '(?<=\d*\.).*(?=[eE].*)')::text[])[1], ''));
            ELSE v_temp_integer:= -1;
            END IF;

            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'real', v_temp_integer);

        WHEN arg_type IN ('float'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'float');

        WHEN pg_typeof(arg) IN ('sys.smallmoney'::regtype, 'sys.money'::regtype) THEN
            RETURN sys.format_numeric(arg::numeric, p_format_pattern, p_culture, 'numeric');
        ELSE
            RAISE datatype_mismatch;
        END CASE;
EXCEPTION
	WHEN datatype_mismatch THEN
		RAISE USING MESSAGE := format('Argument data type % is invalid for argument 1 of format function.', pg_typeof(arg)),
					DETAIL := 'Invalid datatype.',
					HINT := 'Convert it to valid datatype and try again.';
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.FORMAT(IN anyelement, IN NVARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_any(IN arg TEXT, INOUT output ANYELEMENT, IN typmod INT)
RETURNS ANYELEMENT
AS $BODY$ BEGIN
    EXECUTE pg_catalog.format('SELECT CAST(%L AS %s)', arg, format_type(pg_typeof(output), typmod)) INTO output;
    EXCEPTION
        WHEN OTHERS THEN
            -- Do nothing. Output carries NULL.
END; $BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_date_to_string(IN p_datatype TEXT,
                                                                 IN p_dateval DATE,
                                                                 IN p_style NUMERIC DEFAULT 20)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_dateval DATE;
    v_style SMALLINT;
    v_month SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_language VARCHAR COLLATE "C";
    v_monthname VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_style := floor(p_style)::SMALLINT;
    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 13) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 113) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    ELSIF (v_style IN (8, 24, 108)) THEN
        RAISE invalid_datetime_format;
    END IF;
    IF (v_datatype ~* DATATYPE_MASK_REGEXP) THEN
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));
        v_maxlength := CASE
                          WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                          ELSE NVARCHAR_MAX
                       END;
        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);
        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;
        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;
    v_dateval := CASE
                    WHEN (v_style NOT IN (130, 131)) THEN p_dateval
                    ELSE sys.babelfish_conv_greg_to_hijri(p_dateval) + 1
                 END;
    v_day := ltrim(to_char(v_dateval, 'DD'), '0');
    v_month := to_char(v_dateval, 'MM')::SMALLINT;
    v_language := CASE
                     WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                     ELSE CONVERSION_LANG
                  END;
 RAISE NOTICE 'v_language=[%]', v_language;		  
    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;
    v_monthname := (v_lang_metadata_json -> 'months_shortnames') ->> v_month - 1;
    v_resmask := CASE
                    WHEN (v_style IN (1, 22)) THEN 'MM/DD/YY'
                    WHEN (v_style = 101) THEN 'MM/DD/YYYY'
                    WHEN (v_style = 2) THEN 'YY.MM.DD'
                    WHEN (v_style = 102) THEN 'YYYY.MM.DD'
                    WHEN (v_style = 3) THEN 'DD/MM/YY'
                    WHEN (v_style = 103) THEN 'DD/MM/YYYY'
                    WHEN (v_style = 4) THEN 'DD.MM.YY'
                    WHEN (v_style = 104) THEN 'DD.MM.YYYY'
                    WHEN (v_style = 5) THEN 'DD-MM-YY'
                    WHEN (v_style = 105) THEN 'DD-MM-YYYY'
                    WHEN (v_style = 6) THEN 'DD $mnme$ YY'
                    WHEN (v_style IN (13, 106, 113)) THEN 'DD $mnme$ YYYY'
                    WHEN (v_style = 7) THEN '$mnme$ DD, YY'
                    WHEN (v_style = 107) THEN '$mnme$ DD, YYYY'
                    WHEN (v_style = 10) THEN 'MM-DD-YY'
                    WHEN (v_style = 110) THEN 'MM-DD-YYYY'
                    WHEN (v_style = 11) THEN 'YY/MM/DD'
                    WHEN (v_style = 111) THEN 'YYYY/MM/DD'
                    WHEN (v_style = 12) THEN 'YYMMDD'
                    WHEN (v_style = 112) THEN 'YYYYMMDD'
                    WHEN (v_style IN (20, 21, 23, 25, 120, 121, 126, 127)) THEN 'YYYY-MM-DD'
                    WHEN (v_style = 130) THEN 'DD $mnme$ YYYY'
                    WHEN (v_style = 131) THEN pg_catalog.format('%s/MM/YYYY', lpad(v_day, 2, ' '))
                    WHEN (v_style IN (0, 9, 100, 109)) THEN pg_catalog.format('$mnme$ %s YYYY', lpad(v_day, 2, ' '))
                 END;

    v_resstring := to_char(v_dateval, v_resmask);
    v_resstring := pg_catalog.replace(v_resstring, '$mnme$', v_monthname);
    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
    RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from DATE to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
    RAISE USING MESSAGE := pg_catalog.format('Error converting data type DATE to %s.', trim(p_datatype)),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

   WHEN interval_field_overflow THEN
   RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr,
                                     lower(v_res_datatype),
                                     v_maxlength),
                   DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';
    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
    RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

		RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT (or INTEGER) data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_datetime_to_string(IN p_datatype TEXT,
                                                                     IN p_src_datatype TEXT,
                                                                     IN p_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE,
                                                                     IN p_style NUMERIC DEFAULT -1)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_hour VARCHAR COLLATE "C";
    v_month SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_language VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_fractsep VARCHAR COLLATE "C";
    v_monthname VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR COLLATE "C" := '^(?:DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    v_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE;
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_src_datatype := upper(trim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;
    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT;
        v_src_datatype := rtrim(split_part(v_src_datatype, '(', 1));
        IF (v_src_datatype <> 'DATETIME2' AND v_scale IS NOT NULL) THEN
            RAISE invalid_indicator_parameter_value;
        ELSIF (v_scale NOT BETWEEN 0 AND 7) THEN
            RAISE invalid_regular_expression;
        END IF;
        v_scale := coalesce(v_scale, 7);
    ELSE
        RAISE most_specific_type_mismatch;
    END IF;
    IF (scale(p_style) > 0) THEN
        RAISE escape_character_conflict;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (-1, 120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;
    IF (v_datatype ~* DATATYPE_MASK_REGEXP) THEN
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));
        v_maxlength := CASE
                          WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                          ELSE NVARCHAR_MAX
                       END;
        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);
        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4)
        THEN
            RAISE interval_field_overflow;
        END IF;
        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;
    v_datetimeval := CASE
                        WHEN (v_style NOT IN (130, 131)) THEN p_datetimeval
                        ELSE sys.babelfish_conv_greg_to_hijri(p_datetimeval) + INTERVAL '1 day'
                     END;
    v_day := ltrim(to_char(v_datetimeval, 'DD'), '0');
    v_hour := ltrim(to_char(v_datetimeval, 'HH12'), '0');
    v_month := to_char(v_datetimeval, 'MM')::SMALLINT;
    v_language := CASE
                     WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                     ELSE CONVERSION_LANG
                  END;
    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;
    v_monthname := (v_lang_metadata_json -> 'months_shortnames') ->> v_month - 1;
    IF (v_src_datatype IN ('DATETIME', 'SMALLDATETIME')) THEN
        v_fseconds := sys.babelfish_round_fractseconds(to_char(v_datetimeval, 'MS'));
        IF (v_fseconds::INTEGER = 1000) THEN
            v_fseconds := '000';
            v_datetimeval := v_datetimeval + INTERVAL '1 second';
        ELSE
            v_fseconds := lpad(v_fseconds, 3, '0');
        END IF;
    ELSE
        v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(to_char(v_datetimeval, 'US'), v_scale);
        IF (v_scale = 7) THEN
            v_fseconds := concat(v_fseconds, '0');
        END IF;
    END IF;
    v_fractsep := CASE v_src_datatype
                     WHEN 'DATETIME2' THEN '.'
                     ELSE ':'
                  END;
    IF ((v_style = -1 AND v_src_datatype <> 'DATETIME2') OR
        v_style IN (0, 9, 100, 109))
    THEN
    	v_resmask := pg_catalog.format('$mnme$ %s YYYY %s:MI%s',
                            lpad(v_day, 2, ' '),
                            lpad(v_hour, 2, ' '),
                            CASE
                               WHEN (v_style IN (-1, 0, 100)) THEN 'AM'
                               ELSE pg_catalog.format(':SS:%sAM', v_fseconds)
                            END);
                            ELSIF (v_style = 1) THEN
        v_resmask := 'MM/DD/YY';
    ELSIF (v_style = 101) THEN
        v_resmask := 'MM/DD/YYYY';
    ELSIF (v_style = 2) THEN
        v_resmask := 'YY.MM.DD';
    ELSIF (v_style = 102) THEN
        v_resmask := 'YYYY.MM.DD';
    ELSIF (v_style = 3) THEN
        v_resmask := 'DD/MM/YY';
    ELSIF (v_style = 103) THEN
        v_resmask := 'DD/MM/YYYY';
    ELSIF (v_style = 4) THEN
        v_resmask := 'DD.MM.YY';
    ELSIF (v_style = 104) THEN
        v_resmask := 'DD.MM.YYYY';
    ELSIF (v_style = 5) THEN
        v_resmask := 'DD-MM-YY';
    ELSIF (v_style = 105) THEN
        v_resmask := 'DD-MM-YYYY';
    ELSIF (v_style = 6) THEN
        v_resmask := 'DD $mnme$ YY';
    ELSIF (v_style = 106) THEN
        v_resmask := 'DD $mnme$ YYYY';
    ELSIF (v_style = 7) THEN
        v_resmask := '$mnme$ DD, YY';
    ELSIF (v_style = 107) THEN
        v_resmask := '$mnme$ DD, YYYY';
    ELSIF (v_style IN (8, 24, 108)) THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style = 10) THEN
        v_resmask := 'MM-DD-YY';
    ELSIF (v_style = 110) THEN
        v_resmask := 'MM-DD-YYYY';
    ELSIF (v_style = 11) THEN
        v_resmask := 'YY/MM/DD';
    ELSIF (v_style = 111) THEN
        v_resmask := 'YYYY/MM/DD';
    ELSIF (v_style = 12) THEN
        v_resmask := 'YYMMDD';
    ELSIF (v_style = 112) THEN
        v_resmask := 'YYYYMMDD';
    ELSIF (v_style IN (13, 113)) THEN
	    v_resmask := pg_catalog.format('DD $mnme$ YYYY HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (14, 114)) THEN
    	v_resmask := pg_catalog.format('HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (20, 120)) THEN
        v_resmask := 'YYYY-MM-DD HH24:MI:SS';
    ELSIF ((v_style = -1 AND v_src_datatype = 'DATETIME2') OR
           v_style IN (21, 25, 121))
    THEN
    	v_resmask := pg_catalog.format('YYYY-MM-DD HH24:MI:SS.%s', v_fseconds);
    ELSIF (v_style = 22) THEN
    	v_resmask := pg_catalog.format('MM/DD/YY %s:MI:SS AM', lpad(v_hour, 2, ' '));
    ELSIF (v_style = 23) THEN
        v_resmask := 'YYYY-MM-DD';
    ELSIF (v_style IN (126, 127)) THEN
        v_resmask := CASE v_src_datatype
                        WHEN 'SMALLDATETIME' THEN 'YYYY-MM-DDT$rem$HH24:MI:SS'
    					ELSE pg_catalog.format('YYYY-MM-DDT$rem$HH24:MI:SS.%s', v_fseconds)
    				END;
    ELSIF (v_style IN (130, 131)) THEN
        v_resmask := concat(CASE p_style
				        		WHEN 131 THEN pg_catalog.format('%s/MM/YYYY ', lpad(v_day, 2, ' '))
                                ELSE pg_catalog.format('%s $mnme$ YYYY ', lpad(v_day, 2, ' '))
                            END,
                            pg_catalog.format('%s:MI:SS%s%sAM', lpad(v_hour, 2, ' '), v_fractsep, v_fseconds));
    END IF;

    v_resstring := to_char(v_datetimeval, v_resmask);
    v_resstring := pg_catalog.replace(v_resstring, '$mnme$', v_monthname);
    v_resstring := pg_catalog.replace(v_resstring, '$rem$', '');
    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
	WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2'' or ''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "src_datatype" parameter value during conversion process.',
                    HINT := 'Change "srcdatatype" parameter to the proper value and try again.';

	WHEN invalid_regular_expression THEN
		RAISE USING MESSAGE := pg_catalog.format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
										v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

	WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_src_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from %s to a character string.',
                                      v_style, v_src_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
            RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                      v_lengthexpr, lower(v_res_datatype), v_maxlength),
                    DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                    HINT := 'Change size component of data type parameter to the allowable value and try again.';
    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',

                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hijri_date DATE;
BEGIN
    v_hijri_date := sys.babelfish_conv_greg_to_hijri(extract(day from p_datetimeval)::SMALLINT,
                                                         extract(month from p_datetimeval)::SMALLINT,
                                                         extract(year from p_datetimeval)::INTEGER);

    RETURN to_timestamp(pg_catalog.format('%s %s', to_char(v_hijri_date, 'DD.MM.YYYY'),
                                        to_char(p_datetimeval, ' HH24:MI:SS.US')),
                        'DD.MM.YYYY HH24:MI:SS.US');
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hijri_date DATE;
BEGIN
    v_hijri_date := sys.babelfish_conv_hijri_to_greg(extract(day from p_dateval)::NUMERIC,
                                                         extract(month from p_dateval)::NUMERIC,
                                                         extract(year from p_dateval)::NUMERIC);

    RETURN to_timestamp(pg_catalog.format('%s %s', to_char(v_hijri_date, 'DD.MM.YYYY'),
                                        to_char(p_datetimeval, ' HH24:MI:SS.US')),
                        'DD.MM.YYYY HH24:MI:SS.US');
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_time_to_string(IN p_datatype TEXT,
                                                                 IN p_src_datatype TEXT,
                                                                 IN p_timeval TIME(6) WITHOUT TIME ZONE,
                                                                 IN p_style NUMERIC DEFAULT 25)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_hours VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_res_length SMALLINT;
    v_res_datatype VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_res_maxlength SMALLINT;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    -- We use the regex below to make sure input p_datatype is one of them
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    -- We use the regex below to get the length of the datatype, if specified
    -- For example, to get the '10' out of 'varchar(10)'
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR COLLATE "C" := '^\s*(?:TIME)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?\s*$';
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_src_datatype := upper(trim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;
    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := coalesce(substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT, 7);
        IF (v_scale NOT BETWEEN 0 AND 7) THEN
            RAISE invalid_regular_expression;
        END IF;
    ELSE
        RAISE most_specific_type_mismatch;
    END IF;
    IF (v_datatype ~* DATATYPE_MASK_REGEXP)
    THEN
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));
        v_res_maxlength := CASE
                              WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                              ELSE NVARCHAR_MAX
                           END;
        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);
        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;
        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_res_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;
    IF (scale(p_style) > 0) THEN
        RAISE escape_character_conflict;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    ELSIF ((v_style BETWEEN 1 AND 7) OR
           (v_style BETWEEN 10 AND 12) OR
           (v_style BETWEEN 101 AND 107) OR
           (v_style BETWEEN 110 AND 112) OR
           v_style = 23)
    THEN
        RAISE invalid_datetime_format;
    END IF;
    v_hours := ltrim(to_char(p_timeval, 'HH12'), '0');
    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(to_char(p_timeval, 'US'), v_scale);
    IF (v_scale = 7) THEN
        v_fseconds := concat(v_fseconds, '0');
    END IF;
    IF (v_style IN (0, 100))
    THEN
        v_resmask := concat(v_hours, ':MIAM');
    ELSIF (v_style IN (8, 20, 24, 108, 120))
    THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style IN (9, 109))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(v_hours, ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', v_hours, v_fseconds)
                     END;
    ELSIF (v_style IN (13, 14, 21, 25, 113, 114, 121, 126, 127))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN 'HH24:MI:SS'
                        ELSE concat('HH24:MI:SS.', v_fseconds)
                     END;
    ELSIF (v_style = 22)
    THEN
    	v_resmask := pg_catalog.format('%s:MI:SS AM', lpad(v_hours, 2, ' '));
    ELSIF (v_style IN (130, 131))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(lpad(v_hours, 2, ' '), ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', lpad(v_hours, 2, ' '), v_fseconds)
                     END;
    END IF;

    v_resstring := to_char(p_timeval, v_resmask);
    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "src_datatype" parameter value during conversion process.',
                    HINT := 'Change "src_datatype" parameter to the proper value and try again.';

   WHEN invalid_regular_expression THEN
       RAISE USING MESSAGE := pg_catalog.format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr, lower(v_res_datatype), v_res_maxlength),
                   DETAIL := 'Use of incorrect size value of target data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';
    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from TIME to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting data type TIME to %s.',
                                      rtrim(split_part(trim(p_datatype), '(', 1))),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_aws_add_jobschedule (
  par_job_id integer = NULL::integer,
  par_schedule_id integer = NULL::integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  proc_name_mask VARCHAR(100);
  var_owner_login_name VARCHAR(128);
  var_xml TEXT DEFAULT '';
  var_cron_expression VARCHAR(50);
  var_job_cmd VARCHAR(255);
  lambda_arn VARCHAR(255);
  return_message text;
  var_schedule_name VARCHAR(255);
  var_job_name VARCHAR(128);
  var_start_step_id INTEGER;
  var_notify_level_email INTEGER;
  var_notify_email_operator_id INTEGER;
  var_notify_email_operator_name VARCHAR(128);
  notify_email_sender VARCHAR(128);
  var_delete_level INTEGER;
BEGIN
  IF (EXISTS (
      SELECT 1
        FROM sys.sysjobschedules
       WHERE (schedule_id = par_schedule_id)
         AND (job_id = par_job_id)))
  THEN
    SELECT cron_expression
      FROM sys.babelfish_sp_schedule_to_cron (par_job_id, par_schedule_id)
      INTO var_cron_expression;
    SELECT name
      FROM sys.sysschedules
     WHERE schedule_id = par_schedule_id
      INTO var_schedule_name;
    SELECT name
         , start_step_id
         , COALESCE(notify_level_email,0)
         , COALESCE(notify_email_operator_id,0)
         , COALESCE(notify_email_operator_name,'')
         , COALESCE(delete_level,0)
      FROM sys.sysjobs
     WHERE job_id = par_job_id
      INTO var_job_name
         , var_start_step_id
         , var_notify_level_email
         , var_notify_email_operator_id
         , var_notify_email_operator_name
         , var_delete_level;

    proc_name_mask := 'sys_data.sql_agent$job_%s_step_%s';
    var_job_cmd := pg_catalog.format(proc_name_mask, par_job_id, '1');
    notify_email_sender := 'aws_test_email_sender@dbbest.com';


    var_xml := CONCAT(var_xml, '{');
    var_xml := CONCAT(var_xml, '"mode": "add_job",');
    var_xml := CONCAT(var_xml, '"parameters": {');
    var_xml := CONCAT(var_xml, '"vendor": "postgresql",');
    var_xml := CONCAT(var_xml, '"job_name": "',var_schedule_name,'",');
    var_xml := CONCAT(var_xml, '"job_frequency": "',var_cron_expression,'",');
    var_xml := CONCAT(var_xml, '"job_cmd": "',var_job_cmd,'",');
    var_xml := CONCAT(var_xml, '"notify_level_email": ',var_notify_level_email,',');
    var_xml := CONCAT(var_xml, '"delete_level": ',var_delete_level,',');
    var_xml := CONCAT(var_xml, '"uid": "',par_job_id,'",');
    var_xml := CONCAT(var_xml, '"callback": "sys.babelfish_sp_job_log",');
    var_xml := CONCAT(var_xml, '"notification": {');
    var_xml := CONCAT(var_xml, '"notify_email_sender": "',notify_email_sender,'",');
    var_xml := CONCAT(var_xml, '"notify_email_recipient": "',var_notify_email_operator_name,'"');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');
    -- RAISE NOTICE '%', var_xml;
    SELECT sys.babelfish_get_service_setting ('JOB', 'LAMBDA_ARN')
      INTO lambda_arn;
    SELECT sys.awslambda_fn (lambda_arn, var_xml) INTO return_message;
    returncode := 0;
  ELSE
    returncode := 1;
    RAISE 'Job not fount' USING ERRCODE := '50000';
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_aws_add_jobschedule (
  par_job_id integer = NULL::integer,
  par_schedule_id integer = NULL::integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  proc_name_mask VARCHAR(100);
  var_owner_login_name VARCHAR(128);
  var_xml TEXT DEFAULT '';
  var_cron_expression VARCHAR(50);
  var_job_cmd VARCHAR(255);
  lambda_arn VARCHAR(255);
  return_message text;
  var_schedule_name VARCHAR(255);
  var_job_name VARCHAR(128);
  var_start_step_id INTEGER;
  var_notify_level_email INTEGER;
  var_notify_email_operator_id INTEGER;
  var_notify_email_operator_name VARCHAR(128);
  notify_email_sender VARCHAR(128);
  var_delete_level INTEGER;
BEGIN
  IF (EXISTS (
      SELECT 1
        FROM sys.sysjobschedules
       WHERE (schedule_id = par_schedule_id)
         AND (job_id = par_job_id)))
  THEN
    SELECT cron_expression
      FROM sys.babelfish_sp_schedule_to_cron (par_job_id, par_schedule_id)
      INTO var_cron_expression;
    SELECT name
      FROM sys.sysschedules
     WHERE schedule_id = par_schedule_id
      INTO var_schedule_name;
    SELECT name
         , start_step_id
         , COALESCE(notify_level_email,0)
         , COALESCE(notify_email_operator_id,0)
         , COALESCE(notify_email_operator_name,'')
         , COALESCE(delete_level,0)
      FROM sys.sysjobs
     WHERE job_id = par_job_id
      INTO var_job_name
         , var_start_step_id
         , var_notify_level_email
         , var_notify_email_operator_id
         , var_notify_email_operator_name
         , var_delete_level;

    proc_name_mask := 'sys_data.sql_agent$job_%s_step_%s';
    var_job_cmd := pg_catalog.format(proc_name_mask, par_job_id, '1');
    notify_email_sender := 'aws_test_email_sender@dbbest.com';


    var_xml := CONCAT(var_xml, '{');
    var_xml := CONCAT(var_xml, '"mode": "add_job",');
    var_xml := CONCAT(var_xml, '"parameters": {');
    var_xml := CONCAT(var_xml, '"vendor": "postgresql",');
    var_xml := CONCAT(var_xml, '"job_name": "',var_schedule_name,'",');
    var_xml := CONCAT(var_xml, '"job_frequency": "',var_cron_expression,'",');
    var_xml := CONCAT(var_xml, '"job_cmd": "',var_job_cmd,'",');
    var_xml := CONCAT(var_xml, '"notify_level_email": ',var_notify_level_email,',');
    var_xml := CONCAT(var_xml, '"delete_level": ',var_delete_level,',');
    var_xml := CONCAT(var_xml, '"uid": "',par_job_id,'",');
    var_xml := CONCAT(var_xml, '"callback": "sys.babelfish_sp_job_log",');
    var_xml := CONCAT(var_xml, '"notification": {');
    var_xml := CONCAT(var_xml, '"notify_email_sender": "',notify_email_sender,'",');
    var_xml := CONCAT(var_xml, '"notify_email_recipient": "',var_notify_email_operator_name,'"');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');
    -- RAISE NOTICE '%', var_xml;
    SELECT sys.babelfish_get_service_setting ('JOB', 'LAMBDA_ARN')
      INTO lambda_arn;
    SELECT sys.awslambda_fn (lambda_arn, var_xml) INTO return_message;
    returncode := 0;
  ELSE
    returncode := 1;
    RAISE 'Job not fount' USING ERRCODE := '50000';
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_schedule_to_cron (
  par_job_id integer,
  par_schedule_id integer,
  out cron_expression varchar
)
RETURNS VARCHAR AS
$body$
DECLARE
  var_enabled INTEGER;
  var_freq_type INTEGER;
  var_freq_interval INTEGER;
  var_freq_subday_type INTEGER;
  var_freq_subday_interval INTEGER;
  var_freq_relative_interval INTEGER;
  var_freq_recurrence_factor INTEGER;
  var_active_start_date INTEGER;
  var_active_end_date INTEGER;
  var_active_start_time INTEGER;
  var_active_end_time INTEGER;
  var_next_run_date date;
  var_next_run_time time;
  var_next_run_dt timestamp;
  var_tmp_interval varchar(50);
  var_current_dt timestamp;
  var_next_dt timestamp;
BEGIN
  SELECT enabled
       , freq_type
       , freq_interval
       , freq_subday_type
       , freq_subday_interval
       , freq_relative_interval
       , freq_recurrence_factor
       , active_start_date
       , active_end_date
       , active_start_time
       , active_end_time
    FROM sys.sysschedules
    INTO var_enabled
       , var_freq_type
       , var_freq_interval
       , var_freq_subday_type
       , var_freq_subday_interval
       , var_freq_relative_interval
       , var_freq_recurrence_factor
       , var_active_start_date
       , var_active_end_date
       , var_active_start_time
       , var_active_end_time
   WHERE schedule_id = par_schedule_id;
  /* if enabled = 0 return */
  CASE var_freq_type
    WHEN 1 THEN
      NULL;
    WHEN 4 THEN
    BEGIN
        cron_expression :=
        CASE
          /* WHEN var_freq_subday_type = 1 THEN var_freq_subday_interval::character varying || ' At the specified time'  -- start time */
          /* WHEN var_freq_subday_type = 2 THEN var_freq_subday_interval::character varying || ' second'  -- ADD var_freq_subday_interval SECOND */
          WHEN var_freq_subday_type = 4 THEN pg_catalog.format('cron(*/%s * * * ? *)', var_freq_subday_interval::character varying) /* ADD var_freq_subday_interval MINUTE */
          WHEN var_freq_subday_type = 8 THEN pg_catalog.format('cron(0 */%s * * ? *)', var_freq_subday_interval::character varying) /* ADD var_freq_subday_interval HOUR */
          ELSE ''
        END;
    END;
    WHEN 8 THEN
      NULL;
    WHEN 16 THEN
      NULL;
    WHEN 32 THEN
      NULL;
    WHEN 64 THEN
      NULL;
    WHEN 128 THEN
     NULL;
  END CASE;
 -- return cron_expression;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year NUMERIC,
                                                                IN p_month NUMERIC,
                                                                IN p_day NUMERIC,
                                                                IN p_hour NUMERIC,
                                                                IN p_minute NUMERIC,
                                                                IN p_seconds NUMERIC,
                                                                IN p_fractions NUMERIC,
                                                                IN p_precision NUMERIC)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
   v_fractions VARCHAR;
   v_precision SMALLINT;
   v_err_message VARCHAR;
   v_calc_seconds NUMERIC;
BEGIN
   v_fractions := floor(p_fractions)::INTEGER::VARCHAR;
   v_precision := p_precision::SMALLINT;
   IF (scale(p_precision) > 0) THEN
      RAISE most_specific_type_mismatch;
   ELSIF ((p_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
       (p_month::SMALLINT NOT BETWEEN 1 AND 12) OR
       (p_day::SMALLINT NOT BETWEEN 1 AND 31) OR
       (p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
       (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
       (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > p_precision))
   THEN
      RAISE invalid_datetime_format;
   ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
      RAISE invalid_parameter_value;
   END IF;

   v_calc_seconds := pg_catalog.format('%s.%s',
                            floor(p_seconds)::SMALLINT,
                            substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

   RETURN make_timestamp(floor(p_year)::SMALLINT,
                         floor(p_month)::SMALLINT,
                         floor(p_day)::SMALLINT,
                         floor(p_hour)::SMALLINT,
                         floor(p_minute)::SMALLINT,
                         v_calc_seconds);
EXCEPTION
   WHEN most_specific_type_mismatch THEN
      RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type DATETIME2 scale argument are integer constants and integer constant expressions.',
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_parameter_value THEN
      RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_precision),
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_datetime_format THEN
      RAISE USING MESSAGE := 'Cannot construct data type DATETIME2, some of the arguments have values which are not valid.',
                  DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                  HINT := 'Check each input argument belongs to the valid range and try again.';
   WHEN numeric_value_out_of_range THEN
      GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
      v_err_message := upper(split_part(v_err_message, ' ', 1));

      RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                  DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                  HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
                                 v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetimefromparts(IN p_year NUMERIC,
                                                               IN p_month NUMERIC,
                                                               IN p_day NUMERIC,
                                                               IN p_hour NUMERIC,
                                                               IN p_minute NUMERIC,
                                                               IN p_seconds NUMERIC,
                                                               IN p_milliseconds NUMERIC)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
    v_calc_seconds NUMERIC;
    v_milliseconds SMALLINT;
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
BEGIN
    -- Check if arguments are out of range
    IF ((floor(p_year)::SMALLINT NOT BETWEEN 1753 AND 9999) OR
        (floor(p_month)::SMALLINT NOT BETWEEN 1 AND 12) OR
        (floor(p_day)::SMALLINT NOT BETWEEN 1 AND 31) OR
        (floor(p_hour)::SMALLINT NOT BETWEEN 0 AND 23) OR
        (floor(p_minute)::SMALLINT NOT BETWEEN 0 AND 59) OR
        (floor(p_seconds)::SMALLINT NOT BETWEEN 0 AND 59) OR
        (floor(p_milliseconds)::SMALLINT NOT BETWEEN 0 AND 999))
    THEN
        RAISE invalid_datetime_format;
    END IF;

    v_milliseconds := sys.babelfish_round_fractseconds(p_milliseconds::INTEGER);

    v_calc_seconds := pg_catalog.format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             CASE v_milliseconds
                                WHEN 1000 THEN '0'
                                ELSE lpad(v_milliseconds::VARCHAR, 3, '0')
                             END)::NUMERIC;
    v_resdatetime := make_timestamp(floor(p_year)::SMALLINT,
                                    floor(p_month)::SMALLINT,
                                    floor(p_day)::SMALLINT,
                                    floor(p_hour)::SMALLINT,
                                    floor(p_minute)::SMALLINT,
                                    v_calc_seconds);
    RETURN CASE
              WHEN (v_milliseconds != 1000) THEN v_resdatetime
              ELSE v_resdatetime + INTERVAL '1 second'
           END;
EXCEPTION
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type datetime, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';
    WHEN numeric_value_out_of_range THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := upper(split_part(v_err_message, ' ', 1));

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                    HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE VIEW sys.babelfish_configurations_view as
    SELECT * 
    FROM pg_catalog.pg_settings 
    WHERE name collate "C" like 'babelfishpg_tsql.explain_%' OR
          name collate "C" like 'babelfishpg_tsql.escape_hatch_%' OR
          name collate "C" = 'babelfishpg_tsql.enable_pg_hint';
GRANT SELECT on sys.babelfish_configurations_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128),  IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
AS $$
DECLARE
  normalized_name varchar(256);
  default_value text;
  value_type text;
  enum_value text[];
  cnt int;
  cur refcursor;
  guc_name varchar(256);
  server boolean := false;
  prev_user text;
BEGIN
  IF lower("@option_name") like 'babelfishpg_tsql.%' collate "C" THEN
    SELECT "@option_name" INTO normalized_name;
  ELSE
    SELECT concat('babelfishpg_tsql.',"@option_name") INTO normalized_name;
  END IF;

  IF lower("@option_scope") = 'server' THEN
    server := true;
  ELSIF btrim("@option_scope") != '' THEN
    RAISE EXCEPTION 'invalid option: %', "@option_scope";
  END IF;

  SELECT COUNT(*) INTO cnt FROM sys.babelfish_configurations_view where name collate "C" like normalized_name;
  IF cnt = 0 THEN 
    RAISE EXCEPTION 'unknown configuration: %', normalized_name;
  ELSIF cnt > 1 AND (lower("@option_value") != 'ignore' AND lower("@option_value") != 'strict' 
                AND lower("@option_value") != 'default') THEN
    RAISE EXCEPTION 'unvalid option: %', lower("@option_value");
  END IF;

  OPEN cur FOR SELECT name FROM sys.babelfish_configurations_view where name collate "C" like normalized_name;
  LOOP
    FETCH NEXT FROM cur into guc_name;
    exit when not found;

    SELECT boot_val, vartype, enumvals INTO default_value, value_type, enum_value FROM pg_catalog.pg_settings WHERE name = guc_name;
    IF lower("@option_value") = 'default' THEN
        PERFORM pg_catalog.set_config(guc_name, default_value, 'false');
    ELSIF lower("@option_value") = 'ignore' or lower("@option_value") = 'strict' THEN
      IF value_type = 'enum' AND enum_value = '{"strict", "ignore"}' THEN
        PERFORM pg_catalog.set_config(guc_name, "@option_value", 'false');
      ELSE
        CONTINUE;
      END IF;
    ELSE
        PERFORM pg_catalog.set_config(guc_name, "@option_value", 'false');
    END IF;
    IF server THEN
      SELECT current_user INTO prev_user;
      PERFORM sys.babelfish_set_role(session_user);
      IF lower("@option_value") = 'default' THEN
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, default_value);
      ELSIF lower("@option_value") = 'ignore' or lower("@option_value") = 'strict' THEN
        IF value_type = 'enum' AND enum_value = '{"strict", "ignore"}' THEN
          EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, "@option_value");
        ELSE
          CONTINUE;
        END IF;
      ELSE
        -- store the setting in PG master database so that it can be applied to all bbf databases
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, "@option_value");
      END IF;
      PERFORM sys.babelfish_set_role(prev_user);
    END IF;
  END LOOP;

  CLOSE cur;

END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(
	IN varchar(128), IN varchar(128), IN varchar(128)
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour NUMERIC,
                                                           IN p_minute NUMERIC,
                                                           IN p_seconds NUMERIC,
                                                           IN p_fractions NUMERIC,
                                                           IN p_precision NUMERIC)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_fractions VARCHAR;
    v_precision SMALLINT;
    v_err_message VARCHAR;
    v_calc_seconds NUMERIC;
BEGIN
    v_fractions := floor(p_fractions)::INTEGER::VARCHAR;
    v_precision := p_precision::SMALLINT;
    IF (scale(p_precision) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF ((p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
           (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
           (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
           (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
           (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > p_precision))
    THEN
        RAISE invalid_datetime_format;
    ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
        RAISE numeric_value_out_of_range;
    END IF;

    v_calc_seconds := pg_catalog.format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

    RETURN make_time(floor(p_hour)::SMALLINT,
                     floor(p_minute)::SMALLINT,
                     v_calc_seconds);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type DATETIME2 scale argument are integer constants and integer constant expressions.',
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_precision),
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type time, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';
    WHEN numeric_value_out_of_range THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := upper(split_part(v_err_message, ' ', 1));

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                    HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;
CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour TEXT,
                                                           IN p_minute TEXT,
                                                           IN p_seconds TEXT,
                                                           IN p_fractions TEXT,
                                                           IN p_precision TEXT)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.timefromparts(p_hour::NUMERIC, p_minute::NUMERIC,
                                           p_seconds::NUMERIC, p_fractions::NUMERIC,
                                           p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.space(IN number INTEGER, OUT result SYS.VARCHAR) AS $$
-- sys.varchar has default length of 1, so we have to pass in 'number' to be the
-- type modifier.
BEGIN
	EXECUTE pg_catalog.format(E'SELECT repeat(\' \', %s)::SYS.VARCHAR(%s)', number, number) INTO result;
END;
$$
STRICT
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_get_full_year(IN p_short_year TEXT,
                                                           IN p_base_century TEXT DEFAULT '',
                                                           IN p_year_cutoff NUMERIC DEFAULT 49)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
    v_full_year SMALLINT;
    v_short_year SMALLINT;
    v_base_century SMALLINT;
    v_result_param_set JSONB;
    v_full_year_res_jsonb JSONB;
BEGIN
    v_short_year := p_short_year::SMALLINT;

    BEGIN
        v_full_year_res_jsonb := nullif(current_setting('sys.full_year_res_json'), '')::JSONB;
    EXCEPTION
        WHEN undefined_object THEN
        v_full_year_res_jsonb := NULL;
    END;

    SELECT result
      INTO v_full_year
      FROM jsonb_to_recordset(v_full_year_res_jsonb) AS result_set (param1 SMALLINT,
                                                                    param2 TEXT,
                                                                    param3 NUMERIC,
                                                                    result VARCHAR)
     WHERE param1 = v_short_year
       AND param2 = p_base_century
       AND param3 = p_year_cutoff;

    IF (v_full_year IS NULL)
    THEN
        IF (v_short_year <= 99)
        THEN
            v_base_century := CASE
                                 WHEN (p_base_century ~ '^\s*([1-9]{1,2})\s*$') THEN concat(trim(p_base_century), '00')::SMALLINT
                                 ELSE trunc(extract(year from current_date)::NUMERIC, -2)
                              END;

            v_full_year = v_base_century + v_short_year;
            v_full_year = CASE
                             WHEN (v_short_year::NUMERIC > p_year_cutoff) THEN v_full_year - 100
                             ELSE v_full_year
                          END;
        ELSE v_full_year := v_short_year;
        END IF;

        v_result_param_set := jsonb_build_object('param1', v_short_year,
                                                 'param2', p_base_century,
                                                 'param3', p_year_cutoff,
                                                 'result', v_full_year);
        v_full_year_res_jsonb := CASE
                                    WHEN (v_full_year_res_jsonb IS NULL) THEN jsonb_build_array(v_result_param_set)
                                    ELSE v_full_year_res_jsonb || v_result_param_set
                                 END;

        PERFORM set_config('sys.full_year_res_json',
                           v_full_year_res_jsonb::TEXT,
                           FALSE);
    END IF;

    RETURN v_full_year;
EXCEPTION
	WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

create or replace view sys.all_objects as
select 
    cast (name as sys.sysname) 
  , cast (object_id as integer) 
  , cast ( principal_id as integer)
  , cast (schema_id as integer)
  , cast (parent_object_id as integer)
  , cast (type as char(2))
  , cast (type_desc as sys.nvarchar(60))
  , cast (create_date as sys.datetime)
  , cast (modify_date as sys.datetime)
  , cast (case when (schema_id::regnamespace::text = 'sys') then 1
          when name in (select name from sys.shipped_objects_not_in_sys nis 
                        where nis.name = name and nis.schemaid = schema_id and nis.type = type) then 1 
          else 0 end as sys.bit) as is_ms_shipped
  , cast (is_published as sys.bit)
  , cast (is_schema_published as sys.bit)
from
(
-- details of user defined and system tables
select
    t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'U' as type
  , 'USER_TABLE' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and not sys.is_table_type(t.oid)
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system views
select
    t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system foreign key constraints
select
    c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'F' as type
  , 'FOREIGN_KEY_CONSTRAINT'
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'f'
union all
-- details of user defined and system primary key constraints
select
    c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'PK' as type
  , 'PRIMARY_KEY_CONSTRAINT' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'p'
union all
-- details of user defined and system defined procedures
select
    p.proname as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , cast (case when tr.tgrelid is not null 
  		       then tr.tgrelid 
  		       else 0 end as int) 
    as parent_object_id
  , case p.prokind
      when 'p' then 'P'::varchar(2)
      when 'a' then 'AF'::varchar(2)
      else
        case 
          when format_type(p.prorettype, null) = 'trigger'
            then 'TR'::varchar(2)
          when p.proretset then
            case 
              when t.typtype = 'c'
                then 'TF'::varchar(2)
              else 'IF'::varchar(2)
            end
          else 'FN'::varchar(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case 
          when format_type(p.prorettype, null) = 'trigger'
            then 'SQL_TRIGGER'::varchar(60)
          when p.proretset then
            case 
              when t.typtype = 'c'
                then 'SQL_TABLE_VALUED_FUNCTION'::varchar(60)
              else 'SQL_INLINE_TABLE_VALUED_FUNCTION'::varchar(60)
            end
          else 'SQL_SCALAR_FUNCTION'::varchar(60)
        end
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_proc p
inner join pg_namespace s on s.oid = p.pronamespace
inner join pg_catalog.pg_type t on t.oid = p.prorettype
left join pg_trigger tr on tr.tgfoid = p.oid
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
union all
-- details of all default constraints
select
    ('DF_' || o.relname || '_' || d.oid)::name as name
  , d.oid as object_id
  , null::int as principal_id
  , o.relnamespace as schema_id
  , d.adrelid as parent_object_id
  , 'D'::char(2) as type
  , 'DEFAULT_CONSTRAINT'::sys.nvarchar(60) AS type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_attrdef d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join pg_class o on d.adrelid = o.oid
inner join pg_namespace s on s.oid = o.relnamespace
where a.atthasdef = 't' and a.attgenerated = ''
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
union all
-- details of all check constraints
select
    c.conname::name
  , c.oid::integer as object_id
  , NULL::integer as principal_id 
  , c.connamespace::integer as schema_id
  , c.conrelid::integer as parent_object_id
  , 'C'::char(2) as type
  , 'CHECK_CONSTRAINT'::sys.nvarchar(60) as type_desc
  , null::sys.datetime as create_date
  , null::sys.datetime as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_constraint as c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'c' and c.conrelid != 0
union all
-- details of user defined and system defined sequence objects
select
  p.relname as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'SO'::varchar(2) as type
  , 'SEQUENCE_OBJECT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class p
inner join pg_namespace s on s.oid = p.relnamespace
where p.relkind = 'S'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
union all
-- details of user defined table types
select
    ('TT_' || tt.name || '_' || tt.type_table_object_id)::name as name
  , tt.type_table_object_id as object_id
  , tt.principal_id as principal_id
  , tt.schema_id as schema_id
  , 0 as parent_object_id
  , 'TT'::varchar(2) as type
  , 'TABLE_TYPE'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 1 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from sys.table_types tt
) ot;
GRANT SELECT ON sys.all_objects TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helpdbfixedrole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- Returns a list of the fixed database roles. 
	-- Only fixed role present in babelfish is db_owner.
	IF LOWER(RTRIM(@rolename)) IS NULL OR LOWER(RTRIM(@rolename)) = 'db_owner'
	BEGIN
		SELECT CAST('db_owner' AS sys.SYSNAME) AS DbFixedRole, CAST('DB Owners' AS sys.nvarchar(70)) AS Description;
	END
	ELSE IF LOWER(RTRIM(@rolename)) IN (
			'db_accessadmin','db_securityadmin','db_ddladmin', 'db_backupoperator', 
			'db_datareader', 'db_datawriter', 'db_denydatareader', 'db_denydatawriter')
	BEGIN
		-- Return an empty result set instead of raising an error
		SELECT CAST(NULL AS sys.SYSNAME) AS DbFixedRole, CAST(NULL AS sys.nvarchar(70)) AS Description
		WHERE 1=0;	
	END
	ELSE
		RAISERROR('''%s'' is not a known fixed role.', 16, 1, @rolename);
END
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpdbfixedrole TO PUBLIC;

create or replace view sys.databases as
select
  CAST(d.name as SYS.SYSNAME) as name
  , CAST(sys.db_id(d.name) as INT) as database_id
  , CAST(NULL as INT) as source_database_id
  , cast(s.sid as SYS.VARBINARY(85)) as owner_sid
  , CAST(d.crdate AS SYS.DATETIME) as create_date
  , CAST(s.cmptlevel AS SYS.TINYINT) as compatibility_level
  , CAST(c.collname as SYS.SYSNAME) as collation_name
  , CAST(0 AS SYS.TINYINT)  as user_access
  , CAST('MULTI_USER' AS SYS.NVARCHAR(60)) as user_access_desc
  , CAST(0 AS SYS.BIT) as is_read_only
  , CAST(0 AS SYS.BIT) as is_auto_close_on
  , CAST(0 AS SYS.BIT) as is_auto_shrink_on
  , CAST(0 AS SYS.TINYINT) as state
  , CAST('ONLINE' AS SYS.NVARCHAR(60)) as state_desc
  , CAST(
	  	CASE 
			WHEN pg_is_in_recovery() is false THEN 0 
			WHEN pg_is_in_recovery() is true THEN 1 
		END 
	AS SYS.BIT) as is_in_standby
  , CAST(0 AS SYS.BIT) as is_cleanly_shutdown
  , CAST(0 AS SYS.BIT) as is_supplemental_logging_enabled
  , CAST(1 AS SYS.TINYINT) as snapshot_isolation_state
  , CAST('ON' AS SYS.NVARCHAR(60)) as snapshot_isolation_state_desc
  , CAST(1 AS SYS.BIT) as is_read_committed_snapshot_on
  , CAST(1 AS SYS.TINYINT) as recovery_model
  , CAST('FULL' AS SYS.NVARCHAR(60)) as recovery_model_desc
  , CAST(0 AS SYS.TINYINT) as page_verify_option
  , CAST(NULL AS SYS.NVARCHAR(60)) as page_verify_option_desc
  , CAST(1 AS SYS.BIT) as is_auto_create_stats_on
  , CAST(0 AS SYS.BIT) as is_auto_create_stats_incremental_on
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_on
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_async_on
  , CAST(0 AS SYS.BIT) as is_ansi_null_default_on
  , CAST(0 AS SYS.BIT) as is_ansi_nulls_on
  , CAST(0 AS SYS.BIT) as is_ansi_padding_on
  , CAST(0 AS SYS.BIT) as is_ansi_warnings_on
  , CAST(0 AS SYS.BIT) as is_arithabort_on
  , CAST(0 AS SYS.BIT) as is_concat_null_yields_null_on
  , CAST(0 AS SYS.BIT) as is_numeric_roundabort_on
  , CAST(0 AS SYS.BIT) as is_quoted_identifier_on
  , CAST(0 AS SYS.BIT) as is_recursive_triggers_on
  , CAST(0 AS SYS.BIT) as is_cursor_close_on_commit_on
  , CAST(0 AS SYS.BIT) as is_local_cursor_default
  , CAST(0 AS SYS.BIT) as is_fulltext_enabled
  , CAST(0 AS SYS.BIT) as is_trustworthy_on
  , CAST(0 AS SYS.BIT) as is_db_chaining_on
  , CAST(0 AS SYS.BIT) as is_parameterization_forced
  , CAST(0 AS SYS.BIT) as is_master_key_encrypted_by_server
  , CAST(0 AS SYS.BIT) as is_query_store_on
  , CAST(0 AS SYS.BIT) as is_published
  , CAST(0 AS SYS.BIT) as is_subscribed
  , CAST(0 AS SYS.BIT) as is_merge_published
  , CAST(0 AS SYS.BIT) as is_distributor
  , CAST(0 AS SYS.BIT) as is_sync_with_backup
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as service_broker_guid
  , CAST(0 AS SYS.BIT) as is_broker_enabled
  , CAST(0 AS SYS.TINYINT) as log_reuse_wait
  , CAST('NOTHING' AS SYS.NVARCHAR(60)) as log_reuse_wait_desc
  , CAST(0 AS SYS.BIT) as is_date_correlation_on
  , CAST(0 AS SYS.BIT) as is_cdc_enabled
  , CAST(0 AS SYS.BIT) as is_encrypted
  , CAST(0 AS SYS.BIT) as is_honor_broker_priority_on
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as replica_id
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as group_database_id
  , CAST(NULL AS INT) as resource_pool_id
  , CAST(NULL AS SMALLINT) as default_language_lcid
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_language_name
  , CAST(NULL AS INT) as default_fulltext_language_lcid
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_fulltext_language_name
  , CAST(NULL AS SYS.BIT) as is_nested_triggers_on
  , CAST(NULL AS SYS.BIT) as is_transform_noise_words_on
  , CAST(NULL AS SMALLINT) as two_digit_year_cutoff
  , CAST(0 AS SYS.TINYINT) as containment
  , CAST('NONE' AS SYS.NVARCHAR(60)) as containment_desc
  , CAST(0 AS INT) as target_recovery_time_in_seconds
  , CAST(0 AS INT) as delayed_durability
  , CAST(NULL AS SYS.NVARCHAR(60)) as delayed_durability_desc
  , CAST(0 AS SYS.BIT) as is_memory_optimized_elevate_to_snapshot_on
  , CAST(0 AS SYS.BIT) as is_federation_member
  , CAST(0 AS SYS.BIT) as is_remote_data_archive_enabled
  , CAST(0 AS SYS.BIT) as is_mixed_page_allocation_on
  , CAST(0 AS SYS.BIT) as is_temporal_history_retention_enabled
  , CAST(0 AS INT) as catalog_collation_type
  , CAST('Not Applicable' AS SYS.NVARCHAR(60)) as catalog_collation_type_desc
  , CAST(NULL AS SYS.NVARCHAR(128)) as physical_database_name
  , CAST(0 AS SYS.BIT) as is_result_set_caching_on
  , CAST(0 AS SYS.BIT) as is_accelerated_database_recovery_on
  , CAST(0 AS SYS.BIT) as is_tempdb_spill_to_remote_store
  , CAST(0 AS SYS.BIT) as is_stale_page_detection_on
  , CAST(0 AS SYS.BIT) as is_memory_optimized_enabled
  , CAST(0 AS SYS.BIT) as is_ledger_on
 from sys.babelfish_sysdatabases d 
 INNER JOIN sys.sysdatabases s on d.dbid = s.dbid
 LEFT OUTER JOIN pg_catalog.pg_collation c ON d.default_collation = c.collname;
GRANT SELECT ON sys.databases TO PUBLIC;

-- BABELFISH_FUNCTION_EXT
CREATE TABLE sys.babelfish_function_ext (
	nspname NAME NOT NULL,
	funcname NAME NOT NULL,
	orig_name sys.NVARCHAR(128), -- users' original input name
	funcsignature TEXT NOT NULL COLLATE "C",
	default_positions TEXT COLLATE "C",
	flag_validity BIGINT,
	flag_values BIGINT,
	create_date SYS.DATETIME NOT NULL,
	modify_date SYS.DATETIME NOT NULL,
	PRIMARY KEY(nspname, funcsignature)
);
GRANT SELECT ON sys.babelfish_function_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_function_ext', '');

ALTER TABLE sys.babelfish_view_def ADD COLUMN create_date SYS.DATETIME, add COLUMN modify_date SYS.DATETIME;

CREATE OR REPLACE FUNCTION sys.babelfish_get_pltsql_function_signature(IN funcoid OID)
RETURNS text
AS 'babelfishpg_tsql', 'get_pltsql_function_signature' LANGUAGE C;

create or replace view sys.tables as
select
  CAST(t.relname as sys._ci_sysname) as name
  , CAST(t.oid as int) as object_id
  , CAST(NULL as int) as principal_id
  , CAST(t.relnamespace  as int) as schema_id
  , 0 as parent_object_id
  , CAST('U' as CHAR(2)) as type
  , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
  , CAST((select string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as create_date
  , CAST((select string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , case reltoastrelid when 0 then 0 else 1 end as lob_data_space_id
  , CAST(NULL as int) as filestream_data_space_id
  , CAST(relnatts as int) as max_column_id_used
  , CAST(0 as sys.bit) as lock_on_bulk_load
  , CAST(1 as sys.bit) as uses_ansi_nulls
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as has_replication_filter
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_sync_tran_subscribed
  , CAST(0 as sys.bit) as has_unchecked_assembly_data
  , 0 as text_in_row_limit
  , CAST(0 as sys.bit) as large_value_types_out_of_row
  , CAST(0 as sys.bit) as is_tracked_by_cdc
  , CAST(0 as sys.tinyint) as lock_escalation
  , CAST('TABLE' as sys.nvarchar(60)) as lock_escalation_desc
  , CAST(0 as sys.bit) as is_filetable
  , CAST(0 as sys.tinyint) as durability
  , CAST('SCHEMA_AND_DATA' as sys.nvarchar(60)) as durability_desc
  , CAST(0 as sys.bit) is_memory_optimized
  , case relpersistence when 't' then CAST(2 as sys.tinyint) else CAST(0 as sys.tinyint) end as temporal_type
  , case relpersistence when 't' then CAST('SYSTEM_VERSIONED_TEMPORAL_TABLE' as sys.nvarchar(60)) else CAST('NON_TEMPORAL_TABLE' as sys.nvarchar(60)) end as temporal_type_desc
  , CAST(null as integer) as history_table_id
  , CAST(0 as sys.bit) as is_remote_data_archive_enabled
  , CAST(0 as sys.bit) as is_external
from pg_class t 
where t.relnamespace in (select schema_id from sys.schemas)
and t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and t.oid not in (select typrelid from sys.table_types_internal)
and has_schema_privilege(t.relnamespace, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.tables TO PUBLIC;

create or replace view sys.views as 
select 
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type 
  , 'VIEW'::varchar(60) as type_desc
  , vd.create_date::timestamp as create_date
  , vd.create_date::timestamp as modify_date
  , 0 as is_ms_shipped 
  , 0 as is_published 
  , 0 as is_schema_published 
  , 0 as with_check_option 
  , 0 as is_date_correlation_view 
  , 0 as is_tracked_by_cdc 
from pg_class t inner join sys.schemas sch on t.relnamespace = sch.schema_id 
left outer join sys.babelfish_view_def vd on t.relname = vd.object_name and sch.name = vd.schema_name and vd.dbid = sys.db_id() 
where t.relkind = 'v'
and has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.views TO PUBLIC;

create or replace view sys.procedures as
select
  cast(p.proname as sys.sysname) as name
  , cast(p.oid as int) as object_id
  , cast(null as int) as principal_id
  , cast(sch.schema_id as int) as schema_id
  , cast (0 as int) as parent_object_id
  , cast(case p.prokind
      when 'p' then 'P'
      when 'a' then 'AF'
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'
          else 'FN'
        end
    end as sys.bpchar(2)) as type
  , cast(case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'
      when 'a' then 'AGGREGATE_FUNCTION'
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'
          else 'SQL_SCALAR_FUNCTION'
        end
    end as sys.nvarchar(60)) as type_desc
  , cast(f.create_date as sys.datetime) as create_date
  , cast(f.create_date as sys.datetime) as modify_date
  , cast(0 as sys.bit) as is_ms_shipped
  , cast(0 as sys.bit) as is_published
  , cast(0 as sys.bit) as is_schema_published
  , cast(0 as sys.bit) as is_auto_executed
  , cast(0 as sys.bit) as is_execution_replicated
  , cast(0 as sys.bit) as is_repl_serializable_only
  , cast(0 as sys.bit) as skips_repl_constraints
from pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where has_schema_privilege(sch.schema_id, 'USAGE')
and format_type(p.prorettype, null) <> 'trigger'
and has_function_privilege(p.oid, 'EXECUTE');
GRANT SELECT ON sys.procedures TO PUBLIC;

CREATE OR REPLACE VIEW sys.triggers
AS
SELECT
  CAST(p.proname as sys.sysname) as name,
  CAST(p.oid as int) as object_id,
  CAST(1 as sys.tinyint) as parent_class,
  CAST('OBJECT_OR_COLUMN' as sys.nvarchar(60)) AS parent_class_desc,
  CAST(tr.tgrelid as int) AS parent_id,
  CAST('TR' as sys.bpchar(2)) AS type,
  CAST('SQL_TRIGGER' as sys.nvarchar(60)) AS type_desc,
  CAST(f.create_date as sys.datetime) AS create_date,
  CAST(f.create_date as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_ms_shipped,
  CAST(
      CASE WHEN tr.tgenabled = 'D'
      THEN 1
      ELSE 0
      END
      AS sys.bit
  )	AS is_disabled,
  CAST(0 as sys.bit) AS is_not_for_replication,
  CAST(get_bit(CAST(CAST(tr.tgtype as int) as bit(7)),0) as sys.bit) AS is_instead_of_trigger
FROM pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where has_schema_privilege(sch.schema_id, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
and p.prokind = 'f'
and format_type(p.prorettype, null) = 'trigger';
GRANT SELECT ON sys.triggers TO PUBLIC;

ALTER VIEW sys.default_constraints RENAME TO default_constraints_deprecated_in_2_3_0;
ALTER VIEW sys.check_constraints RENAME TO check_constraints_deprecated_in_2_3_0;

create or replace view sys.default_constraints
AS
select CAST(('DF_' || tab.name || '_' || d.oid) as sys.sysname) as name
  , CAST(d.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(tab.schema_id as int) as schema_id
  , CAST(d.adrelid as int) as parent_object_id
  , CAST('D' as char(2)) as type
  , CAST('DEFAULT_CONSTRAINT' as sys.nvarchar(60)) AS type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modified_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(d.adnum as int) as  parent_column_id
  -- use a simple regex to strip the datatype and collation that pg_get_expr returns after a double-colon that is not expected in SQL Server
  , CAST(regexp_replace(pg_get_expr(d.adbin, d.adrelid), '::"?\w+"?| COLLATE "\w+"', '', 'g') as sys.nvarchar(4000)) as definition
  , CAST(1 as sys.bit) as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.atthasdef = 't' and a.attgenerated = ''
AND has_schema_privilege(tab.schema_id, 'USAGE')
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(c.conname as sys.sysname) as name
  , CAST(oid as integer) as object_id
  , CAST(NULL as integer) as principal_id 
  , CAST(c.connamespace as integer) as schema_id
  , CAST(conrelid as integer) as parent_object_id
  , CAST('C' as char(2)) as type
  , CAST('CHECK_CONSTRAINT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(0 as sys.bit) as is_disabled
  , CAST(0 as sys.bit) as is_not_for_replication
  , CAST(0 as sys.bit) as is_not_trusted
  , CAST(c.conkey[1] as integer) AS parent_column_id
  -- use a simple regex to strip the datatype and collation that pg_get_constraintdef returns after a double-colon that is not expected in SQL Server
  , CAST(regexp_replace(substring(pg_get_constraintdef(c.oid) from 7), '::"?\w+"?| COLLATE "\w+"', '', 'g') as sys.nvarchar(4000)) AS definition
  , CAST(1 as sys.bit) as uses_database_collation
  , CAST(0 as sys.bit) as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE has_schema_privilege(s.schema_id, 'USAGE')
AND c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

-- Rebuild dependent view sys.objects
create or replace view sys.objects as
select
      CAST(t.name as sys.sysname) as name 
    , CAST(t.object_id as int) as object_id
    , CAST(t.principal_id as int) as principal_id
    , CAST(t.schema_id as int) as schema_id
    , CAST(t.parent_object_id as int) as parent_object_id
    , CAST('U' as char(2)) as type
    , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
    , CAST(t.create_date as sys.datetime) as create_date
    , CAST(t.modify_date as sys.datetime) as modify_date
    , CAST(t.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(t.is_published as sys.bit) as is_published
    , CAST(t.is_schema_published as sys.bit) as is_schema_published
from  sys.tables t
union all
select
      CAST(v.name as sys.sysname) as name
    , CAST(v.object_id as int) as object_id
    , CAST(v.principal_id as int) as principal_id
    , CAST(v.schema_id as int) as schema_id
    , CAST(v.parent_object_id as int) as parent_object_id
    , CAST('V' as char(2)) as type
    , CAST('VIEW' as sys.nvarchar(60)) as type_desc
    , CAST(v.create_date as sys.datetime) as create_date
    , CAST(v.modify_date as sys.datetime) as modify_date
    , CAST(v.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(v.is_published as sys.bit) as is_published
    , CAST(v.is_schema_published as sys.bit) as is_schema_published
from  sys.views v
union all
select
      CAST(f.name as sys.sysname) as name
    , CAST(f.object_id as int) as object_id
    , CAST(f.principal_id as int) as principal_id
    , CAST(f.schema_id as int) as schema_id
    , CAST(f.parent_object_id as int) as parent_object_id
    , CAST('F' as char(2)) as type
    , CAST('FOREIGN_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(f.create_date as sys.datetime) as create_date
    , CAST(f.modify_date as sys.datetime) as modify_date
    , CAST(f.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(f.is_published as sys.bit) as is_published
    , CAST(f.is_schema_published as sys.bit) as is_schema_published
 from sys.foreign_keys f
union all
select
      CAST(p.name as sys.sysname) as name
    , CAST(p.object_id as int) as object_id
    , CAST(p.principal_id as int) as principal_id
    , CAST(p.schema_id as int) as schema_id
    , CAST(p.parent_object_id as int) as parent_object_id
    , CAST('PK' as char(2)) as type
    , CAST('PRIMARY_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(p.create_date as sys.datetime) as create_date
    , CAST(p.modify_date as sys.datetime) as modify_date
    , CAST(p.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(p.is_published as sys.bit) as is_published
    , CAST(p.is_schema_published as sys.bit) as is_schema_published
from sys.key_constraints p
where p.type = 'PK'
union all
select
      CAST(pr.name as sys.sysname) as name
    , CAST(pr.object_id as int) as object_id
    , CAST(pr.principal_id as int) as principal_id
    , CAST(pr.schema_id as int) as schema_id
    , CAST(pr.parent_object_id as int) as parent_object_id
    , CAST(pr.type as char(2)) as type
    , CAST(pr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(pr.create_date as sys.datetime) as create_date
    , CAST(pr.modify_date as sys.datetime) as modify_date
    , CAST(pr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(pr.is_published as sys.bit) as is_published
    , CAST(pr.is_schema_published as sys.bit) as is_schema_published
 from sys.procedures pr
union all
select
      CAST(tr.name as sys.sysname) as name
    , CAST(tr.object_id as int) as object_id
    , CAST(NULL as int) as principal_id
    , CAST(p.pronamespace as int) as schema_id
    , CAST(tr.parent_id as int) as parent_object_id
    , CAST(tr.type as char(2)) as type
    , CAST(tr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(tr.create_date as sys.datetime) as create_date
    , CAST(tr.modify_date as sys.datetime) as modify_date
    , CAST(tr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(0 as sys.bit) as is_published
    , CAST(0 as sys.bit) as is_schema_published
  from sys.triggers tr
  inner join pg_proc p on p.oid = tr.object_id
union all 
select
    CAST(def.name as sys.sysname) as name
  , CAST(def.object_id as int) as object_id
  , CAST(def.principal_id as int) as principal_id
  , CAST(def.schema_id as int) as schema_id
  , CAST(def.parent_object_id as int) as parent_object_id
  , CAST(def.type as char(2)) as type
  , CAST(def.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(def.create_date as sys.datetime) as create_date
  , CAST(def.modified_date as sys.datetime) as modify_date
  , CAST(def.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(def.is_published as sys.bit) as is_published
  , CAST(def.is_schema_published as sys.bit) as is_schema_published
  from sys.default_constraints def
union all
select
    CAST(chk.name as sys.sysname) as name
  , CAST(chk.object_id as int) as object_id
  , CAST(chk.principal_id as int) as principal_id
  , CAST(chk.schema_id as int) as schema_id
  , CAST(chk.parent_object_id as int) as parent_object_id
  , CAST(chk.type as char(2)) as type
  , CAST(chk.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(chk.create_date as sys.datetime) as create_date
  , CAST(chk.modify_date as sys.datetime) as modify_date
  , CAST(chk.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(chk.is_published as sys.bit) as is_published
  , CAST(chk.is_schema_published as sys.bit) as is_schema_published
  from sys.check_constraints chk
union all
select
    CAST(p.relname as sys.sysname) as name
  , CAST(p.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(s.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('SO' as char(2)) as type
  , CAST('SEQUENCE_OBJECT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from pg_class p
inner join sys.schemas s on s.schema_id = p.relnamespace
and p.relkind = 'S'
and has_schema_privilege(s.schema_id, 'USAGE')
union all
select
    CAST(('TT_' || tt.name || '_' || tt.type_table_object_id) as sys.sysname) as name
  , CAST(tt.type_table_object_id as int) as object_id
  , CAST(tt.principal_id as int) as principal_id
  , CAST(tt.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('TT' as char(2)) as type
  , CAST('TABLE_TYPE' as sys.nvarchar(60)) as type_desc
  , CAST((select string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as create_date
  , CAST((select string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as modify_date
  , CAST(1 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from sys.table_types tt
inner join pg_class c on tt.type_table_object_id = c.oid;
GRANT SELECT ON sys.objects TO PUBLIC;

CREATE OR REPLACE FUNCTION objectproperty(
    id INT,
    property SYS.VARCHAR
    )
RETURNS INT
AS $$
BEGIN

    IF NOT EXISTS(SELECT ao.object_id FROM sys.all_objects ao WHERE object_id = id)
    THEN
        RETURN NULL;
    END IF;

    property := RTRIM(LOWER(COALESCE(property, '')));

    IF property = 'ownerid' -- OwnerId
    THEN
        RETURN (
                SELECT CAST(COALESCE(t1.principal_id, pn.nspowner) AS INT)
                FROM sys.all_objects t1
                INNER JOIN pg_catalog.pg_namespace pn ON pn.oid = t1.schema_id
                WHERE t1.object_id = id);

    ELSEIF property = 'isdefaultcnst' -- IsDefaultCnst
    THEN
        RETURN (SELECT count(distinct dc.object_id) FROM sys.default_constraints dc WHERE dc.object_id = id);

    ELSEIF property = 'execisquotedidenton' -- ExecIsQuotedIdentOn
    THEN
        RETURN (SELECT CAST(sm.uses_quoted_identifier as int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'tablefulltextpopulatestatus' -- TableFullTextPopulateStatus
    THEN
        IF NOT EXISTS (SELECT object_id FROM sys.tables t WHERE t.object_id = id) THEN
            RETURN NULL;
        END IF;
        RETURN 0;

    ELSEIF property = 'tablehasvardecimalstorageformat' -- TableHasVarDecimalStorageFormat
    THEN
        IF NOT EXISTS (SELECT object_id FROM sys.tables t WHERE t.object_id = id) THEN
            RETURN NULL;
        END IF;
        RETURN 0;

    ELSEIF property = 'ismsshipped' -- IsMSShipped
    THEN
        RETURN (SELECT CAST(ao.is_ms_shipped AS int) FROM sys.all_objects ao WHERE ao.object_id = id);

    ELSEIF property = 'isschemabound' -- IsSchemaBound
    THEN
        RETURN (SELECT CAST(sm.is_schema_bound AS int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'execisansinullson' -- ExecIsAnsiNullsOn
    THEN
        RETURN (SELECT CAST(sm.uses_ansi_nulls AS int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'isdeterministic' -- IsDeterministic
    THEN
        RETURN 0;
    
    ELSEIF property = 'isprocedure' -- IsProcedure
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'P');

    ELSEIF property = 'istable' -- IsTable
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IT', 'TT', 'U', 'S'));

    ELSEIF property = 'isview' -- IsView
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'V');
    
    ELSEIF property = 'isusertable' -- IsUserTable
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'U' and is_ms_shipped = 0);
    
    ELSEIF property = 'istablefunction' -- IsTableFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IF', 'TF', 'FT'));
    
    ELSEIF property = 'isinlinefunction' -- IsInlineFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IF'));
    
    ELSEIF property = 'isscalarfunction' -- IsScalarFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('FN', 'FS'));

    ELSEIF property = 'isprimarykey' -- IsPrimaryKey
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'PK');
    
    ELSEIF property = 'isindexed' -- IsIndexed
    THEN
        RETURN (SELECT count(distinct object_id) from sys.indexes WHERE object_id = id and index_id > 0);

    ELSEIF property = 'isdefault' -- IsDefault
    THEN
        RETURN 0;

    ELSEIF property = 'isrule' -- IsRule
    THEN
        RETURN 0;
    
    ELSEIF property = 'istrigger' -- IsTrigger
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('TA', 'TR'));
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.num_days_in_date(IN d1 INTEGER, IN m1 INTEGER, IN y1 INTEGER) RETURNS INTEGER AS $$
DECLARE
	i INTEGER;
	n1 INTEGER;
BEGIN
	n1 = y1 * 365 + d1;
	FOR i in 0 .. m1-2 LOOP
		IF (i = 0 OR i = 2 OR i = 4 OR i = 6 OR i = 7 OR i = 9 OR i = 11) THEN
			n1 = n1 + 31;
		ELSIF (i = 3 OR i = 5 OR i = 8 OR i = 10) THEN
			n1 = n1 + 30;
		ELSIF (i = 1) THEN
			n1 = n1 + 28;
		END IF;
	END LOOP;
	IF m1 <= 2 THEN
		y1 = y1 - 1;
	END IF;
	n1 = n1 + (y1/4 - y1/100 + y1/400);

	return n1;
END
$$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_internal_df(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS INTEGER AS $$
DECLARE
	result INTEGER;
	year_diff INTEGER;
	month_diff INTEGER;
	day_diff INTEGER;
	hour_diff INTEGER;
	minute_diff INTEGER;
	second_diff INTEGER;
	millisecond_diff INTEGER;
	microsecond_diff INTEGER;
	y1 INTEGER;
	m1 INTEGER;
	d1 INTEGER;
	y2 INTEGER;
	m2 INTEGER;
	d2 INTEGER;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		month_diff = sys.datepart('month', enddate) - sys.datepart('month', startdate);
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		month_diff = sys.datepart('month', enddate) - sys.datepart('month', startdate);
		result = year_diff * 12 + month_diff;
	WHEN 'doy', 'y' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		result = day_diff;
	WHEN 'day' THEN
		y1 = sys.datepart('year', enddate);
		m1 = sys.datepart('month', enddate);
		d1 = sys.datepart('day', enddate);
		y2 = sys.datepart('year', startdate);
		m2 = sys.datepart('month', startdate);
		d2 = sys.datepart('day', startdate);
		result = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
	WHEN 'week' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		result = day_diff / 7;
	WHEN 'hour' THEN
		y1 = sys.datepart('year', enddate);
		m1 = sys.datepart('month', enddate);
		d1 = sys.datepart('day', enddate);
		y2 = sys.datepart('year', startdate);
		m2 = sys.datepart('month', startdate);
		d2 = sys.datepart('day', startdate);
		day_diff = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
		hour_diff = sys.datepart('hour', enddate) - sys.datepart('hour', startdate);
		result = day_diff * 24 + hour_diff;
	WHEN 'minute' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
	WHEN 'second' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we don't need to add second_diff again
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we don't need to add second_diff and millisecond_diff again
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(sys.datepart('microsecond', enddate OPERATOR(sys.-) startdate));
		result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = sys.datepart('day', enddate - startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(sys.datepart('microsecond', enddate OPERATOR(sys.-) startdate));
		result = (((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff) * 1000;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
	END CASE;

	return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_internal(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS INTEGER AS $$
DECLARE
	result INTEGER;
	year_diff INTEGER;
	month_diff INTEGER;
	day_diff INTEGER;
	hour_diff INTEGER;
	minute_diff INTEGER;
	second_diff INTEGER;
	millisecond_diff INTEGER;
	microsecond_diff INTEGER;
	y1 INTEGER;
	m1 INTEGER;
	d1 INTEGER;
	y2 INTEGER;
	m2 INTEGER;
	d2 INTEGER;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		month_diff = date_part('month', enddate)::INTEGER - date_part('month', startdate)::INTEGER;
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		month_diff = date_part('month', enddate)::INTEGER - date_part('month', startdate)::INTEGER;
		result = year_diff * 12 + month_diff;
	WHEN 'doy', 'y' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		result = day_diff;
	WHEN 'day' THEN
		y1 = date_part('year', enddate)::INTEGER;
		m1 = date_part('month', enddate)::INTEGER;
		d1 = date_part('day', enddate)::INTEGER;
		y2 = date_part('year', startdate)::INTEGER;
		m2 = date_part('month', startdate)::INTEGER;
		d2 = date_part('day', startdate)::INTEGER;
		result = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
	WHEN 'week' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		result = day_diff / 7;
	WHEN 'hour' THEN
		y1 = date_part('year', enddate)::INTEGER;
		m1 = date_part('month', enddate)::INTEGER;
		d1 = date_part('day', enddate)::INTEGER;
		y2 = date_part('year', startdate)::INTEGER;
		m2 = date_part('month', startdate)::INTEGER;
		d2 = date_part('day', startdate)::INTEGER;
		day_diff = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
		hour_diff = date_part('hour', enddate)::INTEGER - date_part('hour', startdate)::INTEGER;
		result = day_diff * 24 + hour_diff;
	WHEN 'minute' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
	WHEN 'second' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we don't need to add second_diff again
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we don't need to add second_diff and millisecond_diff again
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
		result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
		result = (((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff) * 1000;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
	END CASE;

	return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'check_constraints_deprecated_in_2_3_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'default_constraints_deprecated_in_2_3_0');

-- USER extension
ALTER TABLE sys.babelfish_authid_user_ext add COLUMN IF NOT EXISTS user_can_connect INT NOT NULL DEFAULT 1;

GRANT SELECT ON sys.babelfish_authid_user_ext TO PUBLIC;

-- This is a temporary procedure which is called during upgrade to create guest users
-- for the user created databases if it doesn't have guest user already.
CREATE OR REPLACE PROCEDURE sys.babelfish_update_user_catalog_for_guest()
LANGUAGE C
AS 'babelfishpg_tsql', 'update_user_catalog_for_guest';
 
CALL sys.babelfish_update_user_catalog_for_guest();

ALTER VIEW sys.sp_sproc_columns_view RENAME TO sp_sproc_columns_view_deprecated_in_2_3_0;

CREATE OR REPLACE VIEW sys.sp_sproc_columns_view
AS
SELECT
CAST(sys.db_name() AS sys.sysname) AS PROCEDURE_QUALIFIER -- This will always be objects in current database
, CAST(ss.schema_name AS sys.sysname) AS PROCEDURE_OWNER
, CAST(
CASE
  WHEN ss.prokind = 'p' THEN CONCAT(ss.proname, ';1')
  ELSE CONCAT(ss.proname, ';0')
END
AS sys.nvarchar(134)) AS PROCEDURE_NAME
, CAST(
CASE 
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN '@TABLE_RETURN_VALUE'
    ELSE '@RETURN_VALUE'
  END 
ELSE COALESCE(ss.proargnames[n], '')
END
AS sys.SYSNAME) AS COLUMN_NAME
, CAST(
CASE
WHEN ss.n IS NULL THEN
  CASE 
    WHEN ss.proretset THEN 3
    ELSE 5
  END
WHEN ss.proargmodes[n] in ('o', 'b') THEN 2
ELSE 1
END
AS smallint) AS COLUMN_TYPE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.prokind = 'p' THEN (SELECT data_type FROM sys.spt_datatype_info_table  WHERE type_name = 'int')
    WHEN ss.proretset THEN NULL
    ELSE sdit.data_type 
    END
  WHEN st.is_table_type = 1 THEN -153
  ELSE sdit.data_type 
END
AS smallint) AS DATA_TYPE
, CAST(
CASE 
  WHEN ss.n IS NULL THEN
    CASE 
      WHEN ss.proretset THEN 'table' 
      WHEN ss.prokind = 'p' THEN 'int'
      ELSE st.name
    END
  ELSE st.name
END
AS sys.sysname) AS TYPE_NAME
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE 
      WHEN ss.proretset THEN 0 
    WHEN ss.prokind = 'p' THEN (SELECT precision FROM sys.types WHERE name = 'int')
    ELSE st.precision
  END
  WHEN st.is_table_type = 1 THEN 0
  ELSE st.precision 
END 
AS sys.int) AS PRECISION
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
    WHEN ss.prokind = 'p' THEN (SELECT max_length FROM sys.types WHERE name = 'int')
    ELSE st.max_length
  END
  WHEN st.is_table_type = 1 THEN 2147483647
  ELSE st.max_length 
END
AS sys.int) AS LENGTH
, CAST(
CASE
  WHEN ss.n IS NULL THEN 
    CASE
      WHEN ss.proretset THEN 0 
      WHEN ss.prokind = 'p' THEN (SELECT scale FROM sys.types WHERE name = 'int')
      ELSE st.scale
    END
  WHEN st.is_table_type = 1 THEN NULL
  ELSE st.scale
END
AS smallint) AS SCALE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
    WHEN ss.prokind = 'p' THEN (SELECT num_prec_radix FROM sys.spt_datatype_info_table WHERE type_name = 'int')
    ELSE sdit.num_prec_radix
  END
  WHEN st.is_table_type = 1 THEN NULL
  ELSE sdit.num_prec_radix
END
AS smallint) AS RADIX
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE 
      WHEN ss.proretset OR ss.prokind = 'p' THEN 0
      ELSE sdit.nullable 
    END
  WHEN st.is_table_type = 1 THEN 1
  ELSE sdit.nullable 
END
AS smallint) AS NULLABLE
, CAST(
CASE 
  WHEN ss.n IS NULL AND ss.proretset THEN 'Result table returned by table valued function'
  ELSE NULL
END
AS sys.varchar(254)) AS REMARKS
, CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN NULL
      WHEN ss.prokind = 'p' THEN (SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int')
      ELSE sdit.sql_data_type
    END
  WHEN st.is_table_type = 1 THEN -153
  ELSE sdit.sql_data_type 
END
AS smallint) AS SQL_DATA_TYPE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE 
      WHEN ss.proretset THEN 0
      WHEN ss.prokind = 'p' THEN (SELECT sql_datetime_sub FROM sys.spt_datatype_info_table WHERE type_name = 'int')
      ELSE sdit.sql_datetime_sub
    END
  ELSE sdit.sql_datetime_sub 
END 
AS smallint) AS SQL_DATETIME_SUB
, CAST(
CASE
  WHEN ss.n IS NOT NULL AND st.is_table_type = 1 THEN 2147483647
  ELSE NULL
END
AS sys.int) AS CHAR_OCTET_LENGTH
, CAST(
CASE
  WHEN ss.n IS NULL THEN 0
  ELSE n 
END 
AS sys.int) AS ORDINAL_POSITION
, CAST(
CASE
  WHEN ss.n IS NULL AND ss.proretset THEN 'NO'
  WHEN st.is_table_type = 1 THEN 'YES'
  WHEN sdit.nullable = 1 THEN 'YES'
  ELSE 'NO'
END
AS sys.varchar(254)) AS IS_NULLABLE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
      WHEN ss.prokind = 'p' THEN 56
      ELSE sdit.ss_data_type
    END
  WHEN st.is_table_type = 1 THEN 0
  ELSE sdit.ss_data_type
END
AS sys.tinyint) AS SS_DATA_TYPE
, CAST(ss.proname AS sys.sysname) AS original_procedure_name
FROM 
( 
  -- CTE to query procedures related to bbf
  WITH bbf_proc AS (
    SELECT
      p.proname as proname,
      p.proargnames as proargnames,
      p.proargmodes as proargmodes,
      p.prokind as prokind,
      p.proretset as proretset,
      p.prorettype as prorettype,
      p.proallargtypes as proallargtypes,
      p.proargtypes as proargtypes,
      s.name as schema_name
    FROM 
      pg_proc p
    INNER JOIN (
      SELECT name as name, schema_id as id  FROM sys.schemas 
      UNION ALL 
      SELECT CAST(nspname as sys.sysname) as name, CAST(oid as int) as id 
        from pg_namespace WHERE nspname in ('sys', 'information_schema')
    ) as s ON p.pronamespace = s.id
    WHERE (
      (pg_has_role(p.proowner, 'USAGE') OR has_function_privilege(p.oid, 'EXECUTE'))
      AND (s.name != 'sys' 
        OR p.proname like 'sp\_%' -- filter out internal babelfish-specific procs in sys schema
        OR p.proname like 'xp\_%'
        OR p.proname like 'dm\_%'
        OR p.proname like 'fn\_%'))
  )

  SELECT *
  FROM ( 
    SELECT -- Selects all parameters (input and output), but NOT return values
    p.proname as proname,
    p.proargnames as proargnames,
    p.proargmodes as proargmodes,
    p.prokind as prokind,
    p.proretset as proretset,
    p.prorettype as prorettype,
    p.schema_name as schema_name,
    (information_schema._pg_expandarray(
    COALESCE(p.proallargtypes,
      CASE 
        WHEN p.prokind = 'f' THEN (CAST(p.proargtypes AS oid[]))
        ELSE CAST(p.proargtypes AS oid[])
      END
    ))).x AS x,
    (information_schema._pg_expandarray(
    COALESCE(p.proallargtypes,
      CASE 
        WHEN p.prokind = 'f' THEN (CAST(p.proargtypes AS oid[]))
        ELSE CAST(p.proargtypes AS oid[])
      END
    ))).n AS n
    FROM bbf_proc p) AS t
  WHERE (t.proargmodes[t.n] in ('i', 'o', 'b') OR t.proargmodes is NULL)

  UNION ALL

  SELECT -- Selects all return values (this is because inline-table functions could cause duplicate outputs)
  p.proname as proname,
  p.proargnames as proargnames,
  p.proargmodes as proargmodes,
  p.prokind as prokind,
  p.proretset as proretset,
  p.prorettype as prorettype,
  p.schema_name as schema_name,
  p.prorettype AS x, 
  NULL AS n -- null value indicates that we are retrieving the return values of the proc/func
  FROM bbf_proc p
) ss
LEFT JOIN sys.types st ON ss.x = st.user_type_id -- left join'd because return type of table-valued functions may not have an entry in sys.types
-- Because spt_datatype_info_table does contain user-defind types and their names,
-- the join below allows us to retrieve the name of the base type of the user-defined type
LEFT JOIN sys.spt_datatype_info_table sdit ON sdit.type_name = sys.translate_pg_type_to_tsql(st.system_type_id);
GRANT SELECT ON sys.sp_sproc_columns_view TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sp_sproc_columns_view_deprecated_in_2_3_0');

CREATE OR REPLACE PROCEDURE sys.sp_addrole(IN "@rolename" sys.SYSNAME, IN "@ownername" sys.SYSNAME DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_addrole' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_addrole(IN sys.SYSNAME, IN sys.SYSNAME) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_droprole(IN "@rolename" sys.SYSNAME)
AS 'babelfishpg_tsql', 'sp_droprole' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_droprole(IN sys.SYSNAME) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_addrolemember(IN "@rolename" sys.SYSNAME, IN "@membername" sys.SYSNAME)
AS 'babelfishpg_tsql', 'sp_addrolemember' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_addrolemember(IN sys.SYSNAME, IN sys.SYSNAME) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_droprolemember(IN "@rolename" sys.SYSNAME, IN "@membername" sys.SYSNAME)
AS 'babelfishpg_tsql', 'sp_droprolemember' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_droprolemember(IN sys.SYSNAME, IN sys.SYSNAME) TO PUBLIC;

/*
 * JSON MODIFY
 * This function is used to update the value of a property in a JSON string and returns the updated JSON string.
 * It has been implemented in three parts:
 *  1) Set the append and create_if_missing flag as postgres functions do not directly take append and lax/strict mode in the jsonb_path.
 *  2) To convert the input path into the expected jsonb_path.
 *  3) To implement the main logic of the JSON_MODIFY function by dividing it into 8 different cases.
 */
CREATE OR REPLACE FUNCTION sys.json_modify(in expression sys.NVARCHAR,in path_json TEXT, in new_value TEXT)
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    json_path TEXT;
    json_path_convert TEXT;
    new_jsonb_path TEXT[];
    key_value_type TEXT;
    path_split_array TEXT[];
    comparison_string TEXT COLLATE "C";
    len_array INTEGER;
    word_count INTEGER;
    create_if_missing BOOL = TRUE;
    append_modifier BOOL = FALSE;
    key_exists BOOL;
    key_value JSONB;
    json_expression JSONB = expression::JSONB;
    result_json sys.NVARCHAR;
BEGIN
    path_split_array = regexp_split_to_array(TRIM(path_json) COLLATE "C",'\s+');
    word_count = array_length(path_split_array,1);
    /* 
     * This if else block is added to set the create_if_missing and append_modifier flags.
     * These flags will be used to know the mode and if the optional modifier append is present in the input path_json.
     * It is necessary as postgres functions do not directly take append and lax/strict mode in the jsonb_path.    
     */
    IF word_count = 1 THEN
        json_path = path_split_array[1];
        create_if_missing = TRUE;
        append_modifier = FALSE;
    ELSIF word_count = 2 THEN 
        json_path = path_split_array[2];
        comparison_string = path_split_array[1]; -- append or lax/strict mode
        IF comparison_string = 'append' THEN
            append_modifier = TRUE;
        ELSIF comparison_string = 'strict' THEN
            create_if_missing = FALSE;
        ELSIF comparison_string = 'lax' THEN
            create_if_missing = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
    ELSIF word_count = 3 THEN
        json_path = path_split_array[3];
        comparison_string = path_split_array[1]; -- append mode 
        IF comparison_string = 'append' THEN
            append_modifier = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
        comparison_string = path_split_array[2]; -- lax/strict mode
        IF comparison_string = 'strict' THEN
            create_if_missing = FALSE;
        ELSIF comparison_string = 'lax' THEN
            create_if_missing = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
    ELSE
        RAISE invalid_json_text;
    END IF;

    -- To convert input jsonpath to the required jsonb_path format
    json_path_convert = regexp_replace(json_path, '\$\.|]|\$\[' , '' , 'ig'); -- To remove "$." and "]" sign from the string 
    json_path_convert = regexp_replace(json_path_convert, '\.|\[' , ',' , 'ig'); -- To replace "." and "[" with "," to change into required format
    new_jsonb_path = CONCAT('{',json_path_convert,'}'); -- Final required format of path by jsonb_set

    key_exists = jsonb_path_exists(json_expression,json_path::jsonpath); -- To check if key exist in the given path
    
    --This if else block is to call the jsonb_set function based on the create_if_missing and append_modifier flags
    IF append_modifier THEN 
        IF key_exists THEN
            key_value = jsonb_path_query_first(json_expression,json_path::jsonpath); -- To get the value of the key
            key_value_type = jsonb_typeof(key_value);
            IF key_value_type = 'array' THEN
                len_array = jsonb_array_length(key_value);
                /*
                 * As jsonb_insert requires the index of the value to be inserted, so the below FORMAT function changes the path format into the required jsonb_insert path format.
                 * Eg: JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.skills','Azure'); -> converts the path from '$.skills' to '{skills,2}' instead of '{skills}'
                 */
                new_jsonb_path = FORMAT('%s,%s}',TRIM('}' FROM new_jsonb_path::TEXT),len_array);
                IF new_value IS NULL THEN
                    result_json = jsonb_insert(json_expression,new_jsonb_path,'null'); -- This needs to be done because "to_jsonb(coalesce(new_value, 'null'))" does not result in a JSON NULL
                ELSE
                    result_json = jsonb_insert(json_expression,new_jsonb_path,to_jsonb(new_value));
                END IF;
            ELSE
                IF NOT create_if_missing THEN
                    RAISE sql_json_array_not_found;
                ELSE
                    result_json = json_expression;
                END IF;
            END IF;
        ELSE
            IF NOT create_if_missing THEN
                RAISE sql_json_object_not_found;
            ELSE
                result_json = jsonb_insert(json_expression,new_jsonb_path,to_jsonb(array_agg(new_value))); -- array_agg is used to convert the new_value text into array format as we append functionality is being used
            END IF;
        END IF;
    ELSE --When no append modifier is present
        IF new_value IS NOT NULL THEN
            IF key_exists OR create_if_missing THEN
                result_json = jsonb_set_lax(json_expression,new_jsonb_path,to_jsonb(new_value),create_if_missing);
            ELSE
                RAISE sql_json_object_not_found;
            END IF;
        ELSE
            IF key_exists THEN
                IF NOT create_if_missing THEN
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,to_jsonb(new_value));
                ELSE
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,to_jsonb(new_value),create_if_missing,'delete_key');
                END IF;
            ELSE
                IF NOT create_if_missing THEN
                    RAISE sql_json_object_not_found;
                ELSE
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,to_jsonb(new_value),FALSE);
                END IF;
            END IF;
        END IF;
    END IF;  -- If append_modifier block ends here
    RETURN result_json;
EXCEPTION
    WHEN invalid_json_text THEN
            RAISE USING MESSAGE = 'JSON path is not properly formatted',
                        DETAIL = FORMAT('Unexpected keyword "%s" is found.',comparison_string),
                        HINT = 'Change "modifier/mode" parameter to the proper value and try again.';
    WHEN sql_json_array_not_found THEN
            RAISE USING MESSAGE = 'array cannot be found in the specified JSON path',
                        HINT = 'Change JSON path to target array property and try again.';
    WHEN sql_json_object_not_found THEN
            RAISE USING MESSAGE = 'property cannot be found on the specified JSON path';
END;        
$BODY$
LANGUAGE plpgsql;

-- Helper function to support the FOR JSON clause
CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_text(query text, mode int, include_null_value boolean,
           without_array_wrappers boolean, root_name text)
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'tsql_query_to_json_text'
LANGUAGE C IMMUTABLE COST 100;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_time(IN p_datatype TEXT,
                                                                 IN p_timestring TEXT,
                                                                 IN p_style NUMERIC DEFAULT 0)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hours SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_daypart VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_minutes SMALLINT;
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_timeunit_mask VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,9})';
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '$');
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(TIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
BEGIN
    v_datatype := trim(regexp_replace(p_datatype, 'DATETIME', 'TIME', 'gi'));
    v_timestring := upper(trim(p_timestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_src_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_src_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    v_daypart := substring(v_timestring, 'AM|PM');
    v_timestring := trim(regexp_replace(v_timestring, coalesce(v_daypart, ''), ''));

    v_timeunit_mask :=
        CASE
           WHEN (v_timestring ~* HHMMSSFS_REGEXP) THEN HHMMSSFS_REGEXP
           WHEN (v_timestring ~* HHMMSS_REGEXP) THEN HHMMSS_REGEXP
           WHEN (v_timestring ~* HHMMFS_REGEXP) THEN HHMMFS_REGEXP
           WHEN (v_timestring ~* HHMM_REGEXP) THEN HHMM_REGEXP
           WHEN (v_timestring ~* HH_REGEXP) THEN HH_REGEXP
        END;

    IF (v_timeunit_mask IS NULL) THEN
        RAISE invalid_datetime_format;
    END IF;

    v_regmatch_groups := regexp_matches(v_timestring, v_timeunit_mask, 'gi');

    v_hours := v_regmatch_groups[1]::SMALLINT;
    v_minutes := v_regmatch_groups[2]::SMALLINT;

    IF (v_timestring ~* HHMMFS_REGEXP) THEN
        v_fseconds := v_regmatch_groups[3];
    ELSE
        v_seconds := v_regmatch_groups[3];
        v_fseconds := v_regmatch_groups[4];
    END IF;

   IF (v_daypart IS NOT NULL) THEN
      IF ((v_daypart = 'AM' AND v_hours NOT BETWEEN 0 AND 12) OR
          (v_daypart = 'PM' AND v_hours NOT BETWEEN 1 AND 23))
      THEN
          RAISE numeric_value_out_of_range;
      ELSIF (v_daypart = 'PM' AND v_hours < 12) THEN
          v_hours := v_hours + 12;
      ELSIF (v_daypart = 'AM' AND v_hours = 12) THEN
          v_hours := v_hours - 12;
      END IF;
   END IF;

    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
    v_seconds := concat_ws('.', v_seconds, v_fseconds);

    RETURN make_time(v_hours, v_minutes, v_seconds::NUMERIC);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of conv_string_to_time function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('The style %s is not supported for conversions from VARCHAR to TIME.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := 'Could not extract correct hour value due to it''s inconsistency with AM|PM day part mark.',
                    DETAIL := 'Extracted hour value doesn''t fall in correct day part mark range: 0..12 for "AM" or 1..23 for "PM".',
                    HINT := 'Correct a hour value in the source string or remove AM|PM day part mark out of it.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting time from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;


CREATE OR REPLACE PROCEDURE sys.sp_helpdb(IN "@dbname" VARCHAR(32))
LANGUAGE 'pltsql'
AS $$
BEGIN
  SELECT
  CAST(name AS sys.nvarchar(128)),
  CAST(db_size AS sys.nvarchar(13)),
  CAST(owner AS sys.nvarchar(128)),
  CAST(dbid AS sys.int),
  CAST(created AS sys.nvarchar(11)),
  CAST(status AS sys.nvarchar(600)),
  CAST(compatibility_level AS sys.tinyint)
  FROM sys.babelfish_helpdb(@dbname);

  SELECT
  CAST(NULL AS sys.nchar(128)) AS name,
  CAST(NULL AS smallint) AS fileid,
  CAST(NULL AS sys.nchar(260)) AS filename,
  CAST(NULL AS sys.nvarchar(128)) AS filegroup,
  CAST(NULL AS sys.nvarchar(18)) AS size,
  CAST(NULL AS sys.nvarchar(18)) AS maxsize,
  CAST(NULL AS sys.nvarchar(18)) AS growth,
  CAST(NULL AS sys.varchar(9)) AS usage;

  RETURN 0;
END;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_helpuser("@name_in_db" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If security account is not specified, return info about all users
	IF @name_in_db IS NULL
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner'
					WHEN Ext2.orig_username IS NULL THEN 'public'
					ELSE Ext2.orig_username END
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname
					ELSE Base3.rolname END
					AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base1.oid AS INT) AS 'UserID',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN CAST(Base4.oid AS INT)
					WHEN Ext1.orig_username = 'guest' THEN CAST(0 AS INT)
					ELSE CAST(Base3.oid AS INT) END
					AS SYS.VARBINARY(85)) AS 'SID'
		FROM sys.babelfish_authid_user_ext AS Ext1
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
		LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base3 ON Base3.rolname = LogExt.rolname
		LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.name = DB_NAME()
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
		WHERE Ext1.database_name = DB_NAME()
		AND Ext1.type = 'S'
		AND Ext1.orig_username != 'db_owner'
		ORDER BY UserName, RoleName;
	END
	-- If the security account is the db fixed role - db_owner
    ELSE IF @name_in_db = 'db_owner'
	BEGIN
		-- TODO: Need to change after we can add/drop members to/from db_owner
		SELECT CAST('db_owner' AS SYS.SYSNAME) AS 'Role_name',
			   ROLE_ID('db_owner') AS 'Role_id',
			   CAST('dbo' AS SYS.SYSNAME) AS 'Users_in_role',
			   USER_ID('dbo') AS 'Userid';
	END
	-- If the security account is a db role
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @name_in_db
					OR lower(orig_username) = lower(@name_in_db))
					AND database_name = DB_NAME()
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'Role_name',
			   CAST(Base1.oid AS INT) AS 'Role_id',
			   CAST(Ext2.orig_username AS SYS.SYSNAME) AS 'Users_in_role',
			   CAST(Base2.oid AS INT) AS 'Userid'
		FROM sys.babelfish_authid_user_ext AS Ext2
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.rolname = Ext2.rolname
		INNER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base2.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		WHERE Ext1.database_name = DB_NAME()
		AND Ext2.database_name = DB_NAME()
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		AND (Ext1.orig_username = @name_in_db OR lower(Ext1.orig_username) = lower(@name_in_db))
		ORDER BY Role_name, Users_in_role;
	END
	-- If the security account is a user
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @name_in_db
					OR lower(orig_username) = lower(@name_in_db))
					AND database_name = DB_NAME()
					AND type = 'S')
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner'
					WHEN Ext2.orig_username IS NULL THEN 'public'
					ELSE Ext2.orig_username END
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname
					ELSE Base3.rolname END
					AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base1.oid AS INT) AS 'UserID',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN CAST(Base4.oid AS INT)
					WHEN Ext1.orig_username = 'guest' THEN CAST(0 AS INT)
					ELSE CAST(Base3.oid AS INT) END
					AS SYS.VARBINARY(85)) AS 'SID'
		FROM sys.babelfish_authid_user_ext AS Ext1
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
		LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base3 ON Base3.rolname = LogExt.rolname
		LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.name = DB_NAME()
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
		WHERE Ext1.database_name = DB_NAME()
		AND Ext1.type = 'S'
		AND Ext1.orig_username != 'db_owner'
		AND (Ext1.orig_username = @name_in_db OR lower(Ext1.orig_username) = lower(@name_in_db))
		ORDER BY UserName, RoleName;
	END
	-- If the security account is not valid
	ELSE
		RAISERROR ( 'The name supplied (%s) is not a user, role, or aliased login.', 16, 1, @name_in_db);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_helpuser TO PUBLIC;

-- update datediff functions to either explicitly cast to timestamp or use different helper function
CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal_date(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_internal_date(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER AS $$
DECLARE
	result INTEGER;
	year_diff INTEGER;
	month_diff INTEGER;
	day_diff INTEGER;
	hour_diff INTEGER;
	minute_diff INTEGER;
	second_diff INTEGER;
	millisecond_diff INTEGER;
	microsecond_diff INTEGER;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		month_diff = date_part('month', enddate)::INTEGER - date_part('month', startdate)::INTEGER;
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		month_diff = date_part('month', enddate)::INTEGER - date_part('month', startdate)::INTEGER;
		result = year_diff * 12 + month_diff;
	-- for all intervals smaller than month, (DATE - DATE) already returns the integer number of days
	-- between the dates, so just use that directly as the day_diff. There is no finer resolution
	-- than days with the DATE type anyways.
	WHEN 'doy', 'y' THEN
		day_diff = enddate - startdate;
		result = day_diff;
	WHEN 'day' THEN
		day_diff = enddate - startdate;
		result = day_diff;
	WHEN 'week' THEN
		day_diff = enddate - startdate;
		result = day_diff / 7;
	WHEN 'hour' THEN
		day_diff = enddate - startdate;
		result = day_diff * 24;
	WHEN 'minute' THEN
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60;
	WHEN 'second' THEN
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we don't need to add second_diff again
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60 * 1000;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we don't need to add second_diff and millisecond_diff again
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60 * 1000 * 1000;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60 * 1000 * 1000 * 1000;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
	END CASE;

	return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

-- helper function sys.babelfish_conv_helper_to_datetime(text, bool, numeric) needs to change return type to sys.DATETIME
ALTER FUNCTION sys.babelfish_conv_helper_to_datetime(text, bool, numeric) RENAME TO babelfish_conv_helper_to_datetime_deprecated_in_2_3_0_1;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_datetime_deprecated_in_2_3_0_1');

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg TEXT, IN try BOOL, IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime('DATETIME', arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetime('DATETIME', arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

-- helper function sys.babelfish_conv_helper_to_datetime(anyelement, bool, numeric) is no longer needed,
-- as all arguments should be casted to text anyways. Drop the function.
ALTER FUNCTION sys.babelfish_conv_helper_to_datetime(anyelement, bool, numeric) RENAME TO babelfish_conv_helper_to_datetime_deprecated_in_2_3_0_2;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_datetime_deprecated_in_2_3_0_2');

-- helper function sys.babelfish_try_conv_to_datetime(anyelement) needs to change return type to sys.DATETIME
ALTER FUNCTION sys.babelfish_try_conv_to_datetime(anyelement) RENAME TO babelfish_try_conv_to_datetime_deprecated_in_2_3_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_to_datetime_deprecated_in_2_3_0');

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetime(IN arg anyelement)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN CAST(arg AS TIMESTAMP);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

-- Identity related helper functions are no longer needed
ALTER FUNCTION sys.get_min_id_from_table RENAME TO get_min_id_from_table_deprecated_in_2_3_0;
ALTER FUNCTION sys.get_max_id_from_table RENAME TO get_max_id_from_table_deprecated_in_2_3_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'get_min_id_from_table_deprecated_in_2_3_0');
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'get_max_id_from_table_deprecated_in_2_3_0');


-- Deprecate the function sys.get_tds_id
ALTER FUNCTION sys.get_tds_id RENAME TO get_tds_id_deprecated_2_3_0;

-- Recreate Newer sys.get_tds_id function
create or replace function sys.get_tds_id(
	datatype sys.varchar(50)
)
returns INT
AS $$
DECLARE
	tds_id INT;
BEGIN
	IF datatype IS NULL THEN
		RETURN 0;
	END IF;
	CASE datatype
		WHEN 'text' THEN tds_id = 35;
		WHEN 'uniqueidentifier' THEN tds_id = 36;
		WHEN 'tinyint' THEN tds_id = 38;
		WHEN 'smallint' THEN tds_id = 38;
		WHEN 'int' THEN tds_id = 38;
		WHEN 'bigint' THEN tds_id = 38;
		WHEN 'ntext' THEN tds_id = 99;
		WHEN 'bit' THEN tds_id = 104;
		WHEN 'float' THEN tds_id = 109;
		WHEN 'real' THEN tds_id = 109;
		WHEN 'varchar' THEN tds_id = 167;
		WHEN 'nvarchar' THEN tds_id = 231;
		WHEN 'nchar' THEN tds_id = 239;
		WHEN 'money' THEN tds_id = 110;
		WHEN 'smallmoney' THEN tds_id = 110;
		WHEN 'char' THEN tds_id = 175;
		WHEN 'date' THEN tds_id = 40;
		WHEN 'datetime' THEN tds_id = 111;
		WHEN 'smalldatetime' THEN tds_id = 111;
		WHEN 'numeric' THEN tds_id = 108;
		WHEN 'xml' THEN tds_id = 241;
		WHEN 'decimal' THEN tds_id = 106;
		WHEN 'varbinary' THEN tds_id = 165;
		WHEN 'binary' THEN tds_id = 173;
		WHEN 'image' THEN tds_id = 34;
		WHEN 'time' THEN tds_id = 41;
		WHEN 'datetime2' THEN tds_id = 42;
		WHEN 'sql_variant' THEN tds_id = 98;
		WHEN 'datetimeoffset' THEN tds_id = 43;
		WHEN 'timestamp' THEN tds_id = 173;
		ELSE tds_id = 0;
	END CASE;
	RETURN tds_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- Drop the deprecated function
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'get_tds_id_deprecated_2_3_0');

CREATE OR REPLACE VIEW sys.server_principals
AS SELECT
CAST(Base.rolname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.type AS CHAR(1)) as type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_LOGIN' 
WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
ELSE NULL END AS NVARCHAR(60)) AS type_desc,
CAST(Ext.is_disabled AS INT) AS is_disabled,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.is_fixed_role END AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

GRANT SELECT ON sys.server_principals TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_principals AS SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.oid AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_USER'
WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
ELSE NULL END AS SYS.NVARCHAR(60)) AS type_desc,
CAST(Ext.default_schema_name AS SYS.SYSNAME) AS default_schema_name,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(Ext.owning_principal_id AS INT) AS owning_principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.is_fixed_role AS SYS.BIT) AS is_fixed_role,
CAST(Ext.authentication_type AS INT) AS authentication_type,
CAST(Ext.authentication_type_desc AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(Ext.default_language_lcid AS INT) AS default_language_lcid,
CAST(Ext.allow_encrypted_value_modifications AS SYS.BIT) AS allow_encrypted_value_modifications
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME();

GRANT SELECT ON sys.database_principals TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_role_members AS
SELECT
CAST(Auth1.oid AS INT) AS role_principal_id,
CAST(Auth2.oid AS INT) AS member_principal_id
FROM pg_catalog.pg_auth_members AS Authmbr
INNER JOIN pg_catalog.pg_roles AS Auth1 ON Auth1.oid = Authmbr.roleid
INNER JOIN pg_catalog.pg_roles AS Auth2 ON Auth2.oid = Authmbr.member
INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Auth1.rolname = Ext1.rolname
INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Auth2.rolname = Ext2.rolname
WHERE Ext1.database_name = DB_NAME() 
AND Ext2.database_name = DB_NAME()
AND Ext1.type = 'R'
AND Ext2.orig_username != 'db_owner';

GRANT SELECT ON sys.database_role_members TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_statistics_view AS
SELECT
CAST(t3."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t3."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CAST(NULL AS smallint) AS NON_UNIQUE,
CAST(NULL AS sys.sysname) AS INDEX_QUALIFIER,
CAST(NULL AS sys.sysname) AS INDEX_NAME,
CAST(0 AS smallint) AS TYPE,
CAST(NULL AS smallint) AS SEQ_IN_INDEX,
CAST(NULL AS sys.sysname) AS COLUMN_NAME,
CAST(NULL AS sys.varchar(1)) AS COLLATION,
CAST(t1.reltuples AS int) AS CARDINALITY,
CAST(t1.relpages AS int) AS PAGES,
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN information_schema_tsql.columns t3 ON (t1.relname = t3."TABLE_NAME" AND s1.name = t3."TABLE_SCHEMA")
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
UNION
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CASE
WHEN t5.indisunique = 't' THEN CAST(0 AS smallint)
ELSE CAST(1 AS smallint)
END AS NON_UNIQUE,
CAST(t1.relname AS sys.sysname) AS INDEX_QUALIFIER,
-- the index name created by CREATE INDEX is re-mapped, find it (by checking
-- the ones not in pg_constraint) and restoring it back before display
CASE 
WHEN t8.oid > 0 THEN CAST(t6.relname AS sys.sysname)
ELSE CAST(SUBSTRING(t6.relname,1,LENGTH(t6.relname)-32-LENGTH(t1.relname)) AS sys.sysname) 
END AS INDEX_NAME,
CASE
WHEN t5.indisclustered = 't' THEN CAST(1 AS smallint)
ELSE CAST(3 AS smallint)
END AS TYPE,
CAST(seq + 1 AS smallint) AS SEQ_IN_INDEX,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.n_distinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" AND s1.name = t4."TABLE_SCHEMA")
	JOIN (pg_catalog.pg_index t5 JOIN
		pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
	JOIN pg_catalog.pg_namespace nsp ON (t1.relnamespace = nsp.oid)
	LEFT JOIN pg_catalog.pg_stats t7 ON (t1.relname = t7.tablename AND t7.schemaname = nsp.nspname)
	LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.indkey)
    AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.indkey[seq];
GRANT SELECT on sys.sp_statistics_view TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg TEXT, IN typmod INTEGER)
RETURNS sys.DATETIME2
AS $BODY$
BEGIN
    RETURN CASE typmod
            WHEN 0 THEN CAST(arg as DATETIME2(0))
            WHEN 1 THEN CAST(arg as DATETIME2(1))
            WHEN 2 THEN CAST(arg as DATETIME2(2))
            WHEN 3 THEN CAST(arg as DATETIME2(3))
            WHEN 4 THEN CAST(arg as DATETIME2(4))
            WHEN 5 THEN CAST(arg as DATETIME2(5))
            ELSE CAST(arg as DATETIME2(6))
        END;
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('cannot cast type %s to datetime2.',
                                      pg_typeof(arg));
        WHEN OTHERS THEN
            RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg ANYELEMENT, IN typmod INTEGER)
RETURNS sys.DATETIME2
AS $BODY$
BEGIN
     RETURN CASE typmod
            WHEN 0 THEN CAST(arg as DATETIME2(0))
            WHEN 1 THEN CAST(arg as DATETIME2(1))
            WHEN 2 THEN CAST(arg as DATETIME2(2))
            WHEN 3 THEN CAST(arg as DATETIME2(3))
            WHEN 4 THEN CAST(arg as DATETIME2(4))
            WHEN 5 THEN CAST(arg as DATETIME2(5))
            ELSE CAST(arg as DATETIME2(6))
        END;
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('cannot cast type %s to datetime2.',
                                      pg_typeof(arg));
        WHEN OTHERS THEN
            RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;
