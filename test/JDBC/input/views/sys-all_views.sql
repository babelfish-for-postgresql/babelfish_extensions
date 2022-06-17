CREATE DATABASE db_all_views
GO

USE db_all_views
GO

CREATE TABLE t1(a int)
GO

CREATE VIEW all_views_test1 AS
SELECT * FROM t1
GO

CREATE VIEW all_views_check_option AS
SELECT * FROM t1
WITH CHECK OPTION
GO

-- query a view with no options
SELECT
    name
  , principal_id
  , type
  , type_desc
  , create_date
  , modify_date
  , is_ms_shipped
  , is_published
  , is_schema_published
  , is_replicated
  , has_replication_filter
  , has_opaque_metadata
  , has_unchecked_assembly_data
  , with_check_option
  , is_date_correlation_view
FROM sys.all_views
WHERE name = 'all_views_test1'
GO

-- query a view with check option enabled
SELECT
    name
  , principal_id
  , type
  , type_desc
  , create_date
  , modify_date
  , is_ms_shipped
  , is_published
  , is_schema_published
  , is_replicated
  , has_replication_filter
  , has_opaque_metadata
  , has_unchecked_assembly_data
  , with_check_option
  , is_date_correlation_view
FROM sys.all_views
WHERE name = 'all_views_check_option'
GO

DROP VIEW all_views_check_option
GO

DROP VIEW all_views_test1
GO

DROP TABLE t1
GO

USE master
GO

DROP DATABASE db_all_views
GO