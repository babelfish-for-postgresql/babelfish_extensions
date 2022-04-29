CREATE TABLE sys.babelfish_view_def (
	dbid SMALLINT NOT NULL,
	schema_name NAME NOT NULL,
	object_name NAME NOT NULL,
	definition TEXT NOT NULL COLLATE "C",
	PRIMARY KEY(dbid, schema_name, object_name)
);
GRANT SELECT ON sys.babelfish_view_def TO PUBLIC;
