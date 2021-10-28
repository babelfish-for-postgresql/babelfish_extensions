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

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128),  IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
AS $$
DECLARE
  normalized_name varchar(256);
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

    PERFORM pg_catalog.set_config(eh_name, "@option_value", 'false');
    IF server THEN
      SELECT current_user INTO prev_user;
      PERFORM sys.babelfish_set_role(session_user);
      -- store the setting in PG master database so that it can be applied to all bbf databases
      EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), eh_name, "@option_value");
      PERFORM sys.babelfish_set_role(prev_user);
    END IF;
  END LOOP;

  CLOSE cur;

END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(
	IN varchar(128), IN varchar(128), IN varchar(128)
) TO PUBLIC;
