CREATE TABLE sys.babelfish_view_def (
	db_name NAME NOT NULL,
	schema_name NAME NOT NULL,
	object_name NAME NOT NULL,
	definition TEXT NOT NULL COLLATE "C",
	PRIMARY KEY(db_name, schema_name, object_name)
);
GRANT SELECT ON sys.babelfish_view_def TO PUBLIC;