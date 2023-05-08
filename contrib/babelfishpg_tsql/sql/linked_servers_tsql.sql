CREATE TABLE sys.babelfish_server_options (
	servername sys.SYSNAME NOT NULL PRIMARY KEY COLLATE "C",
	query_timeout INT
);
GRANT SELECT ON sys.babelfish_server_options TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_server_options', '');
