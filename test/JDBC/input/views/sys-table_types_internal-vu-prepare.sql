
DROP TYPE IF EXISTS table_types_internal_test1;
GO

DROP TYPE IF EXISTS table_types_internal_test2;
GO

CREATE TYPE table_types_internal_test1 AS TABLE (Id INT, Name VARCHAR(100));
GO

CREATE TYPE table_types_internal_test2 AS TABLE (Id INT, Name VARCHAR(100), floatNum float, someDate date);
GO
