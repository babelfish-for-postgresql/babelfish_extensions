-- Helper functions to support the FOR XML clause
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml(query text, mode int, element_name text,
           binary_base64 boolean, root_name text)
RETURNS xml
AS 'babelfishpg_tsql', 'tsql_query_to_xml'
LANGUAGE C IMMUTABLE STRICT COST 100;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_text(query text, mode int, element_name text,
           binary_base64 boolean, root_name text)
RETURNS ntext
AS 'babelfishpg_tsql', 'tsql_query_to_xml_text'
LANGUAGE C IMMUTABLE STRICT COST 100;

-- User and Login Functions
CREATE OR REPLACE FUNCTION sys.user_name(IN id OID DEFAULT NULL)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'user_name'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.user_id(IN user_name TEXT DEFAULT NULL)
RETURNS OID
AS 'babelfishpg_tsql', 'user_id'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.suser_name_internal(IN server_user_id OID)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'suser_name'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name(IN server_user_id OID)
RETURNS sys.NVARCHAR(128) AS $$
    SELECT CASE 
        WHEN server_user_id IS NULL THEN NULL
        ELSE sys.suser_name_internal(server_user_id)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name()
RETURNS sys.NVARCHAR(128)
AS $$
    SELECT sys.suser_name_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_name but 
-- with a different input data type
CREATE OR REPLACE FUNCTION sys.suser_sname(IN server_user_sid SYS.VARBINARY(85))
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name(CAST(server_user_sid AS INT)); 
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sname()
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name();
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id_internal(IN login TEXT)
RETURNS OID
AS 'babelfishpg_tsql', 'suser_id'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id(IN login TEXT)
RETURNS OID AS $$
    SELECT CASE
        WHEN login IS NULL THEN NULL
        ELSE sys.suser_id_internal(login)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id()
RETURNS OID
AS $$
    SELECT sys.suser_id_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_id but 
-- with different input/output data types. The second argument will be ignored as its functionality is not supported
CREATE OR REPLACE FUNCTION sys.suser_sid(IN login SYS.SYSNAME, IN Param2 INT DEFAULT NULL)
RETURNS SYS.VARBINARY(85) AS $$
    SELECT CASE
    WHEN login = '' 
        THEN CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85))
    ELSE 
        CAST(CAST(sys.suser_id(login) AS INT) AS SYS.VARBINARY(85))
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sid()
RETURNS SYS.VARBINARY(85)
AS $$
    SELECT CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85));
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Matches and returns object name to Oid
CREATE OR REPLACE FUNCTION sys.OBJECT_NAME(IN object_id INT, IN database_id INT DEFAULT NULL)
RETURNS sys.SYSNAME AS
$BODY$
DECLARE
    object_name TEXT;
    object_oid Oid;
    cur_dat_id Oid;
BEGIN
    IF database_id is not NULL THEN
        SELECT Oid INTO cur_dat_id FROM pg_database WHERE datname = current_database();
        IF database_id::Oid != cur_dat_id THEN
            RAISE EXCEPTION 'Can only do lookup in current database.';
        END IF;
    END IF;

    SELECT CAST(object_id AS Oid) INTO object_oid;
    
    -- First check for tables, sequences, views, etc.
    SELECT relname INTO object_name FROM pg_class WHERE Oid = object_oid;
    IF object_name IS NOT NULL THEN
        RETURN object_name::sys.SYSNAME;
    END IF;
    
	-- Check ENR for any matches
    SELECT relname INTO object_name FROM sys.babelfish_get_enr_list() WHERE reloid = object_oid;
    IF object_name IS NOT NULL THEN
        RETURN object_name::sys.SYSNAME;
    END IF;
    
    -- Next check for functions
    SELECT proname INTO object_name FROM pg_proc WHERE Oid = object_oid; 
    IF object_name IS NOT NULL THEN
        RETURN object_name::sys.SYSNAME;
    END IF;

    -- Next check for types
    SELECT typname INTO object_name FROM pg_type WHERE Oid = object_oid;
    IF object_name IS NOT NULL THEN
        RETURN object_name::sys.SYSNAME;
    END IF;
   
    -- Apparently SYSNAME cannot be null so returning empty string
    RETURN '';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.scope_identity()
RETURNS numeric(38,0) AS
$BODY$
	SELECT sys.babelfish_get_last_identity_numeric()::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.ident_seed(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
	SELECT sys.babelfish_get_identity_param(tablename, 'start'::text)::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.ident_incr(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
	SELECT sys.babelfish_get_identity_param(tablename, 'increment'::text)::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.ident_current(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
	SELECT sys.babelfish_get_identity_current(tablename)::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.checksum(VARIADIC arr TEXT[])
RETURNS INTEGER
AS 'babelfishpg_tsql', 'checksum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year NUMERIC,
                                                                IN p_month NUMERIC,
                                                                IN p_day NUMERIC,
                                                                IN p_hour NUMERIC,
                                                                IN p_minute NUMERIC,
                                                                IN p_seconds NUMERIC,
                                                                IN p_fractions NUMERIC,
                                                                IN p_precision NUMERIC)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
   v_fractions VARCHAR;
   v_precision SMALLINT;
   v_err_message VARCHAR;
   v_calc_seconds NUMERIC;
BEGIN
   v_fractions := floor(p_fractions)::INTEGER::VARCHAR;
   v_precision := p_precision::SMALLINT;

   IF (scale(p_precision) > 0) THEN
      RAISE most_specific_type_mismatch;
   ELSIF ((p_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
       (p_month::SMALLINT NOT BETWEEN 1 AND 12) OR
       (p_day::SMALLINT NOT BETWEEN 1 AND 31) OR
       (p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
       (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
       (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > p_precision))
   THEN
      RAISE invalid_datetime_format;
   ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
      RAISE invalid_parameter_value;
   END IF;

   v_calc_seconds := format('%s.%s',
                            floor(p_seconds)::SMALLINT,
                            substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

   RETURN make_timestamp(floor(p_year)::SMALLINT,
                         floor(p_month)::SMALLINT,
                         floor(p_day)::SMALLINT,
                         floor(p_hour)::SMALLINT,
                         floor(p_minute)::SMALLINT,
                         v_calc_seconds);
EXCEPTION
   WHEN most_specific_type_mismatch THEN
      RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type DATETIME2 scale argument are integer constants and integer constant expressions.',
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_parameter_value THEN
      RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_precision),
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_datetime_format THEN
      RAISE USING MESSAGE := 'Cannot construct data type DATETIME2, some of the arguments have values which are not valid.',
                  DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                  HINT := 'Check each input argument belongs to the valid range and try again.';

   WHEN numeric_value_out_of_range THEN
      GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
      v_err_message := upper(split_part(v_err_message, ' ', 1));

      RAISE USING MESSAGE := format('Error while trying to cast to %s data type.', v_err_message),
                  DETAIL := format('Source value is out of %s data type range.', v_err_message),
                  HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                 v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year TEXT,
                                                                IN p_month TEXT,
                                                                IN p_day TEXT,
                                                                IN p_hour TEXT,
                                                                IN p_minute TEXT,
                                                                IN p_seconds TEXT,
                                                                IN p_fractions TEXT,
                                                                IN p_precision TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.datetime2fromparts(p_year::NUMERIC, p_month::NUMERIC, p_day::NUMERIC,
                                                p_hour::NUMERIC, p_minute::NUMERIC, p_seconds::NUMERIC,
                                                p_fractions::NUMERIC, p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetimefromparts(IN p_year NUMERIC,
                                                               IN p_month NUMERIC,
                                                               IN p_day NUMERIC,
                                                               IN p_hour NUMERIC,
                                                               IN p_minute NUMERIC,
                                                               IN p_seconds NUMERIC,
                                                               IN p_milliseconds NUMERIC)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
    v_calc_seconds NUMERIC;
    v_milliseconds SMALLINT;
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
BEGIN
    -- Check if arguments are out of range
    IF ((floor(p_year)::SMALLINT NOT BETWEEN 1753 AND 9999) OR
        (floor(p_month)::SMALLINT NOT BETWEEN 1 AND 12) OR
        (floor(p_day)::SMALLINT NOT BETWEEN 1 AND 31) OR
        (floor(p_hour)::SMALLINT NOT BETWEEN 0 AND 23) OR
        (floor(p_minute)::SMALLINT NOT BETWEEN 0 AND 59) OR
        (floor(p_seconds)::SMALLINT NOT BETWEEN 0 AND 59) OR
        (floor(p_milliseconds)::SMALLINT NOT BETWEEN 0 AND 999))
    THEN
        RAISE invalid_datetime_format;
    END IF;

    v_milliseconds := sys.babelfish_round_fractseconds(p_milliseconds::INTEGER);

    v_calc_seconds := format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             CASE v_milliseconds
                                WHEN 1000 THEN '0'
                                ELSE lpad(v_milliseconds::VARCHAR, 3, '0')
                             END)::NUMERIC;

    v_resdatetime := make_timestamp(floor(p_year)::SMALLINT,
                                    floor(p_month)::SMALLINT,
                                    floor(p_day)::SMALLINT,
                                    floor(p_hour)::SMALLINT,
                                    floor(p_minute)::SMALLINT,
                                    v_calc_seconds);
    RETURN CASE
              WHEN (v_milliseconds != 1000) THEN v_resdatetime
              ELSE v_resdatetime + INTERVAL '1 second'
           END;
EXCEPTION
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type datetime, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := upper(split_part(v_err_message, ' ', 1));

        RAISE USING MESSAGE := format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := format('Source value is out of %s data type range.', v_err_message),
                    HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetimefromparts(IN p_year TEXT,
                                                               IN p_month TEXT,
                                                               IN p_day TEXT,
                                                               IN p_hour TEXT,
                                                               IN p_minute TEXT,
                                                               IN p_seconds TEXT,
                                                               IN p_milliseconds TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.datetimefromparts(p_year::NUMERIC, p_month::NUMERIC, p_day::NUMERIC,
                                               p_hour::NUMERIC, p_minute::NUMERIC,
                                               p_seconds::NUMERIC, p_milliseconds::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr ANYELEMENT) RETURNS INTEGER AS
$BODY$
DECLARE 
    x NUMERIC;
    y MONEY;
BEGIN
    IF (expr IS NULL) THEN
	    RETURN 0;
    END IF;
    IF ($1::VARCHAR ~ '^\s*$') THEN 
	    RETURN 0;
    END IF;
    IF pg_typeof(expr) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,
    'numeric'::regtype, 'float'::regtype, 'real'::regtype, 'sys.money'::regtype)
	THEN
		RETURN 1;
	END IF;
    x = $1::NUMERIC;
    RETURN 1;
EXCEPTION WHEN others THEN
    BEGIN
        y = $1::sys.MONEY;
        RETURN 1;
        EXCEPTION WHEN others THEN
            RETURN 0;
    END;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr TEXT) RETURNS INTEGER AS
$BODY$
DECLARE 
    x NUMERIC;
    y MONEY;
BEGIN
    IF (expr IS NULL) THEN
	    RETURN 0;
    END IF;
    IF ($1::VARCHAR ~ '^\s*$') THEN 
	    RETURN 0;
    END IF;
    IF pg_typeof(expr) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,
    'numeric'::regtype, 'float'::regtype, 'real'::regtype, 'sys.money'::regtype)
	THEN
		RETURN 1;
	END IF;
    x = $1::NUMERIC;
    RETURN 1;
EXCEPTION WHEN others THEN
    BEGIN
        y = $1::sys.MONEY;
        RETURN 1;
        EXCEPTION WHEN others THEN
            RETURN 0;
    END;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE CALLED ON NULL INPUT;

-- Return the object ID given the object name. Can specify optional type.
CREATE OR REPLACE FUNCTION sys.object_id(IN object_name TEXT, IN object_type char(2) DEFAULT '')
RETURNS INTEGER AS
$BODY$
DECLARE
        id oid;
        db_name text;
        bbf_schema_name text;
		schema_name text;
        schema_oid oid;
        obj_name text;
        is_temp_object boolean;
BEGIN
        id = null;
        schema_oid = NULL;

        SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, obj_name
        FROM sys.babelfish_split_object_name(object_name) s;

        -- Invalid object_name
        IF obj_name IS NULL OR obj_name = '' THEN
            RETURN NULL;
        END IF;

        IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
            bbf_schema_name := sys.schema_name();
        END IF;

        schema_name := sys.bbf_get_current_physical_schema_name(bbf_schema_name);

        -- Check if looking for temp object.
        is_temp_object = left(obj_name, 1) = '#';

        -- Can only search in current database. Allowing tempdb for temp objects.
        IF db_name IS NOT NULL AND db_name <> db_name() AND db_name <> 'tempdb' THEN
            RAISE EXCEPTION 'Can only do lookup in current database.';
        END IF;

        IF schema_name IS NULL OR schema_name = '' THEN
            RETURN NULL;
        END IF;

        -- Searching within a schema. Get schema oid.
        schema_oid = (SELECT oid FROM pg_namespace WHERE nspname = schema_name);
        IF schema_oid IS NULL THEN
            RETURN NULL;
        END IF;

        if object_type <> '' then
            case
                -- Schema does not apply as much to temp objects.
                when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
	            id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) = obj_name limit 1);

                when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
	            id := (select oid from pg_class where lower(relname) = obj_name
                            and relnamespace = schema_oid limit 1);

                when upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
	            id := (select oid from pg_constraint where lower(conname) = obj_name
                            and connamespace = schema_oid limit 1);

                when upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
	            id := (select oid from pg_proc where lower(proname) = obj_name
                            and pronamespace = schema_oid limit 1);

                when upper(object_type) in ('TR', 'TA') then
	            id := (select oid from pg_trigger where lower(tgname) = obj_name limit 1);

                -- Throwing exception as a reminder to add support in the future.
                when upper(object_type) in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                    RAISE EXCEPTION 'Object type currently unsupported.';

                -- unsupported object_type
                else id := null;
            end case;
        else
            if not is_temp_object then id := (
                                            select oid from pg_class where lower(relname) = obj_name
                                                and relnamespace = schema_oid
				            union
			                select oid from pg_constraint where lower(conname) = obj_name
				            and connamespace = schema_oid
                                                union
			                select oid from pg_proc where lower(proname) = obj_name
				            and pronamespace = schema_oid
                                                union
			                select oid from pg_trigger where lower(tgname) = obj_name
			                limit 1);
            else
                -- temp object without "object_type" in-argument
                id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) = obj_name limit 1);
            end if;
        end if;

        RETURN id::integer;
END;
$BODY$
LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.parsename (
	object_name VARCHAR
	,object_piece INT
	)
RETURNS VARCHAR AS $$
/***************************************************************
EXTENSION PACK function PARSENAME(x)
***************************************************************/
SELECT CASE
		WHEN char_length($1) < char_length(replace($1, '.', '')) + 4
			AND $2 BETWEEN 1
				AND 4
			THEN reverse(split_part(reverse($1), '.', $2))
		ELSE NULL
		END $$ immutable LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour NUMERIC,
                                                           IN p_minute NUMERIC,
                                                           IN p_seconds NUMERIC,
                                                           IN p_fractions NUMERIC,
                                                           IN p_precision NUMERIC)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_fractions VARCHAR;
    v_precision SMALLINT;
    v_err_message VARCHAR;
    v_calc_seconds NUMERIC;
BEGIN
    v_fractions := floor(p_fractions)::INTEGER::VARCHAR;
    v_precision := p_precision::SMALLINT;

    IF (scale(p_precision) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF ((p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
           (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
           (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
           (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
           (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > p_precision))
    THEN
        RAISE invalid_datetime_format;
    ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
        RAISE numeric_value_out_of_range;
    END IF;

    v_calc_seconds := format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

    RETURN make_time(floor(p_hour)::SMALLINT,
                     floor(p_minute)::SMALLINT,
                     v_calc_seconds);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type DATETIME2 scale argument are integer constants and integer constant expressions.',
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_precision),
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type time, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := upper(split_part(v_err_message, ' ', 1));

        RAISE USING MESSAGE := format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := format('Source value is out of %s data type range.', v_err_message),
                    HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour TEXT,
                                                           IN p_minute TEXT,
                                                           IN p_seconds TEXT,
                                                           IN p_fractions TEXT,
                                                           IN p_precision TEXT)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.timefromparts(p_hour::NUMERIC, p_minute::NUMERIC,
                                           p_seconds::NUMERIC, p_fractions::NUMERIC,
                                           p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.has_dbaccess(database_name SYSNAME) RETURNS INTEGER AS 
'babelfishpg_tsql', 'has_dbaccess'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION sys.datefromparts(IN year INT, IN month INT, IN day INT)
RETURNS DATE AS
$BODY$
SELECT make_date(year, month, day);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.charindex(expressionToFind PG_CATALOG.TEXT,
										 expressionToSearch PG_CATALOG.TEXT,
										 start_location INTEGER DEFAULT 0)
RETURNS INTEGER AS
$BODY$
SELECT
CASE
WHEN start_location <= 0 THEN
	strpos(expressionToSearch, expressionToFind)
ELSE
	CASE
	WHEN strpos(substr(expressionToSearch, start_location), expressionToFind) = 0 THEN
		0
	ELSE
		strpos(substr(expressionToSearch, start_location), expressionToFind) + start_location - 1
	END
END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.stuff(expr TEXT, start INTEGER, length INTEGER, replace_expr TEXT)
RETURNS TEXT AS
$BODY$
SELECT
CASE
WHEN start <= 0 or start > length(expr) or length < 0 THEN
	NULL
WHEN replace_expr is NULL THEN
	overlay (expr placing '' from start for length)
ELSE
	overlay (expr placing replace_expr from start for length)
END;
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.stuff(expr ANYELEMENT, start INTEGER, length INTEGER, replace_expr ANYELEMENT)
RETURNS ANYELEMENT AS
$BODY$
SELECT
CASE
WHEN start <= 0 or start > length(expr) or length < 0 THEN
	NULL
WHEN replace_expr is NULL THEN
	overlay (expr placing '' from start for length)
ELSE
	overlay (expr placing replace_expr from start for length)
END;
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.len(expr TEXT) RETURNS INTEGER AS
$BODY$
SELECT length(trim(trailing from expr));
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

-- Added for BABEL-1544
CREATE OR REPLACE FUNCTION sys.len(expr sys.BBF_VARBINARY) RETURNS INTEGER AS
'babelfishpg_common', 'varbinary_length'
STRICT
LANGUAGE c IMMUTABLE PARALLEL SAFE;

-- DATALENGTH
CREATE OR REPLACE FUNCTION sys.datalength(ANYELEMENT) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
-- provide both additional functions here to avoid implicit casting between string literals with/without N''
CREATE OR REPLACE FUNCTION sys.datalength(text) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION sys.datalength(char) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
-- TODO: in MSSQL datalength against varchar(max) will return BIGINT instead of INTEGER. However in PG we ignore typmods in functions.
-- However this is not a critical issue so we will just leave it. We may come back to this difference later once we find out solution to typmods.

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER)
RETURNS NUMERIC AS 'babelfishpg_common', 'tsql_numeric_round' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER)
RETURNS NUMERIC AS 'babelfishpg_common', 'tsql_numeric_trunc' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.day(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('day', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.month(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('month', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.year(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('year', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.space(IN number INTEGER, OUT result SYS.VARCHAR) AS $$
-- sys.varchar has default length of 1, so we have to pass in 'number' to be the
-- type modifier.
BEGIN
	EXECUTE format(E'SELECT repeat(\' \', %s)::SYS.VARCHAR(%s)', number, number) INTO result;
END;
$$
STRICT
LANGUAGE plpgsql;

create or replace function sys.isdate(v text)
returns integer
as
$body$
begin
    if v is NULL THEN
        return 0;
    else
        perform v::date;
        return 1;
    end if;
    EXCEPTION WHEN others THEN
    RETURN 0;
end
$body$
language 'plpgsql';

create or replace function sys.PATINDEX(in pattern character varying, in expression character varying) returns bigint as
$body$
declare
  v_find_result character varying;
  v_pos bigint;
  v_regexp_pattern character varying;
begin
  v_pos := null;
  if left(pattern, 1) = '%' then
    v_regexp_pattern := regexp_replace(pattern, '^%', '%#"');
  else
    v_regexp_pattern := '#"' || pattern;
  end if;

  if right(pattern, 1) = '%' then
    v_regexp_pattern := regexp_replace(v_regexp_pattern, '%$', '#"%');
  else
   v_regexp_pattern := v_regexp_pattern || '#"';
 end if;
  v_find_result := substring(expression from v_regexp_pattern for '#');
  if v_find_result <> '' then
    v_pos := strpos(expression, v_find_result);
  end if;
  return v_pos;
end;
$body$
language plpgsql returns null on null input;

create or replace function sys.RAND(x in int)returns double precision
AS 'babelfishpg_tsql', 'tsql_random'
LANGUAGE C IMMUTABLE STRICT COST 1 PARALLEL RESTRICTED;

create or replace function sys.square(in x double precision) returns double precision
AS
$BODY$
DECLARE
	res double precision;
BEGIN
	res = pow(x, 2::float);
	return res;
END;
$BODY$
LANGUAGE plpgsql PARALLEL SAFE IMMUTABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datepart(IN datepart PG_CATALOG.TEXT, IN arg anyelement) RETURNS INTEGER
AS
$body$
BEGIN
    IF pg_typeof(arg) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.datepart_internal(datepart, arg::timestamp,
                     sys.babelfish_get_datetimeoffset_tzoffset(arg)::integer);
    ELSE
        return sys.datepart_internal(datepart, arg);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

-- Duplicate function with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datepart(IN datepart PG_CATALOG.TEXT, IN arg TEXT) RETURNS INTEGER
AS
$body$
BEGIN
    IF pg_typeof(arg) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.datepart_internal(datepart, arg::timestamp,
                     sys.babelfish_get_datetimeoffset_tzoffset(arg)::integer);
    ELSE
        return sys.datepart_internal(datepart, arg);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal_df(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

 -- Duplicate functions with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate TEXT) RETURNS DATETIME
AS
$body$
BEGIN
    IF pg_typeof(startdate) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.dateadd_internal_df(datepart, num,
                     startdate);
    ELSE
        return sys.dateadd_internal(datepart, num,
                     startdate);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT
AS
$body$
BEGIN
    IF pg_typeof(startdate) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.dateadd_internal_df(datepart, num,
                     startdate);
    ELSE
        return sys.dateadd_internal(datepart, num,
                     startdate);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(IN datepart PG_CATALOG.TEXT, IN arg anyelement,IN df_tz INTEGER DEFAULT 0) RETURNS INTEGER AS $$
DECLARE
	result INTEGER;
	first_day DATE;
	first_week_end INTEGER;
	day INTEGER;
BEGIN
	CASE datepart
	WHEN 'dow' THEN
		result = (date_part(datepart, arg)::INTEGER - current_setting('babelfishpg_tsql.datefirst')::INTEGER + 7) % 7 + 1;
	WHEN 'tsql_week' THEN
		first_day = make_date(date_part('year', arg)::INTEGER, 1, 1);
		first_week_end = 8 - sys.datepart_internal('dow', first_day)::INTEGER;
		day = date_part('doy', arg)::INTEGER;
		IF day <= first_week_end THEN
			result = 1;
		ELSE
			result = 2 + (day - first_week_end - 1) / 7;
		END IF;
	WHEN 'second' THEN
		result = TRUNC(date_part(datepart, arg))::INTEGER;
	WHEN 'millisecond' THEN
		result = right(date_part(datepart, arg)::TEXT, 3)::INTEGER;
	WHEN 'microsecond' THEN
		result = right(date_part(datepart, arg)::TEXT, 6)::INTEGER;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		result = right(date_part('microsecond', arg)::TEXT, 6)::INTEGER * 1000;
	WHEN 'tzoffset' THEN
		-- timezone for datetimeoffset
		result = df_tz;
	ELSE
		result = date_part(datepart, arg)::INTEGER;
	END CASE;
	RETURN result;
EXCEPTION WHEN invalid_parameter_value THEN
    -- date_part() throws an exception when trying to get day/month/year etc. from
	-- TIME, so we just need to catch the exception in this case
	-- date_part() returns 0 when trying to get hour/minute/second etc. from
	-- DATE, which is the desirable behavior for datepart() as well.
    -- If the date argument data type does not have the specified datepart,
    -- date_part() will return the default value for that datepart.
    CASE datepart
	-- Case for datepart is year, yy and yyyy, all mappings are defined in gram.y.
    WHEN 'year' THEN RETURN 1900;
    -- Case for datepart is quater, qq and q
    WHEN 'quarter' THEN RETURN 1;
    -- Case for datepart is month, mm and m
    WHEN 'month' THEN RETURN 1;
    -- Case for datepart is day, dd and d
    WHEN 'day' THEN RETURN 1;
    -- Case for datepart is dayofyear, dy
    WHEN 'doy' THEN RETURN 1;
    -- Case for datepart is y(also refers to dayofyear)
    WHEN 'y' THEN RETURN 1;
    -- Case for datepart is week, wk and ww
    WHEN 'tsql_week' THEN RETURN 1;
    -- Case for datepart is iso_week, isowk and isoww
    WHEN 'week' THEN RETURN 1;
    -- Case for datepart is tzoffset and tz
    WHEN 'tzoffset' THEN RETURN 0;
    -- Case for datepart is weekday and dw, return dow according to datefirst
    WHEN 'dow' THEN
        RETURN (1 - current_setting('babelfishpg_tsql.datefirst')::INTEGER + 7) % 7 + 1 ;
	ELSE
        RAISE EXCEPTION '''%'' is not a recognized datepart option', datepart;
        RETURN -1;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd_internal_df(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate datetimeoffset) RETURNS datetimeoffset AS $$
BEGIN
	CASE datepart
	WHEN 'year' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(years => num);
	WHEN 'quarter' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(months => num * 3);
	WHEN 'month' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(months => num);
	WHEN 'dayofyear', 'y' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'day' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'week' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(weeks => num);
	WHEN 'weekday' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(days => num);
	WHEN 'hour' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(hours => num);
	WHEN 'minute' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(mins => num);
	WHEN 'second' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => num);
	WHEN 'millisecond' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => num * 0.001);
	WHEN 'microsecond' THEN
		RETURN startdate OPERATOR(sys.+) make_interval(secs => num * 0.000001);
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		RETURN startdate;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized dateadd option.', datepart;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd_internal(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT AS $$
BEGIN
    IF pg_typeof(startdate) = 'date'::regtype AND
		datepart IN ('hour', 'minute', 'second', 'millisecond', 'microsecond', 'nanosecond') THEN
		RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type date.', datepart;
	END IF;
    IF pg_typeof(startdate) = 'time'::regtype AND
		datepart IN ('year', 'quarter', 'month', 'doy', 'day', 'week', 'weekday') THEN
		RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type time.', datepart;
	END IF;

	CASE datepart
	WHEN 'year' THEN
		RETURN startdate + make_interval(years => num);
	WHEN 'quarter' THEN
		RETURN startdate + make_interval(months => num * 3);
	WHEN 'month' THEN
		RETURN startdate + make_interval(months => num);
	WHEN 'dayofyear', 'y' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'day' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'week' THEN
		RETURN startdate + make_interval(weeks => num);
	WHEN 'weekday' THEN
		RETURN startdate + make_interval(days => num);
	WHEN 'hour' THEN
		RETURN startdate + make_interval(hours => num);
	WHEN 'minute' THEN
		RETURN startdate + make_interval(mins => num);
	WHEN 'second' THEN
		RETURN startdate + make_interval(secs => num);
	WHEN 'millisecond' THEN
		RETURN startdate + make_interval(secs => num * 0.001);
	WHEN 'microsecond' THEN
		RETURN startdate + make_interval(secs => num * 0.000001);
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		RETURN startdate;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized dateadd option.', datepart;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_internal_df(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS INTEGER AS $$
DECLARE
	result INTEGER;
	year_diff INTEGER;
	month_diff INTEGER;
	day_diff INTEGER;
	hour_diff INTEGER;
	minute_diff INTEGER;
	second_diff INTEGER;
	millisecond_diff INTEGER;
	microsecond_diff INTEGER;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		month_diff = sys.datepart('month', enddate) - sys.datepart('month', startdate);
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
		month_diff = sys.datepart('month', enddate) - sys.datepart('month', startdate);
		result = year_diff * 12 + month_diff;
	WHEN 'doy', 'y' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		result = day_diff;
	WHEN 'day' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		result = day_diff;
	WHEN 'week' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		result = day_diff / 7;
	WHEN 'hour' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		result = day_diff * 24 + hour_diff;
	WHEN 'minute' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
	WHEN 'second' THEN
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we don't need to add second_diff again
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we don't need to add second_diff and millisecond_diff again
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(sys.datepart('microsecond', enddate OPERATOR(sys.-) startdate));
		result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = sys.datepart('day', enddate - startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(sys.datepart('microsecond', enddate OPERATOR(sys.-) startdate));
		result = (((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff) * 1000;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
	END CASE;

	return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_internal(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS INTEGER AS $$
DECLARE
	result INTEGER;
	year_diff INTEGER;
	month_diff INTEGER;
	day_diff INTEGER;
	hour_diff INTEGER;
	minute_diff INTEGER;
	second_diff INTEGER;
	millisecond_diff INTEGER;
	microsecond_diff INTEGER;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		month_diff = date_part('month', enddate)::INTEGER - date_part('month', startdate)::INTEGER;
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
		month_diff = date_part('month', enddate)::INTEGER - date_part('month', startdate)::INTEGER;
		result = year_diff * 12 + month_diff;
	WHEN 'doy', 'y' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		result = day_diff;
	WHEN 'day' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		result = day_diff;
	WHEN 'week' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		result = day_diff / 7;
	WHEN 'hour' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		result = day_diff * 24 + hour_diff;
	WHEN 'minute' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
	WHEN 'second' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we don't need to add second_diff again
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we don't need to add second_diff and millisecond_diff again
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
		result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
		result = (((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff) * 1000;
	ELSE
		RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
	END CASE;

	return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg anyelement) RETURNS TEXT AS 
$BODY$
SELECT
    CASE
    WHEN dp = 'month'::text THEN
        to_char(arg::date, 'TMMonth')
    -- '1969-12-28' is a Sunday
    WHEN dp = 'dow'::text THEN
        to_char(arg::date, 'TMDay')
    ELSE
        sys.datepart(dp, arg)::TEXT
    END 
$BODY$
STRICT
LANGUAGE sql IMMUTABLE;

-- Duplicate functions with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg TEXT) RETURNS TEXT AS
$BODY$
SELECT
    CASE
    WHEN dp = 'month'::text THEN
        to_char(arg::date, 'TMMonth')
    -- '1969-12-28' is a Sunday
    WHEN dp = 'dow'::text THEN
        to_char(arg::date, 'TMDay')
    ELSE
        sys.datepart(dp, arg)::TEXT
    END
$BODY$
STRICT
LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.GETUTCDATE() RETURNS sys.DATETIME AS
$BODY$
SELECT CAST(CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS sys.DATETIME);
$BODY$
LANGUAGE SQL PARALLEL SAFE;

-- These come from the built-in pg_catalog.count in pg_aggregate.dat
CREATE AGGREGATE sys.count(*)
(
	sfunc = int8inc,
	combinefunc = int8pl,
	msfunc = int8inc,
	minvfunc = int8dec,
	stype = int8,
	mstype = int8,
	initcond = 0,
	minitcond = 0,
	finalfunc = int4,
	mfinalfunc = int4,
	parallel = safe
);

CREATE AGGREGATE sys.count("any")
(
	sfunc = int8inc_any,
	combinefunc = int8pl,
	msfunc = int8inc_any,
	minvfunc = int8dec_any,
	stype = int8,
	mstype = int8,
	initcond = 0,
	minitcond = 0,
	finalfunc = int4,
	mfinalfunc = int4,
	parallel = safe
);

CREATE AGGREGATE sys.count_big(*)
(
	sfunc = int8inc,
	combinefunc = int8pl,
	msfunc = int8inc,
	minvfunc = int8dec,
	stype = int8,
	mstype = int8,
	initcond = 0,
	minitcond = 0,
	parallel = safe
);

CREATE AGGREGATE sys.count_big("any")
(
	sfunc = int8inc_any,
	combinefunc = int8pl,
	msfunc = int8inc_any,
	minvfunc = int8dec_any,
	stype = int8,
	mstype = int8,
	initcond = 0,
	minitcond = 0,
	parallel = safe
);

CREATE OR REPLACE FUNCTION sys.REPLICATE(string TEXT, number INTEGER)
RETURNS VARCHAR AS
$BODY$
SELECT 
    CASE 
        WHEN number >= 0 THEN repeat(string, number)
        ELSE null
    END;
$BODY$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- @@ functions
CREATE OR REPLACE FUNCTION sys.rowcount()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error()
	   RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.pgerror()
	   RETURNS VARCHAR AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.trancount()
	   RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.datefirst()
	   RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.options()
	   RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.version()
        RETURNS sys.NVARCHAR(255)  AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.servername()
        RETURNS sys.NVARCHAR(128)  AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.servicename()
        RETURNS sys.NVARCHAR(128)  AS 'babelfishpg_tsql' LANGUAGE C;

-- In tsql @@max_precision represents max precision that server supports
-- As of now, we do not support change in max_precision. So, returning default value
CREATE OR REPLACE FUNCTION sys.max_precision()
RETURNS sys.TINYINT  AS 
$$
BEGIN
  RETURN 38;
END;
$$
LANGUAGE plpgsql;

-- not supported, only syntax support
CREATE OR REPLACE FUNCTION sys.PROCID()
	RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.spid()
RETURNS INTEGER AS
$BODY$
SELECT pg_backend_pid();
$BODY$
STRICT
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.get_current_full_xact_id()
    RETURNS XID8 AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'DBTS is not currently supported in Babelfish. please use babelfishpg_tsql.escape_hatch_rowversion to ignore';
    ELSE
        RETURN pg_snapshot_xmin(pg_current_snapshot())::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.nestlevel() RETURNS INTEGER AS
$$
DECLARE
    stack text;
    result integer;
BEGIN
    GET DIAGNOSTICS stack = PG_CONTEXT;
    result := array_length(string_to_array(stack, 'function'), 1) - 2;
    IF result < 0 THEN
        RAISE EXCEPTION 'Invalid output, check stack trace %', stack;
    ELSE
        RETURN result;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.fetch_status()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.cursor_rows()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.cursor_status(text, text)
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

-- Floor for bit
CREATE OR REPLACE FUNCTION sys.floor(sys.bit) RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'bit_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Floor overloading for all int types
CREATE OR REPLACE FUNCTION sys.floor(bigint) RETURNS BIGINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(int) RETURNS INT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(smallint) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(tinyint) RETURNS TINYINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Ceiling for bit
CREATE OR REPLACE FUNCTION sys.ceiling(sys.bit) RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'bit_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Ceiling overloading for all int types
CREATE OR REPLACE FUNCTION sys.ceiling(bigint) RETURNS BIGINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(int) RETURNS INT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(smallint) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(tinyint) RETURNS TINYINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.microsoftversion()
RETURNS INTEGER AS
$BODY$
	SELECT 201332885::INTEGER;
$BODY$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION sys.APPLOCK_MODE(IN "@dbprincipal" varchar(32),
                                            IN "@resource" varchar(255),
                                            IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION')
RETURNS TEXT
AS 'babelfishpg_tsql', 'APPLOCK_MODE' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.APPLOCK_TEST(IN "@dbprincipal" varchar(32),
                                            IN "@resource" varchar(255),
											IN "@lockmode" varchar(32),
                                            IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION')
RETURNS SMALLINT
AS 'babelfishpg_tsql', 'APPLOCK_TEST' LANGUAGE C;

-- Error handling functions
CREATE OR REPLACE FUNCTION sys.xact_state()
RETURNS SMALLINT
AS 'babelfishpg_tsql', 'xact_state' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_line()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_line' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_message()
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'pltsql_error_message' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_number()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_number' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_procedure()
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'pltsql_error_procedure' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_severity()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_severity' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_state()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_state' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.rand() RETURNS FLOAT AS
$$
	SELECT random();
$$
LANGUAGE SQL VOLATILE STRICT PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.DEFAULT_DOMAIN()
RETURNS TEXT
AS 'babelfishpg_tsql', 'default_domain' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.db_id(sys.nvarchar(128)) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'babelfish_db_id'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_id() RETURNS SMALLINT
AS 'babelfishpg_tsql', 'babelfish_db_id'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_name(int) RETURNS sys.nvarchar(128)
AS 'babelfishpg_tsql', 'babelfish_db_name'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_name() RETURNS sys.nvarchar(128)
AS 'babelfishpg_tsql', 'babelfish_db_name'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

-- BABEL-1783: (partial) support for sys.fn_listextendedproperty
create table if not exists sys.extended_properties (
class sys.tinyint,
class_desc sys.nvarchar(60),
major_id int,
minor_id int,
name sys.sysname,
value sys.sql_variant
);
GRANT SELECT ON sys.extended_properties TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.fn_listextendedproperty (
property_name varchar(128),
level0_object_type varchar(128),
level0_object_name varchar(128),
level1_object_type varchar(128),
level1_object_name varchar(128),
level2_object_type varchar(128),
level2_object_name varchar(128)
)
returns table (
objtype	sys.sysname,
objname	sys.sysname,
name	sys.sysname,
value	sys.sql_variant
) 
as $$
begin
-- currently only support COLUMN property
IF (((SELECT coalesce(property_name, '')) = '') or
    ((SELECT coalesce(property_name, '')) = 'COLUMN')) THEN
	IF (((SELECT coalesce(level0_object_type, '')) = 'schema') and
	    ((SELECT coalesce(level1_object_type, '')) = 'table') and
	    ((SELECT coalesce(level2_object_type, '')) = 'column')) THEN
		RETURN query 
		select CAST('COLUMN' AS sys.sysname) as objtype,
		       CAST(t3.column_name AS sys.sysname) as objname,
		       t1.name as name,
		       t1.value as value
		from sys.extended_properties t1, pg_catalog.pg_class t2, information_schema.columns t3
		where t1.major_id = t2.oid and 
			  t2.relname = t3.table_name and 
		      t2.relname = (SELECT coalesce(level1_object_name, '')) and 
			  t3.column_name = (SELECT coalesce(level2_object_name, ''));
	END IF;
END IF;
RETURN;
end;
$$
LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION sys.fn_listextendedproperty(
	varchar(128), varchar(128), varchar(128), varchar(128), varchar(128), varchar(128), varchar(128)
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.exp(IN arg DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'tsql_exp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.exp(DOUBLE PRECISION) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.exp(IN arg NUMERIC)
RETURNS DOUBLE PRECISION
AS
$BODY$
SELECT sys.exp(arg::DOUBLE PRECISION);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.exp(NUMERIC) TO PUBLIC;

-- For numeric/decimal and float/double precision there is already inbuilt functions,
-- Following sign functions are for remaining datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg INT) RETURNS INT AS
$BODY$
SELECT
	CASE
		WHEN arg > 0 THEN 1::INT
		WHEN arg < 0 THEN -1::INT
		ELSE 0::INT
	END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SMALLINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.TINYINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.TINYINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg BIGINT) RETURNS BIGINT AS
$BODY$
SELECT
	CASE
		WHEN arg > 0::BIGINT THEN 1::BIGINT
		WHEN arg < 0::BIGINT THEN -1::BIGINT
		ELSE 0::BIGINT
	END;
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.MONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT
	CASE
		WHEN arg > 0::SYS.MONEY THEN 1::SYS.MONEY
		WHEN arg < 0::SYS.MONEY THEN -1::SYS.MONEY
		ELSE 0::SYS.MONEY
	END;
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.MONEY) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.SMALLMONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT sys.sign(arg::SYS.MONEY);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.SMALLMONEY) TO PUBLIC;

-- To handle remaining input datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg ANYELEMENT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
	sign(arg::SYS.FLOAT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(ANYELEMENT) TO PUBLIC;

-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.sign(IN arg TEXT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
	sign(arg::SYS.FLOAT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(TEXT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.lock_timeout()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.lock_timeout');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.lock_timeout() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.max_connections()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'max_connections');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.max_connections() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.trigger_nestlevel()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select pg_trigger_depth());
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.trigger_nestlevel() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME,
    securable_class SYS.NVARCHAR(60),
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME DEFAULT NULL,
    sub_securable_class SYS.NVARCHAR(60) DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    db_name text;
    bbf_schema_name text;
    pg_schema text;
    object_name text;
    database_id smallint;
    namespace_id oid;
    perm_target_type text;
    function_signature text;
    qualified_name text;
    return_value integer;
BEGIN
    return_value := NULL;

    -- Lower-case to avoid case issues, remove trailing whitespace to match SQL SERVER behavior
    -- Objects created in Babelfish are stored in lower-case in pg_class/pg_proc
    securable = lower(rtrim(securable));
    securable_class = lower(rtrim(securable_class));
    permission = lower(rtrim(permission));
    sub_securable = lower(rtrim(sub_securable));
    sub_securable_class = lower(rtrim(sub_securable_class));

    -- Validate inputs
    IF permission IS NULL THEN
        RETURN NULL;

    -- Assert that securable_class is NULL, object, database, or server
    ELSIF securable_class IS NOT NULL AND securable_class NOT IN('object', 'database', 'server') THEN
        RETURN NULL;

    -- Assert that sub_securable and sub_securable_class are either both NULL or both defined
    ELSIF sub_securable IS NOT NULL AND sub_securable_class IS NULL THEN
        RETURN NULL;
    ELSIF sub_securable IS NULL AND sub_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If they are both defined, sub_securable_class must be set to 'column' and securable_class to 'object'
    ELSIF sub_securable IS NOT NULL
            AND (sub_securable_class != 'column' OR securable_class IS NULL OR securable_class != 'object') THEN
        RETURN NULL;

    -- If securable is null, securable_class must be null or server
    ELSIF securable IS NULL AND securable_class IS NOT NULL AND securable_class != 'server' THEN
        RETURN NULL;
    -- If securable_class is null or server, securable must be null
    ELSIF (securable_class IS NULL OR securable_class = 'server') AND securable IS NOT NULL THEN
        RETURN NULL;

    -- Assert that permission type is compatible with the securable class
    ELSIF securable_class = 'object' AND permission NOT IN('select', 'insert', 'update', 'delete', 'references', 'execute', 'any') THEN
        RETURN NULL;
    ELSIF securable_class = 'database' AND permission NOT IN('create schema', 'create table') THEN
        RETURN NULL;
    ELSIF (securable_class IS NULL OR securable_class = 'server') AND permission != 'view server state' THEN
        RETURN NULL;
    END IF;


    IF securable_class IS NULL OR securable_class = 'server' THEN
        IF CURRENT_USER IN('dbo', 'master_dbo', 'tempdb_dbo', 'msdb_dbo') THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END IF;

    IF securable_class = 'database' THEN
        IF CURRENT_USER IN('dbo', 'master_dbo', 'tempdb_dbo', 'msdb_dbo')
                AND (SELECT count(name) FROM sys.databases WHERE name = securable) = 1
            THEN RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END IF;

    SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, object_name
    FROM sys.babelfish_split_object_name(securable) s;

    -- Invalid securable name
    IF object_name IS NULL OR object_name = '' THEN
        RETURN NULL;
    END IF;

    database_id := (
        SELECT CASE
            WHEN db_name IS NULL OR db_name = '' THEN (sys.db_id())
            ELSE (sys.db_id(db_name))
        END);

    IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
        bbf_schema_name := sys.schema_name();
    END IF;

     -- Translate schema name from bbf to postgres, e.g. dbo -> master_dbo
    pg_schema := (SELECT nspname
                    FROM sys.babelfish_namespace_ext ext
                    WHERE ext.orig_name = bbf_schema_name
                        AND ext.dbid::oid = database_id::oid);

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', pg_schema, '"."', object_name, '"');

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = pg_schema;

    IF sub_securable IS NOT NULL THEN
        sub_securable := sys.babelfish_remove_delimiter_pair(sub_securable);
        IF sub_securable IS NULL THEN
            RETURN NULL;
        END IF;
    END IF;

    perm_target_type := (
        SELECT CASE
            WHEN sub_securable_class = 'column'
                THEN CASE
                    WHEN (SELECT count(name)
                        FROM sys.all_columns
                        WHERE name = sub_securable
                            -- Use V as the object type to specify that the securable is table-like.
                            -- We don't know that the securable is a view, but object_id behaves the
                            -- same for differint table-like types, so V can be arbitrarily chosen.
                            AND object_id = sys.object_id(securable, 'V')) = 1
                                THEN 'column'
                    ELSE NULL
                END

            WHEN (SELECT count(relname)
                    FROM pg_catalog.pg_class
                    WHERE relname = object_name
                        AND relnamespace = namespace_id) = 1
                THEN 'table'

            WHEN (SELECT count(proname)
                    FROM pg_catalog.pg_proc
                    WHERE proname = object_name
                        AND pronamespace = namespace_id
                        AND prokind = 'f') = 1
                THEN 'function'

            WHEN (SELECT count(proname)
                    FROM pg_catalog.pg_proc
                    WHERE proname = object_name
                        AND pronamespace = namespace_id
                        AND prokind = 'p') = 1
                THEN 'procedure'
            ELSE NULL
        END
    );

    -- Object wasn't found
    IF perm_target_type IS NULL THEN
        RETURN 0;
    END IF;

    -- Get signature for function-like objects
    IF perm_target_type IN('function', 'procedure') THEN
        SELECT oid::regprocedure
            INTO function_signature
            FROM pg_catalog.pg_proc
            WHERE proname = object_name
                AND pronamespace = namespace_id;
    END IF;

	return_value := (
        SELECT CASE
            WHEN permission = 'any' THEN sys.has_any_privilege(perm_target_type, pg_schema, object_name, sub_securable)

            WHEN perm_target_type = 'column'
                THEN CASE
                    WHEN permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE has_column_privilege(qualified_name, sub_securable, permission)::integer
                END

            WHEN perm_target_type = 'table'
                THEN CASE
                    WHEN permission = 'execute' THEN 0
                    ELSE has_table_privilege(qualified_name, permission)::integer
                END

            WHEN perm_target_type = 'function'
                THEN CASE
                    WHEN permission IN('select', 'execute')
                        THEN has_function_privilege(function_signature, 'execute')::integer
                    WHEN permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN perm_target_type = 'procedure'
                THEN CASE
                    WHEN permission = 'execute'
                        THEN has_function_privilege(function_signature, 'execute')::integer
                    WHEN permission IN('select', 'update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            ELSE NULL
		END
	);

	RETURN return_value;
	EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION sys.has_perms_by_name(
    securable sys.SYSNAME,
    securable_class sys.nvarchar(60),
    permission sys.SYSNAME,
    sub_securable sys.SYSNAME,
    sub_securable_class sys.nvarchar(60)) TO PUBLIC;

COMMENT ON FUNCTION sys.has_perms_by_name
IS 'This function returns permission information. Currently only works with tables, views, columns, functions, and procedures. Otherwise returns NULL.';

CREATE OR REPLACE FUNCTION sys.schema_name()
RETURNS sys.sysname
LANGUAGE plpgsql
STRICT
AS $function$
begin
    RETURN (select orig_name from sys.babelfish_namespace_ext ext  
                    where ext.nspname = (select current_schema()) and  ext.dbid::oid = sys.db_id()::oid)::sys.sysname;
EXCEPTION 
    WHEN others THEN
        RETURN NULL;
END;
$function$
;
GRANT EXECUTE ON FUNCTION sys.schema_name() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.schema_id()
RETURNS INT
LANGUAGE plpgsql
STRICT
AS $$
BEGIN
  RETURN (select oid from sys.pg_namespace_ext where nspname = (select current_schema()))::INT;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.schema_id() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.original_login()
RETURNS sys.sysname
LANGUAGE plpgsql
STRICT
AS $$
declare return_value text;
begin
	RETURN (select session_user)::sys.sysname;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.original_login() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.columnproperty(object_id oid, property name, property_name text)
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$

declare extra_bytes CONSTANT integer := 4;
declare return_value integer;
begin
	return_value := (
					select 
						case  LOWER(property_name)
							when 'charmaxlen' then 
								(select CASE WHEN a.atttypmod > 0 THEN a.atttypmod - extra_bytes ELSE NULL END  from pg_catalog.pg_attribute a where a.attrelid = object_id and a.attname = property)
							when 'allowsnull' then
								(select CASE WHEN a.attnotnull THEN 0 ELSE 1 END from pg_catalog.pg_attribute a where a.attrelid = object_id and a.attname = property)
							else
								null
						end
					);
	
  RETURN return_value::integer;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.columnproperty(object_id oid, property name, property_name text) TO PUBLIC;

COMMENT ON FUNCTION sys.columnproperty 
IS 'This function returns column or parameter information. Currently only works with "charmaxlen", and "allowsnull" otherwise returns 0.';

-- substring --
CREATE OR REPLACE FUNCTION sys.substring(string TEXT, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.VARCHAR, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.VARCHAR, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.NVARCHAR, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.NCHAR, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- For getting host os from PG_VERSION_STR
CREATE OR REPLACE FUNCTION sys.get_host_os()
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'host_os' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_stat_get_activity(
  IN view_name text,
  OUT procid int,
  OUT client_version int,
  OUT library_name VARCHAR(32),
  OUT language VARCHAR(128),
  OUT quoted_identifier bool,
  OUT arithabort bool,
  OUT ansi_null_dflt_on bool,
  OUT ansi_defaults bool,
  OUT ansi_warnings bool,
  OUT ansi_padding bool,
  OUT ansi_nulls bool,
  OUT concat_null_yields_null bool,
  OUT textsize int,
  OUT datefirst int,
  OUT lock_timeout int,
  OUT transaction_isolation int2,
  OUT client_pid int,
  OUT row_count bigint,
  OUT error int,
  OUT trancount int,
  OUT protocol_version int,
  OUT packet_size int,
  OUT encrypyt_option VARCHAR(40),
  OUT database_id int2)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'tsql_stat_get_activity'
LANGUAGE C VOLATILE STRICT;

CREATE OR REPLACE FUNCTION sys.is_table_type(object_id oid) RETURNS bool AS
$BODY$
SELECT
  EXISTS(
    SELECT 1
    FROM pg_catalog.pg_type pt
    INNER JOIN pg_catalog.pg_depend dep
    ON pt.typrelid = dep.objid
    join sys.schemas sch on pt.typnamespace = sch.schema_id
    JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE pt.typtype = 'c' AND dep.deptype = 'i' AND pt.typrelid = object_id AND pc.relkind = 'r');
$BODY$
LANGUAGE SQL VOLATILE STRICT;

-- JSON Functions
CREATE OR REPLACE FUNCTION sys.isjson(json_string text)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'tsql_isjson' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.json_value(json_string text, path text)
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'tsql_json_value' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.json_query(json_string text, path text default '$')
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_json_query' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sp_datatype_info_helper(
    IN odbcVer smallint,
    IN is_100 bool,
    OUT TYPE_NAME VARCHAR(20),
    OUT DATA_TYPE INT,
    OUT "PRECISION" BIGINT,
    OUT LITERAL_PREFIX VARCHAR(20),
    OUT LITERAL_SUFFIX VARCHAR(20),
    OUT CREATE_PARAMS VARCHAR(20),
    OUT NULLABLE INT,
    OUT CASE_SENSITIVE INT,
    OUT SEARCHABLE INT,
    OUT UNSIGNED_ATTRIBUTE INT,
    OUT MONEY INT,
    OUT AUTO_INCREMENT INT,
    OUT LOCAL_TYPE_NAME VARCHAR(20),
    OUT MINIMUM_SCALE INT,
    OUT MAXIMUM_SCALE INT,
    OUT SQL_DATA_TYPE INT,
    OUT SQL_DATETIME_SUB INT,
    OUT NUM_PREC_RADIX INT,
    OUT INTERVAL_PRECISION INT,
    OUT USERTYPE INT,
    OUT LENGTH INT,
    OUT SS_DATA_TYPE smallint,
-- below column is added in order to join PG's information_schema.columns for sys.sp_columns_100_view
    OUT PG_TYPE_NAME VARCHAR(20)
)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'sp_datatype_info_helper'
LANGUAGE C IMMUTABLE STRICT;
