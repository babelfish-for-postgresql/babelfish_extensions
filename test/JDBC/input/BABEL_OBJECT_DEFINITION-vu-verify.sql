-- Throws an error
SELECT OBJECT_DEFINITION();
GO

-- Should return NULL
SELECT OBJECT_DEFINITION(NULL);
GO

-- Should return NULL
SELECT OBJECT_DEFINITION(OBJECT_ID('object_definition_t1'))
GO

USE object_definition_db;
GO

-- Should return NULL
SELECT OBJECT_DEFINITION(OBJECT_ID('object_definition_t1'))
GO

-- Default constraint
SELECT OBJECT_DEFINITION(cc.object_id) FROM sys.default_constraints cc WHERE parent_object_id = OBJECT_ID('object_definition_t1');
GO

-- Check constraint
SELECT OBJECT_DEFINITION(cc.object_id) FROM sys.check_constraints cc WHERE parent_object_id = OBJECT_ID('object_definition_t2');
GO

-- Procedure
SELECT OBJECT_DEFINITION(OBJECT_ID('object_definition_proc'))
GO

-- Scalar function
SELECT OBJECT_DEFINITION(OBJECT_ID('object_definition_fc1'))
GO

-- DML trigger
-- TODO: After BABEL-3927 is fixed, we get the correct trigger definition.
-- Now, it shows NULL.
SELECT OBJECT_DEFINITION(OBJECT_ID('object_definition_tr1'))
GO

-- Inline table-valued function
SELECT OBJECT_DEFINITION(OBJECT_ID('object_definition_itvf'))
GO

-- Table-valued function
SELECT OBJECT_DEFINITION(OBJECT_ID('object_definition_tvf'))
GO

-- View
SELECT OBJECT_DEFINITION(OBJECT_ID('object_definition_sch.object_definition_v1'))
GO

-- Dependency Test
SELECT * FROM object_definition_v2;
GO
