-- BBF_PARTITION_FUNCTION
-- This catalog stores the metadata of partition funtions.
CREATE TABLE sys.babelfish_partition_function
(
  dbid SMALLINT NOT NULL, -- to maintain separation b/w databases
  function_id INT NOT NULL UNIQUE, -- globally unique ID of partition function
  partition_function_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  input_parameter_type sys.sysname, -- data type of the column which will be used for partitioning
  partition_option sys.bit, -- whether boundary option is LEFT or RIGHT
  range_values sys.sql_variant[] CHECK (array_length(range_values, 1) < 15000), -- boundary values
  create_date SYS.DATETIME NOT NULL,
  modify_date SYS.DATETIME NOT NULL,
  PRIMARY KEY(dbid, partition_function_name)
);

-- SEQUENCE to maintain the ID of partition function.
CREATE SEQUENCE sys.babelfish_partition_function_seq MAXVALUE 2147483647 CYCLE;

-- BBF_PARTITION_SCHEME
-- This catalog stores the metadata of partition schemes.
CREATE TABLE sys.babelfish_partition_scheme
(
  dbid SMALLINT NOT NULL, -- to maintain separation between databases
  scheme_id INT NOT NULL UNIQUE, -- globally unique ID of partition scheme
  partition_scheme_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  partition_function_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  next_used sys.bit, -- next used filegroup is specified or not during creation
  PRIMARY KEY(dbid, partition_scheme_name)
);

-- SEQUENCE to maintain the ID of partition scheme.
-- The combination of the partition scheme ID and filegroup ID are used as
-- DATA_SPACE_ID, where the value 1 is reseverd for [PRIMARY] filegroup.
CREATE SEQUENCE sys.babelfish_partition_scheme_seq START 2 MAXVALUE 2147483647 CYCLE;

-- BBF_PARTITION_DEPEND
-- This catalog tracks the dependecy between partition scheme and partitioned tables created using that.
CREATE TABLE sys.babelfish_partition_depend
(
  dbid SMALLINT NOT NULL, -- to maintain separation between databases
  partition_scheme_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  schema_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  table_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  PRIMARY KEY(dbid, schema_name, table_name)
);

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_function', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_scheme', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_depend', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_function_seq', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_partition_scheme_seq', '');
