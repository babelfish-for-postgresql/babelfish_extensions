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
BEGIN
	if length(separator) != 1 then
		RAISE EXCEPTION 'Invalid separator: %', separator USING HINT =
		'Separator must be length 1';
else
		RETURN QUERY(SELECT cast(unnest(string_to_array(string, separator)) as varchar));
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
