CREATE OR REPLACE PROCEDURE sys.sp_reset_connection()
AS 'babelfishpg_tsql', 'sp_reset_connection_internal' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_reset_connection() TO PUBLIC;