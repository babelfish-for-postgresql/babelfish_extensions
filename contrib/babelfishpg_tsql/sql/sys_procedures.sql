CREATE PROCEDURE sys.sp_unprepare(IN prep_handle INTEGER) 
AS 'babelfishpg_tsql', 'sp_unprepare'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_unprepare(IN INTEGER) TO PUBLIC;

CREATE PROCEDURE sys.sp_prepare(INOUT prep_handle INTEGER, IN params varchar(8000),
  		 						IN stmt varchar(8000), IN options int default 1)
AS 'babelfishpg_tsql', 'sp_prepare'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_prepare(
	INOUT INTEGER, IN varchar(8000), IN varchar(8000), IN int
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_getapplock_function (IN "@resource" varchar(255),
                                               IN "@lockmode" varchar(32),
                                               IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION',
                                               IN "@locktimeout" INTEGER DEFAULT -99,
                                               IN "@dbprincipal" varchar(32) DEFAULT 'dbo')
RETURNS INTEGER
AS 'babelfishpg_tsql', 'sp_getapplock_function' LANGUAGE C;
GRANT EXECUTE ON FUNCTION sys.sp_getapplock_function(
	IN varchar(255), IN varchar(32), IN varchar(32), IN INTEGER, IN varchar(32)
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_releaseapplock_function(IN "@resource" varchar(255),
                                                   IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION',
                                                   IN "@dbprincipal" varchar(32) DEFAULT 'dbo')
RETURNS INTEGER
AS 'babelfishpg_tsql', 'sp_releaseapplock_function' LANGUAGE C;
GRANT EXECUTE ON FUNCTION sys.sp_releaseapplock_function(
	IN varchar(255), IN varchar(32), IN varchar(32)
) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_cursor_list (INOUT "@cursor_return" refcursor,
                                                IN "@cursor_scope" INTEGER)
AS $$
DECLARE
  cur refcursor;
BEGIN
  IF "@cursor_scope" >= 1 AND "@cursor_scope" <= 3 THEN
    OPEN cur FOR EXECUTE 'SELECT reference_name::name, cursor_name::name, cursor_scope::smallint, status::smallint, model::smallint, concurrency::smallint, scrollable::smallint, open_status::smallint, cursor_rows::numeric(10,0), fetch_status::smallint, column_count::smallint, row_count::numeric(10,0), last_operation::smallint, cursor_handle::int FROM sys.babelfish_cursor_list($1)' USING "@cursor_scope";
  ELSE
    RAISE 'invalid @cursor_scope: %', "@cursor_scope";
  END IF;

  -- PG cursor evaluates the query at first fetch. We need to evaluate table function now because cursor_list() depeneds on "current" tsql_estate().
  -- Running MOVE fowrard and backward to force evaluating sys.babelfish_cursor_list() now.
  MOVE NEXT FROM cur;
  MOVE PRIOR FROM cur;
  SELECT cur INTO "@cursor_return";
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_cursor_list(INOUT refcursor, IN INTEGER) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_describe_cursor (INOUT "@cursor_return" refcursor,
                                                   IN "@cursor_source" nvarchar(30),
                                                   IN "@cursor_identity" nvarchar(30))
AS $$
DECLARE
  cur refcursor;
  cursor_source int;
BEGIN
  IF lower("@cursor_source") = 'local' THEN
    cursor_source := 1;
  ELSIF lower("@cursor_source") = 'global' THEN
    cursor_source := 2;
  ELSIF lower("@cursor_source") = 'variable' THEN
    cursor_source := 3;
  ELSE
    RAISE 'invalid @cursor_source: %', "@cursor_source";
  END IF;

  OPEN cur FOR EXECUTE 'SELECT reference_name::name, cursor_name::name, cursor_scope::smallint, status::smallint, model::smallint, concurrency::smallint, scrollable::smallint, open_status::smallint, cursor_rows::numeric(10,0), fetch_status::smallint, column_count::smallint, row_count::numeric(10,0), last_operation::smallint, cursor_handle::int FROM sys.babelfish_cursor_list($1) WHERE cursor_source = $1 and reference_name = $2' USING cursor_source, "@cursor_identity";

  -- PG cursor evaluates the query at first fetch. We need to evaluate table function now because cursor_list() depeneds on "current" tsql_estate().
  -- Running MOVE fowrard and backward to force evaluating sys.babelfish_cursor_list() now.
  MOVE NEXT FROM cur;
  MOVE PRIOR FROM cur;
  SELECT cur INTO "@cursor_return";
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_describe_cursor(
	INOUT refcursor, IN nvarchar(30), IN nvarchar(30)
) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure()
AS 'babelfishpg_tsql', 'sp_babelfish_configure'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure() TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128))
AS 'babelfishpg_tsql', 'sp_babelfish_configure'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(IN varchar(128)) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128),  IN "@option_value" varchar(128))
AS $$
BEGIN
  CALL sys.sp_babelfish_configure("@option_name", "@option_value", '');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(IN varchar(128), IN varchar(128)) TO PUBLIC;

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

CREATE OR REPLACE PROCEDURE sys.sp_execute_postgresql(IN "@postgresStmt" sys.nvarchar)
AS 'babelfishpg_tsql', 'sp_execute_postgresql' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_execute_postgresql(IN sys.nvarchar) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_addlinkedserver( IN "@server" sys.sysname,
                                                    IN "@srvproduct" sys.nvarchar(128) DEFAULT NULL,
                                                    IN "@provider" sys.nvarchar(128) DEFAULT 'SQLNCLI',
                                                    IN "@datasrc" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@location" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@provstr" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@catalog" sys.sysname DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_addlinkedserver_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_addlinkedserver(IN sys.sysname,
                                                  IN sys.nvarchar(128),
                                                  IN sys.nvarchar(128),
                                                  IN sys.nvarchar(4000),
                                                  IN sys.nvarchar(4000),
                                                  IN sys.nvarchar(4000),
                                                  IN sys.sysname)
TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_addlinkedsrvlogin( IN "@rmtsrvname" sys.sysname,
                                                      IN "@useself" sys.varchar(8) DEFAULT 'TRUE',
                                                      IN "@locallogin" sys.sysname DEFAULT NULL,
                                                      IN "@rmtuser" sys.sysname DEFAULT NULL,
                                                      IN "@rmtpassword" sys.sysname DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_addlinkedsrvlogin_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_addlinkedsrvlogin(IN sys.sysname,
                                                    IN sys.varchar(8),
                                                    IN sys.sysname,
                                                    IN sys.sysname,
                                                    IN sys.sysname)
TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_droplinkedsrvlogin( IN "@rmtsrvname" sys.sysname,
                                                      IN "@locallogin" sys.sysname)
AS 'babelfishpg_tsql', 'sp_droplinkedsrvlogin_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_droplinkedsrvlogin(IN sys.sysname,
                                                    IN sys.sysname)
TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_dropserver( IN "@server" sys.sysname,
                                                    IN "@droplogins" sys.bpchar(10) DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_dropserver_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_dropserver( IN "@server" sys.sysname,
                                                    IN "@droplogins" sys.bpchar(10))
TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_serveroption( IN "@server" sys.sysname,
                                                    IN "@optname" sys.varchar(35),
                                                    IN "@optvalue" sys.varchar(10))
AS 'babelfishpg_tsql', 'sp_serveroption_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_serveroption( IN "@server" sys.sysname,
                                                    IN "@optname" sys.varchar(35),
                                                    IN "@optvalue" sys.varchar(10))
TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_volatility(IN "@function_name" sys.varchar DEFAULT NULL, IN "@volatility" sys.varchar DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_babelfish_volatility' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_babelfish_volatility(IN sys.varchar, IN sys.varchar) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.bbf_set_context_info(IN context_info sys.VARBINARY(128))
AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE PROCEDURE sys.sp_testlinkedserver(IN "@servername" sys.sysname)
AS 'babelfishpg_tsql', 'sp_testlinkedserver_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_testlinkedserver(IN sys.sysname) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_addextendedproperty
(
  "@name" sys.sysname,
  "@value" sys.sql_variant = NULL,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_addextendedproperty TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_updateextendedproperty
(
  "@name" sys.sysname,
  "@value" sys.sql_variant = NULL,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_updateextendedproperty TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_dropextendedproperty
(
  "@name" sys.sysname,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_dropextendedproperty TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_enum_oledb_providers()
AS 'babelfishpg_tsql', 'sp_enum_oledb_providers_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_enum_oledb_providers() TO PUBLIC;
