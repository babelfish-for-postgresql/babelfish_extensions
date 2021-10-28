/* Built in functions */
CREATE FUNCTION sys.sysdatetime() RETURNS datetime2
    AS $$select clock_timestamp()::datetime2;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysdatetime() TO PUBLIC; 

CREATE FUNCTION sys.sysdatetimeoffset() RETURNS sys.datetimeoffset
    -- Casting to text as there are not type cast function from timestamptz to datetimeoffset
    AS $$select cast(cast(clock_timestamp() as text) as sys.datetimeoffset);$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysdatetimeoffset() TO PUBLIC; 


CREATE FUNCTION sys.sysutcdatetime() RETURNS sys.datetime2
    AS $$select (clock_timestamp() AT TIME ZONE 'UTC')::sys.datetime2;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysutcdatetime() TO PUBLIC; 


CREATE FUNCTION sys.getdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', clock_timestamp()::timestamp)::sys.datetime;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.getdate() TO PUBLIC; 


CREATE FUNCTION sys.getutcdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', clock_timestamp() AT TIME ZONE 'UTC')::sys.datetime;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.getutcdate() TO PUBLIC; 


CREATE FUNCTION sys.isnull(text,text) RETURNS text AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(text,text) TO PUBLIC;

CREATE FUNCTION sys.isnull(boolean,boolean) RETURNS boolean AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(boolean,boolean) TO PUBLIC;

CREATE FUNCTION sys.isnull(smallint,smallint) RETURNS smallint AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(smallint,smallint) TO PUBLIC;

CREATE FUNCTION sys.isnull(integer,integer) RETURNS integer AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(integer,integer) TO PUBLIC;

CREATE FUNCTION sys.isnull(bigint,bigint) RETURNS bigint AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(bigint,bigint) TO PUBLIC;

CREATE FUNCTION sys.isnull(real,real) RETURNS real AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(real,real) TO PUBLIC;

CREATE FUNCTION sys.isnull(double precision, double precision) RETURNS double precision AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(double precision, double precision) TO PUBLIC;

CREATE FUNCTION sys.isnull(numeric,numeric) RETURNS numeric AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(numeric,numeric) TO PUBLIC;

CREATE FUNCTION sys.isnull(date, date) RETURNS date AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(date,date) TO PUBLIC;

CREATE FUNCTION sys.isnull(timestamp,timestamp) RETURNS timestamp AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(timestamp,timestamp) TO PUBLIC;

CREATE FUNCTION sys.isnull(timestamp with time zone,timestamp with time zone) RETURNS timestamp with time zone AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(timestamp with time zone,timestamp with time zone) TO PUBLIC;

/* Tsql tables */
CREATE TABLE IF NOT EXISTS sys.service_settings
(
    service character varying(50) NOT NULL
    ,setting character varying(100) NOT NULL
    ,value character varying
);
GRANT SELECT ON sys.service_settings TO PUBLIC;

comment on table sys.service_settings is 'Settings for Extension Pack services';
comment on column sys.service_settings.service is 'Service name';
comment on column sys.service_settings.setting is 'Setting name';
comment on column sys.service_settings.value is 'Setting value';

CREATE TABLE sys.versions
(
    extpackcomponentname VARCHAR(256) NOT NULL,
    componentversion VARCHAR(256)
);
GRANT SELECT ON sys.versions TO PUBLIC;

CREATE TABLE sys.syslanguages (
    lang_id SMALLINT,
    lang_name_pg VARCHAR(30),
    lang_alias_pg VARCHAR(30),
    lang_name_mssql VARCHAR(30),
    lang_alias_mssql VARCHAR(30),
    territory VARCHAR(50),
    spec_culture VARCHAR(10),
    lang_data_jsonb JSONB
) WITH (OIDS = FALSE);
GRANT SELECT ON sys.syslanguages TO PUBLIC;
