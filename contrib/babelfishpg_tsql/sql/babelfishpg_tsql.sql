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

CREATE FUNCTION sessionproperty (TEXT)
	   RETURNS  sys.SQL_VARIANT AS 'babelfishpg_tsql', 'sessionproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION fulltextserviceproperty (TEXT)
	RETURNS sys.int AS 'babelfishpg_tsql', 'fulltextserviceproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION COLUMNS_UPDATED ()
	   RETURNS sys.VARBINARY AS 'babelfishpg_tsql', 'columnsupdated' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION UPDATE (TEXT)
	   RETURNS BOOLEAN AS 'babelfishpg_tsql', 'updated' LANGUAGE C STABLE;

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
-- below column is added in order to join information_schema.columns of PG for sys.sp_columns_100_view
PG_TYPE_NAME VARCHAR(20)
);
GRANT SELECT ON sys.spt_datatype_info_table TO PUBLIC;

INSERT INTO sys.spt_datatype_info_table VALUES (N'datetimeoffset', -155, 34, N'''', N'''', N'scale               ', 1, 0, 3, NULL, 0, NULL, N'datetimeoffset', 0, 7, -155, 0, NULL, NULL, 0, 68, 0, 'datetimeoffset');
INSERT INTO sys.spt_datatype_info_table VALUES (N'time', -154, 16, N'''', N'''', N'scale               ', 1, 0, 3, NULL, 0, NULL, N'time', 0, 7, -154, 0, NULL, NULL, 0, 32, 0, 'time');
INSERT INTO sys.spt_datatype_info_table VALUES (N'xml', -152, 0, N'N''', N'''', NULL, 1, 1, 0, NULL, 0, NULL, N'xml', NULL, NULL, -152, NULL, NULL, NULL, 0, 2147483646, 0, N'xml');
INSERT INTO sys.spt_datatype_info_table VALUES (N'geometry', -151, 0, NULL, NULL, NULL, 1, 1, 0, NULL, 0, NULL, N'geometry', NULL, NULL, -151, NULL, NULL, NULL, 0, 2147483646, 23, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'geography', -151, 0, NULL, NULL, NULL, 1, 1, 0, NULL, 0, NULL, N'geography', NULL, NULL, -151, NULL, NULL, NULL, 0, 2147483646, 23, NULL);
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
    WHEN 'decimal' THEN radix = 10;
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
  WHEN type IN ('geometry', 'geography') THEN length = -1;
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
     JOIN information_schema_tsql.columns_internal t4 ON (t1.oid = t4."TABLE_OID")
     LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname::sys.nvarchar(128) = t4."COLUMN_NAME"
     LEFT JOIN pg_type t ON t.oid = a.atttypid
     LEFT JOIN sys.columns t6 ON
     (
      t1.oid = t6.object_id AND
      t4."ORDINAL_POSITION" = t6.column_id
     )
     , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
     , sys.spt_datatype_info_table AS t5
  WHERE (t4."DATA_TYPE" = CAST(t5.TYPE_NAME AS sys.nvarchar(128)) OR (t4."DATA_TYPE" = 'bytea' AND t5.TYPE_NAME = 'image'))
    AND ext.dbid = sys.db_id();

GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

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
	IF @fusepattern = 1 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
		where pg_catalog.lower(table_name) like pg_catalog.lower(sys.babelfish_truncate_identifier(@table_name)) COLLATE database_default
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_owner),'')) = '' or table_owner like sys.babelfish_truncate_identifier(@table_owner) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_qualifier),'')) = '' or table_qualifier like sys.babelfish_truncate_identifier(@table_qualifier) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@column_name),'')) = '' or column_name like sys.babelfish_truncate_identifier(@column_name) collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
	ELSE 
		select table_qualifier, precision from sys.sp_columns_100_view
			where sys.babelfish_truncate_identifier(@table_name) = table_name collate database_default
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_owner), '')) = '' or table_owner = sys.babelfish_truncate_identifier(@table_owner) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_qualifier),'')) = '' or table_qualifier = sys.babelfish_truncate_identifier(@table_qualifier) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@column_name),'')) = '' or column_name = sys.babelfish_truncate_identifier(@column_name) collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
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
	IF @fusepattern = 1 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			ss_is_sparse as SS_IS_SPARSE,
			ss_is_column_set as SS_IS_COLUMN_SET,
			ss_is_computed as SS_IS_COMPUTED,
			ss_is_identity as SS_IS_IDENTITY,
			ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
			ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
			ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
			ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
			ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
			ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
		-- TODO: Temporary fix to use \ as escape character for now, need to remove ESCAPE clause from LIKE once we have fixed the dependencies on this procedure
		where pg_catalog.lower(table_name) like pg_catalog.lower(sys.babelfish_truncate_identifier(@table_name)) COLLATE database_default ESCAPE '\' -- '  adding quote in comment to suppress build warning
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_owner),'')) = '' or table_owner like sys.babelfish_truncate_identifier(@table_owner) collate database_default ESCAPE '\') -- '  adding quote in comment to suppress build warning
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_qualifier),'')) = '' or table_qualifier like sys.babelfish_truncate_identifier(@table_qualifier) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@column_name),'')) = '' or column_name like sys.babelfish_truncate_identifier(@column_name) collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
	ELSE 
		select table_qualifier, precision from sys.sp_columns_100_view
			where sys.babelfish_truncate_identifier(@table_name) = table_name collate database_default
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_owner), '')) = '' or table_owner = sys.babelfish_truncate_identifier(@table_owner) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@table_qualifier),'')) = '' or table_qualifier = sys.babelfish_truncate_identifier(@table_qualifier) collate database_default)
			and ((SELECT coalesce(sys.babelfish_truncate_identifier(@column_name),'')) = '' or column_name = sys.babelfish_truncate_identifier(@column_name) collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
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
		WHEN 'text' COLLATE sys.database_default THEN tds_id = 35;
		WHEN 'uniqueidentifier' COLLATE sys.database_default THEN tds_id = 36;
		WHEN 'tinyint' COLLATE sys.database_default THEN tds_id = 38;
		WHEN 'smallint' COLLATE sys.database_default THEN tds_id = 38;
		WHEN 'int' COLLATE sys.database_default THEN tds_id = 38;
		WHEN 'bigint' COLLATE sys.database_default THEN tds_id = 38;
		WHEN 'ntext' COLLATE sys.database_default THEN tds_id = 99;
		WHEN 'bit' COLLATE sys.database_default THEN tds_id = 104;
		WHEN 'float' COLLATE sys.database_default THEN tds_id = 109;
		WHEN 'real' COLLATE sys.database_default THEN tds_id = 109;
		WHEN 'varchar' COLLATE sys.database_default THEN tds_id = 167;
		WHEN 'nvarchar' COLLATE sys.database_default THEN tds_id = 231;
		WHEN 'nchar' COLLATE sys.database_default THEN tds_id = 239;
		WHEN 'money' COLLATE sys.database_default THEN tds_id = 110;
		WHEN 'smallmoney' COLLATE sys.database_default THEN tds_id = 110;
		WHEN 'char' COLLATE sys.database_default THEN tds_id = 175;
		WHEN 'date' COLLATE sys.database_default THEN tds_id = 40;
		WHEN 'datetime' COLLATE sys.database_default THEN tds_id = 111;
		WHEN 'smalldatetime' COLLATE sys.database_default THEN tds_id = 111;
		WHEN 'numeric' COLLATE sys.database_default THEN tds_id = 108;
		WHEN 'xml' COLLATE sys.database_default THEN tds_id = 241;
		WHEN 'decimal' COLLATE sys.database_default THEN tds_id = 106;
		WHEN 'varbinary' COLLATE sys.database_default THEN tds_id = 165;
		WHEN 'binary' COLLATE sys.database_default THEN tds_id = 173;
		WHEN 'image' COLLATE sys.database_default THEN tds_id = 34;
		WHEN 'time' COLLATE sys.database_default THEN tds_id = 41;
		WHEN 'datetime2' COLLATE sys.database_default THEN tds_id = 42;
		WHEN 'sql_variant' COLLATE sys.database_default THEN tds_id = 98;
		WHEN 'datetimeoffset' COLLATE sys.database_default THEN tds_id = 43;
		WHEN 'timestamp' COLLATE sys.database_default THEN tds_id = 173;
		WHEN 'vector' COLLATE sys.database_default THEN tds_id = 167; -- Same as varchar 
		WHEN 'sparsevec' COLLATE sys.database_default THEN tds_id = 167; -- Same as varchar 
		WHEN 'halfvec' COLLATE sys.database_default THEN tds_id = 167; -- Same as varchar 
		WHEN 'geometry' COLLATE sys.database_default THEN tds_id = 240;
		WHEN 'geography' COLLATE sys.database_default THEN tds_id = 240;
		ELSE tds_id = 0;
	END CASE;
	RETURN tds_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

create or replace function sys.sp_describe_first_result_set_internal(
	tsqlquery sys.nvarchar(8000),
    params sys.nvarchar(8000) = NULL, 
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
	"@tsql" sys.nvarchar(8000),
    "@params" sys.nvarchar(8000) = NULL, 
    "@browse_information_mode" sys.tinyint = 0)
AS $$
BEGIN
	select * from sys.sp_describe_first_result_set_internal(@tsql, @params,  @browse_information_mode) order by column_ordinal;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_first_result_set TO PUBLIC;

CREATE OR REPLACE VIEW sys.spt_tablecollations_view AS
    SELECT
        c.object_id                      AS object_id,
        CAST(p.relnamespace AS int)      AS schema_id,
        c.column_id                      AS colid,
        CAST(c.name AS sys.varchar)      AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c
        INNER JOIN pg_catalog.pg_class p ON (c.object_id = p.oid)
    WHERE
        c.is_sparse = 0;
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
        s_tcv.object_id = (SELECT sys.object_id(@object))
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
    LEFT JOIN information_schema_tsql.columns_internal isc ON
        (
            o.object_id = isc."TABLE_OID" AND
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
language plpgsql STABLE;

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
WHERE t1.relnamespace = t3.schema_id AND t1.relnamespace = t2.oid AND t1.relkind IN ('r','p','v','m') 
AND t1.relispartition = false
AND has_table_privilege(t1.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.sp_tables_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_tables (
    "@table_name" sys.nvarchar(384) = NULL,
    "@table_owner" sys.nvarchar(384) = NULL, 
    "@table_qualifier" sys.sysname = NULL,
    "@table_type" sys.nvarchar(100) = NULL,
    "@fusepattern" sys.bit = '1')
AS $$
BEGIN

	-- Temporary variable to hold the current database name
	DECLARE @current_db_name sys.sysname;

	-- Handle special case: Enumerate all databases when name and owner are blank but qualifier is '%'
	IF (@table_qualifier = '%' AND @table_owner = '' AND @table_name = '')
	BEGIN
		SELECT
			d.name AS TABLE_QUALIFIER,
			CAST(NULL AS sys.sysname) AS TABLE_OWNER,
			CAST(NULL AS sys.sysname) AS TABLE_NAME,
			CAST(NULL AS sys.varchar(32)) AS TABLE_TYPE,
			CAST(NULL AS sys.varchar(254)) AS REMARKS
		FROM sys.databases d ORDER BY TABLE_QUALIFIER;
		
		RETURN;
	END;

	SELECT @current_db_name = sys.db_name();

	IF (@table_qualifier != '' AND LOWER(@table_qualifier) != LOWER(@current_db_name))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	IF (@fusepattern = 1)
		SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			remarks AS REMARKS
		FROM sys.sp_tables_view 
		WHERE (@table_name IS NULL OR table_name LIKE @table_name collate database_default)
		AND (@table_owner IS NULL OR table_owner LIKE @table_owner collate database_default)
		AND (@table_qualifier IS NULL OR table_qualifier LIKE @table_qualifier collate database_default)
		AND (
			@table_type IS NULL OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''TABLE''%' collate database_default AND table_type = 'TABLE' collate database_default) OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''VIEW''%' collate database_default AND table_type = 'VIEW' collate database_default)
		)
		ORDER BY TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME;
	ELSE
		SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			remarks AS REMARKS
		FROM sys.sp_tables_view
		WHERE (@table_name IS NULL OR table_name = @table_name collate database_default)
		AND (@table_owner IS NULL OR table_owner = @table_owner collate database_default)
		AND (@table_qualifier IS NULL OR table_qualifier = @table_qualifier collate database_default)
		AND (
			@table_type IS NULL OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''TABLE''%' collate database_default AND table_type = 'TABLE' collate database_default) OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''VIEW''%' collate database_default AND table_type = 'VIEW' collate database_default)
		)
		ORDER BY TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME;
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_tables TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.fn_mapped_system_error_list ()
returns table (pg_sql_state sys.nvarchar(5), error_message sys.nvarchar(4000), error_msg_parameters sys.nvarchar(4000), sql_error_code int)
AS 'babelfishpg_tsql', 'babel_list_mapped_error'
LANGUAGE C IMMUTABLE STRICT;
GRANT ALL on FUNCTION sys.fn_mapped_system_error_list TO PUBLIC;

-- BABEL-2259: Support sp_databases System Stored Procedure
-- Lists databases that either reside in an instance of the SQL Server or
-- are accessible through a database gateway
DROP VIEW IF EXISTS sys.sp_databases_view CASCADE;

CREATE VIEW sys.sp_databases_view AS
	SELECT CAST(database_name AS sys.SYSNAME),
	-- DATABASE_SIZE returns a NULL value for databases larger than 2.15 TB
	CASE WHEN (sum(table_size)::NUMERIC/1024.0) > 2.15 * 1024.0 * 1024.0 * 1024.0 THEN NULL
		ELSE CAST((sum(table_size)::NUMERIC/1024.0) AS int) END as database_size,
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
		LEFT JOIN pg_catalog.pg_class ON relnamespace = pg_catalog.pg_namespace.oid where pg_catalog.pg_class.relkind = 'r'
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
CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
	JOIN information_schema_tsql.columns_internal t4 ON (t1.oid = t4."TABLE_OID")
	JOIN pg_constraint t5 ON t1.oid = t5.conrelid
	, generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
	AND CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.conkey)
	AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.conkey[seq]
  AND ext.dbid = sys.db_id();

GRANT SELECT on sys.sp_pkeys_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = 'dbo',
	"@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
	select * from sys.sp_pkeys_view
	where table_name = @table_name
		and table_owner = coalesce(@table_owner, 'dbo') 
		and ((SELECT
		         coalesce(@table_qualifier, '')) = '' or
		         table_qualifier = @table_qualifier )
	order by table_qualifier,
	         table_owner,
		 table_name,
		 key_seq;
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

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
    JOIN information_schema_tsql.columns_internal t3 ON (t1.oid = t3."TABLE_OID")
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
    JOIN information_schema_tsql.columns_internal t4 ON (t1.oid = t4."TABLE_OID")
	JOIN (pg_catalog.pg_index t5 JOIN
		pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
	JOIN pg_catalog.pg_namespace nsp ON (t1.relnamespace = nsp.oid)
	LEFT JOIN pg_catalog.pg_stats t7 ON (t1.relname = t7.tablename AND t7.schemaname = nsp.nspname)
	LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.indkey)
    AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.indkey[seq];
GRANT SELECT on sys.sp_statistics_view TO PUBLIC;

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
	select * from sys.sp_statistics_view
	where @table_name = table_name
		and ((SELECT coalesce(@table_owner,'')) = '' or table_owner = @table_owner )
		and ((SELECT coalesce(@table_qualifier,'')) = '' or table_qualifier = @table_qualifier )
		and ((SELECT coalesce(@index_name,'')) = '' or index_name like @index_name )
		and ((UPPER(@is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (UPPER(@is_unique) = 'N'))
	order by non_unique, type, index_name, seq_in_index;
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
	select * from sys.sp_statistics_view
	where @table_name = table_name
		and ((SELECT coalesce(@table_owner,'')) = '' or table_owner = @table_owner )
		and ((SELECT coalesce(@table_qualifier,'')) = '' or table_qualifier = @table_qualifier )
		and ((SELECT coalesce(@index_name,'')) = '' or index_name like @index_name )
		and ((UPPER(@is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (UPPER(@is_unique) = 'N'))
	order by non_unique, type, index_name, seq_in_index;
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

  IF pg_catalog.lower("@resample") = 'resample' THEN
    RAISE NOTICE 'ignoring resample option';
  ELSIF pg_catalog.lower("@resample") != 'no' THEN
    RAISE EXCEPTION 'Invalid option name %', "@resample";
  END IF;

  ANALYZE;

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
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantor::name) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantee::name) AS sys.sysname) AS GRANTEE,
CAST(t5.privilege_type AS sys.varchar(32)) COLLATE sys.database_default AS PRIVILEGE,
CAST(t5.is_grantable AS sys.varchar(3)) COLLATE sys.database_default AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.column_privileges t5 ON t1.relname = t5.table_name AND t2.nspname = t5.table_schema
	JOIN pg_attribute t6 ON t6.attrelid = t1.oid AND t6.attname = t5.column_name
	JOIN sys.babelfish_authid_user_ext ext ON ext.rolname = t5.grantee
WHERE ext.orig_username NOT IN ('db_datawriter', 'db_datareader');
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
CAST(TABLE_QUALIFIER AS sys.sysname) COLLATE sys.database_default AS TABLE_QUALIFIER,
CAST(TABLE_OWNER AS sys.sysname) AS TABLE_OWNER,
CAST(TABLE_NAME AS sys.sysname) COLLATE sys.database_default AS TABLE_NAME,
CAST(GRANTOR AS sys.sysname) AS GRANTOR,
CAST(GRANTEE AS sys.sysname) AS GRANTEE,
CAST(PRIVILEGE AS sys.sysname) COLLATE sys.database_default AS PRIVILEGE,
CAST(IS_GRANTABLE AS sys.sysname) COLLATE sys.database_default AS IS_GRANTABLE
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
	JOIN sys.babelfish_authid_user_ext ext ON ext.rolname = t4.grantee
WHERE t4.privilege_type = 'DELETE' AND ext.orig_username != 'db_datawriter';
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
		WHEN type COLLATE sys.database_default in ('real','float') THEN sp_columns_max_length * 2 - 1
		WHEN type COLLATE sys.database_default in ('char','varchar','binary','varbinary') THEN sp_columns_max_length
		WHEN type COLLATE sys.database_default in ('nchar','nvarchar') THEN sp_columns_max_length / 2
		WHEN type COLLATE sys.database_default in ('sysname','uniqueidentifier') THEN sp_datatype_info_precision
		ELSE sp_columns_precision
	END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_length_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
	CASE
		WHEN type COLLATE sys.database_default in ('decimal','numeric','money','smallmoney') THEN sp_columns_precision + 2
		WHEN type COLLATE sys.database_default in ('time','date','datetime2','datetimeoffset') THEN sp_columns_precision * 2
		WHEN type COLLATE sys.database_default in ('smalldatetime') THEN sp_columns_precision
		WHEN type COLLATE sys.database_default in ('datetime') THEN sp_columns_max_length * 2
		WHEN type COLLATE sys.database_default in ('sql_variant') THEN sp_datatype_info_precision
		ELSE sp_columns_max_length
	END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_scale_helper(IN type TEXT, IN sp_columns_scale INT) RETURNS INT
AS $$
SELECT
	CASE
		WHEN type COLLATE sys.database_default in ('bit','real','float','char','varchar','nchar','nvarchar','time','date','datetime2','datetimeoffset','varbinary','binary','sql_variant','sysname','uniqueidentifier') THEN NULL
		ELSE sp_columns_scale
	END;
$$ LANGUAGE SQL IMMUTABLE;

-- TODO: BABEL-2838
CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT
CAST(1 AS SMALLINT) AS SCOPE,
CAST(coalesce (split_part(a.attoptions[1] COLLATE "C", '=', 2) ,a.attname) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS SMALLINT) AS DATA_TYPE,

CASE -- cases for when they are of type identity. 
	WHEN  a.attidentity <> ''::"char" AND (t1.name = 'decimal' OR t1.name = 'numeric')
	THEN CAST(PG_CATALOG.CONCAT(t1.name, '() identity') AS sys.sysname)
	WHEN  a.attidentity <> ''::"char" AND (t1.name != 'decimal' AND t1.name != 'numeric')
	THEN CAST(PG_CATALOG.CONCAT(t1.name, ' identity') AS sys.sysname)
	ELSE CAST(t1.name AS sys.sysname)
END AS TYPE_NAME,

CAST(sys.sp_special_columns_precision_helper(COALESCE(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS INT) AS PRECISION,
CAST(sys.sp_special_columns_length_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS INT) AS LENGTH,
CAST(sys.sp_special_columns_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.scale) AS SMALLINT) AS SCALE,
CAST(1 AS smallint) AS PSEUDO_COLUMN,
CASE
	WHEN a.attnotnull
	THEN CAST(0 AS INT)
	ELSE CAST(1 AS INT) END
AS IS_NULLABLE,
CAST(nsp_ext.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(C.relname AS sys.sysname) AS TABLE_NAME,

CASE 
	WHEN X.indisprimary
	THEN CAST('p' AS sys.sysname)
	ELSE CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
END AS CONSTRAINT_TYPE,
CAST(I.relname AS sys.sysname) CONSTRAINT_NAME,
CAST(X.indexrelid AS int) AS INDEX_ID

FROM( pg_index X
JOIN pg_class C ON X.indrelid = C.oid
JOIN pg_class I ON I.oid = X.indexrelid
CROSS JOIN LATERAL unnest(X.indkey) AS ak(k)
        LEFT JOIN pg_attribute a
                       ON (a.attrelid = X.indrelid AND a.attnum = ak.k)
)
LEFT JOIN sys.pg_namespace_ext nsp_ext ON C.relnamespace = nsp_ext.oid
LEFT JOIN sys.schemas s1 ON s1.schema_id = C.relnamespace
LEFT JOIN sys.columns c1 ON c1.object_id = X.indrelid AND cast(a.attname AS sys.sysname) = c1.name COLLATE sys.database_default
LEFT JOIN pg_catalog.pg_type AS T ON T.oid = c1.system_type_id
LEFT JOIN sys.types AS t1 ON a.atttypid = t1.user_type_id
LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON T.typname = t6.pg_type_name OR T.typname = t6.type_name --need in order to get accurate DATA_TYPE value
, sys.translate_pg_type_to_tsql(t1.user_type_id) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t1.system_type_id) AS tsql_base_type_name
WHERE X.indislive ;

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
CAST(nsp_ext2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST(bbf_nsp2.orig_name AS sys.sysname) AS PKTABLE_OWNER ,
CAST(c2.relname AS sys.sysname) AS PKTABLE_NAME,
CAST(COALESCE(split_part(a2.attoptions[1] COLLATE "C", '=', 2),a2.attname) AS sys.sysname) AS PKCOLUMN_NAME,
CAST(nsp_ext.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST(bbf_nsp.orig_name AS sys.sysname) AS FKTABLE_OWNER ,
CAST(c.relname AS sys.sysname) AS FKTABLE_NAME,
CAST(COALESCE(split_part(a.attoptions[1] COLLATE "C", '=', 2),a.attname) AS sys.sysname) AS FKCOLUMN_NAME,
CAST(nr AS smallint) AS KEY_SEQ,
CASE
   WHEN const1.confupdtype = 'c' THEN CAST(0 AS smallint) -- cascade
   WHEN const1.confupdtype = 'a' THEN CAST(1 AS smallint) -- no action
   WHEN const1.confupdtype = 'n' THEN CAST(2 AS smallint) -- set null
   WHEN const1.confupdtype = 'd' THEN CAST(3 AS smallint) -- set default
END AS UPDATE_RULE,

CASE
   WHEN const1.confdeltype = 'c' THEN CAST(0 AS smallint) -- cascade
   WHEN const1.confdeltype = 'a' THEN CAST(1 AS smallint) -- no action
   WHEN const1.confdeltype = 'n' THEN CAST(2 AS smallint) -- set null
   WHEN const1.confdeltype = 'd' THEN CAST(3 AS smallint) -- set default
   ELSE CAST(0 AS smallint)
END AS DELETE_RULE,
CAST(const1.conname AS sys.sysname) AS FK_NAME,
CAST(const2.conname AS sys.sysname) AS PK_NAME,
CASE
   WHEN const1.condeferrable = false THEN CAST(7 as smallint) -- not deferrable
   ELSE (CASE WHEN const1.condeferred = false THEN CAST(6 as smallint) --  not deferred by default
              ELSE CAST(5 as smallint) -- deferred by default
         END)
END AS DEFERRABILITY

FROM (pg_constraint const1
-- join with nsp_Ext to get constraints in current namespace
JOIN sys.pg_namespace_ext nsp_ext ON nsp_ext.oid = const1.connamespace
--get the table names corresponding to foreign keys
JOIN pg_class c ON const1.conrelid = c.oid AND const1.contype ='f'
-- join wiht bbf_nsp to get all constraint related to tsql endpoint and the owner of foreign key
JOIN sys.babelfish_namespace_ext bbf_nsp ON bbf_nsp.nspname = nsp_ext.nspname AND bbf_nsp.dbid = sys.db_id()
-- lateral join to use the conkey and confkey to join with pg_attribute to get column names
CROSS JOIN LATERAL unnest(const1.conkey,const1.confkey) WITH ORDINALITY AS ak(j, k, nr)
            LEFT JOIN pg_attribute a
                       ON (a.attrelid = const1.conrelid AND a.attnum = ak.j)
            LEFT JOIN pg_attribute a2
                       ON (a2.attrelid = const1.confrelid AND a2.attnum = ak.k)
)
-- get the index that foreign key depends on
LEFT JOIN pg_depend d1 ON d1.objid = const1.oid AND d1.classid = 'pg_constraint'::regclass
           AND d1.refclassid = 'pg_class'::regclass AND d1.refobjsubid = 0
-- get the pkey/ukey constraint for this index
LEFT JOIN pg_depend d2 ON d2.refclassid = 'pg_constraint'::regclass AND d2.classid = 'pg_class'::regclass AND d2.objid = d1.refobjid AND d2.objsubid = 0 AND d2.deptype = 'i'
-- get the constraint name from new pg_constraint
LEFT JOIN pg_constraint const2 ON const2.oid = d2.refobjid AND const2.contype IN ('p', 'u') AND const2.conrelid = const1.confrelid
-- get the namespace name for primary key
LEFT JOIN sys.pg_namespace_ext nsp_ext2 ON const2.connamespace = nsp_ext2.oid
-- get the owner name for primary key
LEFT JOIN sys.babelfish_namespace_ext bbf_nsp2 ON bbf_nsp2.nspname = nsp_ext2.nspname AND bbf_nsp2.dbid = sys.db_id()
-- get the table name for primary key
LEFT JOIN pg_class c2 ON const2.conrelid = c2.oid AND const2.contype IN ('p', 'u');

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
	PK_NAME,
	DEFERRABILITY
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
CAST(d.name AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS PROCEDURE_OWNER, 

CASE 
	WHEN p.prokind = 'p' THEN CAST(PG_CATALOG.concat(p.proname, ';1') AS sys.nvarchar(134))
	ELSE CAST(PG_CATALOG.concat(p.proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) COLLATE sys.database_default AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM pg_catalog.pg_proc p 

INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id 
INNER JOIN sys.databases d ON d.database_id = sys.db_id()

UNION 

SELECT CAST((SELECT sys.db_name()) AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
CAST(nspname AS sys.sysname) AS PROCEDURE_OWNER,

CASE 
	WHEN prokind = 'p' THEN cast(PG_CATALOG.concat(proname, ';1') AS sys.nvarchar(134))
	ELSE cast(PG_CATALOG.concat(proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) COLLATE sys.database_default AS REMARKS,
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
					WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
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
				WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = 'sys')
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			ELSE IF EXISTS ( 
				SELECT * FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
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
				WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
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
				WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
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
			WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
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
			WHERE ((SELECT COALESCE(@sp_name,'')) = '' OR LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) LIKE LOWER(@sp_name))
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

	login_valid = (login = suser_name() COLLATE sys.database_default) OR 
		(EXISTS (SELECT name
	 			FROM sys.server_principals
		 	 	WHERE 
				LOWER(name) = login COLLATE sys.database_default
				AND type IN ('S', 'R')));
 	
 	IF NOT login_valid THEN
 		RETURN NULL;
    
    ELSIF role = 'public' COLLATE sys.database_default THEN
    	RETURN 1;
	
 	ELSIF role COLLATE sys.database_default IN ('sysadmin', 'securityadmin', 'dbcreator') THEN
	  	has_role = (pg_has_role(login::TEXT, role::TEXT, 'MEMBER')
				OR ((login COLLATE sys.database_default NOT IN ('sysadmin', 'securityadmin', 'dbcreator'))
					AND pg_has_role(login::TEXT, 'sysadmin'::TEXT, 'MEMBER')));
	    IF has_role THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	
    ELSIF role COLLATE sys.database_default IN (
            'serveradmin',
            'setupadmin',
            'processadmin',
            'diskadmin',
            'bulkadmin') THEN 
    	RETURN 0;
 	
    ELSE
 		  RETURN NULL;
 	END IF;
	
 	EXCEPTION WHEN OTHERS THEN
	 	  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

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
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname COLLATE database_default
					ELSE LogExt.orig_loginname END
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
		AND (Ext1.type != 'R' OR Ext1.type != 'A')
		AND Ext1.orig_username NOT IN ('db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin')
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
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@name_in_db))
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
		AND Ext2.orig_username NOT IN ('db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin')
		AND (Ext1.orig_username = @name_in_db OR pg_catalog.lower(Ext1.orig_username) = pg_catalog.lower(@name_in_db))
		ORDER BY Role_name, Users_in_role;
	END
	-- If the security account is a user
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @name_in_db
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@name_in_db))
					AND database_name = DB_NAME()
					AND type != 'R')
	BEGIN
		SELECT DISTINCT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner' 
					WHEN Ext2.orig_username IS NULL THEN 'public' 
					ELSE Ext2.orig_username END 
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname COLLATE database_default
					ELSE LogExt.orig_loginname END
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
		AND (Ext1.type != 'R' OR Ext1.type != 'A')
		AND Ext1.orig_username NOT IN ('db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin')
		AND (Ext1.orig_username = @name_in_db OR pg_catalog.lower(Ext1.orig_username) = pg_catalog.lower(@name_in_db))
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
		WHERE Ext1.type = 'R' AND Ext2.type != 'Z'
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
					'serveradmin', 'setupadmin', 'processadmin',
					'diskadmin', 'bulkadmin')
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R' AND Ext2.type != 'Z'
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

CREATE OR REPLACE PROCEDURE sys.sp_helpdbfixedrole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- Returns a list of the fixed database roles. 
	IF LOWER(RTRIM(@rolename)) IS NULL OR LOWER(RTRIM(@rolename)) IN ('db_owner', 'db_accessadmin', 'db_securityadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin')
	BEGIN
		SELECT CAST(DbFixedRole as sys.SYSNAME) AS DbFixedRole, CAST(Description AS sys.nvarchar(70)) AS Description FROM (
			VALUES ('db_owner', 'DB Owners'),
			('db_accessadmin', 'DB Access Administrators'),
			('db_securityadmin', 'DB Security Administrators'),
			('db_datareader', 'DB Data Reader'),
			('db_datawriter', 'DB Data Writer'),
			('db_ddladmin', 'DB DDL Administrators')) x(DbFixedRole, Description)
			WHERE LOWER(RTRIM(@rolename)) IS NULL OR LOWER(RTRIM(@rolename)) = DbFixedRole;
	END
	ELSE IF LOWER(RTRIM(@rolename)) IN (
			'db_backupoperator', 'db_denydatareader', 'db_denydatawriter')
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


CREATE OR REPLACE PROCEDURE sys.sp_set_session_context ("@key" sys.NVARCHAR(128), 
	"@value" sys.SQL_VARIANT, "@read_only" sys.bit = 0)
AS 'babelfishpg_tsql', 'sp_set_session_context'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_set_session_context TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.session_context ("@key" sys.NVARCHAR(128))
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_tsql', 'session_context'
LANGUAGE C;
GRANT EXECUTE ON FUNCTION sys.session_context TO PUBLIC;

-- SYSLOGINS
CREATE OR REPLACE VIEW sys.syslogins
AS SELECT 
Base.sid AS sid,
CAST(9 AS SYS.TINYINT) AS status,
Base.create_date AS createdate,
Base.modify_date AS updatedate,
Base.create_date AS accdate,
CAST(0 AS INT) AS totcpu,
CAST(0 AS INT) AS totio,
CAST(0 AS INT) AS spacelimit,
CAST(0 AS INT) AS timelimit,
CAST(0 AS INT) AS resultlimit,
Base.name AS name,
Base.default_database_name AS dbname,
Base.default_language_name AS default_language_name,
CAST(Base.name AS SYS.NVARCHAR(128)) AS loginname,
CAST(NULL AS SYS.NVARCHAR(128)) AS password,
CAST(0 AS INT) AS denylogin,
CAST(1 AS INT) AS hasaccess,
CAST( 
  CASE 
    WHEN Base.type_desc = 'WINDOWS_LOGIN' OR Base.type_desc = 'WINDOWS_GROUP' THEN 1 
    ELSE 0
  END
AS INT) AS isntname,
CAST(
   CASE 
    WHEN Base.type_desc = 'WINDOWS_GROUP' THEN 1 
    ELSE 0
  END
  AS INT) AS isntgroup,
CAST(
  CASE 
    WHEN Base.type_desc = 'WINDOWS_LOGIN' THEN 1 
    ELSE 0
  END
AS INT) AS isntuser,
CAST(
    CASE
        WHEN is_srvrolemember('sysadmin', Base.name) = 1 THEN 1
        ELSE 0
    END
AS INT) AS sysadmin,
CAST(
    CASE
        WHEN is_srvrolemember('securityadmin', Base.name) = 1 THEN 1
        ELSE 0
    END
AS INT) AS securityadmin,
CAST(0 AS INT) AS serveradmin,
CAST(0 AS INT) AS setupadmin,
CAST(0 AS INT) AS processadmin,
CAST(0 AS INT) AS diskadmin,
CAST(
    CASE
        WHEN is_srvrolemember('dbcreator', Base.name) = 1 THEN 1
        ELSE 0
    END
AS INT) AS dbcreator,
CAST(0 AS INT) AS bulkadmin
FROM sys.server_principals AS Base
WHERE Base.type in ('S', 'U');

GRANT SELECT ON sys.syslogins TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_sproc_columns_view
AS
SELECT
CAST(sys.db_name() AS sys.sysname) AS PROCEDURE_QUALIFIER -- This will always be objects in current database
, CAST(ss.schema_name AS sys.sysname) AS PROCEDURE_OWNER
, CAST(
CASE
  WHEN ss.prokind = 'p' THEN PG_CATALOG.CONCAT(ss.proname, ';1')
  ELSE PG_CATALOG.CONCAT(ss.proname, ';0')
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
AS sys.varchar(254)) COLLATE sys.database_default AS REMARKS
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
AS sys.varchar(254)) COLLATE sys.database_default AS IS_NULLABLE
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
LEFT JOIN sys.types st ON ss.x = st.user_type_id -- left joined because return type of table-valued functions may not have an entry in sys.types
-- Because spt_datatype_info_table does contain user-defind types and their names,
-- the join below allows us to retrieve the name of the base type of the user-defined type
LEFT JOIN sys.spt_datatype_info_table sdit ON sdit.type_name = sys.translate_pg_type_to_tsql(st.system_type_id);
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
	SELECT @column_name = LOWER(COALESCE(@column_name, ''))
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
				AND (@column_name = '' OR column_name LIKE @column_name)
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

CREATE OR REPLACE PROCEDURE sys.sp_helplinkedsrvlogin(
	IN "@rmtsrvname" sysname DEFAULT NULL,
	IN "@locallogin" sysname DEFAULT NULL
)
AS $$
DECLARE @server_id INT;
DECLARE @local_principal_id INT;
BEGIN
	IF @rmtsrvname IS NOT NULL
		BEGIN
			SELECT @server_id = server_id FROM sys.servers WHERE name = @rmtsrvname;

			IF @server_id IS NULL
				BEGIN
					RAISERROR('The server ''%s'' does not exist', 16, 1, @rmtsrvname);
					RETURN 1;
				END
		END

	IF @locallogin IS NOT NULL
		BEGIN
			SELECT @local_principal_id = usesysid FROM pg_user WHERE CAST(usename as sys.sysname) = @locallogin;
		END
	
	SELECT
		s.name AS "Linked Server",
		CAST(u.usename as sys.sysname) AS "Local Login", 
		CAST(0 as smallint) AS "Is Self Mapping", 
		l.remote_name AS "Remote Login"
	FROM sys.linked_logins AS l 
	LEFT JOIN sys.servers AS s ON l.server_id = s.server_id
	LEFT JOIN pg_user AS u ON l.local_principal_id = u.usesysid
	WHERE (@server_id is NULL or @server_id = s.server_id) AND ((@local_principal_id is NULL AND @locallogin IS NULL) or @local_principal_id = l.local_principal_id);
END;
$$ LANGUAGE pltsql;
GRANT EXECUTE ON PROCEDURE sys.sp_helplinkedsrvlogin TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_internal(
	IN "@objname" sys.nvarchar(776),
	IN "@newname" sys.SYSNAME,
	IN "@schemaname" sys.nvarchar(776),
	IN "@objtype" char(2) DEFAULT NULL,
	IN "@curr_relname" sys.nvarchar(776) DEFAULT NULL
) AS 'babelfishpg_tsql', 'sp_rename_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.babelfish_sp_rename_internal TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_word_parse(
	IN "@input" sys.nvarchar(776),
	IN "@objtype" sys.varchar(13),
	INOUT "@subname" sys.nvarchar(776),
	INOUT "@curr_relname" sys.nvarchar(776),
	INOUT "@schemaname" sys.nvarchar(776),
	INOUT "@dbname" sys.nvarchar(776)
)
AS $$
BEGIN
	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row, * 
	INTO #sp_rename_temptable 
	FROM sys.babelfish_split_identifier(@input) ORDER BY row DESC;

	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as id, * 
	INTO #sp_rename_temptable2 
	FROM #sp_rename_temptable;
	
	DECLARE @row_count INT;
	SELECT @row_count = COUNT(*) FROM #sp_rename_temptable2;

	IF @objtype = 'COLUMN'
		BEGIN
			IF @row_count = 1
				BEGIN
					THROW 33557097, N'Either the parameter @objname is ambiguous or the claimed @objtype (COLUMN) is wrong.', 1;
				END
			ELSE IF @row_count > 4
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					IF @row_count > 1
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SELECT @curr_relname = value FROM #sp_rename_temptable2 WHERE id = 2;
							SET @schemaname = sys.schema_name();

						END
					IF @row_count > 2
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 3;
						END
					IF @row_count > 3
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 4;
							IF @dbname != sys.db_name()
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
	ELSE
		BEGIN
			IF @row_count > 3
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					SET @curr_relname = NULL;
					IF @row_count > 0
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SET @schemaname = sys.schema_name();
						END
					IF @row_count > 1
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 2;
						END
					IF @row_count > 2
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 3;
							IF @dbname != sys.db_name()
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.babelfish_sp_rename_word_parse(IN sys.nvarchar(776), IN sys.varchar(13), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776), INOUT sys.nvarchar(776)) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_renamedb(
	IN "@objname" sys.SYSNAME,
	IN "@newname" sys.SYSNAME
)
AS 'babelfishpg_tsql', 'sp_renamedb_internal'
LANGUAGE C;

CREATE OR REPLACE PROCEDURE sys.sp_rename(
	IN "@objname" sys.nvarchar(776) = NULL,
	IN "@newname" sys.SYSNAME = NULL,
	IN "@objtype" sys.varchar(13) DEFAULT NULL
)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET @objtype = TRIM(@objtype);
	If @objtype IS NULL
		BEGIN
			THROW 33557097, N'Please provide @objtype that is supported in Babelfish', 1;
		END
	ELSE IF @objtype = 'INDEX'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Index', 1;
		END
	ELSE IF @objtype = 'STATISTICS'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Statistics', 1;
		END
	ELSE IF @objtype = 'DATABASE'
		BEGIN
			exec sys.sp_renamedb @objname, @newname;
		END
	ELSE
		BEGIN
			DECLARE @subname sys.nvarchar(776);
			DECLARE @schemaname sys.nvarchar(776);
			DECLARE @dbname sys.nvarchar(776);
			DECLARE @curr_relname sys.nvarchar(776);
			
			EXEC sys.babelfish_sp_rename_word_parse @objname, @objtype, @subname OUT, @curr_relname OUT, @schemaname OUT, @dbname OUT;

			DECLARE @currtype char(2);

			IF @objtype = 'COLUMN'
				BEGIN
					DECLARE @col_count INT;
					SELECT @col_count = COUNT(*)FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @curr_relname and COLUMN_NAME = @subname;
					IF @col_count < 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'CO';
				END
			ELSE IF @objtype = 'USERDATATYPE'
				BEGIN
					DECLARE @alias_count INT;
					SELECT @alias_count = COUNT(*) FROM sys.types t1 INNER JOIN sys.schemas s1 ON t1.schema_id = s1.schema_id 
					WHERE s1.name = @schemaname AND t1.name = @subname;
					IF @alias_count > 1
						BEGIN
							THROW 33557097, N'There are multiple objects with the given @objname.', 1;
						END
					IF @alias_count < 1
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'AL';				
				END
			ELSE IF @objtype = 'OBJECT'
				BEGIN
					DECLARE @count INT;
					SELECT type INTO #tempTable FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
					WHERE s1.name = @schemaname AND o1.name = @subname;
					SELECT @count = COUNT(*) FROM #tempTable;

					IF @count < 1
						BEGIN
							-- sys.objects does not show routines which current user cannot execute but
							-- roles like db_ddladmin allow renaming a procedure even though they cannot
							-- execute it, so search again in pg_proc if count is zero
							DROP TABLE #tempTable;
							SELECT CAST(CASE 
											WHEN p.prokind = 'p' THEN 'P'
											WHEN p.prokind = 'a' THEN 'AF'
											WHEN format_type(p.prorettype, NULL) = 'trigger' THEN 'TR'
											ELSE 'FN'
										END as sys.bpchar(2)) AS type INTO #tempTable
							FROM pg_proc p INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id
							WHERE s1.name = @schemaname AND CAST(p.proname AS sys.sysname) = @subname;
							SELECT @count = COUNT(*) FROM #tempTable;
						END
					IF @count > 1
						BEGIN
							THROW 33557097, N'There are multiple objects with the given @objname.', 1;
						END
					IF @count < 1
						BEGIN
							-- TABLE TYPE: check if there is a match in sys.table_types (if we cannot alter sys.objects table_type naming)
							SELECT @count = COUNT(*) FROM sys.table_types tt1 INNER JOIN sys.schemas s1 ON tt1.schema_id = s1.schema_id 
							WHERE s1.name = @schemaname AND tt1.name = @subname;
							IF @count > 1
								BEGIN
									THROW 33557097, N'There are multiple objects with the given @objname.', 1;
								END
							ELSE IF @count < 1
								BEGIN
									THROW 33557097, N'There is no object with the given @objname.', 1;
								END
							ELSE
								BEGIN
									SET @currtype = 'TT'
								END
						END
					IF @currtype IS NULL
						BEGIN
							SELECT @currtype = type from #tempTable;
						END
					IF @currtype = 'TR' OR @currtype = 'TA'
						BEGIN
							DECLARE @physical_schema_name sys.nvarchar(776) = '';
							SELECT @physical_schema_name = nspname FROM sys.babelfish_namespace_ext WHERE dbid = sys.db_id() AND orig_name = @schemaname;
							SELECT @curr_relname = relname FROM pg_catalog.pg_trigger tr LEFT JOIN pg_catalog.pg_class c ON tr.tgrelid = c.oid LEFT JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid 
							WHERE tr.tgname = @subname AND n.nspname = @physical_schema_name;
						END
				END
			ELSE
				BEGIN
					THROW 33557097, N'Provided @objtype is not currently supported in Babelfish', 1;
				END
			EXEC sys.babelfish_sp_rename_internal @subname, @newname, @schemaname, @currtype, @curr_relname;
			PRINT 'Caution: Changing any part of an object name could break scripts and stored procedures.';
		END
END;
$$;
GRANT EXECUTE on PROCEDURE sys.sp_rename(IN sys.nvarchar(776), IN sys.SYSNAME, IN sys.varchar(13)) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_linkedservers()
AS $$
BEGIN
    SELECT 
		name AS "SRV_NAME", 
		CAST(provider AS sys.nvarchar(128)) AS "SRV_PROVIDERNAME", 
		CAST(product AS sys.nvarchar(128)) AS "SRV_PRODUCT", 
		data_source AS "SRV_DATASOURCE",
		provider_string AS "SRV_PROVIDERSTRING",
		location AS "SRV_LOCATION",
		catalog AS "SRV_CAT" 
	FROM sys.servers
	ORDER BY SRV_NAME
END;
$$ LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_linkedservers TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.context_info()
RETURNS sys.VARBINARY(128)
AS
$$
BEGIN
    return sys.bbf_get_context_info()
END;
$$
LANGUAGE pltsql STABLE;

-- sp_babelfish_autoformat is a helper procedure which formats the contents of a table (or view)
-- as narrowly as possible given its actual column contents.
-- This proc is currently only used by sp_who but could be applied more generically.
-- A complication is that the metadata for #tmp tables cannot be found in the babelfish
-- catalogs, so we have to use some trickery to make things work.
-- Not all datatypes are handled as well as might be possible, but it is sufficient for 
-- the current purposes.
-- Note that this proc may increase the response time for the first execution of sp_who, but 
-- we are looking at prioritizing user-friendliness (easy-to-read output) here. Also, sp_who 
-- is very unlikely to be part of performance-critical workload.
CREATE OR REPLACE PROCEDURE sys.sp_babelfish_autoformat(
	IN "@tab"        sys.VARCHAR(257) DEFAULT NULL,
	IN "@orderby"    sys.VARCHAR(1000) DEFAULT '',
	IN "@printrc"    sys.bit DEFAULT 1,
	IN "@hiddencols" sys.VARCHAR(1000) DEFAULT NULL)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET NOCOUNT ON
	DECLARE @rc INT
	DECLARE @id INT
	DECLARE @objtype sys.VARCHAR(2)	
	DECLARE @msg sys.VARCHAR(200)	
	
	IF @tab IS NULL
	BEGIN
		RAISERROR('Must specify table name', 16, 1)
		RETURN		
	END
	
	IF TRIM(@tab) = ''
	BEGIN
		RAISERROR('Must specify table name', 16, 1)
		RETURN		
	END	
	
	-- Since we cannot find #tmp tables in the Babelfish catalogs, we cannot check 
	-- their existence other than by trying to select from them
	-- Function sys.babelfish_get_enr_list() could be used to determine if a #tmp table
	-- exists but the columns and datatypes can still not be retrieved, it would be of 
	-- little use here. 
	-- NB: not handling uncommon but valid T-SQL syntax '<schemaname>.#tmp' for #tmp tables
	IF sys.SUBSTRING(@tab,1,1) <> '#'
	BEGIN
		SET @id = sys.OBJECT_ID(@tab)
		IF @id IS NULL
		BEGIN
			IF sys.SUBSTRING(UPPER(@tab),1,4) = 'DBO.'
			BEGIN
				SET @id = sys.OBJECT_ID('SYS.' + sys.SUBSTRING(@tab,5))
			END
			IF @id IS NULL
			BEGIN		
				SET @msg = 'Table or view '''+@tab+''' not found'
				RAISERROR(@msg, 16, 1)
				RETURN		
			END
		END
	END
	
	SELECT @objtype = type COLLATE DATABASE_DEFAULT FROM sys.sysobjects WHERE id = @id 
	IF @objtype NOT IN ('U', 'S', 'V') 
	BEGIN
		SET @msg = ''''+@tab+''' is not a table or view'
		RAISERROR(@msg, 16, 1)
		RETURN		
	END
	
	-- check for 'ORDER BY', if specified
	SET @orderby = TRIM(@orderby)
	IF @orderby <> ''
	BEGIN
		IF UPPER(@orderby) NOT LIKE 'ORDER BY%'
		BEGIN
			RAISERROR('@orderby parameter must start with ''ORDER BY''', 16, 1)
			RETURN
		END
	END
	
	-- columns to hide in final client output
	-- assuming delimited column names do not contain spaces or commas inside the name
	-- remove any spaces around the commas:
	WHILE (sys.CHARINDEX(' ,', @hiddencols) > 0) or (sys.CHARINDEX(', ', @hiddencols) > 0)
	BEGIN
		SET @hiddencols = sys.REPLACE(@hiddencols, ' ,', ',')
		SET @hiddencols = sys.REPLACE(@hiddencols, ', ', ',')
	END
	IF sys.LEN(@hiddencols) IS NOT NULL SET @hiddencols = ',' + @hiddencols + ','
	SET @hiddencols = UPPER(@hiddencols)	

	-- Need to use a guaranteed-uniquely named table as intermediate step since we cannot 
	-- access the metadata in case a #tmp table is passed as argument
	-- But when we copy the #tmp table into another table, we get all the attributes and metadata
	DECLARE @tmptab sys.VARCHAR(63) = 'sp_babelfish_autoformat' + sys.REPLACE(CAST(NEWID() AS sys.NVARCHAR(36)), '-', '')
	DECLARE @tmptab2 sys.VARCHAR(63) = 'sp_babelfish_autoformat' + sys.REPLACE(CAST(NEWID() AS sys.NVARCHAR(36)), '-', '')
	DECLARE @cmd sys.VARCHAR(1000) = 'SELECT * INTO ' + @tmptab + ' FROM ' + @tab
	
	BEGIN TRY
		-- create the first work table
		EXECUTE(@cmd)

		-- Get the columns
		SELECT 
		   c.name AS colname, c.colid AS colid, t.name AS basetype, 0 AS maxlen
		INTO #sp_bbf_autoformat
		FROM sys.syscolumns c left join sys.systypes t 
		ON c.xusertype = t.xusertype		
		WHERE c.id = sys.OBJECT_ID(@tmptab)
		ORDER BY c.colid

		-- Get max length for each column based on the data
		DECLARE @colname sys.VARCHAR(63), @basetype sys.VARCHAR(63), @maxlen int
		DECLARE c CURSOR FOR SELECT colname, basetype, maxlen FROM #sp_bbf_autoformat ORDER BY colid
		OPEN c
		WHILE 1=1
		BEGIN
			FETCH c INTO @colname, @basetype, @maxlen
			IF @@fetch_status <> 0 BREAK
			SET @cmd = 'DECLARE @i INT SELECT @i=ISNULL(MAX(sys.LEN(CAST([' + @colname + '] AS sys.VARCHAR(500)))),4) FROM ' + @tmptab + ' UPDATE #sp_bbf_autoformat SET maxlen = @i WHERE colname = ''' + @colname + ''''
			EXECUTE(@cmd)
		END
		CLOSE c
		DEALLOCATE c

		-- Generate the final SELECT
		DECLARE @selectlist sys.VARCHAR(8000) = ''
		DECLARE @collist sys.VARCHAR(8000) = ''
		DECLARE @fmtstart sys.VARCHAR(30) = ''
		DECLARE @fmtend sys.VARCHAR(30) = ''
		OPEN c
		WHILE 1=1
		BEGIN
			FETCH c INTO @colname, @basetype, @maxlen
			IF @@fetch_status <> 0 BREAK
			IF sys.LEN(@colname) > @maxlen SET @maxlen = sys.LEN(@colname)
			IF @maxlen <= 0 SET @maxlen = 1
			
			IF (sys.CHARINDEX(',' + UPPER(@colname) + ',', @hiddencols) > 0) OR (sys.CHARINDEX(',[' + UPPER(@colname) + '],', @hiddencols) > 0) 
			BEGIN
				SET @selectlist += ' [' + @colname + '],'			
			END
			ELSE 
			BEGIN
				SET @fmtstart = ''
				SET @fmtend = ''
				IF @basetype IN ('tinyint', 'smallint', 'int', 'bigint', 'decimal', 'numeric', 'real', 'float') 
				BEGIN
					SET @fmtstart = 'CAST(right(space('+CAST(@maxlen AS sys.VARCHAR)+')+'
					SET @fmtend = ','+CAST(@maxlen AS sys.VARCHAR)+') AS sys.VARCHAR(' + CAST(@maxlen AS sys.VARCHAR) + '))'
				END

				SET @selectlist += ' '+@fmtstart+'CAST([' + @colname + '] AS sys.VARCHAR(' + CAST(@maxlen AS sys.VARCHAR) + '))'+@fmtend+' AS [' + @colname + '],'
				SET @collist += '['+@colname + '],'
			END
		END
		CLOSE c
		DEALLOCATE c

		-- Remove redundant commas
		SET @collist = sys.SUBSTRING(@collist, 1, sys.LEN(@collist)-1)
		SET @selectlist = sys.SUBSTRING(@selectlist, 1, sys.LEN(@selectlist)-1)	
		SET @selectlist = 'SELECT ' + @selectlist + ' INTO ' + @tmptab2 + ' FROM ' + @tmptab + ' ' + @orderby
		
		-- create the second work table
		EXECUTE(@selectlist)
		
		-- perform the final SELECT to generate the result set for the client
		EXECUTE('SELECT ' + @collist + ' FROM ' + @tmptab2)
			
		-- PRINT rowcount if desired
		SET @rc = @@rowcount
		IF @printrc = 1
		BEGIN
			PRINT '   '
			SET @cmd = '(' + CAST(@rc AS sys.VARCHAR) + ' rows affected)'
			PRINT @cmd
		END
		
		-- Cleanup: these work tables are permanent tables after all
		EXECUTE('DROP TABLE IF EXISTS ' + @tmptab)
		EXECUTE('DROP TABLE IF EXISTS ' + @tmptab2)	
	END TRY	
	BEGIN CATCH
		-- Cleanup in case of an unexpected error
		EXECUTE('DROP TABLE IF EXISTS ' + @tmptab)
		EXECUTE('DROP TABLE IF EXISTS ' + @tmptab2)		
	END CATCH

	RETURN
END
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_autoformat(IN sys.VARCHAR(257), IN sys.VARCHAR(1000), sys.bit, sys.VARCHAR(1000)) TO PUBLIC;


-- sp_who presents the contents of sysprocesses in a human-readable format.
-- With 'postgres' as argument or with optional second argument as 'postgres',
-- active PG connections will also be reported; by default only TDS connections are reported.
CREATE OR REPLACE PROCEDURE sys.sp_who(
	IN "@loginame" sys.sysname DEFAULT NULL,
	IN "@option"   sys.VARCHAR(30) DEFAULT NULL)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET NOCOUNT ON
	DECLARE @msg sys.VARCHAR(200)
	DECLARE @show_pg BIT = 0
	DECLARE @hide_col sys.VARCHAR(50) 
	
	IF @option IS NOT NULL
	BEGIN
		IF LOWER(TRIM(@option)) <> 'postgres' 
		BEGIN
			RAISERROR('Parameter @option can only be ''postgres''', 16, 1)
			RETURN			
		END
	END
	
	-- Take a copy of sysprocesses so that we reference it only once
	SELECT DISTINCT * INTO #sp_who_sysprocesses FROM sys.sysprocesses

	-- Get the executing statement for each spid and extract the main stmt type
	-- This is for informational purposes only
	SELECT pid, CAST(query AS sys.VARCHAR(MAX)) INTO #sp_who_tmp FROM pg_stat_activity pgsa
	
	UPDATE #sp_who_tmp SET query = ' ' + TRIM(CAST(UPPER(query) AS sys.VARCHAR(MAX)))
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(9), ' ')
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(10), ' ')
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(13), ' ')
	WHILE (SELECT count(*) FROM #sp_who_tmp WHERE sys.CHARINDEX('  ',query)>0) > 0 
	BEGIN
		UPDATE #sp_who_tmp SET query = sys.REPLACE(query, '  ', ' ')
	END

	-- Determine type of stmt to report by sp_who: very basic only
	-- NB: not handling presence of comments in the query string
	UPDATE #sp_who_tmp 
	SET query = 
	    CASE 
			WHEN PATINDEX('%[^a-zA-Z0-9_]UPDATE[^a-zA-Z0-9_]%', query) > 0 THEN 'UPDATE'
			WHEN PATINDEX('%[^a-zA-Z0-9_]DELETE[^a-zA-Z0-9_]%', query) > 0 THEN 'DELETE'
			WHEN PATINDEX('%[^a-zA-Z0-9_]INSERT[^a-zA-Z0-9_]%', query) > 0 THEN 'INSERT'
			WHEN PATINDEX('%[^a-zA-Z0-9_]SELECT[^a-zA-Z0-9_]%', query) > 0 THEN 'SELECT'
			WHEN PATINDEX('%[^a-zA-Z0-9_]WAITFOR[^a-zA-Z0-9_]%', query) > 0 THEN 'WAITFOR'
			WHEN PATINDEX('%[^a-zA-Z0-9_]CREATE ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('CREATE ', query))
			WHEN PATINDEX('%[^a-zA-Z0-9_]ALTER ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('ALTER ', query))
			WHEN PATINDEX('%[^a-zA-Z0-9_]DROP ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('DROP ', query))
			ELSE sys.SUBSTRING(query, 1, sys.CHARINDEX(' ', query))
		END

	UPDATE #sp_who_tmp 
	SET query = sys.SUBSTRING(query,1, 8-1 + sys.CHARINDEX(' ', sys.SUBSTRING(query,8,99)))
	WHERE query LIKE 'CREATE %' OR query LIKE 'ALTER %' OR query LIKE 'DROP %'	

	-- The executing spid is always shown as doing a SELECT
	UPDATE #sp_who_tmp SET query = 'SELECT' WHERE pid = @@spid
	UPDATE #sp_who_tmp SET query = TRIM(query)

	-- Get all current connections
	SELECT 
		spid, 
		MAX(blocked) AS blocked, 
		0 AS ecid, 
		CAST('' AS sys.VARCHAR(100)) AS status,
		CAST('' AS sys.VARCHAR(100)) AS loginname,
		CAST('' AS sys.VARCHAR(100)) AS hostname,
		0 AS dbid,
		CAST('' AS sys.VARCHAR(100)) AS cmd,
		0 AS request_id,
		CAST('TDS' AS sys.VARCHAR(20)) AS connection,
		hostprocess
	INTO #sp_who_proc
	FROM #sp_who_sysprocesses
		GROUP BY spid, status, hostprocess
		
	-- Add attributes to each connection
	UPDATE #sp_who_proc
	SET ecid = sp.ecid,
		status = sp.status,
		loginname = sp.loginname,
		hostname = sp.hostname,
		dbid = sp.dbid,
		request_id = sp.request_id
	FROM #sp_who_sysprocesses sp
		WHERE #sp_who_proc.spid = sp.spid				

	-- Identify PG connections: the hostprocess PID comes from the TDS login packet 
	-- and therefore PG connections do not have a value here
	UPDATE #sp_who_proc
	SET connection = 'PostgreSQL'
	WHERE hostprocess IS NULL 

	-- Keep or delete PG connections
	IF (LOWER(@loginame) = 'postgres' OR LOWER(@option) = 'postgres')
	begin    
		-- Show PG connections; these have dbid = 0
		-- This is a Babelfish-specific enhancement, since PG connections may also be active in the Babelfish DB
		-- and it may be useful to see these displayed
		SET @show_pg = 1
		
		-- blank out the loginame parameter for the tests below
		IF LOWER(@loginame) = 'postgres' SET @loginame = NULL
	END
	
	-- By default, do not show the column indicating the connection type since SQL Server does not have this column
	SET @hide_col = 'connection' 
	
	IF (@show_pg = 1) 
	BEGIN
		SET @hide_col = ''
	END
	ELSE 
	BEGIN
		-- Delete PG connections
		DELETE #sp_who_proc
		WHERE dbid = 0
	END
			
	-- Apply filter if specified
	IF (@loginame IS NOT NULL)
	BEGIN
		IF (TRIM(@loginame) = '')
		BEGIN
			-- Raise error
			SET @msg = ''''+@loginame+''' is not a valid login or you do not have permission.'
			RAISERROR(@msg, 16, 1)
			RETURN
		END
		
		IF (sys.ISNUMERIC(@loginame) = 1)
		BEGIN
			-- Remove all connections except the specified one
			DELETE #sp_who_proc
			WHERE spid <> CAST(@loginame AS INT)
		END
		ELSE 
		BEGIN	
			IF (LOWER(@loginame) = 'active')
			BEGIN
				-- Remove all 'idle' connections 
				DELETE #sp_who_proc
				WHERE status = 'idle'
			END
			ELSE 
			BEGIN
				-- Verify the specified login name exists
				IF (sys.SUSER_ID(@loginame) IS NULL)
				BEGIN
					SET @msg = ''''+@loginame+''' is not a valid login or you do not have permission.'
					RAISERROR(@msg, 16, 1)
					RETURN					
				END
				ELSE 
				BEGIN
					-- Keep only connections for the specified login
					DELETE #sp_who_proc
					WHERE sys.SUSER_ID(loginname) <> sys.SUSER_ID(@loginame)
				END
			END
		END
	END			
			
	-- Create final result set; use DISTINCT since there are usually duplicate rows from the PG catalogs
	SELECT distinct 
		p.spid AS spid, 
		p.ecid AS ecid, 
		CAST(LEFT(p.status,20) AS sys.VARCHAR(20)) AS status,
		CAST(LEFT(p.loginname,40) AS sys.VARCHAR(40)) AS loginame,
		CAST(LEFT(p.hostname,60) AS sys.VARCHAR(60)) AS hostname,
		p.blocked AS blk, 
		CAST(LEFT(db_name(p.dbid),40) AS sys.VARCHAR(40)) AS dbname,
		CAST(LEFT(#sp_who_tmp.query,30)as sys.VARCHAR(30)) AS cmd,
		p.request_id AS request_id,
		connection
	INTO #sp_who_tmp2
	FROM #sp_who_proc p, #sp_who_tmp
		WHERE p.spid = #sp_who_tmp.pid
		ORDER BY spid		
	
	-- Patch up remaining cases
	UPDATE #sp_who_tmp2
	SET cmd = 'AWAITING COMMAND'
	WHERE TRIM(ISNULL(cmd,'')) = '' AND status = 'idle'
	
	UPDATE #sp_who_tmp2
	SET cmd = 'UNKNOWN'
	WHERE TRIM(cmd) = ''	
	
	-- Format the result set as narrow as possible for readability
	SET @hide_col += ',hostprocess'
	EXECUTE sys.sp_babelfish_autoformat @tab='#sp_who_tmp2', @orderby='ORDER BY spid', @hiddencols=@hide_col, @printrc=0
	RETURN
END	
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_who(IN sys.sysname, IN sys.VARCHAR(30)) TO PUBLIC;

-- Change the owner of the current database.
-- This is a wrapper around ALTER AUTHORIZATION ON DATABASE::
CREATE OR REPLACE PROCEDURE sys.sp_changedbowner(
	IN "@loginame" sys.sysname,
	IN "@map"      sys.VARCHAR(5) DEFAULT NULL) -- this parameter is ignored in T-SQL
LANGUAGE 'pltsql'
AS $$
BEGIN
	DECLARE @cmd sys.NVARCHAR(300)
	DECLARE @db  sys.sysname = DB_NAME()

	-- For a NULL login name, do nothing
	IF @loginame IS NULL
	BEGIN
		RETURN
	END

	IF (@db = 'master') OR (@db = 'tempdb')
	BEGIN
		RAISERROR('Cannot change the owner of the master or tempdb database.', 16, 1)
		RETURN
	END

	IF SUSER_ID(@loginame) IS NULL
	BEGIN
		RAISERROR('Cannot find the principal ''%s'', because it does not exist or you do not have permission.', 16, 1, @loginame)
		RETURN
	END

	-- Compose the ALTER ATHORIZATION statement:
	SET @cmd = 'ALTER AUTHORIZATION ON DATABASE::[' + @db + '] TO [' + SUSER_NAME(SUSER_ID(@loginame)) + ']'
	EXECUTE(@cmd)
END
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_changedbowner(IN sys.sysname, IN sys.VARCHAR(5)) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_procedure_params_100_managed(IN "@procedure_name" sys.sysname, 
                                                                IN "@group_number" integer DEFAULT 1, 
                                                                IN "@procedure_schema" sys.sysname DEFAULT NULL, 
                                                                IN "@parameter_name" sys.sysname DEFAULT NULL)
AS $$
BEGIN
	IF @procedure_schema IS NULL OR @procedure_schema = ''
		BEGIN
			SELECT @procedure_schema = default_schema_name from sys.babelfish_authid_user_ext WHERE orig_username = user_name() AND database_name = db_name();
		END

        SELECT 	v.column_name AS [PARAMETER_NAME],
		CAST (CASE v.column_type
			WHEN 5 THEN 4
                        WHEN 3 THEN 4
                        ELSE v.column_type END
                     	AS smallint) AS [PARAMETER_TYPE],
        	CAST (CASE v.type_name
			WHEN 'int' THEN 8
                        WHEN 'nchar' THEN 10
                        WHEN 'char' THEN 3
                        WHEN 'date' THEN 31
                        WHEN 'nvarchar' THEN 12
                        WHEN 'varchar' THEN 22
                        WHEN 'table' THEN 23
                        WHEN 'datetime' THEN 4
                        WHEN 'datetime2' THEN 33
                        WHEN 'datetimeoffset' THEN 34
                        WHEN 'smalldatetime' THEN 15
			WHEN 'time' THEN 32
                        WHEN 'decimal' THEN 5
			WHEN 'numeric' THEN 5
                        WHEN 'float' THEN 6
                        WHEN 'real' THEN 13
                        WHEN 'nchar' THEN 10
                        WHEN 'flag' THEN 2
                        WHEN 'money' THEN 9
                        WHEN 'smallmoney' THEN 17
                        WHEN 'tinyint' THEN 20
                        WHEN 'smallint' THEN 16
                        WHEN 'bigint' THEN 0
                        WHEN 'bit' THEN 2
			WHEN 'text' THEN 18
			WHEN 'ntext' THEN 11
			WHEN 'binary' THEN 1
			WHEN 'varbinary' THEN 21
			WHEN 'image' THEN 7
                        ELSE 0 END
                	AS smallint) AS [MANAGED_DATA_TYPE],
        	CAST (CASE 
			WHEN v.type_name IN (N'nchar', N'nvarchar') AND p.max_length <> -1 THEN p.max_length / 2
			WHEN v.type_name IN (N'char', N'varchar', N'binary', N'varbinary') AND p.max_length <> -1 THEN p.max_length
			WHEN v.type_name IN (N'nvarchar', N'varchar', N'varbinary') AND p.max_length = -1 THEN 0
                	WHEN v.type_name IN (N'text', N'image') THEN 2147483647
                	WHEN v.type_name = 'ntext' THEN 1073741823
                	ELSE NULL END 
			AS INT) AS [CHARACTER_MAXIMUM_LENGTH],
        	CAST(CASE 
			WHEN v.type_name IN (N'int', N'smallint', N'bigint', N'tinyint', N'float', N'real', N'decimal', N'numeric', N'money', N'smallmoney') 
				THEN v.PRECISION
			ELSE NULL END 
			AS smallint) AS [NUMERIC_PRECISION],
        	CAST(CASE 
			WHEN v.type_name IN (N'decimal', N'numeric') THEN v.SCALE 
			ELSE NULL END 
			AS smallint ) AS [NUMERIC_SCALE],
        	CAST(NULL AS sys.nvarchar(128)) AS [TYPE_CATALOG_NAME],
        	CAST(NULL AS sys.nvarchar(128)) AS [TYPE_SCHEMA_NAME],
        	CAST(v.TYPE_NAME AS sys.nvarchar(128)) AS [TYPE_NAME],
        	CAST(NULL AS sys.nvarchar(128)) AS XML_CATALOGNAME,
        	CAST(NULL AS sys.nvarchar(128)) AS XML_SCHEMANAME,
        	CAST(NULL AS sys.nvarchar(128)) AS XML_SCHEMACOLLECTIONNAME,
        	CAST(CASE
			WHEN v.type_name = 'datetime' THEN 3
                    	WHEN v.type_name IN (N'datetime2', N'datetimeoffset', N'time') THEN 7
			WHEN v.type_name IN (N'date', N'smalldatetime') THEN 0
                    	ELSE NULL END AS int) AS [SS_DATETIME_PRECISION]
   	FROM sys.sp_sproc_columns_view v
   	LEFT OUTER JOIN sys.all_parameters AS p 
	ON v.column_name = p.name AND p.object_id = object_id(PG_CATALOG.CONCAT(@procedure_schema, '.', @procedure_name))
   	WHERE v.original_procedure_name = @procedure_name
    	AND v.procedure_owner = @procedure_schema
	AND (@parameter_name IS NULL OR column_name = @parameter_name)
	AND @group_number = 1
    	ORDER BY PROCEDURE_OWNER, PROCEDURE_NAME, ORDINAL_POSITION;
END;
$$ LANGUAGE pltsql;
GRANT EXECUTE ON PROCEDURE sys.sp_procedure_params_100_managed TO PUBLIC;
