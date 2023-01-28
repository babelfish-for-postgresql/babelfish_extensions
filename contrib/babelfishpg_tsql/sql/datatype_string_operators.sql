CREATE OR REPLACE FUNCTION sys.hashbytes(IN alg VARCHAR, IN data VARCHAR) RETURNS sys.bbf_varbinary
AS 'babelfishpg_tsql', 'hashbytes' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.hashbytes(IN VARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.hashbytes(IN alg VARCHAR, IN data sys.bbf_varbinary) RETURNS sys.bbf_varbinary
AS 'babelfishpg_tsql', 'hashbytes' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.hashbytes(IN VARCHAR, IN sys.bbf_varbinary) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.quotename(IN input_string VARCHAR, IN delimiter char default '[') RETURNS
sys.nvarchar AS 'babelfishpg_tsql', 'quotename' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.quotename(IN VARCHAR, IN char) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.unicode(IN str VARCHAR) returns INTEGER
as
$BODY$
	select ascii(str);
$BODY$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.unicode(IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.string_split(IN string VARCHAR, IN separator VARCHAR, OUT value VARCHAR) RETURNS SETOF VARCHAR AS
$body$
DECLARE
    v_string VARCHAR COLLATE "C";
    v_separator VARCHAR COLLATE "C";
BEGIN
	if length(separator) != 1 then
		RAISE EXCEPTION 'Invalid separator: %', separator USING HINT =
		'Separator must be length 1';
        else
	        v_string := string; -- use COLLATE "C"
		v_separator := separator; -- use COLLATE "C"
		RETURN QUERY(SELECT cast(unnest(string_to_array(v_string, v_separator)) as varchar));
        end if;
END
$body$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.string_split(IN VARCHAR, IN VARCHAR, OUT VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.string_escape(IN str sys.NVARCHAR, IN type TEXT) RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'string_escape' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.string_escape(IN sys.NVARCHAR, IN TEXT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.formatmessage(IN message_str TEXT) RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'formatmessage' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.formatmessage(IN TEXT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.formatmessage(IN message_str VARCHAR) RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'formatmessage' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.formatmessage(IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.formatmessage(IN message_str TEXT, VARIADIC "any") RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'formatmessage' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.formatmessage(IN TEXT, VARIADIC "any") TO PUBLIC; 

CREATE OR REPLACE FUNCTION sys.formatmessage(IN message_str VARCHAR, VARIADIC "any") RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'formatmessage' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.formatmessage(IN VARCHAR, VARIADIC "any") TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.format_datetime(IN value anyelement, IN format_pattern NVARCHAR,IN culture VARCHAR,  IN data_type VARCHAR DEFAULT '') RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'format_datetime' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.format_datetime(IN anyelement, IN NVARCHAR, IN VARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.format_numeric(IN value anyelement, IN format_pattern NVARCHAR,IN culture VARCHAR,  IN data_type VARCHAR DEFAULT '', IN e_position INT DEFAULT -1) RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'format_numeric' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.format_numeric(IN anyelement, IN NVARCHAR, IN VARCHAR, IN VARCHAR, IN INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.FORMAT(IN arg anyelement, IN p_format_pattern NVARCHAR, IN p_culture VARCHAR default 'en-us')
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    arg_type regtype;
    v_temp_integer INTEGER;
BEGIN
    arg_type := pg_typeof(arg);

    CASE
        WHEN arg_type IN ('time'::regtype ) THEN
            RETURN sys.format_datetime(arg, p_format_pattern, p_culture, 'time');

        WHEN arg_type IN ('date'::regtype, 'sys.datetime'::regtype, 'sys.smalldatetime'::regtype, 'sys.datetime2'::regtype ) THEN
            RETURN sys.format_datetime(arg::timestamp, p_format_pattern, p_culture);

        WHEN arg_type IN ('sys.tinyint'::regtype) THEN
            RETURN sys.format_numeric(arg::SMALLINT, p_format_pattern, p_culture, 'tinyint');

        WHEN arg_type IN ('smallint'::regtype) THEN
            RETURN sys.format_numeric(arg::SMALLINT, p_format_pattern, p_culture, 'smallint');

        WHEN arg_type IN ('integer'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'integer');

         WHEN arg_type IN ('bigint'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'bigint');

        WHEN arg_type IN ('numeric'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'numeric');

        WHEN arg_type IN ('sys.decimal'::regtype) THEN
            RETURN sys.format_numeric(arg::numeric, p_format_pattern, p_culture, 'numeric');

        WHEN arg_type IN ('real'::regtype) THEN
            IF(p_format_pattern LIKE 'R%') THEN
                v_temp_integer := length(nullif((regexp_matches(arg::real::text, '(?<=\d*\.).*(?=[eE].*)')::text[])[1], ''));
            ELSE v_temp_integer:= -1;
            END IF;

            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'real', v_temp_integer);

        WHEN arg_type IN ('float'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'float');

        WHEN pg_typeof(arg) IN ('sys.smallmoney'::regtype, 'sys.money'::regtype) THEN
            RETURN sys.format_numeric(arg::numeric, p_format_pattern, p_culture, 'numeric');
        ELSE
            RAISE datatype_mismatch;
        END CASE;
EXCEPTION
	WHEN datatype_mismatch THEN
		RAISE USING MESSAGE := format('Argument data type % is invalid for argument 1 of format function.', pg_typeof(arg)),
					DETAIL := 'Invalid datatype.',
					HINT := 'Convert it to valid datatype and try again.';
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.FORMAT(IN anyelement, IN NVARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.STR(IN float_expression NUMERIC, IN length INTEGER DEFAULT 10, IN decimal_point INTEGER DEFAULT 0) RETURNS VARCHAR 
AS
'babelfishpg_tsql', 'float_str' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.STR(IN NUMERIC, IN INTEGER, IN INTEGER) TO PUBLIC;
