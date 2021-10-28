-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION babelfishpg_tds" to load this file. \quit

CREATE FUNCTION sys.inject_fault(
  faultname text,
  num_occurrences int4)
RETURNS text
AS 'MODULE_PATHNAME'
LANGUAGE C VOLATILE STRICT;

CREATE FUNCTION sys.inject_fault(
  faultname text,
  num_occurrences int4,
  tamper_byte int4)
RETURNS text
AS 'MODULE_PATHNAME'
LANGUAGE C VOLATILE STRICT;

CREATE FUNCTION sys.inject_fault_status(
  faultname text)
RETURNS text
AS 'MODULE_PATHNAME'
LANGUAGE C VOLATILE STRICT;

CREATE FUNCTION trigger_test_fault()
RETURNS text
AS 'MODULE_PATHNAME'
LANGUAGE C VOLATILE STRICT;

CREATE FUNCTION sys.inject_fault(
  faultname text)
RETURNS text
AS $$ SELECT sys.inject_fault(faultname, 1) $$
LANGUAGE SQL;

CREATE FUNCTION sys.disable_injected_fault(
  faultname text)
RETURNS text
AS $$ SELECT sys.inject_fault(faultname, 0) $$
LANGUAGE SQL;

CREATE FUNCTION sys.inject_fault_all()
RETURNS text
AS $$ SELECT sys.inject_fault('all', 1) $$
LANGUAGE SQL;

CREATE FUNCTION sys.disable_injected_fault_all()
RETURNS text
AS $$ SELECT sys.inject_fault('all', 0) $$
LANGUAGE SQL;
