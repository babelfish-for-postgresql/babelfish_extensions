SELECT schemaname, indexname FROM pg_indexes WHERE tablename='table.test' AND indexname LIKE 'ft_index%' ORDER BY schemaname;
GO

SELECT schemaname, indexname FROM pg_indexes WHERE tablename='test_table' AND indexname LIKE 'ft_index%' ORDER BY schemaname;
GO