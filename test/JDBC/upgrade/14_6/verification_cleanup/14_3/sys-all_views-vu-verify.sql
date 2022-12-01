-- sla 60000
SELECT * FROM sys_all_views_dep_view_vu_prepare
GO

EXEC sys_all_views_dep_proc_vu_prepare
GO

SELECT * FROM sys_all_views_dep_func_vu_prepare()
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
WHERE name = 'sys_all_views_select_vu_prepare'
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
WHERE name = 'sys_all_views_select_chk_option_vu_prepare'
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.all_views');
GO
