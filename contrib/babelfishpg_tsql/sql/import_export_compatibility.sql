CREATE TABLE sys.assemblies(
	name VARCHAR(255),
	principal_id int,
	assembly_id int,
	is_nullable int,
	is_fixed_length int,
	max_length int
);
GRANT SELECT ON sys.assemblies TO PUBLIC;

CREATE TABLE sys.assembly_types (
	assembly_id int,
	assembly_class VARCHAR(255)
);
GRANT SELECT ON sys.assembly_types TO PUBLIC;

-- Cannot be implemented without a full implementation of assemblies.
-- However, a full implementation isn't needed for import-export support yet
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

CREATE OR REPLACE FUNCTION schema_id(IN schema_name VARCHAR) RETURNS INT
AS 'babelfishpg_tsql', 'schema_id' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION schema_id(IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION schema_name(IN id oid) RETURNS VARCHAR
AS 'babelfishpg_tsql', 'schema_name' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION schema_name(IN oid) TO PUBLIC;
