SELECT 
CASE 
    WHEN OBJECT_ID('pk_id') = OBJECT_ID('pk_id', 'pk')
    THEN 'Match'
    ELSE 'No Match'
END AS Result;
GO

SELECT 
CASE 
    WHEN OBJECT_ID('fk_constraint') = OBJECT_ID('fk_constraint', 'f')
    THEN 'Match'
    ELSE 'No Match'
END AS Result;
GO

SELECT 
CASE 
    WHEN OBJECT_ID('chk_age') = OBJECT_ID('chk_age', 'c')
    THEN 'Match'
    ELSE 'No Match'
END AS Result;
GO

SELECT 
CASE 
    WHEN OBJECT_ID('unq_name') = OBJECT_ID('unq_name', 'uq')
    THEN 'Match'
    ELSE 'No Match'
END AS Result;
GO

-- Initially when we used to query using full index name, we used to get the corresponding OID from pg_class which is incorrect
-- this should now return NULL
SELECT OBJECT_ID('object_id_idx_name');
GO

SELECT OBJECT_ID('object_id_idx_parent_id');
GO

-- Unique constraints metadata test

-- CREATE TABLE constraint
SELECT o.name AS constraint_name,
       o.type,
       o.type_desc
FROM sys.objects o WHERE o.parent_object_id = OBJECT_ID('object_id_conflict_t2') AND o.type = 'UQ';
GO

-- ALTER TABLE constraint
SELECT o.name AS constraint_name,
       o.type,
       o.type_desc
FROM sys.objects o WHERE o.parent_object_id = OBJECT_ID('object_id_conflict_t') AND o.type = 'UQ';
GO