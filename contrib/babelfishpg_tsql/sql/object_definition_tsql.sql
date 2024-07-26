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

CREATE TABLE sys.babelfish_pivot_view
(
  dbid SMALLINT NOT NULL,
  pivot_view_uuid sys.NVARCHAR(128) NOT NULL,
  schema_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  pivot_view_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  agg_func_name sys.NVARCHAR(128) NOT NULL,
  PRIMARY KEY(pivot_view_uuid)
);

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_view_def', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_pivot_view', '');