CREATE TABLE sys.babelfish_view_def (
	dbid SMALLINT NOT NULL,
	schema_name sys.SYSNAME NOT NULL,
	object_name sys.SYSNAME NOT NULL,
	definition sys.NTEXT,
	is_ansi_nulls_on sys.BIT,
	uses_quoted_identifier sys.BIT,
	is_schema_bound	sys.BIT,
	uses_database_collation sys.BIT,
	PRIMARY KEY(dbid, schema_name, object_name)
);
GRANT SELECT ON sys.babelfish_view_def TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_view_def', '');