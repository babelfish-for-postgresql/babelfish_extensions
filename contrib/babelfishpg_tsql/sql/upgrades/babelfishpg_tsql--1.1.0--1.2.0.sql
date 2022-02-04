-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '1.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.lock_timeout()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.lock_timeout');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.lock_timeout() TO PUBLIC;

CREATE OR REPLACE FUNCTION COLUMNS_UPDATED ()
	 	   RETURNS sys.VARBINARY AS 'babelfishpg_tsql', 'columnsupdated' LANGUAGE C;

CREATE OR REPLACE FUNCTION UPDATE (TEXT)
	 	   RETURNS BOOLEAN AS 'babelfishpg_tsql', 'updated' LANGUAGE C;

-- Added for BABEL-1544
CREATE OR REPLACE FUNCTION sys.len(expr sys.BBF_VARBINARY) RETURNS INTEGER AS
'babelfishpg_common', 'varbinary_length'
STRICT
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128),  IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
AS $$
DECLARE
  normalized_name varchar(256);
  default_value text;
  cnt int;
  cur refcursor;
  eh_name varchar(256);
  server boolean := false;
  prev_user text;
BEGIN
  IF lower("@option_name") like 'babelfishpg_tsql.%' THEN
    SELECT "@option_name" INTO normalized_name;
  ELSE
    SELECT concat('babelfishpg_tsql.',"@option_name") INTO normalized_name;
  END IF;

  IF lower("@option_scope") = 'server' THEN
    server := true;
  ELSIF btrim("@option_scope") != '' THEN
    RAISE EXCEPTION 'invalid option: %', "@option_scope";
  END IF;

  SELECT COUNT(*) INTO cnt FROM pg_catalog.pg_settings WHERE name like normalized_name and name like '%escape_hatch%';
  IF cnt = 0 THEN
    RAISE EXCEPTION 'unknown configuration: %', normalized_name;
  END IF;

  OPEN cur FOR SELECT name FROM pg_catalog.pg_settings WHERE name like normalized_name and name like '%escape_hatch%';

  LOOP
    FETCH NEXT FROM cur into eh_name;
    exit when not found;

    -- Each setting has a boot_val which is the wired-in default value
    -- Assuming that escape hatches cannot be modified using ALTER SYTEM/config file
    -- we are setting the boot_val as the default value for the escape hatches
    SELECT boot_val INTO default_value FROM pg_catalog.pg_settings WHERE name = eh_name;
    IF lower("@option_value") = 'default' THEN
        PERFORM pg_catalog.set_config(eh_name, default_value, 'false');
    ELSE
        PERFORM pg_catalog.set_config(eh_name, "@option_value", 'false');
    END IF;
    IF server THEN
      SELECT current_user INTO prev_user;
      PERFORM sys.babelfish_set_role(session_user);
      IF lower("@option_value") = 'default' THEN
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), eh_name, default_value);
      ELSE
        -- store the setting in PG master database so that it can be applied to all bbf databases
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), eh_name, "@option_value");
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

-- For getting host os from PG_VERSION_STR
CREATE OR REPLACE FUNCTION sys.get_host_os()
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'host_os' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE VIEW sys.dm_os_host_info AS
SELECT
  -- get_host_os() depends on a Postgres function created separately.
  cast( sys.get_host_os() as sys.nvarchar(256) ) as host_platform
  -- Hardcoded at the moment. Should likely be GUC with default '' (empty string).
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_distribution') as sys.nvarchar(256) ) as host_distribution
  -- documentation on one hand states this is empty string on linux, but otoh shows an example with "ubuntu 16.04"
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_release') as sys.nvarchar(256) ) as host_release
  -- empty string on linux.
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_service_pack_level') as sys.nvarchar(256) )
    as host_service_pack_level
  -- windows stock keeping unit. null on linux.
  , cast( null as int ) as host_sku
  -- lcid
  , cast( sys.collationproperty( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.server_collation_name') , 'lcid') as int )
    as "os_language_version";
GRANT SELECT ON sys.dm_os_host_info TO PUBLIC;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
