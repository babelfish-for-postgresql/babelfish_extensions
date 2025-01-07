------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '5.1.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.nvarcharvarbinary(sys.NVARCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'nvarcharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinarysysnvarchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.NVARCHAR
AS 'babelfishpg_common', 'varbinarynvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binarysysnvarchar(sys.BBF_BINARY, integer, boolean)
RETURNS sys.NVARCHAR
AS 'babelfishpg_common', 'varbinarynvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nvarcharbinary(sys.NVARCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'nvarcharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
