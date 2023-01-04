
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
		WHEN type = 'sysname'
		THEN 128
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
			THEN -1
			ELSE typmod - 4
			END
		WHEN type IN ('nchar', 'nvarchar')
		THEN CASE WHEN typmod = -1 /* default typmod */
			THEN -1
			ELSE (typmod - 4) * 2
			END
		WHEN type IN ('text', 'image')
		THEN 2147483647 /* 2^30 + 1 */
		WHEN type = 'ntext'
		THEN 2147483646 /* 2^30 */
		WHEN type = 'sysname'
		THEN 256
		WHEN type = 'sql_variant'
		THEN 0
		WHEN type = 'xml'
		THEN -1
	   ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_max_length_for_routines(type text, typmod int4) RETURNS integer
        LANGUAGE sql
        IMMUTABLE
        PARALLEL SAFE
        RETURNS NULL ON NULL INPUT
        AS
$$SELECT
        CASE WHEN type IN ('char', 'nchar', 'varchar', 'nvarchar', 'binary', 'varbinary')
                THEN CASE WHEN typmod = -1
                        THEN 1
                        ELSE typmod - 4
                        END
                WHEN type IN ('text', 'image')
                THEN 2147483647
                WHEN type = 'ntext'
                THEN 1073741823
                WHEN type = 'sysname'
                THEN 128
                WHEN type = 'xml'
                THEN -1
                WHEN type = 'sql_variant'
                THEN 0
                ELSE null
        END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_octet_length_for_routines(type text, typmod int4) RETURNS integer
        LANGUAGE sql
        IMMUTABLE
        PARALLEL SAFE
        RETURNS NULL ON NULL INPUT
        AS
$$SELECT
        CASE WHEN type IN ('char', 'varchar', 'binary', 'varbinary')
                THEN CASE WHEN typmod = -1 /* default typmod */
                        THEN 1
                        ELSE typmod - 4
                        END
                WHEN type IN ('nchar', 'nvarchar')
                THEN CASE WHEN typmod = -1 /* default typmod */
                        THEN 2
                        ELSE (typmod - 4) * 2
                        END
                WHEN type IN ('text', 'image')
                THEN 2147483647 /* 2^30 + 1 */
                WHEN type = 'ntext'
                THEN 2147483646 /* 2^30 */
                WHEN type = 'sysname'
                THEN 256
                WHEN type = 'sql_variant'
                THEN 0
                WHEN type = 'xml'
                THEN -1
           ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision(type text, typid oid, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$
	SELECT
	CASE typid
		WHEN 21 /*int2*/ THEN 5
		WHEN 23 /*int4*/ THEN 10
		WHEN 20 /*int8*/ THEN 19
		WHEN 1700 /*numeric*/ THEN
			CASE WHEN typmod = -1 THEN null
				ELSE ((typmod - 4) >> 16) & 65535
			END
		WHEN 700 /*float4*/ THEN 24
		WHEN 701 /*float8*/ THEN 53
		ELSE
			CASE WHEN type = 'tinyint' THEN 3
				WHEN type = 'money' THEN 19
				WHEN type = 'smallmoney' THEN 10
				WHEN type = 'decimal'	THEN
					CASE WHEN typmod = -1 THEN null
						ELSE ((typmod - 4) >> 16) & 65535
					END
				ELSE null
			END
	END
$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision_radix(type text, typid oid, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$SELECT
	CASE WHEN typid IN (700, 701) THEN 2
		WHEN typid IN (20, 21, 23, 1700) THEN 10
		WHEN type IN ('tinyint', 'money', 'smallmoney') THEN 10
		ELSE null
	END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_scale(type text, typid oid, typmod int4) RETURNS integer
	LANGUAGE sql
	IMMUTABLE
	PARALLEL SAFE
	RETURNS NULL ON NULL INPUT
	AS
$$
	SELECT
	CASE WHEN typid IN (21, 23, 20) THEN 0
		WHEN typid IN (1700) THEN
			CASE WHEN typmod = -1 THEN null
				ELSE (typmod - 4) & 65535
			END
		WHEN type = 'tinyint' THEN 0
		WHEN type IN ('money', 'smallmoney') THEN 4
		WHEN type = 'decimal' THEN
			CASE WHEN typmod = -1 THEN NULL
				ELSE (typmod - 4) & 65535
			END
		ELSE null
	END
$$;

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
	  WHEN type IN ('time', 'datetime2', 'smalldatetime', 'datetimeoffset')
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
				CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype)
				ELSE tsql_type_name END
				AS sys.nvarchar(128))
				AS "DATA_TYPE",

			CAST(
				information_schema_tsql._pgtsql_char_max_length(tsql_type_name, true_typmod)
				AS int)
				AS "CHARACTER_MAXIMUM_LENGTH",

			CAST(
				information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, true_typmod)
				AS int)
				AS "CHARACTER_OCTET_LENGTH",

			CAST(
				/* Handle Tinyint separately */
				information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, true_typid, true_typmod)
				AS sys.tinyint)
				AS "NUMERIC_PRECISION",

			CAST(
				information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, true_typid, true_typmod)
				AS smallint)
				AS "NUMERIC_PRECISION_RADIX",

			CAST(
				information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, true_typid, true_typmod)
				AS int)
				AS "NUMERIC_SCALE",

			CAST(
				information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
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
		LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
		information_schema_tsql._pgtsql_truetypid(nt, a, t) AS true_typid,
		information_schema_tsql._pgtsql_truetypmod(nt, a, t) AS true_typmod,
		sys.translate_pg_type_to_tsql(true_typid) AS tsql_type_name

	WHERE (NOT pg_is_other_temp_schema(nc.oid))
		AND a.attnum > 0 AND NOT a.attisdropped
		AND c.relkind IN ('r', 'v', 'p')
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_column_privilege(c.oid, a.attnum,
									'SELECT, INSERT, UPDATE, REFERENCES'))
		AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.columns TO PUBLIC;

/*
 * DOMAINS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.domains AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
		CAST(t.typname AS sys.sysname) AS "DOMAIN_NAME",
		CAST(case when is_tbl_type THEN 'table type' ELSE tsql_type_name END AS sys.sysname) AS "DATA_TYPE",

		CAST(information_schema_tsql._pgtsql_char_max_length(tsql_type_name, t.typtypmod)
			AS int)
		AS "CHARACTER_MAXIMUM_LENGTH",

		CAST(information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, t.typtypmod)
			AS int)
		AS "CHARACTER_OCTET_LENGTH",

		CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
		CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",

		/* Returns Babelfish specific collation name. */
		CAST(
			CASE co.collname
				WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
				ELSE co.collname
			END
		AS sys.nvarchar(128)) AS "COLLATION_NAME",

		CAST(null AS sys.varchar(6)) AS "CHARACTER_SET_CATALOG",
		CAST(null AS sys.varchar(3)) AS "CHARACTER_SET_SCHEMA",
		/*
		 * TODO: We need to first create mapping of collation name to char-set name;
		 * Until then return null.
		 */
		CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

		CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.typbasetype, t.typtypmod)
			AS sys.tinyint)
		AS "NUMERIC_PRECISION",

		CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, t.typbasetype, t.typtypmod)
			AS smallint)
		AS "NUMERIC_PRECISION_RADIX",

		CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.typbasetype, t.typtypmod)
			AS int)
		AS "NUMERIC_SCALE",

		CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, t.typtypmod)
			AS smallint)
		AS "DATETIME_PRECISION",

		CAST(case when is_tbl_type THEN NULL ELSE t.typdefault END AS sys.nvarchar(4000)) AS "DOMAIN_DEFAULT"

		FROM (pg_type t JOIN sys.pg_namespace_ext nc ON t.typnamespace = nc.oid)
		LEFT JOIN pg_collation co ON t.typcollation = co.oid
		LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
		sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_type_name,
		sys.is_table_type(t.typrelid) as is_tbl_type

		WHERE (pg_has_role(t.typowner, 'USAGE')
			OR has_type_privilege(t.oid, 'USAGE'))
		AND (t.typtype = 'd' OR is_tbl_type)
		AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.domains TO PUBLIC;

/*
 * TABLES view
 */

CREATE VIEW information_schema_tsql.tables AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		   CAST(
			 CASE WHEN c.reloptions[1] LIKE 'bbf_original_rel_name%' THEN substring(c.reloptions[1], 23)
                  ELSE c.relname END
			 AS sys._ci_sysname) AS "TABLE_NAME",

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

/*
 * TABLE_CONSTRAINTS view
 */

CREATE VIEW information_schema_tsql.table_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
           CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
           CAST(nr.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
           CAST(extr.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
           CAST(r.relname AS sys.sysname) AS "TABLE_NAME",
           CAST(
             CASE c.contype WHEN 'c' THEN 'CHECK'
                            WHEN 'f' THEN 'FOREIGN KEY'
                            WHEN 'p' THEN 'PRIMARY KEY'
                            WHEN 'u' THEN 'UNIQUE' END
             AS sys.varchar(11)) COLLATE sys.database_default AS "CONSTRAINT_TYPE",
           CAST('NO' AS sys.varchar(2)) AS "IS_DEFERRABLE",
           CAST('NO' AS sys.varchar(2)) AS "INITIALLY_DEFERRED"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nr.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype NOT IN ('t', 'x')
          AND r.relkind IN ('r', 'p')
          AND (NOT pg_is_other_temp_schema(nr.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		  AND  extc.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.table_constraints TO PUBLIC;

/*
 * VIEWS view
 */

CREATE OR REPLACE VIEW information_schema_tsql.views AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
			CAST(ext.orig_name AS sys.nvarchar(128)) AS  "TABLE_SCHEMA",
			CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
			CAST(vd.definition AS sys.nvarchar(4000)) AS "VIEW_DEFINITION",

			CAST(
				CASE WHEN 'check_option=cascaded' = ANY (c.reloptions)
					THEN 'CASCADE'
					ELSE 'NONE' END
				AS sys.varchar(7)) COLLATE sys.database_default AS "CHECK_OPTION",

			CAST('NO' AS sys.varchar(2)) AS "IS_UPDATABLE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		LEFT OUTER JOIN sys.babelfish_namespace_ext ext
			ON (nc.nspname = ext.nspname COLLATE sys.database_default)
		LEFT OUTER JOIN sys.babelfish_view_def vd
			ON ext.dbid = vd.dbid
				AND (ext.orig_name = vd.schema_name COLLATE sys.database_default)
				AND (CAST(c.relname AS sys.nvarchar(128)) = vd.object_name COLLATE sys.database_default)

	WHERE c.relkind = 'v'
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.views TO PUBLIC;

/*
 * CHECK_CONSTRAINTS view
 */

CREATE VIEW information_schema_tsql.check_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
	    CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
	    CAST(sys.tsql_get_constraintdef(c.oid) AS sys.nvarchar(4000)) AS "CHECK_CLAUSE"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nc.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND (NOT pg_is_other_temp_schema(nc.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))
		  AND  extc.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.check_constraints TO PUBLIC;

/*
 * CONSTARINT_COLUMN_USAGE
 */

CREATE OR REPLACE VIEW information_schema_tsql.CONSTRAINT_COLUMN_USAGE AS
SELECT    CAST(tblcat AS sys.nvarchar(128)) AS "TABLE_CATALOG",
          CAST(tblschema AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
          CAST(tblname AS sys.nvarchar(128)) AS "TABLE_NAME" ,
          CAST(colname AS sys.nvarchar(128)) AS "COLUMN_NAME",
          CAST(cstrcat AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
          CAST(cstrschema AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
          CAST(cstrname AS sys.nvarchar(128)) AS "CONSTRAINT_NAME"

FROM (
        /* check constraints */
   SELECT DISTINCT extr.orig_name, r.relname, r.relowner, a.attname, extc.orig_name, c.conname, nr.dbname, nc.dbname
     FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
          sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
          pg_attribute a,
          pg_constraint c,
          pg_class r, pg_depend d

     WHERE nr.oid = r.relnamespace
          AND r.oid = a.attrelid
          AND d.refclassid = 'pg_catalog.pg_class'::regclass
          AND d.refobjid = r.oid
          AND d.refobjsubid = a.attnum
          AND d.classid = 'pg_catalog.pg_constraint'::regclass
          AND d.objid = c.oid
          AND c.connamespace = nc.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND NOT a.attisdropped
	  AND (pg_has_role(r.relowner, 'USAGE')
		OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
		OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))

       UNION ALL

        /* unique/primary key/foreign key constraints */
   SELECT extr.orig_name, r.relname, r.relowner, a.attname, extc.orig_name, c.conname, nr.dbname, nc.dbname
     FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
          sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
          pg_attribute a,
          pg_constraint c,
          pg_class r
     WHERE nr.oid = r.relnamespace
          AND r.oid = a.attrelid
          AND nc.oid = c.connamespace
          AND r.oid = c.conrelid
          AND a.attnum = ANY (c.conkey)
          AND NOT a.attisdropped
          AND c.contype IN ('p', 'u', 'f')
          AND r.relkind IN ('r', 'p')
	  AND (pg_has_role(r.relowner, 'USAGE')
		OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
		OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))

      ) AS x (tblschema, tblname, tblowner, colname, cstrschema, cstrname, tblcat, cstrcat);

GRANT SELECT ON information_schema_tsql.CONSTRAINT_COLUMN_USAGE TO PUBLIC;

/*
* COLUMN_DOMAIN_USAGE
*/

CREATE OR REPLACE VIEW information_schema_tsql.COLUMN_DOMAIN_USAGE AS
    SELECT isc_col."DOMAIN_CATALOG",
           isc_col."DOMAIN_SCHEMA" ,
           CAST(isc_col."DOMAIN_NAME" AS sys.sysname),
           isc_col."TABLE_CATALOG",
           isc_col."TABLE_SCHEMA",
           CAST(isc_col."TABLE_NAME" AS sys.sysname),
           CAST(isc_col."COLUMN_NAME" AS sys.sysname)

    FROM information_schema_tsql.columns AS isc_col
    WHERE isc_col."DOMAIN_NAME" IS NOT NULL;

GRANT SELECT ON information_schema_tsql.COLUMN_DOMAIN_USAGE TO PUBLIC;

/*
 *ISC routines view
 */
CREATE OR REPLACE VIEW information_schema_tsql.routines AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SPECIFIC_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "SPECIFIC_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "SPECIFIC_NAME",
           CAST(nc.dbname AS sys.nvarchar(128)) AS "ROUTINE_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "ROUTINE_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "ROUTINE_NAME",
           CAST(CASE p.prokind WHEN 'f' THEN 'FUNCTION' WHEN 'p' THEN 'PROCEDURE' END
           	 AS sys.nvarchar(20)) AS "ROUTINE_TYPE",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_NAME",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_NAME",
	   CAST(case when is_tbl_type THEN 'table' when p.prokind = 'p' THEN NULL ELSE tsql_type_name END AS sys.nvarchar(128)) AS "DATA_TYPE",
           CAST(information_schema_tsql._pgtsql_char_max_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_MAXIMUM_LENGTH",
           CAST(information_schema_tsql._pgtsql_char_octet_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_OCTET_LENGTH",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_SCHEMA",
           CAST(
                 CASE co.collname
                       WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
                       ELSE co.collname
                 END
            AS sys.nvarchar(128)) AS "COLLATION_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",
	    /*
                 * TODO: We need to first create mapping of collation name to char-set name;
                 * Until then return null.
            */
	    CAST(case when tsql_type_name IN ('nchar','nvarchar') THEN 'UNICODE' when tsql_type_name IN ('char','varchar') THEN 'iso_1' ELSE NULL END AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",
	    CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION",
	    CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_SCALE",
            CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
                        AS smallint)
            AS "DATETIME_PRECISION",
	    CAST(NULL AS sys.nvarchar(30)) AS "INTERVAL_TYPE",
            CAST(NULL AS smallint) AS "INTERVAL_PRECISION",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_NAME",
            CAST(NULL AS bigint) AS "MAXIMUM_CARDINALITY",
            CAST(NULL AS sys.nvarchar(128)) AS "DTD_IDENTIFIER",
            CAST(CASE WHEN l.lanname = 'sql' THEN 'SQL' WHEN l.lanname = 'pltsql' THEN 'SQL' ELSE 'EXTERNAL' END AS sys.nvarchar(30)) AS "ROUTINE_BODY",
            CAST(sys.tsql_get_functiondef(p.oid) AS sys.nvarchar(4000)) AS "ROUTINE_DEFINITION",
            CAST(NULL AS sys.nvarchar(128)) AS "EXTERNAL_NAME",
            CAST(NULL AS sys.nvarchar(30)) AS "EXTERNAL_LANGUAGE",
            CAST(NULL AS sys.nvarchar(30)) AS "PARAMETER_STYLE",
            CAST(CASE WHEN p.provolatile = 'i' THEN 'YES' ELSE 'NO' END AS sys.nvarchar(10)) AS "IS_DETERMINISTIC",
	    CAST(CASE p.prokind WHEN 'p' THEN 'MODIFIES' ELSE 'READS' END AS sys.nvarchar(30)) AS "SQL_DATA_ACCESS",
            CAST(CASE WHEN p.prokind <> 'p' THEN
              CASE WHEN p.proisstrict THEN 'YES' ELSE 'NO' END END AS sys.nvarchar(10)) AS "IS_NULL_CALL",
            CAST(NULL AS sys.nvarchar(128)) AS "SQL_PATH",
            CAST('YES' AS sys.nvarchar(10)) AS "SCHEMA_LEVEL_ROUTINE",
            CAST(CASE p.prokind WHEN 'f' THEN 0 WHEN 'p' THEN -1 END AS smallint) AS "MAX_DYNAMIC_RESULT_SETS",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_USER_DEFINED_CAST",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_IMPLICITLY_INVOCABLE",
            CAST(NULL AS sys.datetime) AS "CREATED",
            CAST(NULL AS sys.datetime) AS "LAST_ALTERED"

       FROM sys.pg_namespace_ext nc LEFT JOIN sys.babelfish_namespace_ext ext ON nc.nspname = ext.nspname,
            pg_proc p inner join sys.schemas sch on sch.schema_id = p.pronamespace
	    inner join sys.all_objects ao on ao.object_id = CAST(p.oid AS INT),
            pg_language l,
            pg_type t LEFT JOIN pg_collation co ON t.typcollation = co.oid,
            sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name,
            sys.tsql_get_returnTypmodValue(p.oid) AS true_typmod,
	    sys.is_table_type(t.typrelid) as is_tbl_type

       WHERE
            (case p.prokind 
	       when 'p' then true 
	       when 'a' then false
               else 
    	           (case format_type(p.prorettype, null) 
	   	      when 'trigger' then false 
	   	      else true 
   		    end) 
            end)  
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND has_function_privilege(p.oid, 'EXECUTE')
            AND (pg_has_role(t.typowner, 'USAGE')
            OR has_type_privilege(t.oid, 'USAGE'))
            AND ext.dbid = cast(sys.db_id() as oid)
	    AND p.prolang = l.oid
            AND p.prorettype = t.oid
            AND p.pronamespace = nc.oid
	    AND CAST(ao.is_ms_shipped as INT) = 0;

GRANT SELECT ON information_schema_tsql.routines TO PUBLIC;

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);
