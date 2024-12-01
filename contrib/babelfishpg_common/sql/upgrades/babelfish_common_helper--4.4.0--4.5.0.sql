------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "4.5.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.nvarcharvarbinary(sys.NVARCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'nvarcharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.NVARCHAR AS sys.BBF_VARBINARY)
WITH FUNCTION sys.nvarcharvarbinary (sys.NVARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinarysysnvarchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.NVARCHAR
AS 'babelfishpg_common', 'varbinarynvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS sys.NVARCHAR)
WITH FUNCTION sys.varbinarysysnvarchar (sys.BBF_VARBINARY, integer, boolean) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.nvarcharbinary(sys.NVARCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'nvarcharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.NVARCHAR AS sys.BBF_BINARY)
WITH FUNCTION sys.nvarcharbinary (sys.NVARCHAR, integer, boolean) AS ASSIGNMENT;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);

