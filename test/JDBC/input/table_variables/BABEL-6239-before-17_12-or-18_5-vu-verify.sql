-- FIXME: computed column using mutable function error. To be fixed with BABEL-2022
EXEC dbo.create_fti_columns @SEARCHABLE_COLUMNS = '1|2|3^1|2^1^1';
GO

-- FIXME: computed column using mutable function error. To be fixed with BABEL-2022
EXEC dbo.create_fti_columns @SEARCHABLE_COLUMNS = '1|2|3^1|2^1^1|2^0'
GO