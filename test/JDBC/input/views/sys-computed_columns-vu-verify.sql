SELECT name FROM sys.computed_columns where name in ('scc_multiplied')
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.computed_columns');
GO

Select definition FROM sys.computed_columns WHERE name='scc_first_number';
GO

Select definition FROM sys.computed_columns WHERE name='scc_second_number';
GO

Select definition FROM sys.computed_columns WHERE name='scc_multiplied';
GO
