CREATE TABLE sys.babelfish_view_def (
	dbid SMALLINT NOT NULL,
	schema_name sys.SYSNAME NOT NULL,
	object_name sys.SYSNAME NOT NULL,
	definition TEXT,
	PRIMARY KEY(dbid, schema_name, object_name)
);
GRANT SELECT ON sys.babelfish_view_def TO PUBLIC;
