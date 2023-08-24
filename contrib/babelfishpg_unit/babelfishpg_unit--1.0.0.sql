--complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION IF NOT EXISTS babelfishpg_unit" to load this file. \quit

-- Invoke all tests
CREATE OR REPLACE FUNCTION babelfishpg_unit.babelfishpg_unit_run_tests() RETURNS 
TABLE(TEST_NAME text, STATUS text, MESSAGE text, RUNTIME bigint, ENABLED text)
as 'babelfishpg_unit', 'babelfishpg_unit_run_tests'
LANGUAGE C IMMUTABLE STRICT;

-- Invoke specific tests by passing test_name, cateogry_name or JIRA associated with
CREATE OR REPLACE FUNCTION babelfishpg_unit.babelfishpg_unit_run_tests(VARIADIC name text[]) RETURNS 
TABLE(TEST_NAME text, STATUS text, MESSAGE text, RUNTIME bigint, ENABLED text)
as 'babelfishpg_unit', 'babelfishpg_unit_run_tests' 
LANGUAGE C IMMUTABLE STRICT;
