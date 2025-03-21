------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '5.2.0'" to load this file. \quit

CREATE CAST (INT4 AS sys.BBF_VARBINARY)
WITH FUNCTION sys.int4varbinary (INT4, integer, boolean) AS IMPLICIT;

CREATE CAST (REAL AS sys.BBF_VARBINARY)
WITH FUNCTION sys.float4varbinary (REAL, integer, boolean) AS IMPLICIT;