-- SQL declarations for is_babelfish_namespace with prosupport
-- Run this after building and installing the extension

-- Create the support function first
CREATE OR REPLACE FUNCTION sys.is_babelfish_namespace_support(internal)
RETURNS internal
AS 'babelfishpg_tsql', 'is_babelfish_namespace_support'
LANGUAGE C STRICT;

-- Create the main function with SUPPORT clause
CREATE OR REPLACE FUNCTION sys.is_babelfish_namespace(ns_oid oid)
RETURNS boolean
AS 'babelfishpg_tsql', 'is_babelfish_namespace'
LANGUAGE C STABLE STRICT
SUPPORT sys.is_babelfish_namespace_support;

-- Privilege support function: provides accurate selectivity for has_*_privilege()
CREATE OR REPLACE FUNCTION sys.has_privilege_support(internal)
RETURNS internal
AS 'babelfishpg_tsql', 'has_privilege_support'
LANGUAGE C STRICT;

-- Attach to built-in privilege functions used in system views
UPDATE pg_catalog.pg_proc SET prosupport = 'sys.has_privilege_support'::regproc
WHERE proname = 'has_table_privilege'
  AND pronargs = 2
  AND proargtypes[0] = 'oid'::regtype
  AND proargtypes[1] = 'text'::regtype;

UPDATE pg_catalog.pg_proc SET prosupport = 'sys.has_privilege_support'::regproc
WHERE proname = 'has_function_privilege'
  AND pronargs = 2
  AND proargtypes[0] = 'oid'::regtype
  AND proargtypes[1] = 'text'::regtype;

UPDATE pg_catalog.pg_proc SET prosupport = 'sys.has_privilege_support'::regproc
WHERE proname = 'has_column_privilege'
  AND pronargs = 3
  AND proargtypes[0] = 'oid'::regtype
  AND proargtypes[1] = 'text'::regtype
  AND proargtypes[2] = 'text'::regtype;
