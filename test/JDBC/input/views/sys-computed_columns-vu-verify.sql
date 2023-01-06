SELECT name FROM sys.computed_columns where name in ('scc_multiplied')
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.computed_columns');
GO

SELECT name, definition
FROM sys.computed_columns
WHERE name in ('scc_first_number', 'scc_second_number', 'scc_multiplied')
ORDER BY name
GO

Select sys.tsql_get_expr(adbin, adrelid) FROM pg_attrdef WHERE adrelid = (select oid from pg_class where relname='sys_computed_columns_vu_prepare_t1')
GO

Select sys.tsql_get_expr('scc_second_number',123)
GO

Select sys.tsql_get_expr('abc',123)
GO

Select sys.tsql_get_expr('abc',0)
GO