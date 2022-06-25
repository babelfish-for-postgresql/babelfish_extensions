Drop PROCEDURE demo_proc;

create or replace view demo_view as
select distinct
  c.oid as constraint_object_id
  , c.confkey as constraint_column_id
  , c.conrelid as parent_object_id
  , a_con.attnum as parent_column_id
  , c.confrelid as referenced_object_id
  , a_conf.attnum as referenced_column_id
from pg_constraint c
inner join pg_attribute a_con on a_con.attrelid = c.conrelid and a_con.attnum = any(c.conkey)
inner join pg_attribute a_conf on a_conf.attrelid = c.confrelid and a_conf.attnum = any(c.confkey)
where c.contype = 'f';
GRANT SELECT ON sys.foreign_key_columns TO PUBLIC;

CREATE FUNCTION sys.demo1() RETURNS sys.datetimeoffset
    -- Casting to text as there are not type cast function from timestamptz to datetimeoffset
    AS $$select cast(cast(clock_timestamp() as text) as sys.datetimeoffset);$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysdatetimeoffset() TO PUBLIC;

CREATE FUNCTION sys.demo2(text,text) RETURNS text AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(text,text) TO PUBLIC;


CREATE OR REPLACE PROCEDURE demo_proc()
LANGUAGE plpgsql
AS $$
BEGIN
  CREATE OR REPLACE PROCEDURE sys.create_xp_qv_in_master_dbo()
  LANGUAGE C
  AS 'babelfishpg_tsql', 'create_xp_qv_in_master_dbo_internal';

  CREATE OR REPLACE PROCEDURE sys.create_xp_instance_regread_in_master_dbo()
  LANGUAGE C
  AS 'babelfishpg_tsql', 'create_xp_instance_regread_in_master_dbo_internal';

  CALL sys.create_xp_qv_in_master_dbo();
  ALTER PROCEDURE master_dbo.xp_qv OWNER TO sysadmin;
  DROP PROCEDURE sys.create_xp_qv_in_master_dbo;

  CALL sys.create_xp_instance_regread_in_master_dbo();
  ALTER PROCEDURE master_dbo.xp_instance_regread(sys.nvarchar(512), sys.sysname, sys.nvarchar(512), int) OWNER TO sysadmin;
  ALTER PROCEDURE master_dbo.xp_instance_regread(sys.nvarchar(512), sys.sysname, sys.nvarchar(512), sys.nvarchar(512)) OWNER TO sysadmin;
  DROP PROCEDURE sys.create_xp_instance_regread_in_master_dbo;
END
$$;