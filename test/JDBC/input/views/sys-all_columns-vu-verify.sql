SELECT name, is_nullable, column_id 
FROM sys.all_columns 
WHERE name in ('sac_int_col', 'sac_text_col_not_null', 'sac_date_col')
ORDER BY name
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.all_columns');
GO

SELECT name, column_id, max_length, precision, scale, collation_name, is_nullable, is_ansi_padded, is_rowguidcol, is_identity, is_computed, is_filestream, is_replicated, is_non_sql_subscribed, is_merge_published, is_dts_replicated, is_xml_document, xml_collection_id, default_object_id, rule_object_id, is_sparse, is_column_set, generated_always_type, generated_always_type_desc
FROM sys.all_columns
WHERE name='intcol' OR name='char128col' OR name='bitcol' OR name='datecol' OR name='moneycol' OR name='datetimecol'
ORDER BY name
GO

SELECT is_computed FROM sys.all_columns WHERE name = 'col_computed'
GO

SELECT is_computed FROM sys.all_columns WHERE name = 'col_two'
GO

SELECT is_computed FROM sys.all_columns WHERE name = 'col_one'
GO

SELECT is_computed FROM sys.all_columns WHERE name = 'random_col'
GO

SELECT is_identity FROM sys.all_columns WHERE name = 'col_three'
GO

SELECT is_identity FROM sys.all_columns WHERE name = 'col_two'
GO
