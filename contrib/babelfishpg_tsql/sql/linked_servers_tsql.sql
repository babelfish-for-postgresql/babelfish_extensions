CREATE TABLE sys.babelfish_server_options (
	servername sys.SYSNAME NOT NULL PRIMARY KEY COLLATE "C",
	query_timeout INT,
	connect_timeout INT,
	rpc_out BOOLEAN DEFAULT FALSE
);
GRANT SELECT ON sys.babelfish_server_options TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_server_options', '');
