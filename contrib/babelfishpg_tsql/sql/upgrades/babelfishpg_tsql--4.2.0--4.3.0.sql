-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.3.0'" to load this file. \quit

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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

-- BBF_PARTITION_FUNCTION
-- This catalog stores the metadata of partition funtions.
CREATE TABLE sys.babelfish_partition_function
(
  dbid SMALLINT NOT NULL, -- to maintain separation b/w databases
  function_id INT NOT NULL UNIQUE, -- globally unique ID of partition function
  partition_function_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  input_parameter_type sys.sysname, -- data type of the column which will be used for partitioning
  partition_option sys.bit, -- whether boundary option is LEFT or RIGHT
  range_values sys.sql_variant[] CHECK (array_length(range_values, 1) < 15000), -- boundary values
  create_date SYS.DATETIME NOT NULL,
  modify_date SYS.DATETIME NOT NULL,
  PRIMARY KEY(dbid, partition_function_name)
);

-- SEQUENCE to maintain the ID of partition function.
CREATE SEQUENCE sys.babelfish_partition_function_seq MAXVALUE 2147483647 CYCLE;

-- BBF_PARTITION_SCHEME
-- This catalog stores the metadata of partition schemes.
CREATE TABLE sys.babelfish_partition_scheme
(
  dbid SMALLINT NOT NULL, -- to maintain separation between databases
  scheme_id INT NOT NULL UNIQUE, -- globally unique ID of partition scheme
  partition_scheme_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  partition_function_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  next_used sys.bit, -- next used filegroup is specified or not during creation
  PRIMARY KEY(dbid, partition_scheme_name)
);

-- SEQUENCE to maintain the ID of partition scheme.
-- The combination of the partition scheme ID and filegroup ID are used as
-- DATA_SPACE_ID, where the value 1 is reseverd for [PRIMARY] filegroup.
CREATE SEQUENCE sys.babelfish_partition_scheme_seq START 2 MAXVALUE 2147483647 CYCLE;

-- BBF_PARTITION_DEPEND
-- This catalog tracks the dependecy between partition scheme and partitioned tables created using that.
CREATE TABLE sys.babelfish_partition_depend
(
  dbid SMALLINT NOT NULL, -- to maintain separation between databases
  partition_scheme_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  schema_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  table_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  PRIMARY KEY(dbid, schema_name, table_name)
);

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_function', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_scheme', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_depend', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_function_seq', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_scheme_seq', '');


CREATE OR REPLACE PROCEDURE initialize_babelfish ( sa_name VARCHAR(128) )
LANGUAGE plpgsql
AS $$
DECLARE
	reserved_roles varchar[] := ARRAY['sysadmin', 'master_dbo', 'master_guest', 'master_db_owner', 'tempdb_dbo', 'tempdb_guest', 'tempdb_db_owner', 'msdb_dbo', 'msdb_guest', 'msdb_db_owner'];
	user_id  oid := -1;
	db_name  name := NULL;
	role_name varchar;
	dba_name varchar;
BEGIN
	-- check reserved roles
	FOREACH role_name IN ARRAY reserved_roles LOOP
	BEGIN
		SELECT oid INTO user_id FROM pg_roles WHERE rolname = role_name;
		IF user_id > 0 THEN
			SELECT datname INTO db_name FROM pg_shdepend AS s INNER JOIN pg_database AS d ON s.dbid = d.oid WHERE s.refobjid = user_id;
			IF db_name IS NOT NULL THEN
				RAISE E'Could not initialize babelfish in current database: Reserved role % used in database %.\nIf babelfish was initialized in %, please remove babelfish and try again.', role_name, db_name, db_name;
			ELSE
				RAISE E'Could not initialize babelfish in current database: Reserved role % exists. \nPlease rename or drop existing role and try again ', role_name;
			END IF;
		END IF;
	END;
	END LOOP;

	SELECT pg_get_userbyid(datdba) INTO dba_name FROM pg_database WHERE datname = CURRENT_DATABASE();
	IF sa_name <> dba_name THEN
		RAISE E'Could not initialize babelfish with given role name: % is not the DB owner of current database.', sa_name;
	END IF;

	EXECUTE format('CREATE ROLE bbf_role_admin CREATEDB CREATEROLE INHERIT PASSWORD NULL');
	EXECUTE format('GRANT CREATE ON DATABASE %s TO bbf_role_admin WITH GRANT OPTION', CURRENT_DATABASE());
	EXECUTE format('GRANT %I to bbf_role_admin WITH ADMIN TRUE;', sa_name);
	EXECUTE format('CREATE ROLE sysadmin CREATEDB CREATEROLE INHERIT ROLE %I', sa_name);
	EXECUTE format('GRANT sysadmin TO bbf_role_admin WITH ADMIN TRUE');
	EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_partition_function_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_partition_scheme_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_db_seq TO sysadmin WITH GRANT OPTION');
	EXECUTE format('GRANT CREATE, CONNECT, TEMPORARY ON DATABASE %s TO sysadmin WITH GRANT OPTION', CURRENT_DATABASE());
	EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = true', CURRENT_DATABASE());
	EXECUTE 'SET babelfishpg_tsql.enable_ownership_structure = true';
	CALL sys.babel_initialize_logins(sa_name);
	CALL sys.babel_initialize_logins('sysadmin');
	CALL sys.babel_initialize_logins('bbf_role_admin');
	CALL sys.babel_create_builtin_dbs(sa_name);
	CALL sys.initialize_babel_extras();
	-- run analyze for all babelfish catalog
	CALL sys.analyze_babelfish_catalogs();
END
$$;

CREATE OR REPLACE PROCEDURE remove_babelfish ()
LANGUAGE plpgsql
AS $$
BEGIN
	CALL sys.babel_drop_all_dbs();
	CALL sys.babel_drop_all_logins();
	EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = false', CURRENT_DATABASE());
	EXECUTE 'ALTER SEQUENCE sys.babelfish_db_seq RESTART';
	EXECUTE 'ALTER SEQUENCE sys.babelfish_partition_function_seq RESTART';
	EXECUTE 'ALTER SEQUENCE sys.babelfish_partition_scheme_seq RESTART';
	DROP OWNED BY sysadmin;
	DROP ROLE sysadmin;
	DROP OWNED BY bbf_role_admin;
	DROP ROLE bbf_role_admin;
END
$$;

CREATE OR REPLACE VIEW sys.partition_functions AS
SELECT
  partition_function_name as name,
  function_id,
  CAST('R' as sys.bpchar(2)) as type,
  CAST('RANGE' as sys.nvarchar(60)) as type_desc,
  CAST(ARRAY_LENGTH(range_values, 1)+1 as int) fanout,
  CAST(partition_option as sys.bit) as boundary_value_on_right,
  CAST(0 as sys.bit) as is_system,
  create_date,
  modify_date
FROM
  sys.babelfish_partition_function
WHERE
  dbid = sys.db_id();
GRANT SELECT ON sys.partition_functions TO PUBLIC;

CREATE OR REPLACE VIEW sys.partition_range_values AS
SELECT
  function_id,
  CAST(1 as int) as parameter_id,
  CAST(t.boundary_id as int),
  t.value
FROM
  sys.babelfish_partition_function,
  unnest(range_values) WITH ORDINALITY as t(value, boundary_id)
where
  dbid = sys.db_id();
GRANT SELECT ON sys.partition_range_values TO PUBLIC;

CREATE OR REPLACE VIEW sys.partition_parameters AS
SELECT
  function_id,
  cast(1 as int) as parameter_id,
  st.system_type_id,
  st.max_length,
  st.precision,
  st.scale,
  st.collation_name,
  st.user_type_id
FROM
  sys.babelfish_partition_function pf
INNER JOIN
  sys.types st on (pf.input_parameter_type = st.name and st.user_type_id = st.system_type_id)
WHERE
  dbid = sys.db_id();
GRANT SELECT ON  sys.partition_parameters TO PUBLIC;

CREATE OR REPLACE VIEW sys.partition_schemes AS
SELECT
  partition_scheme_name as name,
  scheme_id as data_space_id,
  CAST('PS' as sys.bpchar(2)) as type,
  CAST('PARTITION_SCHEME' as sys.nvarchar(60)) as type_desc,
  CAST(0 as sys.bit) as is_default,
  CAST(0 as sys.bit) as is_system,
  pf.function_id
FROM
  sys.babelfish_partition_scheme ps
INNER JOIN
  sys.babelfish_partition_function pf ON (pf.partition_function_name = ps.partition_function_name and ps.dbid = pf.dbid)
WHERE
  ps.dbid = sys.db_id();
GRANT SELECT ON sys.partition_schemes TO PUBLIC;

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
		WHEN 'vector' THEN tds_id = 167; -- Same as varchar 
		WHEN 'sparsevec' THEN tds_id = 167; -- Same as varchar 
		WHEN 'halfvec' THEN tds_id = 167; -- Same as varchar 
		WHEN 'geometry' THEN tds_id = 240;
		WHEN 'geography' THEN tds_id = 240;
		ELSE tds_id = 0;
	END CASE;
	RETURN tds_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_max_length(type text, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT
	CASE WHEN type IN ('char', 'nchar', 'varchar', 'nvarchar', 'binary', 'varbinary')
		THEN CASE WHEN typmod = -1
			THEN -1
			ELSE typmod - 4
			END
		WHEN type IN ('text', 'image')
		THEN 2147483647
		WHEN type = 'ntext'
		THEN 1073741823
		WHEN type = 'sysname'
		THEN 128
		WHEN type IN ('xml', 'vector', 'halfvec', 'sparsevec', 'geometry', 'geography')
		THEN -1
		WHEN type = 'sql_variant'
		THEN 0
		ELSE null
	END$$;

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
		WHEN 'vector' THEN max_length = -1; -- dummy as varchar max
    WHEN 'halfvec' THEN max_length = -1; -- dummy as varchar max
    WHEN 'sparsevec' THEN max_length = -1; -- dummy as varchar max
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
		WHEN v_type in ('geometry', 'geography') THEN max_length = -1;
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

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
