CREATE FUNCTION pltsql_call_handler ()
	   RETURNS language_handler AS 'babelfishpg_tsql' LANGUAGE C;

CREATE FUNCTION pltsql_validator (oid)
	   RETURNS void AS 'babelfishpg_tsql' LANGUAGE C;

CREATE FUNCTION pltsql_inline_handler(internal)
	   RETURNS void AS 'babelfishpg_tsql' LANGUAGE C;

-- language
CREATE TRUSTED LANGUAGE pltsql
       HANDLER pltsql_call_handler
       INLINE pltsql_inline_handler
       VALIDATOR pltsql_validator;
GRANT USAGE ON LANGUAGE pltsql TO public;

COMMENT ON LANGUAGE pltsql IS 'PL/TSQL procedural language';

CREATE FUNCTION serverproperty (TEXT)
	   RETURNS  sys.SQL_VARIANT AS 'babelfishpg_tsql', 'serverproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION databasepropertyex (TEXT, TEXT)
	   RETURNS  sys.SQL_VARIANT AS 'babelfishpg_tsql', 'databasepropertyex' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION connectionproperty (TEXT)
		RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'connectionproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION collationproperty (TEXT, TEXT)
        RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'collationproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sessionproperty (TEXT)
	   RETURNS  sys.SQL_VARIANT AS 'babelfishpg_tsql', 'sessionproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION fulltextserviceproperty (TEXT)
	RETURNS sys.int AS 'babelfishpg_tsql', 'fulltextserviceproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION COLUMNS_UPDATED ()
	   RETURNS sys.VARBINARY AS 'babelfishpg_tsql', 'columnsupdated' LANGUAGE C;

CREATE OR REPLACE FUNCTION UPDATE (TEXT)
	   RETURNS BOOLEAN AS 'babelfishpg_tsql', 'updated' LANGUAGE C;

CREATE OR REPLACE PROCEDURE xp_qv(IN nvarchar(256), IN nvarchar(256))
	   AS 'babelfishpg_tsql', 'xp_qv_internal' LANGUAGE C;

CREATE PROCEDURE xp_instance_regread(IN p1 sys.nvarchar(512), 
	IN p2 sys.sysname, IN p3 sys.nvarchar(512), INOUT out_param int)
AS 'babelfishpg_tsql', 'xp_instance_regread_internal'
LANGUAGE C;

CREATE PROCEDURE xp_instance_regread(IN p1 sys.nvarchar(512), 
	IN p2 sys.sysname, IN p3 sys.nvarchar(512), INOUT out_param sys.nvarchar(512))
AS 'babelfishpg_tsql', 'xp_instance_regread_internal'
LANGUAGE C;

--
-- The procedures below requires return code as a RETURN statement which is
-- only possible in pltsql. Therefore, we create them here and call into the
-- corresponding internal functions.
CREATE OR REPLACE PROCEDURE sys.sp_getapplock(IN "@resource" varchar(255),
                                               IN "@lockmode" varchar(32),
                                               IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION',
                                               IN "@locktimeout" INTEGER DEFAULT -99,
                                               IN "@dbprincipal" varchar(32) DEFAULT 'dbo')
LANGUAGE 'pltsql'
AS $$
begin
	declare @ret int;
	select @ret = sp_getapplock_function(@resource, @lockmode, @lockowner, @locktimeout, @dbprincipal);
    return @ret;
end;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_releaseapplock(IN "@resource" varchar(255),
                                                   IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION',
                                                   IN "@dbprincipal" varchar(32) DEFAULT 'dbo')
LANGUAGE 'pltsql'
AS $$
begin
	declare @ret int;
	select @ret = sp_releaseapplock_function(@resource, @lockowner, @dbprincipal);
    return @ret;
end;
$$;

-- sys.sp_oledb_ro_usrname is needed for TDS v7.2
-- In tsql, sp_oledb_ro_usrname stored procedure returns the database read only status.
-- Return values: 
-- 1. RO status (VARCHAR(1)) - "N" or "Y", "N" for not read only, "Y" for read only 
-- 2. user_name (sysname or NVARCHAR(128)) - The current database user
CREATE OR REPLACE PROCEDURE sys.sp_oledb_ro_usrname()
LANGUAGE 'pltsql'
AS $$
BEGIN
  SELECT CAST((SELECT CASE WHEN pg_is_in_recovery() = 'f' THEN 'N' ELSE 'Y' END) AS VARCHAR(1)) RO, CAST(current_user as NVARCHAR(128));
END ;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_helpdb()
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
  FROM sys.babelfish_helpdb();

  RETURN 0;
END;
$$;

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
  FROM sys.babelfish_helpdb("@dbname");

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

-- BABEL-1643
CREATE TABLE sys.spt_datatype_info_table
(TYPE_NAME VARCHAR(20), DATA_TYPE INT, PRECISION BIGINT,
LITERAL_PREFIX VARCHAR(20), LITERAL_SUFFIX VARCHAR(20),
CREATE_PARAMS CHAR(20), NULLABLE INT, CASE_SENSITIVE INT,
SEARCHABLE INT, UNSIGNED_ATTRIBUTE INT, MONEY INT,
AUTO_INCREMENT INT, LOCAL_TYPE_NAME VARCHAR(20),
MINIMUM_SCALE INT, MAXIMUM_SCALE INT, SQL_DATA_TYPE INT,
SQL_DATETIME_SUB INT, NUM_PREC_RADIX INT, INTERVAL_PRECISION INT,
USERTYPE INT, LENGTH INT, SS_DATA_TYPE SYS.TINYINT, 
-- below column is added in order to join PG's information_schema.columns for sys.sp_columns_100_view
PG_TYPE_NAME VARCHAR(20)
);
GRANT SELECT ON sys.spt_datatype_info_table TO PUBLIC;

INSERT INTO sys.spt_datatype_info_table VALUES (N'datetimeoffset', -155, 34, N'''', N'''', N'scale               ', 1, 0, 3, NULL, 0, NULL, N'datetimeoffset', 0, 7, -155, 0, NULL, NULL, 0, 68, 0, 'datetimeoffset');
INSERT INTO sys.spt_datatype_info_table VALUES (N'time', -154, 16, N'''', N'''', N'scale               ', 1, 0, 3, NULL, 0, NULL, N'time', 0, 7, -154, 0, NULL, NULL, 0, 32, 0, 'time');
INSERT INTO sys.spt_datatype_info_table VALUES (N'xml', -152, 0, N'N''', N'''', NULL, 1, 1, 0, NULL, 0, NULL, N'xml', NULL, NULL, -152, NULL, NULL, NULL, 0, 2147483646, 0, N'xml');
INSERT INTO sys.spt_datatype_info_table VALUES (N'sql_variant', -150, 8000, NULL, NULL, NULL, 1, 0, 2, NULL, 0, NULL, N'sql_variant', 0, 0, -150, NULL, 10, NULL, 0, 8000, 39, 'sql_variant');
INSERT INTO sys.spt_datatype_info_table VALUES (N'uniqueidentifier', -11, 36, N'''', N'''', NULL, 1, 0, 2, NULL, 0, NULL, N'uniqueidentifier', NULL, NULL, -11, NULL, NULL, NULL, 0, 16, 37, 'uniqueidentifier');
INSERT INTO sys.spt_datatype_info_table VALUES (N'ntext', -10, 1073741823, N'N''', N'''', NULL, 1, 1, 1, NULL, 0, NULL, N'ntext', NULL, NULL, -10, NULL, NULL, NULL, 0, 2147483646, 35, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'nvarchar', -9, 4000, N'N''', N'''', N'max length          ', 1, 1, 3, NULL, 0, NULL, N'nvarchar', NULL, NULL, -9, NULL, NULL, NULL, 0, 2, 39, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'sysname', -9, 128, N'N''', N'''', NULL, 0, 1, 3, NULL, 0, NULL, N'sysname', NULL, NULL, -9, NULL, NULL, NULL, 18, 256, 39, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'nchar', -8, 4000, N'N''', N'''', N'length              ', 1, 1, 3, NULL, 0, NULL, N'nchar', NULL, NULL, -8, NULL, NULL, NULL, 0, 2, 39, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'bit', -7, 1, NULL, NULL, NULL, 1, 0, 2, NULL, 0, NULL, N'bit', 0, 0, -7, NULL, NULL, NULL, 16, 1, 50, 'bit');
INSERT INTO sys.spt_datatype_info_table VALUES (N'tinyint', -6, 3, NULL, NULL, NULL, 1, 0, 2, 1, 0, 0, N'tinyint', 0, 0, -6, NULL, 10, NULL, 5, 1, 38, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'tinyint identity', -6, 3, NULL, NULL, NULL, 0, 0, 2, 1, 0, 1, N'tinyint identity', 0, 0, -6, NULL, 10, NULL, 5, 1, 38, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'bigint', -5, 19, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'bigint', 0, 0, -5, NULL, 10, NULL, 0, 8, 108, 'int8');
INSERT INTO sys.spt_datatype_info_table VALUES (N'bigint identity', -5, 19, NULL, NULL, NULL, 0, 0, 2, 0, 0, 1, N'bigint identity', 0, 0, -5, NULL, 10, NULL, 0, 8, 108, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'image', -4, 2147483647, N'0x', NULL, NULL, 1, 0, 0, NULL, 0, NULL, N'image', NULL, NULL, -4, NULL, NULL, NULL, 20, 2147483647, 34, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'varbinary', -3, 8000, N'0x', NULL, N'max length          ', 1, 0, 2, NULL, 0, NULL, N'varbinary', NULL, NULL, -3, NULL, NULL, NULL, 4, 1, 37, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'binary', -2, 8000, N'0x', NULL, N'length              ', 1, 0, 2, NULL, 0, NULL, N'binary', NULL, NULL, -2, NULL, NULL, NULL, 3, 1, 37, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'timestamp', -2, 8, N'0x', NULL, NULL, 0, 0, 2, NULL, 0, NULL, N'timestamp', NULL, NULL, -2, NULL, NULL, NULL, 80, 8, 45, 'timestamp');
INSERT INTO sys.spt_datatype_info_table VALUES (N'text', -1, 2147483647, N'''', N'''', NULL, 1, 1, 1, NULL, 0, NULL, N'text', NULL, NULL, -1, NULL, NULL, NULL, 19, 2147483647, 35, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'char', 1, 8000, N'''', N'''', N'length              ', 1, 1, 3, NULL, 0, NULL, N'char', NULL, NULL, 1, NULL, NULL, NULL, 1, 1, 39, N'bpchar');
INSERT INTO sys.spt_datatype_info_table VALUES (N'numeric', 2, 38, NULL, NULL, N'precision,scale     ', 1, 0, 2, 0, 0, 0, N'numeric', 0, 38, 2, NULL, 10, NULL, 10, 20, 108, 'numeric');
INSERT INTO sys.spt_datatype_info_table VALUES (N'numeric() identity', 2, 38, NULL, NULL, N'precision           ', 0, 0, 2, 0, 0, 1, N'numeric() identity', 0, 0, 2, NULL, 10, NULL, 10, 20, 108, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'decimal', 3, 38, NULL, NULL, N'precision,scale     ', 1, 0, 2, 0, 0, 0, N'decimal', 0, 38, 3, NULL, 10, NULL, 24, 20, 106, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'money', 3, 19, N'$', NULL, NULL, 1, 0, 2, 0, 1, 0, N'money', 4, 4, 3, NULL, 10, NULL, 11, 21, 110, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'smallmoney', 3, 10, N'$', NULL, NULL, 1, 0, 2, 0, 1, 0, N'smallmoney', 4, 4, 3, NULL, 10, NULL, 21, 12, 110, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'decimal() identity', 3, 38, NULL, NULL, N'precision           ', 0, 0, 2, 0, 0, 1, N'decimal() identity', 0, 0, 3, NULL, 10, NULL, 24, 20, 106, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'int', 4, 10, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'int', 0, 0, 4, NULL, 10, NULL, 7, 4, 38, N'int4');
INSERT INTO sys.spt_datatype_info_table VALUES (N'int identity', 4, 10, NULL, NULL, NULL, 0, 0, 2, 0, 0, 1, N'int identity', 0, 0, 4, NULL, 10, NULL, 7, 4, 38, N'');
INSERT INTO sys.spt_datatype_info_table VALUES (N'smallint', 5, 5, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'smallint', 0, 0, 5, NULL, 10, NULL, 6, 2, 38, 'int2');
INSERT INTO sys.spt_datatype_info_table VALUES (N'smallint identity', 5, 5, NULL, NULL, NULL, 0, 0, 2, 0, 0, 1, N'smallint identity', 0, 0, 5, NULL, 10, NULL, 6, 2, 38, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'float', 6, 53, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'float', NULL, NULL, 6, NULL, 2, NULL, 8, 8, 109, 'float8');
INSERT INTO sys.spt_datatype_info_table VALUES (N'real', 7, 24, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'real', NULL, NULL, 7, NULL, 2, NULL, 23, 4, 109, 'float4');
INSERT INTO sys.spt_datatype_info_table VALUES (N'varchar', 12, 8000, N'''', N'''', N'max length          ', 1, 1, 3, NULL, 0, NULL, N'varchar', NULL, NULL, 12, NULL, NULL, NULL, 2, 1, 39, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'date', 91, 10, N'''', N'''', NULL, 1, 0, 3, NULL, 0, NULL, N'date', NULL, 0, 9, 1, NULL, NULL, 0, 20, 0, 'date');
INSERT INTO sys.spt_datatype_info_table VALUES (N'datetime2', 93, 27, N'''', N'''', N'scale               ', 1, 0, 3, NULL, 0, NULL, N'datetime2', 0, 7, 9, 3, NULL, NULL, 0, 54, 0, 'datetime2');
INSERT INTO sys.spt_datatype_info_table VALUES (N'datetime', 93, 23, N'''', N'''', NULL, 1, 0, 3, NULL, 0, NULL, N'datetime', 3, 3, 9, 3, NULL, NULL, 12, 16, 111, 'datetime');
INSERT INTO sys.spt_datatype_info_table VALUES (N'smalldatetime', 93, 16, N'''', N'''', NULL, 1, 0, 3, NULL, 0, NULL, N'smalldatetime', 0, 0, 9, 3, NULL, NULL, 22, 16, 111, 'smalldatetime');

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
               CREATE_PARAMS::CHAR(20), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, false) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info_100 (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
               CREATE_PARAMS::CHAR(20), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, true) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE FUNCTION sys.tsql_type_radix_for_sp_columns_helper(IN type TEXT)
RETURNS SMALLINT
AS $$
DECLARE
  radix SMALLINT;
BEGIN
  CASE type
    WHEN 'tinyint' THEN radix = 10;
    WHEN 'money' THEN radix = 10;
    WHEN 'smallmoney' THEN radix = 10;
    WHEN 'sql_variant' THEN radix = 10;
  ELSE
    radix = NULL;
  END CASE;
  RETURN radix;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_type_length_for_sp_columns_helper(IN type TEXT, IN typelen INT, IN typemod INT)
RETURNS INT
AS $$
DECLARE
  length INT;
  precision INT;
BEGIN
  -- unknown tsql type
  IF type IS NULL THEN
    RETURN typelen::INT;
  END IF;

  IF typemod = -1 AND (type = 'varchar' OR type = 'nvarchar' OR type = 'varbinary') THEN
    length = 0;
    RETURN length;
  END IF;

  IF typelen != -1 THEN
    CASE type
    WHEN 'tinyint' THEN length = 1;
    WHEN 'date' THEN length = 6;
    WHEN 'smalldatetime' THEN length = 16;
    WHEN 'smallmoney' THEN length = 12;
    WHEN 'money' THEN length = 21;
    WHEN 'datetime' THEN length = 16;
    WHEN 'datetime2' THEN length = 16;
    WHEN 'datetimeoffset' THEN length = 20;
    WHEN 'time' THEN length = 12;
    WHEN 'timestamp' THEN length = 8;
    ELSE length = typelen;
    END CASE;
    RETURN length;
  END IF;

  CASE
  WHEN type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary') THEN length = typemod - 4;
  WHEN type in ('nchar', 'nvarchar') THEN length = (typemod - 4) * 2;
  WHEN type in ('text', 'image') THEN length = 2147483647;
  WHEN type = 'ntext' THEN length = 2147483646;
  WHEN type = 'xml' THEN length = 0;
  WHEN type = 'sql_variant' THEN length = 8000;
  WHEN type = 'money' THEN length = 21;
  WHEN type = 'sysname' THEN length = (typemod - 4) * 2;
  WHEN type in ('numeric', 'decimal') THEN
    precision = ((typemod - 4) >> 16) & 65535;
    length = precision + 2;
  ELSE
    length = typemod;
  END CASE;
  RETURN length;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- BABEL-1784: support for sp_columns/sp_columns_100
CREATE OR REPLACE VIEW sys.sp_columns_100_view AS
  SELECT 
  CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
  CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
  CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
  CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
  CAST(t5.data_type AS smallint) AS DATA_TYPE,
  CAST(coalesce(tsql_type_name, t.typname) AS sys.sysname) AS TYPE_NAME,

  CASE WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", a.atttypmod)) AS INT)
    WHEN tsql_type_name = 'timestamp'
    THEN 8
    ELSE
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", t.typtypmod)) AS INT)
  END AS PRECISION,

  CASE WHEN a.atttypmod != -1
    THEN
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, a.atttypmod) AS int)
    ELSE
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, t.typtypmod) AS int)
  END AS LENGTH,


  CASE WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", a.atttypmod, true)) AS smallint)
    ELSE
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", t.typtypmod, true)) AS smallint)
  END AS SCALE,


  CAST(coalesce(t4."NUMERIC_PRECISION_RADIX", sys.tsql_type_radix_for_sp_columns_helper(t4."DATA_TYPE")) AS smallint) AS RADIX,
  case
    when t4."IS_NULLABLE" = 'YES' then CAST(1 AS smallint)
    else CAST(0 AS smallint)
  end AS NULLABLE,

  CAST(NULL AS varchar(254)) AS remarks,
  CAST(t4."COLUMN_DEFAULT" AS sys.nvarchar(4000)) AS COLUMN_DEF,
  CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
  CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,

  CASE WHEN t4."DATA_TYPE" = 'xml' THEN 0::INT
    WHEN t4."DATA_TYPE" = 'sql_variant' THEN 8000::INT
    WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    ELSE CAST(t4."CHARACTER_OCTET_LENGTH" AS int)
  END AS CHAR_OCTET_LENGTH,

  CAST(t4."ORDINAL_POSITION" AS int) AS ORDINAL_POSITION,
  CAST(t4."IS_NULLABLE" AS varchar(254)) AS IS_NULLABLE,
  CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
  CAST(0 AS smallint) AS SS_IS_SPARSE,
  CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
  CAST(t6.is_computed as smallint) AS SS_IS_COMPUTED,
  CAST(t6.is_identity as smallint) AS SS_IS_IDENTITY,
  CAST(NULL AS varchar(254)) SS_UDT_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_ASSEMBLY_TYPE_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_NAME

  FROM pg_catalog.pg_class t1
     JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
     JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
     LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
     JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" AND ext.orig_name = t4."TABLE_SCHEMA")
     LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname = t4."COLUMN_NAME"
     LEFT JOIN pg_type t ON t.oid = a.atttypid
     LEFT JOIN sys.columns t6 ON
     (
      t1.oid = t6.object_id AND
      t4."ORDINAL_POSITION" = t6.column_id
     )
     , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
     , sys.spt_datatype_info_table AS t5
  WHERE (t4."DATA_TYPE" = t5.TYPE_NAME)
    AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

-- internal function in order to workaround BABEL-1597 for BABEL-1784
drop function if exists sys.sp_columns_100_internal(
	in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384),
    in_table_qualifier sys.nvarchar(384),
    in_column_name sys.nvarchar(384),
	in_NameScope int,
    in_ODBCVer int,
    in_fusepattern smallint);
create function sys.sp_columns_100_internal(
	in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384) = '', 
    in_table_qualifier sys.nvarchar(384) = '',
    in_column_name sys.nvarchar(384) = '',
	in_NameScope int = 0,
    in_ODBCVer int = 2,
    in_fusepattern smallint = 1)
returns table (
	out_table_qualifier sys.sysname,
	out_table_owner sys.sysname,
	out_table_name sys.sysname,
	out_column_name sys.sysname,
	out_data_type smallint,
	out_type_name sys.sysname,
	out_precision int,
	out_length int,
	out_scale smallint,
	out_radix smallint,
	out_nullable smallint,
	out_remarks varchar(254),
	out_column_def sys.nvarchar(4000),
	out_sql_data_type smallint,
	out_sql_datetime_sub smallint,
	out_char_octet_length int,
	out_ordinal_position int,
	out_is_nullable varchar(254),
	out_ss_is_sparse smallint,
	out_ss_is_column_set smallint,
	out_ss_is_computed smallint,
	out_ss_is_identity smallint,
	out_ss_udt_catalog_name varchar(254),
	out_ss_udt_schema_name varchar(254),
	out_ss_udt_assembly_type_name varchar(254),
	out_ss_xml_schemacollection_catalog_name varchar(254),
	out_ss_xml_schemacollection_schema_name varchar(254),
	out_ss_xml_schemacollection_name varchar(254),
	out_ss_data_type sys.tinyint
)
as $$
begin
	IF in_fusepattern = 1 THEN
		return query
	    select table_qualifier, 
				table_owner,
				table_name,
				column_name,
				data_type,
				type_name,
				precision,
				length,
				scale,
				radix,
				nullable,
				remarks,
				column_def,
				sql_data_type,
				sql_datetime_sub,
				char_octet_length,
				ordinal_position,
				is_nullable,
				ss_is_sparse,
				ss_is_column_set,
				ss_is_computed,
				ss_is_identity,
				ss_udt_catalog_name,
				ss_udt_schema_name,
				ss_udt_assembly_type_name,
				ss_xml_schemacollection_catalog_name,
				ss_xml_schemacollection_schema_name,
				ss_xml_schemacollection_name,
				ss_data_type
		from sys.sp_columns_100_view
	    where lower(table_name) similar to lower(in_table_name) COLLATE "C" -- TBD - this should be changed to ci_as
	      and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner like in_table_owner collate sys.bbf_unicode_general_ci_as)
	      and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier like in_table_qualifier collate sys.bbf_unicode_general_ci_as)
	      and ((SELECT coalesce(in_column_name,'')) = '' or column_name like in_column_name collate sys.bbf_unicode_general_ci_as)
		order by table_qualifier,
		         table_owner,
			 table_name,
			 ordinal_position;
	ELSE 
		return query
	    select table_qualifier, precision from sys.sp_columns_100_view
	      where in_table_name = table_name collate sys.bbf_unicode_general_ci_as
	      and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner collate sys.bbf_unicode_general_ci_as)
	      and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier collate sys.bbf_unicode_general_ci_as)
	      and ((SELECT coalesce(in_column_name,'')) = '' or column_name = in_column_name collate sys.bbf_unicode_general_ci_as)
		order by table_qualifier,
		         table_owner,
			 table_name,
			 ordinal_position;
	END IF;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_columns (
	"@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
	"@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
	select out_table_qualifier as TABLE_QUALIFIER, 
			out_table_owner as TABLE_OWNER,
			out_table_name as TABLE_NAME,
			out_column_name as COLUMN_NAME,
			out_data_type as DATA_TYPE,
			out_type_name as TYPE_NAME,
			out_precision as PRECISION,
			out_length as LENGTH,
			out_scale as SCALE,
			out_radix as RADIX,
			out_nullable as NULLABLE,
			out_remarks as REMARKS,
			out_column_def as COLUMN_DEF,
			out_sql_data_type as SQL_DATA_TYPE,
			out_sql_datetime_sub as SQL_DATETIME_SUB,
			out_char_octet_length as CHAR_OCTET_LENGTH,
			out_ordinal_position as ORDINAL_POSITION,
			out_is_nullable as IS_NULLABLE,
			(
			CASE
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = -6 THEN 48 -- Tinyint Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = 5 THEN 52 -- Smallint Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = 4 THEN 56 -- Int Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = -5 THEN 63 -- Bigint Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = 3 THEN 55 -- Decimal Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = 2 THEN 63 -- Numeric Identity
				ELSE out_ss_data_type
			END
			) as SS_DATA_TYPE
	from sys.sp_columns_100_internal(sys.babelfish_truncate_identifier(@table_name),
		sys.babelfish_truncate_identifier(@table_owner),
		sys.babelfish_truncate_identifier(@table_qualifier),
		sys.babelfish_truncate_identifier(@column_name), @NameScope, @ODBCVer, @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_columns_100 (
	"@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
	"@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
	select out_table_qualifier as TABLE_QUALIFIER, 
			out_table_owner as TABLE_OWNER,
			out_table_name as TABLE_NAME,
			out_column_name as COLUMN_NAME,
			out_data_type as DATA_TYPE,
			out_type_name as TYPE_NAME,
			out_precision as PRECISION,
			out_length as LENGTH,
			out_scale as SCALE,
			out_radix as RADIX,
			out_nullable as NULLABLE,
			out_remarks as REMARKS,
			out_column_def as COLUMN_DEF,
			out_sql_data_type as SQL_DATA_TYPE,
			out_sql_datetime_sub as SQL_DATETIME_SUB,
			out_char_octet_length as CHAR_OCTET_LENGTH,
			out_ordinal_position as ORDINAL_POSITION,
			out_is_nullable as IS_NULLABLE,
			out_ss_is_sparse as SS_IS_SPARSE,
			out_ss_is_column_set as SS_IS_COLUMN_SET,
			out_ss_is_computed as SS_IS_COMPUTED,
			out_ss_is_identity as SS_IS_IDENTITY,
			out_ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
			out_ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
			out_ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
			out_ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
			out_ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
			out_ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
			(
			CASE
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = -6 THEN 48 -- Tinyint Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = 5 THEN 52 -- Smallint Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = 4 THEN 56 -- Int Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = -5 THEN 63 -- Bigint Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = 3 THEN 55 -- Decimal Identity
				WHEN out_ss_is_identity = 1 AND out_sql_data_type = 2 THEN 63 -- Numeric Identity
				ELSE out_ss_data_type
			END
			) as SS_DATA_TYPE
	from sys.sp_columns_100_internal(sys.babelfish_truncate_identifier(@table_name),
		sys.babelfish_truncate_identifier(@table_owner),
		sys.babelfish_truncate_identifier(@table_qualifier),
		sys.babelfish_truncate_identifier(@column_name), @NameScope, @ODBCVer, @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_100 TO PUBLIC;

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
		ELSE tds_id = 0;
	END CASE;
	RETURN tds_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

create or replace function sys.sp_describe_first_result_set_internal(
	tsqlquery varchar(384),
    params varchar(384) = NULL, 
    browseMode sys.tinyint = 0
)
returns table (
	is_hidden sys.bit,
	column_ordinal int,
	name sys.sysname,
	is_nullable sys.bit,
	system_type_id int,
	system_type_name sys.nvarchar(256),
	max_length smallint,
	"precision" sys.tinyint,
	scale sys.tinyint,
	collation_name sys.sysname,
	user_type_id int,
	user_type_database sys.sysname,
	user_type_schema sys.sysname,
	user_type_name sys.sysname,
	assembly_qualified_type_name sys.nvarchar(4000),
	xml_collection_id int,
	xml_collection_database sys.sysname,
	xml_collection_schema sys.sysname,
	xml_collection_name sys.sysname,
	is_xml_document sys.bit,
	is_case_sensitive sys.bit,
	is_fixed_length_clr_type sys.bit,
	source_server sys.sysname,
	source_database sys.sysname,
	source_schema sys.sysname,
	source_table sys.sysname,
	source_column sys.sysname,
	is_identity_column sys.bit,
	is_part_of_unique_key sys.bit,
	is_updateable sys.bit,
	is_computed_column sys.bit,
	is_sparse_column_set sys.bit,
	ordinal_in_order_by_list smallint,
	order_by_list_length smallint,
	order_by_is_descending smallint,
	tds_type_id int,
	tds_length int,
	tds_collation_id int,
	ss_data_type sys.tinyint
)
AS 'babelfishpg_tsql', 'sp_describe_first_result_set_internal'
LANGUAGE C;
GRANT ALL on FUNCTION sys.sp_describe_first_result_set_internal TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_describe_first_result_set (
	"@tsql" varchar(384),
    "@params" varchar(384) = NULL, 
    "@browse_information_mode" sys.tinyint = 0)
AS $$
BEGIN
	select * from sys.sp_describe_first_result_set_internal(@tsql, @params,  @browse_information_mode);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_first_result_set TO PUBLIC;

CREATE OR REPLACE VIEW sys.spt_tablecollations_view AS
    SELECT
        o.object_id         AS object_id,
        o.schema_id         AS schema_id,
        c.column_id         AS colid,
        CASE WHEN p.attoptions[1] LIKE 'bbf_original_name=%' THEN split_part(p.attoptions[1], '=', 2)
            ELSE c.name END AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c INNER JOIN
        sys.all_objects o ON (c.object_id = o.object_id) JOIN
        pg_attribute p ON (c.name = p.attname AND c.object_id = p.attrelid)
    WHERE
        c.is_sparse = 0 AND p.attnum >= 0;
GRANT SELECT ON sys.spt_tablecollations_view TO PUBLIC;

-- We are limited by what postgres procedures can return here, but IEW may not
-- need it for initial compatibility
CREATE OR REPLACE PROCEDURE sys.sp_tablecollations_100
(
    IN "@object" nvarchar(4000)
)
AS $$
BEGIN
    select
        s_tcv.colid         AS colid,
        s_tcv.name          AS name,
        s_tcv.tds_collation_100 AS tds_collation,
        s_tcv.collation_100 AS collation
    from
        sys.spt_tablecollations_view s_tcv
    where
        s_tcv.object_id = sys.object_id(@object)
    order by colid;
END;
$$
LANGUAGE 'pltsql';

-- TODO: Remove information_schema references
CREATE OR REPLACE VIEW sys.spt_columns_view_managed AS
SELECT
    o.object_id                     AS OBJECT_ID,
    isc."TABLE_CATALOG"::information_schema.sql_identifier               AS TABLE_CATALOG,
    isc."TABLE_SCHEMA"::information_schema.sql_identifier                AS TABLE_SCHEMA,
    o.name                          AS TABLE_NAME,
    c.name                          AS COLUMN_NAME,
    isc."ORDINAL_POSITION"::information_schema.cardinal_number           AS ORDINAL_POSITION,
    isc."COLUMN_DEFAULT"::information_schema.character_data              AS COLUMN_DEFAULT,
    isc."IS_NULLABLE"::information_schema.yes_or_no                      AS IS_NULLABLE,
    isc."DATA_TYPE"::information_schema.character_data                   AS DATA_TYPE,

    CAST (CASE WHEN isc."CHARACTER_MAXIMUM_LENGTH" < 0 THEN 0 ELSE isc."CHARACTER_MAXIMUM_LENGTH" END
		AS information_schema.cardinal_number) AS CHARACTER_MAXIMUM_LENGTH,

    CAST (CASE WHEN isc."CHARACTER_OCTET_LENGTH" < 0 THEN 0 ELSE isc."CHARACTER_OCTET_LENGTH" END
		AS information_schema.cardinal_number)      AS CHARACTER_OCTET_LENGTH,

    CAST (CASE WHEN isc."NUMERIC_PRECISION" < 0 THEN 0 ELSE isc."NUMERIC_PRECISION" END
		AS information_schema.cardinal_number)      AS NUMERIC_PRECISION,

    CAST (CASE WHEN isc."NUMERIC_PRECISION_RADIX" < 0 THEN 0 ELSE isc."NUMERIC_PRECISION_RADIX" END
		AS information_schema.cardinal_number)      AS NUMERIC_PRECISION_RADIX,

    CAST (CASE WHEN isc."NUMERIC_SCALE" < 0 THEN 0 ELSE isc."NUMERIC_SCALE" END
		AS information_schema.cardinal_number)      AS NUMERIC_SCALE,

    CAST (CASE WHEN isc."DATETIME_PRECISION" < 0 THEN 0 ELSE isc."DATETIME_PRECISION" END
		AS information_schema.cardinal_number)      AS DATETIME_PRECISION,

    isc."CHARACTER_SET_CATALOG"::information_schema.sql_identifier       AS CHARACTER_SET_CATALOG,
    isc."CHARACTER_SET_SCHEMA"::information_schema.sql_identifier        AS CHARACTER_SET_SCHEMA,
    isc."CHARACTER_SET_NAME"::information_schema.sql_identifier          AS CHARACTER_SET_NAME,
    isc."COLLATION_CATALOG"::information_schema.sql_identifier           AS COLLATION_CATALOG,
    isc."COLLATION_SCHEMA"::information_schema.sql_identifier            AS COLLATION_SCHEMA,
    c.collation_name                                                     AS COLLATION_NAME,
    isc."DOMAIN_CATALOG"::information_schema.sql_identifier              AS DOMAIN_CATALOG,
    isc."DOMAIN_SCHEMA"::information_schema.sql_identifier               AS DOMAIN_SCHEMA,
    isc."DOMAIN_NAME"::information_schema.sql_identifier                 AS DOMAIN_NAME,
    c.is_sparse                     AS IS_SPARSE,
    c.is_column_set                 AS IS_COLUMN_SET,
    c.is_filestream                 AS IS_FILESTREAM
FROM
    sys.objects o JOIN sys.columns c ON
        (
            c.object_id = o.object_id and
            o.type in ('U', 'V')  -- limit columns to tables and views
        )
    LEFT JOIN information_schema_tsql.columns isc ON
        (
            sys.schema_name(o.schema_id) = isc."TABLE_SCHEMA" and
            o.name = isc."TABLE_NAME" and
            c.name = isc."COLUMN_NAME"
        )
    WHERE CAST("COLUMN_NAME" AS sys.nvarchar(128)) NOT IN ('cmin', 'cmax', 'xmin', 'xmax', 'ctid', 'tableoid');
GRANT SELECT ON sys.spt_columns_view_managed TO PUBLIC;

CREATE FUNCTION sys.sp_columns_managed_internal(
    in_catalog sys.nvarchar(128), 
    in_owner sys.nvarchar(128),
    in_table sys.nvarchar(128),
    in_column sys.nvarchar(128),
    in_schematype int)
RETURNS TABLE (
    out_table_catalog sys.nvarchar(128),
    out_table_schema sys.nvarchar(128),
    out_table_name sys.nvarchar(128),
    out_column_name sys.nvarchar(128),
    out_ordinal_position int,
    out_column_default sys.nvarchar(4000),
    out_is_nullable sys.nvarchar(3),
    out_data_type sys.nvarchar,
    out_character_maximum_length int,
    out_character_octet_length int,
    out_numeric_precision int,
    out_numeric_precision_radix int,
    out_numeric_scale int,
    out_datetime_precision int,
    out_character_set_catalog sys.nvarchar(128),
    out_character_set_schema sys.nvarchar(128),
    out_character_set_name sys.nvarchar(128),
    out_collation_catalog sys.nvarchar(128),
    out_is_sparse int,
    out_is_column_set int,
    out_is_filestream int
    )
AS
$$
BEGIN
    RETURN QUERY 
        SELECT CAST(table_catalog AS sys.nvarchar(128)),
            CAST(table_schema AS sys.nvarchar(128)),
            CAST(table_name AS sys.nvarchar(128)),
            CAST(column_name AS sys.nvarchar(128)),
            CAST(ordinal_position AS int),
            CAST(column_default AS sys.nvarchar(4000)),
            CAST(is_nullable AS sys.nvarchar(3)),
            CAST(data_type AS sys.nvarchar),
            CAST(character_maximum_length AS int),
            CAST(character_octet_length AS int),
            CAST(numeric_precision AS int),
            CAST(numeric_precision_radix AS int),
            CAST(numeric_scale AS int),
            CAST(datetime_precision AS int),
            CAST(character_set_catalog AS sys.nvarchar(128)),
            CAST(character_set_schema AS sys.nvarchar(128)),
            CAST(character_set_name AS sys.nvarchar(128)),
            CAST(collation_catalog AS sys.nvarchar(128)),
            CAST(is_sparse AS int),
            CAST(is_column_set AS int),
            CAST(is_filestream AS int)
        FROM sys.spt_columns_view_managed s_cv
        WHERE
        (in_catalog IS NULL OR s_cv.TABLE_CATALOG LIKE LOWER(in_catalog)) AND
        (in_owner IS NULL OR s_cv.TABLE_SCHEMA LIKE LOWER(in_owner)) AND
        (in_table IS NULL OR s_cv.TABLE_NAME LIKE LOWER(in_table)) AND
        (in_column IS NULL OR s_cv.COLUMN_NAME LIKE LOWER(in_column)) AND
        (in_schematype = 0 AND (s_cv.IS_SPARSE = 0) OR in_schematype = 1 OR in_schematype = 2 AND (s_cv.IS_SPARSE = 1));
END;
$$
language plpgsql;

CREATE PROCEDURE sys.sp_columns_managed
(
    "@Catalog"          nvarchar(128) = NULL,
    "@Owner"            nvarchar(128) = NULL,
    "@Table"            nvarchar(128) = NULL,
    "@Column"           nvarchar(128) = NULL,
    "@SchemaType"       nvarchar(128) = 0)        --  0 = 'select *' behavior (default), 1 = all columns, 2 = columnset columns
AS
$$
BEGIN
    SELECT
        out_TABLE_CATALOG AS TABLE_CATALOG,
        out_TABLE_SCHEMA AS TABLE_SCHEMA,
        out_TABLE_NAME AS TABLE_NAME,
        out_COLUMN_NAME AS COLUMN_NAME,
        out_ORDINAL_POSITION AS ORDINAL_POSITION,
        out_COLUMN_DEFAULT AS COLUMN_DEFAULT,
        out_IS_NULLABLE AS IS_NULLABLE,
        out_DATA_TYPE AS DATA_TYPE,
        out_CHARACTER_MAXIMUM_LENGTH AS CHARACTER_MAXIMUM_LENGTH,
        out_CHARACTER_OCTET_LENGTH AS CHARACTER_OCTET_LENGTH,
        out_NUMERIC_PRECISION AS NUMERIC_PRECISION,
        out_NUMERIC_PRECISION_RADIX AS NUMERIC_PRECISION_RADIX,
        out_NUMERIC_SCALE AS NUMERIC_SCALE,
        out_DATETIME_PRECISION AS DATETIME_PRECISION,
        out_CHARACTER_SET_CATALOG AS CHARACTER_SET_CATALOG,
        out_CHARACTER_SET_SCHEMA AS CHARACTER_SET_SCHEMA,
        out_CHARACTER_SET_NAME AS CHARACTER_SET_NAME,
        out_COLLATION_CATALOG AS COLLATION_CATALOG,
        out_IS_SPARSE AS IS_SPARSE,
        out_IS_COLUMN_SET AS IS_COLUMN_SET,
        out_IS_FILESTREAM AS IS_FILESTREAM
    FROM
        sys.sp_columns_managed_internal(@Catalog, @Owner, @Table, @Column, @SchemaType) s_cv
    ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, IS_NULLABLE;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_managed TO PUBLIC;

-- BABEL-1797: initial support of sp_describe_undeclared_parameters
-- sys.sp_describe_undeclared_parameters_internal: internal function
-- For the result rows, can we create a template table for it?
create function sys.sp_describe_undeclared_parameters_internal(
	tsqlquery sys.nvarchar(4000),
    params sys.nvarchar(4000) = NULL
)
returns table (
	parameter_ordinal 							int, -- NOT NULL
	name 										sys.sysname, -- NOT NULL
	suggested_system_type_id 					int, -- NOT NULL
	suggested_system_type_name 					sys.nvarchar(256),
	suggested_max_length 						smallint, -- NOT NULL
	suggested_precision 						sys.tinyint, -- NOT NULL
	suggested_scale 							sys.tinyint, -- NOT NULL
	suggested_user_type_id 						int, -- NOT NULL
	suggested_user_type_database 				sys.sysname,
	suggested_user_type_schema 					sys.sysname,
	suggested_user_type_name 					sys.sysname,
	suggested_assembly_qualified_type_name 		sys.nvarchar(4000),
	suggested_xml_collection_id 				int,
	suggested_xml_collection_database 			sys.sysname,
	suggested_xml_collection_schema 			sys.sysname,
	suggested_xml_collection_name 				sys.sysname,
	suggested_is_xml_document 					sys.bit, -- NOT NULL
	suggested_is_case_sensitive 				sys.bit, -- NOT NULL
	suggested_is_fixed_length_clr_type 			sys.bit, -- NOT NULL
	suggested_is_input 							sys.bit, -- NOT NULL
	suggested_is_output 						sys.bit, -- NOT NULL
	formal_parameter_name 						sys.sysname,
	suggested_tds_type_id 						int, -- NOT NULL
	suggested_tds_length 						int -- NOT NULL
)
AS 'babelfishpg_tsql', 'sp_describe_undeclared_parameters_internal'
LANGUAGE C;
GRANT ALL on FUNCTION sys.sp_describe_undeclared_parameters_internal TO PUBLIC;

CREATE PROCEDURE sys.sp_describe_undeclared_parameters (
	"@tsql" sys.nvarchar(4000),
    "@params" sys.nvarchar(4000) = NULL)
AS $$
BEGIN
	select * from sys.sp_describe_undeclared_parameters_internal(@tsql, @params);
	return 1;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_undeclared_parameters TO PUBLIC;

-- BABEL-1782
CREATE OR REPLACE VIEW sys.sp_tables_view AS
SELECT
t2.dbname AS TABLE_QUALIFIER,
CAST(t3.name AS name) AS TABLE_OWNER,
t1.relname AS TABLE_NAME,

CASE 
WHEN t1.relkind = 'v' 
	THEN 'VIEW'
ELSE 'TABLE'
END AS TABLE_TYPE,

CAST(NULL AS varchar(254)) AS remarks
FROM pg_catalog.pg_class AS t1, sys.pg_namespace_ext AS t2, sys.schemas AS t3
WHERE t1.relnamespace = t3.schema_id AND t1.relnamespace = t2.oid AND t1.relkind IN ('r','v','m') 
AND has_schema_privilege(t1.relnamespace, 'USAGE')
AND has_table_privilege(t1.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.sp_tables_view TO PUBLIC;

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
	   
		IF (SELECT count(*) FROM unnest(string_to_array(cs_as_in_table_type, ',')) WHERE upper(trim(unnest)) = 'TABLE' OR upper(trim(unnest)) = '''TABLE''') >= 1 THEN
			opt_table = 'TABLE';
		END IF;
		IF (SELECT count(*) from unnest(string_to_array(cs_as_in_table_type, ',')) WHERE upper(trim(unnest)) = 'VIEW' OR upper(trim(unnest)) = '''VIEW''') >= 1 THEN
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
	 

CREATE OR REPLACE PROCEDURE sys.sp_tables (
    "@table_name" sys.nvarchar(384) = '',
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.sysname = '',
    "@table_type" sys.nvarchar(100) = '',
    "@fusepattern" sys.bit = '1')
AS $$
	DECLARE @opt_table sys.varchar(16) = '';
	DECLARE @opt_view sys.varchar(16) = ''; 
BEGIN
	IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	SELECT
	CAST(out_table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
	CAST(out_table_owner AS sys.sysname) AS TABLE_OWNER,
	CAST(out_table_name AS sys.sysname) AS TABLE_NAME,
	CAST(out_table_type AS sys.varchar(32)) AS TABLE_TYPE,
	CAST(out_remarks AS sys.varchar(254)) AS REMARKS
	FROM sys.sp_tables_internal(@table_name, @table_owner, @table_qualifier, CAST(@table_type AS varchar(100)), @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_tables TO PUBLIC;

CREATE FUNCTION sys.fn_mapped_system_error_list ()
returns table (sql_error_code int)
AS 'babelfishpg_tsql', 'babel_list_mapped_error'
LANGUAGE C IMMUTABLE STRICT;
GRANT ALL on FUNCTION sys.fn_mapped_system_error_list TO PUBLIC;

-- BABEL-2259: Support sp_databases System Stored Procedure
-- Lists databases that either reside in an instance of the SQL Server or
-- are accessible through a database gateway
DROP VIEW IF EXISTS sys.sp_databases_view CASCADE;

CREATE OR REPLACE VIEW sys.sp_databases_view AS
	SELECT CAST(database_name AS sys.SYSNAME),
	-- DATABASE_SIZE returns a NULL value for databases larger than 2.15 TB
	CASE WHEN (sum(table_size)/1024.0) > 2.15 * 1024.0 * 1024.0 * 1024.0 THEN NULL
		ELSE CAST((sum(table_size)/1024.0) AS int) END as database_size,
	CAST(NULL AS sys.VARCHAR(254)) as remarks
	FROM (
		SELECT pg_catalog.pg_namespace.oid as schema_oid,
		pg_catalog.pg_namespace.nspname as schema_name,
		INT.name AS database_name,
		coalesce(pg_relation_size(pg_catalog.pg_class.oid), 0) as table_size
		FROM
		sys.babelfish_namespace_ext EXT
		JOIN sys.babelfish_sysdatabases INT ON EXT.dbid = INT.dbid
		JOIN pg_catalog.pg_namespace ON pg_catalog.pg_namespace.nspname = EXT.nspname
		LEFT JOIN pg_catalog.pg_class ON relnamespace = pg_catalog.pg_namespace.oid
	) t
	GROUP BY database_name
	ORDER BY database_name;
GRANT SELECT on sys.sp_databases_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_databases ()
AS $$
BEGIN
	SELECT database_name as "DATABASE_NAME",
		database_size as "DATABASE_SIZE", 
		remarks as "REMARKS" from sys.sp_databases_view;
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_databases TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_pkeys_view AS
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
	JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" AND ext.orig_name = t4."TABLE_SCHEMA")
	JOIN pg_constraint t5 ON t1.oid = t5.conrelid
	, generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
	AND CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.conkey)
	AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.conkey[seq]
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT on sys.sp_pkeys_view TO PUBLIC;

-- internal function in order to workaround BABEL-1597
create or replace function sys.sp_pkeys_internal(
	in_table_name sys.nvarchar(384),
	in_table_owner sys.nvarchar(384) = '',
	in_table_qualifier sys.nvarchar(384) = ''
)
returns table(
	out_table_qualifier sys.sysname,
	out_table_owner sys.sysname,
	out_table_name sys.sysname,
	out_column_name sys.sysname,
	out_key_seq smallint,
	out_pk_name sys.sysname
)
as $$
begin
	return query
	select * from sys.sp_pkeys_view
	where table_name = in_table_name collate sys.bbf_unicode_general_ci_as
		and table_owner = coalesce(in_table_owner,'dbo') collate sys.bbf_unicode_general_ci_as
		and ((SELECT
		         coalesce(in_table_qualifier,'')) = '' or
		         table_qualifier = in_table_qualifier collate sys.bbf_unicode_general_ci_as)
	order by table_qualifier,
	         table_owner,
		 table_name,
		 key_seq;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = 'dbo',
	"@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
	select out_table_qualifier as TABLE_QUALIFIER,
			out_table_owner as TABLE_OWNER,
			out_table_name as TABLE_NAME,
			out_column_name as COLUMN_NAME,
			out_key_seq as KEY_SEQ,
			out_pk_name as PK_NAME
	from sys.sp_pkeys_internal(@table_name, @table_owner, @table_qualifier);
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

CREATE VIEW sys.sp_statistics_view AS
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
WHEN t7.starelid > 0 THEN CAST(0 AS smallint)
ELSE
	CASE
	WHEN t5.indisclustered = 't' THEN CAST(1 AS smallint)
	ELSE CAST(3 AS smallint)
	END
END AS TYPE,
CAST(seq + 1 AS smallint) AS SEQ_IN_INDEX,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.stadistinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" AND s1.name = t4."TABLE_SCHEMA")
	JOIN (pg_catalog.pg_index t5 JOIN
		pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
	LEFT JOIN pg_catalog.pg_statistic t7 ON t1.oid = t7.starelid
	LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.indkey)
    AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.indkey[seq];
GRANT SELECT on sys.sp_statistics_view TO PUBLIC;

create function sys.sp_statistics_internal(
    in_table_name sys.sysname,
    in_table_owner sys.sysname = '',
    in_table_qualifier sys.sysname = '',
    in_index_name sys.sysname = '',
	in_is_unique char = 'N',
	in_accuracy char = 'Q'
)
returns table(
    out_table_qualifier sys.sysname,
    out_table_owner sys.sysname,
    out_table_name sys.sysname,
	out_non_unique smallint,
	out_index_qualifier sys.sysname,
	out_index_name sys.sysname,
	out_type smallint,
	out_seq_in_index smallint,
	out_column_name sys.sysname,
	out_collation sys.varchar(1),
	out_cardinality int,
	out_pages int,
	out_filter_condition sys.varchar(128)
)
as $$
begin
    return query
    select * from sys.sp_statistics_view
    where in_table_name = table_name COLLATE sys.bbf_unicode_general_ci_as
        and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner  COLLATE sys.bbf_unicode_general_ci_as)
        and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier COLLATE sys.bbf_unicode_general_ci_as)
        and ((SELECT coalesce(in_index_name,'')) = '' or index_name like in_index_name COLLATE sys.bbf_unicode_general_ci_as)
        and ((UPPER(in_is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (UPPER(in_is_unique) = 'N'))
    order by non_unique, type, index_name, seq_in_index;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_statistics(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
	"@index_name" sys.sysname = '',
	"@is_unique" char = 'N',
	"@accuracy" char = 'Q'
)
AS $$
BEGIN
    IF @index_name = '%'
	BEGIN
	    SELECT @index_name = ''
	END
    select out_table_qualifier as table_qualifier,
            out_table_owner as table_owner,
            out_table_name as table_name,
			out_non_unique as non_unique,
			out_index_qualifier as index_qualifier,
			out_index_name as index_name,
			out_type as type,
			out_seq_in_index as seq_in_index,
			out_column_name as column_name,
			out_collation as collation,
			out_cardinality as cardinality,
			out_pages as pages,
			out_filter_condition as filter_condition
    from sys.sp_statistics_internal(@table_name, @table_owner, @table_qualifier, @index_name, @is_unique, @accuracy);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics TO PUBLIC;

-- same as sp_statistics
CREATE OR REPLACE PROCEDURE sys.sp_statistics_100(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
	"@index_name" sys.sysname = '',
	"@is_unique" char = 'N',
	"@accuracy" char = 'Q'
)
AS $$
BEGIN
    IF @index_name = '%'
	BEGIN
	    SELECT @index_name = ''
	END
    select out_table_qualifier as TABLE_QUALIFIER,
            out_table_owner as TABLE_OWNER,
            out_table_name as TABLE_NAME,
			out_non_unique as NON_UNIQUE,
			out_index_qualifier as INDEX_QUALIFIER,
			out_index_name as INDEX_NAME,
			out_type as TYPE,
			out_seq_in_index as SEQ_IN_INDEX,
			out_column_name as COLUMN_NAME,
			out_collation as COLLATION,
			out_cardinality as CARDINALITY,
			out_pages as PAGES,
			out_filter_condition as FILTER_CONDITION
    from sys.sp_statistics_internal(@table_name, @table_owner, @table_qualifier, @index_name, @is_unique, @accuracy);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics_100 TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.printarg(IN "@message" TEXT)
AS $$
BEGIN
  PRINT @message;
END;
$$ LANGUAGE pltsql;
GRANT EXECUTE ON PROCEDURE sys.printarg(IN "@message" TEXT) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8) DEFAULT 'NO')
AS $$
BEGIN
  IF sys.user_name() != 'dbo' THEN
    RAISE EXCEPTION 'user does not have permission';
  END IF;

  IF lower("@resample") = 'resample' THEN
    RAISE NOTICE 'ignoring resample option';
  ELSIF lower("@resample") != 'no' THEN
    RAISE EXCEPTION 'Invalid option name %', "@resample";
  END IF;

  ANALYZE VERBOSE;

  CALL sys.printarg('Statistics for all tables have been updated. Refer logs for details.');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE on PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8)) TO PUBLIC;

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

-- For some cases, T-SQL throws an error in DML-time even though it can be detected in DDL-time.
-- This function can be used in DDL-time to postpone errors without impacting general DML performance.
CREATE OR REPLACE FUNCTION sys.babelfish_runtime_error(msg ANYCOMPATIBLE)
RETURNS ANYCOMPATIBLE AS
$$
BEGIN
	RAISE EXCEPTION '%', msg;
END;
$$
LANGUAGE PLPGSQL;
GRANT ALL on FUNCTION sys.babelfish_runtime_error TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_column_privileges_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(COALESCE(SPLIT_PART(t6.attoptions[1], '=', 2), t5.column_name) AS sys.sysname) AS COLUMN_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantee) AS sys.sysname) AS GRANTEE,
CAST(t5.privilege_type AS sys.varchar(32)) AS PRIVILEGE,
CAST(t5.is_grantable AS sys.varchar(3)) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.column_privileges t5 ON t1.relname = t5.table_name AND t2.nspname = t5.table_schema
	JOIN pg_attribute t6 ON t6.attrelid = t1.oid AND t6.attname = t5.column_name;
GRANT SELECT ON sys.sp_column_privileges_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_column_privileges(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
    "@column_name" sys.nvarchar(384) = ''
)
AS $$
BEGIN
    IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
 	
	IF (COALESCE(@table_owner, '') = '')
	BEGIN
		
		IF EXISTS ( 
			SELECT * FROM sys.sp_column_privileges_view 
			WHERE LOWER(@table_name) = LOWER(table_name) and LOWER(SCHEMA_NAME()) = LOWER(table_qualifier)
			)
		BEGIN 
			SELECT 
			TABLE_QUALIFIER,
			TABLE_OWNER,
			TABLE_NAME,
			COLUMN_NAME,
			GRANTOR,
			GRANTEE,
			PRIVILEGE,
			IS_GRANTABLE
			FROM sys.sp_column_privileges_view
			WHERE LOWER(@table_name) = LOWER(table_name)
				AND (LOWER(SCHEMA_NAME()) = LOWER(table_owner))
				AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
				AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
			ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
		END
		ELSE
		BEGIN
			SELECT 
			TABLE_QUALIFIER,
			TABLE_OWNER,
			TABLE_NAME,
			COLUMN_NAME,
			GRANTOR,
			GRANTEE,
			PRIVILEGE,
			IS_GRANTABLE
			FROM sys.sp_column_privileges_view
			WHERE LOWER(@table_name) = LOWER(table_name)
				AND (LOWER('dbo')= LOWER(table_owner))
				AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
				AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
			ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
		END
	END
	ELSE
	BEGIN
		SELECT 
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		COLUMN_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE
		FROM sys.sp_column_privileges_view
		WHERE LOWER(@table_name) = LOWER(table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
			AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
			AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
		ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
	END
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_column_privileges TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_table_privileges_view AS
-- Will use sp_column_priivleges_view to get information from SELECT, INSERT and REFERENCES (only need permission from 1 column in table)
SELECT DISTINCT
CAST(TABLE_QUALIFIER AS sys.sysname) AS TABLE_QUALIFIER,
CAST(TABLE_OWNER AS sys.sysname) AS TABLE_OWNER,
CAST(TABLE_NAME AS sys.sysname) AS TABLE_NAME,
CAST(GRANTOR AS sys.sysname) AS GRANTOR,
CAST(GRANTEE AS sys.sysname) AS GRANTEE,
CAST(PRIVILEGE AS sys.sysname) AS PRIVILEGE,
CAST(IS_GRANTABLE AS sys.sysname) AS IS_GRANTABLE
FROM sys.sp_column_privileges_view

UNION 
-- We need these set of joins only for the DELETE privilege
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantee) AS sys.sysname) AS GRANTEE,
CAST(t4.privilege_type AS sys.sysname) AS PRIVILEGE,
CAST(t4.is_grantable AS sys.sysname) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.table_privileges t4 ON t1.relname = t4.table_name
WHERE t4.privilege_type = 'DELETE'; 
GRANT SELECT on sys.sp_table_privileges_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_table_privileges(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = '',
	"@table_qualifier" sys.sysname = '',
	"@fusepattern" sys.bit = 1
)
AS $$
BEGIN
	
	IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	IF @fusepattern = 1
	BEGIN
		SELECT 
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE FROM sys.sp_table_privileges_view
		WHERE LOWER(TABLE_NAME) LIKE LOWER(@table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(TABLE_OWNER) LIKE LOWER(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
	END
	ELSE 
	BEGIN
		SELECT
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE FROM sys.sp_table_privileges_view
		WHERE LOWER(TABLE_NAME) = LOWER(@table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(TABLE_OWNER) = LOWER(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
	END
	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_table_privileges TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_precision_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
	CASE
		WHEN type in ('real','float') THEN sp_columns_max_length * 2 - 1
		WHEN type in ('char','varchar','binary','varbinary') THEN sp_columns_max_length
		WHEN type in ('nchar','nvarchar') THEN sp_columns_max_length / 2
		WHEN type in ('sysname','uniqueidentifier') THEN sp_datatype_info_precision
		ELSE sp_columns_precision
	END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_length_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
	CASE
		WHEN type in ('decimal','numeric','money','smallmoney') THEN sp_columns_precision + 2
		WHEN type in ('time','date','datetime2','datetimeoffset') THEN sp_columns_precision * 2
		WHEN type in ('smalldatetime') THEN sp_columns_precision
		WHEN type in ('datetime') THEN sp_columns_max_length * 2
		WHEN type in ('sql_variant') THEN sp_datatype_info_precision
		ELSE sp_columns_max_length
	END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_scale_helper(IN type TEXT, IN sp_columns_scale INT) RETURNS INT
AS $$
SELECT
	CASE
		WHEN type in ('bit','real','float','char','varchar','nchar','nvarchar','time','date','datetime2','datetimeoffset','varbinary','binary','sql_variant','sysname','uniqueidentifier') THEN NULL
		ELSE sp_columns_scale
	END;
$$ LANGUAGE SQL IMMUTABLE;

-- TODO: BABEL-2838
CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT DISTINCT 
CAST(1 as smallint) AS SCOPE,
CAST(coalesce (split_part(pa.attoptions[1], '=', 2) ,c1.name) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS smallint) AS DATA_TYPE,

CASE -- cases for when they are of type identity. 
	WHEN c1.is_identity = 1 AND (t8.name = 'decimal' or t8.name = 'numeric') 
	THEN CAST(CONCAT(t8.name, '() identity') AS sys.sysname)
	WHEN c1.is_identity = 1 AND (t8.name != 'decimal' AND t8.name != 'numeric')
	THEN CAST(CONCAT(t8.name, ' identity') AS sys.sysname)
	ELSE CAST(t8.name AS sys.sysname)
END AS TYPE_NAME,

CAST(sys.sp_special_columns_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS int) AS PRECISION,
CAST(sys.sp_special_columns_length_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS int) AS LENGTH,
CAST(sys.sp_special_columns_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.scale) AS smallint) AS SCALE,
CAST(1 AS smallint) AS PSEUDO_COLUMN,
CAST(c1.is_nullable AS int) AS IS_NULLABLE,
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,

CASE 
	WHEN idx.is_primary_key != 1
	THEN CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
	ELSE CAST('p' AS sys.sysname)
END AS CONSTRAINT_TYPE,
CAST(idx.name AS sys.sysname) AS CONSTRAINT_NAME,
CAST(idx.index_id AS int) AS INDEX_ID
        
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	LEFT JOIN sys.indexes idx ON idx.object_id = t1.oid
	INNER JOIN pg_catalog.pg_attribute i2 ON idx.index_id = i2.attrelid
	INNER JOIN sys.columns c1 ON c1.object_id = idx.object_id AND i2.attname = c1.name

	JOIN pg_catalog.pg_type AS t7 ON t7.oid = c1.system_type_id
	JOIN sys.types AS t8 ON c1.user_type_id = t8.user_type_id 
	LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON t7.typname = t6.pg_type_name OR t7.typname = t6.type_name --need in order to get accurate DATA_TYPE value
	LEFT JOIN pg_catalog.pg_attribute AS pa ON t1.oid = pa.attrelid AND c1.name = pa.attname
	, sys.translate_pg_type_to_tsql(t8.user_type_id) AS tsql_type_name
	, sys.translate_pg_type_to_tsql(t8.system_type_id) AS tsql_base_type_name
	WHERE has_schema_privilege(s1.schema_id, 'USAGE');
  
GRANT SELECT ON sys.sp_special_columns_view TO PUBLIC;


CREATE OR REPLACE PROCEDURE sys.sp_special_columns(
	"@table_name" sys.sysname,
	"@table_owner" sys.sysname = '',
	"@qualifier" sys.sysname = '',
	"@col_type" char(1) = 'R',
	"@scope" char(1) = 'T',
	"@nullable" char(1) = 'U',
	"@odbcver" int = 2
)
AS $$
DECLARE @special_col_type sys.sysname;
DECLARE @constraint_name sys.sysname;
BEGIN
	IF (@qualifier != '') AND (LOWER(@qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
		
	END
	
	IF (LOWER(@col_type) = LOWER('V'))
	BEGIN
		THROW 33557097, N'TIMESTAMP datatype is not currently supported in Babelfish', 1;
	END
	
	IF (LOWER(@nullable) = LOWER('O'))
	BEGIN
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE LOWER(@table_name) = LOWER(table_name)
			AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0)
		ORDER BY constraint_type, index_id;
	
		IF @special_col_type='u'
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT  
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
				
			END
			ELSE
			BEGIN
				SELECT  
				SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
			END
		
		END
		
		ELSE 
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
			ELSE
			BEGIN
				SELECT SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN  FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
		END
	END
	
	ELSE 
	BEGIN
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE LOWER(@table_name) = LOWER(table_name)
			AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier))
		ORDER BY constraint_type, index_id;

		IF @special_col_type='u'
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
			END
			
			ELSE
			BEGIN
				SELECT SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
			END
		
		END
		ELSE
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name; 
			END
			
			ELSE
			BEGIN
				SELECT SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
    
		END
	END

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_special_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_special_columns_100(
	"@table_name" sys.sysname,
	"@table_owner" sys.sysname = '',
	"@qualifier" sys.sysname = '',
	"@col_type" char(1) = 'R',
	"@scope" char(1) = 'T',
	"@nullable" char(1) = 'U',
	"@odbcver" int = 2
)
AS $$
BEGIN
	EXEC sp_special_columns @table_name, @table_owner, @qualifier, @col_type, @scope, @nullable, @odbcver
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_special_columns_100 TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
-- primary key info
CAST(t2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname = ref.table_schema) AS sys.sysname) AS PKTABLE_OWNER,
CAST(ref.table_name AS sys.sysname) AS PKTABLE_NAME,
CAST(coalesce(split_part(pkname_table.attoptions[1], '=', 2), ref.column_name) AS sys.sysname) AS PKCOLUMN_NAME,

-- foreign key info
CAST(t2.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname = fk.table_schema) AS sys.sysname) AS FKTABLE_OWNER,
CAST(fk.table_name AS sys.sysname) AS FKTABLE_NAME,
CAST(coalesce(split_part(fkname_table.attoptions[1], '=', 2), fk.column_name) AS sys.sysname) AS FKCOLUMN_NAME,

CAST(seq AS smallint) AS KEY_SEQ,
CASE
    WHEN map.update_rule = 'NO ACTION' THEN CAST(1 AS smallint)
    WHEN map.update_rule = 'SET NULL' THEN CAST(2 AS smallint)
    WHEN map.update_rule = 'SET DEFAULT' THEN CAST(3 AS smallint)
    ELSE CAST(0 AS smallint)
END AS UPDATE_RULE,

CASE
    WHEN map.delete_rule = 'NO ACTION' THEN CAST(1 AS smallint)
    WHEN map.delete_rule = 'SET NULL' THEN CAST(2 AS smallint)
    WHEN map.delete_rule = 'SET DEFAULT' THEN CAST(3 AS smallint)
    ELSE CAST(0 AS smallint)
END AS DELETE_RULE,
CAST(fk.constraint_name AS sys.sysname) AS FK_NAME,
CAST(ref.constraint_name AS sys.sysname) AS PK_NAME
        
FROM information_schema.referential_constraints AS map

-- join unique constraints (e.g. PKs constraints) to ref columns info
INNER JOIN information_schema.key_column_usage AS ref
	JOIN pg_catalog.pg_class p1 -- Need to join this in order to get oid for pkey's original bbf name
    JOIN sys.pg_namespace_ext p2 ON p1.relnamespace = p2.oid
    JOIN information_schema.columns p4 ON p1.relname = p4.table_name AND p1.relnamespace::regnamespace::text = p4.table_schema
    JOIN pg_constraint p5 ON p1.oid = p5.conrelid
    ON (p1.relname=ref.table_name AND p4.column_name=ref.column_name AND ref.table_schema = p2.nspname AND ref.table_schema = p4.table_schema)
    
    ON ref.constraint_catalog = map.unique_constraint_catalog
    AND ref.constraint_schema = map.unique_constraint_schema
    AND ref.constraint_name = map.unique_constraint_name

-- join fk columns to the correct ref columns using ordinal positions
INNER JOIN information_schema.key_column_usage AS fk
    ON  fk.constraint_catalog = map.constraint_catalog
    AND fk.constraint_schema = map.constraint_schema
    AND fk.constraint_name = map.constraint_name
    AND fk.position_in_unique_constraint = ref.ordinal_position

INNER JOIN pg_catalog.pg_class t1 
    JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
    JOIN information_schema.columns t4 ON t1.relname = t4.table_name AND t1.relnamespace::regnamespace::text = t4.table_schema
    JOIN pg_constraint t5 ON t1.oid = t5.conrelid
    ON (t1.relname=fk.table_name AND t4.column_name=fk.column_name AND fk.table_schema = t2.nspname AND fk.table_schema = t4.table_schema)
    
-- get foreign key's original bbf name
JOIN pg_catalog.pg_attribute fkname_table
	ON (t1.oid = fkname_table.attrelid) AND (fk.column_name = fkname_table.attname)

-- get primary key's original bbf name
JOIN pg_catalog.pg_attribute pkname_table
	ON (p1.oid = pkname_table.attrelid) AND (ref.column_name = pkname_table.attname)
	
	, generate_series(1,16) seq -- BBF has max 16 columns per primary key
WHERE t5.contype = 'f'
AND CAST(t4.dtd_identifier AS smallint) = ANY (t5.conkey)
AND CAST(t4.dtd_identifier AS smallint) = t5.conkey[seq];

GRANT SELECT ON sys.sp_fkeys_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_fkeys(
	"@pktable_name" sys.sysname = '',
	"@pktable_owner" sys.sysname = '',
	"@pktable_qualifier" sys.sysname = '',
	"@fktable_name" sys.sysname = '',
	"@fktable_owner" sys.sysname = '',
	"@fktable_qualifier" sys.sysname = ''
)
AS $$
BEGIN
	
	IF coalesce(@pktable_name,'') = '' AND coalesce(@fktable_name,'') = '' 
	BEGIN
		THROW 33557097, N'Primary or foreign key table name must be given.', 1;
	END
	
	IF (@pktable_qualifier != '' AND (SELECT sys.db_name()) != @pktable_qualifier) OR 
		(@fktable_qualifier != '' AND (SELECT sys.db_name()) != @fktable_qualifier) 
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
  	END
  	
  	SELECT 
	PKTABLE_QUALIFIER,
	PKTABLE_OWNER,
	PKTABLE_NAME,
	PKCOLUMN_NAME,
	FKTABLE_QUALIFIER,
	FKTABLE_OWNER,
	FKTABLE_NAME,
	FKCOLUMN_NAME,
	KEY_SEQ,
	UPDATE_RULE,
	DELETE_RULE,
	FK_NAME,
	PK_NAME
	FROM sys.sp_fkeys_view
	WHERE ((SELECT coalesce(@pktable_name,'')) = '' OR LOWER(pktable_name) = LOWER(@pktable_name))
		AND ((SELECT coalesce(@fktable_name,'')) = '' OR LOWER(fktable_name) = LOWER(@fktable_name))
		AND ((SELECT coalesce(@pktable_owner,'')) = '' OR LOWER(pktable_owner) = LOWER(@pktable_owner))
		AND ((SELECT coalesce(@pktable_qualifier,'')) = '' OR LOWER(pktable_qualifier) = LOWER(@pktable_qualifier))
		AND ((SELECT coalesce(@fktable_owner,'')) = '' OR LOWER(fktable_owner) = LOWER(@fktable_owner))
		AND ((SELECT coalesce(@fktable_qualifier,'')) = '' OR LOWER(fktable_qualifier) = LOWER(@fktable_qualifier))
	ORDER BY fktable_qualifier, fktable_owner, fktable_name, key_seq;

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_fkeys TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_stored_procedures_view AS
SELECT 
CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS PROCEDURE_OWNER, 

CASE 
	WHEN p.prokind = 'p' THEN CAST(concat(p.proname, ';1') AS sys.nvarchar(134))
	ELSE CAST(concat(p.proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM pg_catalog.pg_proc p 

INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id 
INNER JOIN sys.databases d ON d.database_id = sys.db_id()
WHERE has_schema_privilege(s1.schema_id, 'USAGE')

UNION 

SELECT CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
CAST(nspname AS sys.sysname) AS PROCEDURE_OWNER,

CASE 
	WHEN prokind = 'p' THEN cast(concat(proname, ';1') AS sys.nvarchar(134))
	ELSE cast(concat(proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM    pg_catalog.pg_namespace n 
JOIN    pg_catalog.pg_proc p 
ON      pronamespace = n.oid   
WHERE nspname = 'sys' AND (proname LIKE 'sp\_%' OR proname LIKE 'xp\_%' OR proname LIKE 'dm\_%' OR proname LIKE 'fn\_%');

GRANT SELECT ON sys.sp_stored_procedures_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_stored_procedures(
    "@sp_name" sys.nvarchar(390) = '',
    "@sp_owner" sys.nvarchar(384) = '',
    "@sp_qualifier" sys.sysname = '',
    "@fusepattern" sys.bit = '1'
)
AS $$
BEGIN
	IF (@sp_qualifier != '') AND LOWER(sys.db_name()) != LOWER(@sp_qualifier)
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	-- If @sp_name or @sp_owner = '%', it gets converted to NULL or '' regardless of @fusepattern 
	IF @sp_name = '%'
	BEGIN
		SELECT @sp_name = ''
	END
	
	IF @sp_owner = '%'
	BEGIN
		SELECT @sp_owner = ''
	END
	
	-- Changes fusepattern to 0 if no wildcards are used. NOTE: Need to add [] wildcard pattern when it is implemented. Wait for BABEL-2452
	IF @fusepattern = 1
	BEGIN
		IF (CHARINDEX('%', @sp_name) != 0 AND CHARINDEX('_', @sp_name) != 0 AND CHARINDEX('%', @sp_owner) != 0 AND CHARINDEX('_', @sp_owner) != 0 )
		BEGIN
			SELECT @fusepattern = 0;
		END
	END
	
	-- Condition for when sp_name argument is not given or is null, or is just a wildcard (same order)
	IF COALESCE(@sp_name, '') = ''
	BEGIN
		IF @fusepattern=1 
		BEGIN
			SELECT 
			PROCEDURE_QUALIFIER,
			PROCEDURE_OWNER,
			PROCEDURE_NAME,
			NUM_INPUT_PARAMS,
			NUM_OUTPUT_PARAMS,
			NUM_RESULT_SETS,
			REMARKS,
			PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
			WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
		ELSE
		BEGIN
			SELECT 
			PROCEDURE_QUALIFIER,
			PROCEDURE_OWNER,
			PROCEDURE_NAME,
			NUM_INPUT_PARAMS,
			NUM_OUTPUT_PARAMS,
			NUM_RESULT_SETS,
			REMARKS,
			PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
			WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
	END
	-- When @sp_name is not null
	ELSE
	BEGIN
		-- When sp_owner is null and fusepattern = 0
		IF (@fusepattern = 0 AND  COALESCE(@sp_owner,'') = '') 
		BEGIN
			IF EXISTS ( -- Search in the sys schema 
					SELECT * FROM sys.sp_stored_procedures_view
					WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
						AND (LOWER(procedure_owner) = 'sys'))
			BEGIN
				SELECT PROCEDURE_QUALIFIER,
				PROCEDURE_OWNER,
				PROCEDURE_NAME,
				NUM_INPUT_PARAMS,
				NUM_OUTPUT_PARAMS,
				NUM_RESULT_SETS,
				REMARKS,
				PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = 'sys')
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			ELSE IF EXISTS ( 
				SELECT * FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = LOWER(SCHEMA_NAME()))
					)
			BEGIN
				SELECT PROCEDURE_QUALIFIER,
				PROCEDURE_OWNER,
				PROCEDURE_NAME,
				NUM_INPUT_PARAMS,
				NUM_OUTPUT_PARAMS,
				NUM_RESULT_SETS,
				REMARKS,
				PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = LOWER(SCHEMA_NAME()))
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			ELSE -- Search in the dbo schema (if nothing exists it should just return nothing). 
			BEGIN
				SELECT PROCEDURE_QUALIFIER,
				PROCEDURE_OWNER,
				PROCEDURE_NAME,
				NUM_INPUT_PARAMS,
				NUM_OUTPUT_PARAMS,
				NUM_RESULT_SETS,
				REMARKS,
				PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = 'dbo')
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			
		END
		ELSE IF (@fusepattern = 0 AND  COALESCE(@sp_owner,'') != '')
		BEGIN
			SELECT 
			PROCEDURE_QUALIFIER,
			PROCEDURE_OWNER,
			PROCEDURE_NAME,
			NUM_INPUT_PARAMS,
			NUM_OUTPUT_PARAMS,
			NUM_RESULT_SETS,
			REMARKS,
			PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
			WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
				AND (LOWER(procedure_owner) = LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
		ELSE -- fusepattern = 1
		BEGIN
			SELECT 
			PROCEDURE_QUALIFIER,
			PROCEDURE_OWNER,
			PROCEDURE_NAME,
			NUM_INPUT_PARAMS,
			NUM_OUTPUT_PARAMS,
			NUM_RESULT_SETS,
			REMARKS,
			PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
			WHERE ((SELECT COALESCE(@sp_name,'')) = '' OR LOWER(LEFT(procedure_name, -2)) LIKE LOWER(@sp_name))
				AND ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
	END	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_stored_procedures TO PUBLIC;

CREATE OR REPLACE FUNCTION is_srvrolemember(role sys.SYSNAME, login sys.SYSNAME DEFAULT suser_name())
RETURNS INTEGER AS
$$
DECLARE has_role BOOLEAN;
DECLARE login_valid BOOLEAN;
BEGIN
	role  := TRIM(trailing from LOWER(role));
	login := TRIM(trailing from LOWER(login));
	
	login_valid = (login = suser_name()) OR 
		(EXISTS (SELECT name
	 			FROM sys.server_principals
		 	 	WHERE 
				LOWER(name) = login 
				AND type = 'S'));
 	
 	IF NOT login_valid THEN
 		RETURN NULL;
    
    ELSIF role = 'public' THEN
    	RETURN 1;
	
 	ELSIF role = 'sysadmin' THEN
	  	has_role = pg_has_role(login::TEXT, role::TEXT, 'MEMBER');
	    IF has_role THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	
    ELSIF role IN (
            'serveradmin',
            'securityadmin',
            'setupadmin',
            'securityadmin',
            'processadmin',
            'dbcreator',
            'diskadmin',
            'bulkadmin') THEN 
    	RETURN 0;
 	
    ELSE
 		  RETURN NULL;
 	END IF;
	
 	EXCEPTION WHEN OTHERS THEN
	 	  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

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
			   CAST(Ext1.login_name AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base1.oid AS INT) AS 'UserID',
			   CAST(CAST(Base1.oid AS INT) AS SYS.VARBINARY(85)) AS 'SID'
		FROM sys.babelfish_authid_user_ext AS Ext1
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
		LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
		WHERE Ext1.database_name = DB_NAME()
		AND Ext1.type = 'S'
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
			   CAST(Ext1.login_name AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base1.oid AS INT) AS 'UserID',
			   CAST(CAST(Base1.oid AS INT) AS SYS.VARBINARY(85)) AS 'SID'
		FROM sys.babelfish_authid_user_ext AS Ext1
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
		LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
		LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
		LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
		WHERE Ext1.database_name = DB_NAME()
		AND Ext1.type = 'S'
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

CREATE OR REPLACE PROCEDURE sys.sp_helprole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If role is not specified, return info for all roles in the current db
	IF @rolename IS NULL
	BEGIN
		SELECT CAST(Ext.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Base.oid AS INT) AS 'RoleId',
			   0 AS 'IsAppRole'
		FROM pg_catalog.pg_roles AS Base 
		INNER JOIN sys.babelfish_authid_user_ext AS Ext
		ON Base.rolname = Ext.rolname
		WHERE Ext.database_name = DB_NAME()
		AND Ext.type = 'R'
		ORDER BY RoleName;
	END
	-- If a valid role is specified, return its info
	ELSE IF EXISTS (SELECT 1 
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @rolename
					OR lower(orig_username) = lower(@rolename))
					AND database_name = DB_NAME()
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Base.oid AS INT) AS 'RoleId',
			   0 AS 'IsAppRole'
		FROM pg_catalog.pg_roles AS Base 
		INNER JOIN sys.babelfish_authid_user_ext AS Ext
		ON Base.rolname = Ext.rolname
		WHERE Ext.database_name = DB_NAME()
		AND Ext.type = 'R'
		AND (Ext.orig_username = @rolename OR lower(Ext.orig_username) = lower(@rolename))
		ORDER BY RoleName;
	END
	-- If the specified role is not valid
	ELSE
		RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprole TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helprolemember("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If role is not specified, return info for all roles that have at least
	-- one member in the current db
	IF @rolename IS NULL
	BEGIN
		SELECT CAST(Ext1.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Ext2.orig_username AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.database_name = DB_NAME()
		AND Ext2.database_name = DB_NAME()
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		ORDER BY RoleName, MemberName;
	END
	-- If a valid role is specified, return its member info
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @rolename
					OR lower(orig_username) = lower(@rolename))
					AND database_name = DB_NAME()
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext1.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Ext2.orig_username AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.database_name = DB_NAME()
		AND Ext2.database_name = DB_NAME()
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		AND (Ext1.orig_username = @rolename OR lower(Ext1.orig_username) = lower(@rolename))
		ORDER BY RoleName, MemberName;
	END
	-- If the specified role is not valid
	ELSE
		RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprolemember TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_sproc_columns_view AS
-- Get parameters (if any) for a user-defined stored procedure/function
(SELECT 
	CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(ext.orig_name AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CAST(coalesce(args.parameter_name, '') AS sys.sysname) AS COLUMN_NAME,
	CAST(1 AS smallint) AS COLUMN_TYPE,
	CAST(t5.data_type AS smallint) AS DATA_TYPE,
	CAST(coalesce(t6.name, '') AS sys.sysname) AS TYPE_NAME,
	CAST(t6.precision AS int) AS PRECISION,
	CAST(t6.max_length AS int) AS LENGTH,
	CAST(t6.scale AS smallint) AS SCALE,
	CAST(t5.num_prec_radix AS smallint) AS RADIX,
	CAST(t6.is_nullable AS smallint) AS NULLABLE,
	CAST(NULL AS varchar(254)) AS REMARKS,
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
	CAST(t5.sql_datetime_sub AS smallint) AS SQL_DATETIME_SUB,
	CAST(NULL AS int) AS CHAR_OCTET_LENGTH,
	CAST(args.ordinal_position AS int) AS ORDINAL_POSITION,
	CAST('YES' AS varchar(254)) AS IS_NULLABLE,
	CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	JOIN information_schema.parameters args
		ON proc.specific_schema = args.specific_schema AND proc.specific_name = args.specific_name
	INNER JOIN sys.babelfish_namespace_ext ext ON proc.specific_schema = ext.nspname
	INNER JOIN sys.databases d ON d.database_id =ext.dbid
	INNER JOIN sys.spt_datatype_info_table AS t5 
		JOIN sys.types t6
		JOIN sys.types t7 ON t6.system_type_id = t7.user_type_id
			ON t7.name = t5.type_name
		ON (args.data_type != 'USER-DEFINED' AND args.udt_name = t5.pg_type_name AND t6.name = t7.name)
		OR (args.data_type='USER-DEFINED' AND args.udt_name = t6.name)
	WHERE coalesce(args.parameter_name, '') LIKE '@%'
		AND ext.dbid = sys.db_id()
		AND has_schema_privilege(proc.specific_schema, 'USAGE')

UNION ALL

-- Create row describing return type for a user-defined stored procedure/function
SELECT 
	CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(ext.orig_name AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast('@TABLE_RETURN_VALUE' AS sys.sysname)
		ELSE cast('@RETURN_VALUE' AS sys.sysname)
 	END AS COLUMN_NAME,
	 
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(3 AS smallint)
		ELSE CAST(5 as smallint) 
	END AS COLUMN_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN cast((SELECT data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast(null AS smallint)
		ELSE CAST(t5.data_type AS smallint)
	END AS DATA_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('int' AS sys.sysname) 
		WHEN pg_function_result_type like '%TABLE%' then CAST('table' AS sys.sysname)
		ELSE CAST(coalesce(t6.name, '') AS sys.sysname) 
	END AS TYPE_NAME,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.precision AS int) 
	END AS PRECISION,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(4 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.max_length AS int) 
	END AS LENGTH,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t6.scale AS smallint) 
	END AS SCALE,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t5.num_prec_radix AS smallint) 
	END AS RADIX,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
		ELSE CAST(t6.is_nullable AS smallint)
	END AS NULLABLE,
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('Result table returned by table valued function' AS varchar(254)) 
		ELSE CAST(NULL AS varchar(254)) 
	END AS REMARKS,
	
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(null AS smallint) 
		ELSE CAST(t5.sql_data_type AS smallint) 
	END AS SQL_DATA_TYPE,
	
	CAST(null AS smallint) AS SQL_DATETIME_SUB,
	CAST(null AS int) AS CHAR_OCTET_LENGTH,
	CAST(0 AS int) AS ORDINAL_POSITION,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('NO' AS varchar(254)) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('NO' AS varchar(254))
		ELSE CAST('YES' AS varchar(254)) 
	END AS IS_NULLABLE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(56 AS sys.tinyint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS sys.tinyint) 
		ELSE CAST(t5.ss_data_type AS sys.tinyint) 
	END AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name

	FROM information_schema.routines proc
	INNER JOIN sys.babelfish_namespace_ext ext ON proc.specific_schema = ext.nspname
	INNER JOIN sys.databases d ON d.database_id = ext.dbid
	INNER JOIN pg_catalog.pg_proc p ON proc.specific_name = p.proname || '_' || p.oid
	LEFT JOIN sys.spt_datatype_info_table AS t5 
		JOIN sys.types t6
		JOIN sys.types t7 ON t6.system_type_id = t7.user_type_id
		ON t7.name = t5.type_name
	ON (proc.data_type != 'USER-DEFINED' 
			AND proc.type_udt_name = t5.pg_type_name 
			AND t6.name = t7.name)
		OR (proc.data_type = 'USER-DEFINED' 
			AND proc.type_udt_name = t6.name),
	pg_get_function_result(p.oid) AS pg_function_result_type
	WHERE ext.dbid = sys.db_id() AND has_schema_privilege(proc.specific_schema, 'USAGE'))

UNION ALL 

-- Get parameters (if any) for a system stored procedure/function
(SELECT 
	CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(args.specific_schema AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' then CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CAST(coalesce(args.parameter_name, '') AS sys.sysname) AS COLUMN_NAME,
	CAST(1 as smallint) AS COLUMN_TYPE,
	CAST(t5.data_type AS smallint) AS DATA_TYPE,
	CAST(coalesce(t6.name, '') as sys.sysname) as TYPE_NAME,
	CAST(t6.precision as int) as PRECISION,
	CAST(t6.max_length as int) as LENGTH,
	CAST(t6.scale AS smallint) AS SCALE,
	CAST(t5.num_prec_radix AS smallint) AS RADIX,
	CAST(t6.is_nullable as smallint) AS NULLABLE,
	CAST(NULL AS varchar(254)) AS REMARKS,
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
	CAST(t5.sql_datetime_sub AS smallint) AS SQL_DATETIME_SUB,
	CAST(NULL AS int) AS CHAR_OCTET_LENGTH,
	CAST(args.ordinal_position AS int) AS ORDINAL_POSITION,
	CAST('YES' AS varchar(254)) AS IS_NULLABLE,
	CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	JOIN information_schema.parameters args
		on proc.specific_schema = args.specific_schema
		and proc.specific_name = args.specific_name 
	LEFT JOIN sys.spt_datatype_info_table AS t5 
		LEFT JOIN sys.types t6 ON t6.name = t5.type_name
		ON args.udt_name = t5.pg_type_name OR args.udt_name = t5.type_name
	WHERE args.specific_schema ='sys' 
		AND coalesce(args.parameter_name, '') LIKE '@%' 
		AND (args.specific_name LIKE 'sp\_%' 
			OR args.specific_name LIKE 'xp\_%'
			OR args.specific_name LIKE 'dm\_%'
			OR  args.specific_name LIKE 'fn\_%')
		AND has_schema_privilege(proc.specific_schema, 'USAGE')
		
UNION ALL

-- Create row describing return type for a system stored procedure/function
SELECT 
	CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(proc.specific_schema AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' then CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast('@TABLE_RETURN_VALUE' AS sys.sysname)
		ELSE cast('@RETURN_VALUE' AS sys.sysname)
 	END AS COLUMN_NAME,
	 
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(3 AS smallint)
		ELSE CAST(5 AS smallint) 
	END AS COLUMN_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN cast((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast(null AS smallint)
		ELSE CAST(t5.data_type AS smallint)
	END AS DATA_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('int' AS sys.sysname) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('table' AS sys.sysname)
		ELSE CAST(coalesce(t6.name, '') AS sys.sysname) 
	END AS TYPE_NAME,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.precision AS int) 
	END AS PRECISION,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(4 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.max_length AS int) 
	END AS LENGTH,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t6.scale AS smallint) 
	END AS SCALE,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t5.num_prec_radix AS smallint) 
	END AS RADIX,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
		ELSE CAST(t6.is_nullable AS smallint)
	END AS NULLABLE,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('Result table returned by table valued function' AS varchar(254)) 
		ELSE CAST(NULL AS varchar(254)) 
	END AS REMARKS,
	
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(null AS smallint) 
		ELSE CAST(t5.sql_data_type AS smallint) 
	END AS SQL_DATA_TYPE,
	
	CAST(null AS smallint) AS SQL_DATETIME_SUB,
	CAST(null AS int) AS CHAR_OCTET_LENGTH,
	CAST(0 AS int) AS ORDINAL_POSITION,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('NO' AS varchar(254)) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('NO' AS varchar(254))
		ELSE CAST('YES' AS varchar(254)) 
	END AS IS_NULLABLE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(56 AS sys.tinyint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS sys.tinyint) 
		ELSE CAST(t5.ss_data_type AS sys.tinyint) 
	END AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	INNER JOIN pg_catalog.pg_proc p ON proc.specific_name = p.proname || '_' || p.oid
	LEFT JOIN sys.spt_datatype_info_table AS t5
		LEFT JOIN sys.types t6 ON t6.name = t5.type_name
	ON proc.type_udt_name = t5.pg_type_name OR proc.type_udt_name = t5.type_name, 
	pg_get_function_result(p.oid) AS pg_function_result_type
	WHERE proc.specific_schema = 'sys' 
		AND (proc.specific_name LIKE 'sp\_%' 
			OR proc.specific_name LIKE 'xp\_%' 
			OR proc.specific_name LIKE 'dm\_%'
			OR  proc.specific_name LIKE 'fn\_%')
		AND has_schema_privilege(proc.specific_schema, 'USAGE')
	);	
GRANT SELECT ON sys.sp_sproc_columns_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_sproc_columns(
	"@procedure_name" sys.nvarchar(390) = '%',
	"@procedure_owner" sys.nvarchar(384) = NULL,
	"@procedure_qualifier" sys.sysname = NULL,
	"@column_name" sys.nvarchar(384) = NULL,
	"@odbcver" int = 2,
	"@fusepattern" sys.bit = '1'
)	
AS $$
	SELECT @procedure_name = LOWER(COALESCE(@procedure_name, ''))
	SELECT @procedure_owner = LOWER(COALESCE(@procedure_owner, ''))
	SELECT @procedure_qualifier = LOWER(COALESCE(@procedure_qualifier, ''))
	SELECT @column_name = LOWER(COALESCE(@column_Name, ''))
BEGIN 
	IF (@procedure_qualifier != '' AND (SELECT LOWER(sys.db_name())) != @procedure_qualifier)
		BEGIN
			THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 	   	END
	IF @fusepattern = '1'
		BEGIN
			SELECT PROCEDURE_QUALIFIER,
					PROCEDURE_OWNER,
					PROCEDURE_NAME,
					COLUMN_NAME,
					COLUMN_TYPE,
					DATA_TYPE,
					TYPE_NAME,
					PRECISION,
					LENGTH,
					SCALE,
					RADIX,
					NULLABLE,
					REMARKS,
					COLUMN_DEF,
					SQL_DATA_TYPE,
					SQL_DATETIME_SUB,
					CHAR_OCTET_LENGTH,
					ORDINAL_POSITION,
					IS_NULLABLE,
					SS_DATA_TYPE
			FROM sys.sp_sproc_columns_view
			WHERE (@procedure_name = '' OR original_procedure_name LIKE @procedure_name)
				AND (@procedure_owner = '' OR procedure_owner LIKE @procedure_owner)
				AND (@column_name = '' OR column_name  LIKE @column_name)
				AND (@procedure_qualifier = '' OR procedure_qualifier = @procedure_qualifier)
			ORDER BY procedure_qualifier, procedure_owner, procedure_name, ordinal_position;
		END
	ELSE
		BEGIN
			SELECT PROCEDURE_QUALIFIER,
					PROCEDURE_OWNER,
					PROCEDURE_NAME,
					COLUMN_NAME,
					COLUMN_TYPE,
					DATA_TYPE,
					TYPE_NAME,
					PRECISION,
					LENGTH,
					SCALE,
					RADIX,
					NULLABLE,
					REMARKS,
					COLUMN_DEF,
					SQL_DATA_TYPE,
					SQL_DATETIME_SUB,
					CHAR_OCTET_LENGTH,
					ORDINAL_POSITION,
					IS_NULLABLE,
					SS_DATA_TYPE
			FROM sys.sp_sproc_columns_view
			WHERE (@procedure_name = '' OR original_procedure_name = @procedure_name)
				AND (@procedure_owner = '' OR procedure_owner = @procedure_owner)
				AND (@column_name = '' OR column_name = @column_name)
				AND (@procedure_qualifier = '' OR procedure_qualifier = @procedure_qualifier)
			ORDER BY procedure_qualifier, procedure_owner, procedure_name, ordinal_position;
		END
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL ON PROCEDURE sys.sp_sproc_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_sproc_columns_100(
	"@procedure_name" sys.nvarchar(390) = '%',
	"@procedure_owner" sys.nvarchar(384) = NULL,
	"@procedure_qualifier" sys.sysname = NULL,
	"@column_name" sys.nvarchar(384) = NULL,
	"@odbcver" int = 2,
	"@fusepattern" sys.bit = '1'
)    
AS $$
BEGIN 
    exec sys.sp_sproc_columns @procedure_name, @procedure_owner, @procedure_qualifier, @column_name, @odbcver, @fusepattern;
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL ON PROCEDURE sys.sp_sproc_columns_100 TO PUBLIC;
