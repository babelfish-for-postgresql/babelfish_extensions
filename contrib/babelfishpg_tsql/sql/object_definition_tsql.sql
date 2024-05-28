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

-- BBF_PARTITION_FUNCTION
-- This catalog stores the metadata of partition funtions.
CREATE TABLE sys.babelfish_partition_function
(
  dbid SMALLINT NOT NULL,
  function_id INT NOT NULL UNIQUE,
  partition_function_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  input_type sys.sysname,
  partition_option sys.bit,
  range_values sys.sql_variant[],
  create_date SYS.DATETIME NOT NULL,
  modify_date SYS.DATETIME NOT NULL,
  PRIMARY KEY(dbid, partition_function_name)
);

-- SEQUENCE to maintain the ID of partition function.
CREATE SEQUENCE sys.babelfish_partition_function_seq START 2 MAXVALUE 2147483647 CYCLE;

-- BBF_PARTITION_SCHEME
-- This catalog stores the metadata of partition schemes.
CREATE TABLE sys.babelfish_partition_scheme
(
  dbid SMALLINT NOT NULL,
  scheme_id INT NOT NULL UNIQUE,
  partition_scheme_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  partition_function_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  next_used sys.bit,
  PRIMARY KEY(dbid, partition_scheme_name)
);

-- SEQUENCE to maintain the ID of partition scheme.
CREATE SEQUENCE sys.babelfish_partition_scheme_seq START 2 MAXVALUE 2147483647 CYCLE;

-- BBF_PARTITION_DEPEND
-- This catalog tracks the dependecy b/w partition scheme and partitioned tables created using that.
CREATE TABLE sys.babelfish_partition_depend
(
  dbid SMALLINT NOT NULL,
  partition_scheme_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  schema_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  table_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  PRIMARY KEY(dbid, schema_name, table_name)
);

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_view_def', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_function', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_scheme', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_depend', '');