USE master
GO

Create sequence test_seq as int 
GO

Create schema sch
GO

Create sequence sch.ははははははははははははははははは 
GO

CREATE VIEW sys_sequences_vu_prepare_view AS
select
    name
  , principal_id
  , parent_object_id
  , type
  , type_desc
  , create_date
  , modify_date
  , is_ms_shipped
  , is_published
  , is_schema_published
  , start_value
  , increment
  , minimum_value
  , maximum_value
  , is_cycling
  , is_cached
  , cache_size
  , system_type_id
  , user_type_id
  , precision
  , scale
  , current_value
  , is_exhausted
  , last_used_value FROM sys.sequences
GO

CREATE PROC sys_sequences_vu_prepare_proc AS
SELECT
    name
  , principal_id
  , parent_object_id
  , type
  , type_desc
  , create_date
  , modify_date
  , is_ms_shipped
  , is_published
  , is_schema_published
  , start_value
  , increment
  , minimum_value
  , maximum_value
  , is_cycling
  , is_cached
  , cache_size
  , system_type_id
  , user_type_id
  , precision
  , scale
  , current_value
  , is_exhausted
  , last_used_value FROM sys.sequences
GO

CREATE FUNCTION sys_sequences_vu_prepare_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sequences WHERE is_cycling= 0)
END
GO

CREATE FUNCTION sys_sequences_vu_prepare_func1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sequences WHERE name='TEST_SEq');
END
GO

CREATE FUNCTION sys_sequences_vu_prepare_func2()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.sequences WHERE name='ははははははははははははははははは');
END
GO