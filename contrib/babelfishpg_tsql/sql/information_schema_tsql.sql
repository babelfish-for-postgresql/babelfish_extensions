
/*
 * TSQL Information Schema
 *
 * Copyright (c) 2003-2020, PostgreSQL Global Development Group
 *
 * contrib/babelfishpg_tsql/sql/information_schema_tsql.sql
 *
 */

/*
 * INFORMATION_SCHEMA_TSQL schema
 */

CREATE SCHEMA information_schema_tsql;
GRANT USAGE ON SCHEMA information_schema_tsql TO PUBLIC;
SET search_path TO information_schema_tsql;


/*
 * Introducing information_schema_tsql Utility functions;
 * Re-using most of the original functions provided by Postgres.
 */

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_truetypid(nt pg_namespace, at pg_attribute, tp pg_type) RETURNS oid
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT CASE WHEN nt.nspname = 'pg_catalog' OR nt.nspname = 'sys' THEN at.atttypid ELSE tp.typbasetype END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_truetypmod(nt pg_namespace, at pg_attribute, tp pg_type) RETURNS int4
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT CASE WHEN nt.nspname = 'pg_catalog' OR nt.nspname = 'sys' THEN at.atttypmod ELSE tp.typtypmod END$$;

-- these functions encapsulate knowledge about the encoding of typmod:

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
		WHEN type = 'xml'
		THEN -1
		WHEN type = 'sql_variant'
		THEN 0
		ELSE null
	END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_octet_length(type text, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT
	CASE WHEN type IN ('char', 'varchar', 'binary', 'varbinary')
		THEN CASE WHEN typmod = -1 /* default typmod */
			THEN CAST(2147483646 AS integer) /* 2^30 */
			ELSE typmod - 4
			END
		WHEN type IN ('nchar', 'nvarchar')
		THEN CASE WHEN typmod = -1 /* default typmod */
			THEN CAST(2147483646 AS integer) /* 2^30 */
			ELSE (typmod - 4) * 2
			END
		WHEN type IN ('text', 'image')
		THEN 2147483647 /* 2^30 + 1 */
		WHEN type = 'ntext'
		THEN 2147483646 /* 2^30 */
		WHEN type = 'sql_variant'
		THEN 0
		WHEN type = 'xml'
		THEN -1
	   ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision(typid oid, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT
  CASE typid
		 WHEN 21 /*int2*/ THEN 5
		 WHEN 23 /*int4*/ THEN 10
		 WHEN 20 /*int8*/ THEN 19
		 WHEN 1700 /*numeric*/ THEN
			  CASE WHEN typmod = -1
				   THEN null
				   ELSE ((typmod - 4) >> 16) & 65535
				   END
		 WHEN 700 /*float4*/ THEN 24
		 WHEN 701 /*float8*/ THEN 53
		 ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision_radix(typid oid, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT
	CASE WHEN typid IN (700, 701) THEN 2
		WHEN typid IN (20, 21, 23, 1700) THEN 10
		ELSE null
	END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_scale(typid oid, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT
	CASE WHEN typid IN (21, 23, 20) THEN 0
		WHEN typid IN (1700) THEN
			CASE WHEN typmod = -1
				 THEN null
				 ELSE (typmod - 4) & 65535
				 END
		ELSE null
	END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_datetime_precision(type text, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT
  CASE WHEN type = 'date'
		   THEN 0
		WHEN type = 'datetime'
		THEN 3
	   WHEN type IN ('time', 'datetime2', 'smalldatetime')
		   THEN CASE WHEN typmod < 0 THEN 6 ELSE typmod END
	   ELSE null
  END$$;


/*
 * COLUMNS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.columns AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
			CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
			CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
			CAST(a.attname AS sys.nvarchar(128)) AS "COLUMN_NAME",
			CAST(a.attnum AS int) AS "ORDINAL_POSITION",
			CAST(CASE WHEN a.attgenerated = '' THEN pg_get_expr(ad.adbin, ad.adrelid) END AS sys.nvarchar(4000)) AS "COLUMN_DEFAULT",
			CAST(CASE WHEN a.attnotnull OR (t.typtype = 'd' AND t.typnotnull) THEN 'NO' ELSE 'YES' END
				AS varchar(3))
				AS "IS_NULLABLE",

			CAST(
				sys.translate_pg_type_to_tsql(information_schema_tsql._pgtsql_truetypid(nt, a, t)) AS sys.nvarchar(128))
				AS "DATA_TYPE",

			CAST(
				information_schema_tsql._pgtsql_char_max_length(sys.translate_pg_type_to_tsql(information_schema_tsql._pgtsql_truetypid(nt, a, t)),
					information_schema_tsql._pgtsql_truetypmod(nt, a, t))
				AS int)
				AS "CHARACTER_MAXIMUM_LENGTH",

			CAST(
				information_schema_tsql._pgtsql_char_octet_length(sys.translate_pg_type_to_tsql(information_schema_tsql._pgtsql_truetypid(nt, a, t)),
					information_schema_tsql._pgtsql_truetypmod(nt, a, t))
				AS int)
				AS "CHARACTER_OCTET_LENGTH",

			CAST(
				/* Handle Tinyint separately */
				CASE WHEN sys.translate_pg_type_to_tsql(information_schema_tsql._pgtsql_truetypid(nt, a, t)) = 'tinyint'
					THEN 3
					ELSE information_schema_tsql._pgtsql_numeric_precision(information_schema_tsql._pgtsql_truetypid(nt, a, t),
						information_schema_tsql._pgtsql_truetypmod(nt, a, t))
					END
				AS sys.tinyint)
				AS "NUMERIC_PRECISION",

			CAST(
				information_schema_tsql._pgtsql_numeric_precision_radix(information_schema_tsql._pgtsql_truetypid(nt, a, t),
					information_schema_tsql._pgtsql_truetypmod(nt, a, t))
				AS smallint)
				AS "NUMERIC_PRECISION_RADIX",

			CAST(
				information_schema_tsql._pgtsql_numeric_scale(information_schema_tsql._pgtsql_truetypid(nt, a, t),
					information_schema_tsql._pgtsql_truetypmod(nt, a, t))
				AS int)
				AS "NUMERIC_SCALE",

			CAST(
				information_schema_tsql._pgtsql_datetime_precision(sys.translate_pg_type_to_tsql(information_schema_tsql._pgtsql_truetypid(nt, a, t)),
					information_schema_tsql._pgtsql_truetypmod(nt, a, t))
				AS smallint)
				AS "DATETIME_PRECISION",

			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",
			/*
			 * TODO: We need to first create mapping of collation name to char-set name;
			 * Until then return null.
			 */
			CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

			CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
			CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",

			/* Returns Babelfish specific collation name. */
			CAST(co.collname AS sys.nvarchar(128)) AS "COLLATION_NAME",

			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN nc.dbname ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN ext.orig_name ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
			CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
				THEN t.typname ELSE null END
				AS sys.nvarchar(128)) AS "DOMAIN_NAME"

	FROM (pg_attribute a LEFT JOIN pg_attrdef ad ON attrelid = adrelid AND attnum = adnum)
		JOIN (pg_class c JOIN sys.pg_namespace_ext nc ON (c.relnamespace = nc.oid)) ON a.attrelid = c.oid
		JOIN (pg_type t JOIN pg_namespace nt ON (t.typnamespace = nt.oid)) ON a.atttypid = t.oid
		LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON (bt.typnamespace = nbt.oid))
			ON (t.typtype = 'd' AND t.typbasetype = bt.oid)
		LEFT JOIN pg_collation co on co.oid = a.attcollation
		LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname

	WHERE (NOT pg_is_other_temp_schema(nc.oid))
		AND a.attnum > 0 AND NOT a.attisdropped
		AND c.relkind IN ('r', 'v', 'p')
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_column_privilege(c.oid, a.attnum,
									'SELECT, INSERT, UPDATE, REFERENCES'))
		AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.columns TO PUBLIC;


/*
 * TABLES view
 */

CREATE VIEW information_schema_tsql.tables AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		   CAST(c.relname AS sys.sysname) AS "TABLE_NAME",

		   CAST(
			 CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
				  WHEN c.relkind = 'v' THEN 'VIEW'
				  ELSE null END
			 AS varchar(10)) AS "TABLE_TYPE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		   LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname

	WHERE c.relkind IN ('r', 'v', 'p')
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);
