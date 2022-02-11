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

-- ODBCVer ignored for now
CREATE OR REPLACE PROCEDURE sys.sp_datatype_info (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
               CREATE_PARAMS, NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
       from sys.spt_datatype_info_table where @data_type = 0 or data_type = @data_type;		
END;
$$
LANGUAGE 'pltsql';
-- same as sp_datatype_info
CREATE OR REPLACE PROCEDURE sys.sp_datatype_info_100 (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
               CREATE_PARAMS, NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.spt_datatype_info_table where @data_type = 0 or data_type = @data_type;
END;
$$
LANGUAGE 'pltsql';


-- BABEL-1784: support for sp_columns/sp_columns_100
CREATE VIEW sys.sp_columns_100_view AS
SELECT 
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3.rolname AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4.column_name AS sys.sysname) AS COLUMN_NAME,
CAST(t5.data_type AS smallint) AS DATA_TYPE,
CAST(t5.type_name AS sys.sysname) AS TYPE_NAME,
CAST(t4.numeric_precision AS INT) AS PRECISION,
CAST(t5.length AS int) AS LENGTH,
CAST(t4.numeric_scale AS smallint) AS SCALE,
CAST(t4.numeric_precision_radix AS smallint) AS RADIX,
case
  when t4.is_nullable = 'YES' then CAST(1 AS smallint)
  else CAST(0 AS smallint)
end AS NULLABLE,
CAST(NULL AS varchar(254)) AS remarks,
CAST(t4.column_default AS sys.nvarchar(4000)) AS COLUMN_DEF,
CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,
CAST(t4.character_octet_length AS int) AS CHAR_OCTET_LENGTH,
CAST(t4.dtd_identifier AS int) AS ORDINAL_POSITION,
CAST(t4.is_nullable AS varchar(254)) AS IS_NULLABLE,
CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
CAST(0 AS smallint) AS SS_IS_SPARSE,
CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
case
  when t4.is_generated = 'NEVER' then CAST(0 AS smallint)
  else CAST(1 AS smallint)
end AS SS_IS_COMPUTED,
case
  when t4.is_identity = 'YES' then CAST(1 AS smallint)
  else CAST(0 AS smallint)
end AS SS_IS_IDENTITY,
CAST(NULL AS varchar(254)) SS_UDT_CATALOG_NAME,
CAST(NULL AS varchar(254)) SS_UDT_SCHEMA_NAME,
CAST(NULL AS varchar(254)) SS_UDT_ASSEMBLY_TYPE_NAME,
CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_NAME
FROM pg_catalog.pg_class t1
	 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	 JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
     JOIN information_schema.columns t4 ON t1.relname = t4.table_name,
	sys.spt_datatype_info_table AS t5
WHERE (t4.data_type = t5.pg_type_name 
	OR ((SELECT coalesce(t4.domain_name, '') != 'tinyint') AND (SELECT coalesce(t4.domain_name, '') != 'nchar') AND t5.pg_type_name = t4.udt_name)
	OR (t4.domain_schema = 'sys' AND t5.type_name = t4.domain_name));
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
	    where table_name like in_table_name
	      and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner like in_table_owner)
	      and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier like in_table_qualifier)
	      and ((SELECT coalesce(in_column_name,'')) = '' or column_name like in_column_name)
		order by table_qualifier, table_owner, table_name;
	ELSE 
		return query
	    select table_qualifier, precision from sys.sp_columns_100_view
	      where in_table_name = table_name
	      and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner)
	      and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
	      and ((SELECT coalesce(in_column_name,'')) = '' or column_name = in_column_name)
		order by table_qualifier, table_owner, table_name;
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
	select out_table_qualifier as table_qualifier, 
			out_table_owner as table_owner,
			out_table_name as table_name,
			out_column_name as column_name,
			out_data_type as data_type,
			out_type_name as type_name,
			out_precision as precision,
			out_length as length,
			out_scale as scale,
			out_radix as radix,
			out_nullable as nullable,
			out_remarks as remarks,
			out_column_def as column_def,
			out_sql_data_type as sql_data_type,
			out_sql_datetime_sub as sql_datetime_sub,
			out_char_octet_length as char_octet_length,
			out_ordinal_position as ordinal_position,
			out_is_nullable as is_nullable,
			out_ss_data_type as ss_data_type
	from sys.sp_columns_100_internal(@table_name, @table_owner,@table_qualifier, @column_name, @NameScope,@ODBCVer, @fusepattern);
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
	select out_table_qualifier as table_qualifier, 
			out_table_owner as table_owner,
			out_table_name as table_name,
			out_column_name as column_name,
			out_data_type as data_type,
			out_type_name as type_name,
			out_precision as precision,
			out_length as length,
			out_scale as scale,
			out_radix as radix,
			out_nullable as nullable,
			out_remarks as remarks,
			out_column_def as column_def,
			out_sql_data_type as sql_data_type,
			out_sql_datetime_sub as sql_datetime_sub,
			out_char_octet_length as char_octet_length,
			out_ordinal_position as ordinal_position,
			out_is_nullable as is_nullable,
			out_ss_is_sparse as ss_is_sparse,
			out_ss_is_column_set as ss_is_column_set,
			out_ss_is_computed as ss_is_computed,
			out_ss_is_identity as ss_is_identity,
			out_ss_udt_catalog_name as ss_udt_catalog_name,
			out_ss_udt_schema_name as ss_udt_schema_name,
			out_ss_udt_assembly_type_name as ss_udt_assembly_type_name,
			out_ss_xml_schemacollection_catalog_name as ss_xml_schemacollection_catalog_name,
			out_ss_xml_schemacollection_schema_name as ss_xml_schemacollection_schema_name,
			out_ss_xml_schemacollection_name as ss_xml_schemacollection_name,
			out_ss_data_type as ss_data_type
	from sys.sp_columns_100_internal(@table_name, @table_owner,@table_qualifier, @column_name, @NameScope,@ODBCVer, @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_100 TO PUBLIC;

-- BABEL-1785: initial support of sp_describe_first_result_set
-- sys.sp_describe_first_result_set_internal: internal function 
-- used to workaround BABEL-1597 
create function sys.sp_describe_first_result_set_internal(
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
as $$
	declare _args text[]; -- placeholder: parse @params and feed the tsqlquery
begin
	IF tsqlquery ILIKE 'select %' THEN
		DROP VIEW IF EXISTS sp_describe_first_result_set_view;
		EXECUTE 'create temp view sp_describe_first_result_set_view as ' || tsqlquery USING _args;
		RETURN query
		SELECT
			CAST(0 AS sys.bit) AS is_hidden,
			CAST(t1.dtd_identifier AS int) AS column_ordinal,
			CAST(t1.column_name AS sys.sysname) AS name,
			case
				when t1.is_nullable = 'Y' then CAST(1 AS sys.bit)
				else CAST(0 AS sys.bit)
			end as is_nullable,
			0 as system_type_id, 
			CAST('' as sys.nvarchar(256)) as system_type_name, 
			CAST(t2.length AS smallint) AS max_length,
			CAST(t1.numeric_precision AS sys.tinyint) AS precision,
			CAST(t1.numeric_scale AS sys.tinyint) AS scale,
			CAST((SELECT coalesce(t1.collation_name, '')) AS sys.sysname) as collation_name,
			CAST(NULL as int) as user_type_id, 
			CAST('' as sys.sysname) as user_type_database, 
			CAST('' as sys.sysname) as user_type_schema, 
			CAST('' as sys.sysname) as user_type_name, 
			CAST('' as sys.nvarchar(4000)) as assembly_qualified_type_name, 
			CAST(NULL as int) as xml_collection_id,
			CAST('' as sys.sysname) as xml_collection_database,
			CAST('' as sys.sysname) as xml_collection_schema,
			CAST('' as sys.sysname) as xml_collection_name,
			case 
				when t1.data_type = 'xml' then CAST(1 AS sys.bit)
				else CAST(0 AS sys.bit)
			end as is_xml_document,
			case
				when t1.udt_name = 'citext' then CAST(0 AS sys.bit)
				else CAST(1 AS sys.bit)
			end as is_case_sensitive,
			CAST(0 as sys.bit) as is_fixed_length_clr_type,
			CAST('' as sys.sysname) as source_server, 
			CAST('' as sys.sysname) as source_database,
			CAST('' as sys.sysname) as source_schema,
			CAST('' as sys.sysname) as source_table,
			CAST('' as sys.sysname) as source_column,
			case
				when t1.is_identity = 'YES' then CAST(1 AS sys.bit)
				else CAST(0 AS sys.bit)
			end as is_identity_column,
			CAST(NULL as sys.bit) as is_part_of_unique_key,-- pg_constraint
			case 
				when t1.is_updatable = 'YES' then CAST(1 AS sys.bit)
				else CAST(0 AS sys.bit)
			end as is_updateable,
			case
				when t1.is_generated = 'NEVER' then CAST(0 AS sys.bit)
				else CAST(1 AS sys.bit)
			end as is_computed_column,
			CAST(0 as sys.bit) as is_sparse_column_set,
			CAST(NULL as smallint) ordinal_in_order_by_list,
			CAST(NULL as smallint) order_by_list_length,
			CAST(NULL as smallint) order_by_is_descending,
			-- below are for internal usage
			CAST(NULL as int) as tds_type_id,
			CAST(NULL as int) as tds_length,
			CAST(NULL as int) as tds_collation_id,
			CAST(1 AS sys.tinyint) AS tds_collation_sort_id
		FROM information_schema.columns t1, sys.spt_datatype_info_table t2 
		WHERE table_name = 'sp_describe_first_result_set_view'
			AND (t1.data_type = t2.pg_type_name
				OR ((SELECT coalesce(t1.domain_name, '') != 'tinyint') 
					AND (SELECT coalesce(t1.domain_name, '') != 'nchar') 
					AND t2.pg_type_name = t1.udt_name)
				OR (t1.domain_schema = 'sys' AND t2.type_name = t1.domain_name));
		DROP VIEW sp_describe_first_result_set_view;
	END IF;
end;
$$
LANGUAGE plpgsql;
GRANT ALL on FUNCTION sys.sp_describe_first_result_set_internal TO PUBLIC;

CREATE PROCEDURE sys.sp_describe_first_result_set (
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
        pg_attribute p ON (c.name = p.attname)
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

CREATE VIEW sys.spt_columns_view_managed AS
SELECT
    o.object_id                     AS OBJECT_ID,
    isc.table_catalog               AS TABLE_CATALOG,
    isc.table_schema                AS TABLE_SCHEMA,
    o.name                          AS TABLE_NAME,
    c.name                          AS COLUMN_NAME,
    isc.ordinal_position            AS ORDINAL_POSITION,
    isc.column_default              AS COLUMN_DEFAULT,
    isc.is_nullable                 AS IS_NULLABLE,
    isc.data_type                   AS DATA_TYPE,
    isc.character_maximum_length    AS CHARACTER_MAXIMUM_LENGTH,
    isc.character_octet_length      AS CHARACTER_OCTET_LENGTH,
    isc.numeric_precision           AS NUMERIC_PRECISION,
    isc.numeric_precision_radix     AS NUMERIC_PRECISION_RADIX,
    isc.numeric_scale               AS NUMERIC_SCALE,
    isc.datetime_precision          AS DATETIME_PRECISION,
    isc.character_set_catalog       AS CHARACTER_SET_CATALOG,
    isc.character_set_schema        AS CHARACTER_SET_SCHEMA,
    isc.character_set_name          AS CHARACTER_SET_NAME,
    isc.collation_catalog           AS COLLATION_CATALOG,
    isc.collation_schema            AS COLLATION_SCHEMA,
    c.collation_name                AS COLLATION_NAME,
    isc.domain_catalog              AS DOMAIN_CATALOG,
    isc.domain_schema               AS DOMAIN_SCHEMA,
    isc.domain_name                 AS DOMAIN_NAME,
    c.is_sparse                     AS IS_SPARSE,
    c.is_column_set                 AS IS_COLUMN_SET,
    c.is_filestream                 AS IS_FILESTREAM
FROM
    sys.objects o JOIN sys.columns c ON
        (
            c.object_id = o.object_id and
            o.type in ('U', 'V')  -- limit columns to tables and views
        )
    LEFT JOIN information_schema.columns isc ON
        (
            sys.schema_name(o.schema_id) = isc.table_schema and
            o.name = isc.table_name and
            c.name = isc.column_name
        )
    WHERE CAST(column_name AS sys.nvarchar(128)) NOT IN ('cmin', 'cmax', 'xmin', 'xmax', 'ctid', 'tableoid');

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
        (in_catalog IS NULL OR s_cv.TABLE_CATALOG LIKE in_catalog) AND
        (in_owner IS NULL OR s_cv.TABLE_SCHEMA LIKE in_owner) AND
        (in_table IS NULL OR s_cv.TABLE_NAME LIKE in_table) AND
        (in_column IS NULL OR s_cv.COLUMN_NAME LIKE in_column) AND
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
        sys.sp_columns_managed_internal(@Catalog, @Owner, "@Table", "@Column", @SchemaType) s_cv
    ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, IS_NULLABLE;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_managed TO PUBLIC;

-- BABEL-1797: initial support of sp_describe_undeclared_parameters
-- sys.sp_describe_undeclared_parameters_internal: internal function
-- For the result rows, can we create a template table for it?
create function sys.sp_describe_undeclared_parameters_internal(
	tsqlquery varchar(384),
    params varchar(384) = NULL
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
	"@tsql" varchar(384),
    "@params" varchar(384) = NULL)
AS $$
BEGIN
	select * from sys.sp_describe_undeclared_parameters_internal(@tsql, @params);
	return 1;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_undeclared_parameters TO PUBLIC;

-- BABEL-1782
CREATE VIEW sys.sp_tables_view AS
SELECT 
t2.dbname AS TABLE_QUALIFIER,
t3.rolname AS TABLE_OWNER,
t1.relname AS TABLE_NAME,
case
  when t1.relkind = 'v' then 'VIEW'
  else 'TABLE'
end AS TABLE_TYPE,
CAST(NULL AS varchar(254)) AS remarks
FROM pg_catalog.pg_class AS t1, sys.pg_namespace_ext AS t2, pg_catalog.pg_roles AS t3 
WHERE t1.relowner = t3.oid AND t1.relnamespace = t2.oid;
GRANT SELECT on sys.sp_tables_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_tables (
	"@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.sysname = '',
    "@table_type" sys.nvarchar(100) = '',
    "@fusepattern" sys.bit = '1')
AS $$
BEGIN
	DECLARE @_opt_view varchar(16) = ''
	DECLARE @_opt_table varchar(16) = ''
	IF (select count(*) from STRING_SPLIT(@table_type, ',') where trim(value) = 'VIEW') = 1
	  BEGIN
		SET @_opt_view = 'VIEW'
	  END
	IF (select count(*) from STRING_SPLIT(@table_type, ',') where trim(value) = 'TABLE') = 1
	  BEGIN
		SET @_opt_table = 'TABLE'
	  END
	IF @fUsePattern = '1'
	  BEGIN
        select * from sys.sp_tables_view where 
		(@table_name = '' or table_name like @table_name)
		and (@table_owner = '' or table_owner like @table_owner)
		and (@table_qualifier = '' or table_qualifier like @table_qualifier)
		and (@table_type = '' or table_type = @_opt_table or table_type = @_opt_view);
	  END
	ELSE
	  BEGIN
        select * from sys.sp_tables_view where 
		(@table_name = '' or table_name = @table_name)
		and (@table_owner = '' or table_owner = @table_owner)
		and (@table_qualifier = '' or table_qualifier = @table_qualifier)
		and (@table_type = '' or table_type = @_opt_table or table_type = @_opt_view);
	  END
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_tables TO PUBLIC;

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

CREATE VIEW sys.sp_pkeys_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3.rolname AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4.column_name AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
	JOIN information_schema.columns t4 ON t1.relname = t4.table_name
	JOIN pg_constraint t5 ON t1.oid = t5.conrelid
	, generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
	AND CAST(t4.dtd_identifier AS smallint) = ANY (t5.conkey)
	AND CAST(t4.dtd_identifier AS smallint) = t5.conkey[seq];

GRANT SELECT on sys.sp_pkeys_view TO PUBLIC;

-- internal function in order to workaround BABEL-1597
create function sys.sp_pkeys_internal(
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
	where in_table_name = table_name
		and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner)
		and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
	order by table_qualifier, table_owner, table_name, key_seq;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = '',
	"@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
	select out_table_qualifier as table_qualifier,
			out_table_owner as table_owner,
			out_table_name as table_name,
			out_column_name as column_name,
			out_key_seq as key_seq,
			out_pk_name as pk_name
	from sys.sp_pkeys_internal(@table_name, @table_owner, @table_qualifier);
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

CREATE VIEW sys.sp_statistics_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3.rolname AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
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
CAST(t4.column_name AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.stadistinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema.columns t4 ON t1.relname = t4.table_name
	JOIN (pg_catalog.pg_index t5 JOIN
		pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
	LEFT JOIN pg_catalog.pg_statistic t7 ON t1.oid = t7.starelid
	LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4.dtd_identifier AS smallint) = ANY (t5.indkey)
    AND CAST(t4.dtd_identifier AS smallint) = t5.indkey[seq];
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
    where in_table_name = table_name
        and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner)
        and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
        and ((SELECT coalesce(in_index_name,'')) = '' or index_name like in_index_name)
        and ((in_is_unique = 'N') or (in_is_unique = 'Y' and non_unique = 0))
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

  CALL printarg('Statistics for all tables have been updated. Refer logs for details.');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE on PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8)) TO PUBLIC;
