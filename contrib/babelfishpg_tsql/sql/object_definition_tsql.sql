CREATE TABLE sys.babelfish_view_def (
	dbid SMALLINT NOT NULL,
	schema_name sys.SYSNAME NOT NULL,
	object_name sys.SYSNAME NOT NULL,
	definition sys.NTEXT,
	flag_validity BIGINT,
	flag_values BIGINT,
	create_date SYS.DATETIME,
	modify_date SYS.DATETIME,
	PRIMARY KEY(dbid, schema_name, object_name)
);
GRANT SELECT ON sys.babelfish_view_def TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_view_def', '');