-- sys.assemblies should be a view, but the underlying system catalogs have not
-- been implemented in Babelfish yet (sys.sysclsobjs, etc)
CREATE TABLE sys.assemblies(
        name sys.sysname,
        principal_id int,
        assembly_id int,
		clr_name nvarchar(4000),
        permission_set  tinyint,
        permission_set_desc     nvarchar(60),
        is_visible      bit,
        create_date     datetime,
        modify_date     datetime,
        is_user_defined bit
);
GRANT SELECT ON sys.assemblies TO PUBLIC;

CREATE OR REPLACE VIEW sys.assembly_types
AS
SELECT
   CAST(t.name as sys.sysname) AS name,
   -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
   -- This is because the IDs of generated SQL Server system type values generated by B
   -- Babelfish installation will exceed the size of TINYINT.
   CAST(t.system_type_id as int) AS system_type_id,
   CAST(t.user_type_id as int) AS user_type_id,
   CAST(t.schema_id as int) AS schema_id,
   CAST(t.principal_id as int) AS principal_id,
   CAST(t.max_length as smallint) AS max_length,
   CAST(t.precision as sys.tinyint) AS precision,
   CAST(t.scale as sys.tinyint) AS scale,
   CAST(t.collation_name as sys.sysname) AS collation_name,
   CAST(t.is_nullable as sys.bit) AS is_nullable,
   CAST(t.is_user_defined as sys.bit) AS is_user_defined,
   CAST(t.is_assembly_type as sys.bit) AS is_assembly_type,
   CAST(t.default_object_id as int) AS default_object_id,
   CAST(t.rule_object_id as int) AS rule_object_id,
   CAST(NULL as int) AS assembly_id,
   CAST(NULL as sys.sysname) AS assembly_class,
   CAST(NULL as sys.bit) AS is_binary_ordered,
   CAST(NULL as sys.bit) AS is_fixed_length,
   CAST(NULL as sys.nvarchar(40)) AS prog_id,
   CAST(NULL as sys.nvarchar(4000)) AS assembly_qualified_name,
   CAST(t.is_table_type as sys.bit) AS is_table_type
FROM sys.types t
WHERE t.is_assembly_type = 1;
GRANT SELECT ON sys.assembly_types TO PUBLIC;

-- Cannot be implemented without a full implementation of assemblies.
-- However, a full implementation is not needed for import-export support yet
CREATE OR REPLACE FUNCTION assemblyproperty(IN a VARCHAR, IN b VARCHAR) RETURNS sys.sql_variant
AS
$body$
	SELECT CAST('' AS sys.sql_variant);
$body$
LANGUAGE SQL IMMUTABLE STRICT;
GRANT EXECUTE ON FUNCTION assemblyproperty(IN VARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION is_member(IN a VARCHAR) RETURNS INT
AS 'babelfishpg_tsql', 'is_member' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION is_member(IN VARCHAR) TO PUBLIC;

-- Two declarations of schema_id are required because if default value is used
-- for no paramters then we can't differentiate between cases when no argument
-- is passed and when default value is passed as parameter. However, same C 
-- function is called where both the cases are handled.
CREATE OR REPLACE FUNCTION schema_id()
RETURNS INT AS 'babelfishpg_tsql', 'schema_id' LANGUAGE C STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.schema_id() TO PUBLIC;

CREATE OR REPLACE FUNCTION schema_id(IN schema_name sys.SYSNAME)
RETURNS INT AS 'babelfishpg_tsql', 'schema_id' LANGUAGE C STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.schema_id(schema_name sys.SYSNAME) TO PUBLIC;

CREATE OR REPLACE FUNCTION schema_name(IN id oid) RETURNS VARCHAR
AS 'babelfishpg_tsql', 'schema_name' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION schema_name(IN oid) TO PUBLIC;
