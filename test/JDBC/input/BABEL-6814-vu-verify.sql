-- Test 1: sys.objects point lookup - left side cast pattern
SELECT name FROM sys.objects
WHERE object_id = (SELECT object_id FROM sys.objects WHERE name = 'babel_6814_t1');
GO

-- Test 2: sys.objects point lookup - right side cast pattern
SELECT name FROM sys.objects
WHERE (SELECT object_id FROM sys.objects WHERE name = 'babel_6814_t1') = object_id;
GO

-- Test 3: Both patterns return same result
SELECT CASE WHEN
    (SELECT name FROM sys.objects WHERE object_id = (SELECT object_id FROM sys.objects WHERE name = 'babel_6814_t1'))
    =
    (SELECT name FROM sys.objects WHERE (SELECT object_id FROM sys.objects WHERE name = 'babel_6814_t1') = object_id)
THEN 'PASS' ELSE 'FAIL' END;
GO

-- Test 4: sys.indexes - lookup by object_id
SELECT i.index_id, i.type_desc FROM sys.indexes i
WHERE i.object_id = (SELECT object_id FROM sys.tables WHERE name = 'babel_6814_t1')
ORDER BY i.index_id;
GO

-- Test 5: sys.columns - lookup by object_id
SELECT name, column_id FROM sys.columns
WHERE object_id = (SELECT object_id FROM sys.tables WHERE name = 'babel_6814_t1')
ORDER BY column_id;
GO

-- Test 6: sys.schemas - lookup by schema_id
SELECT name FROM sys.schemas WHERE schema_id = SCHEMA_ID('dbo');
GO

-- Test 7: Non-existent object returns 0 rows
SELECT name FROM sys.objects WHERE object_id = 99999999;
GO

-- Test 8: Correlated subquery pattern
SELECT t.name,
    (SELECT o.type FROM sys.objects o WHERE o.object_id = t.object_id) as obj_type
FROM sys.tables t
WHERE t.name IN ('babel_6814_t1', 'babel_6814_t2')
ORDER BY t.name;
GO

-- Test 9: Correlated subquery - reversed operand
SELECT t.name,
    (SELECT o.type FROM sys.objects o WHERE t.object_id = o.object_id) as obj_type
FROM sys.tables t
WHERE t.name IN ('babel_6814_t1', 'babel_6814_t2')
ORDER BY t.name;
GO

-- Test 10: Join pattern - sys.objects JOIN sys.columns
SELECT o.name, c.name as col_name
FROM sys.objects o
JOIN sys.columns c ON o.object_id = c.object_id
WHERE o.name = 'babel_6814_t1'
ORDER BY c.column_id;
GO

-- Test 11: Join pattern - sys.tables JOIN sys.indexes
SELECT t.name, i.index_id, i.type_desc
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name = 'babel_6814_t1'
ORDER BY i.index_id;
GO

-- Test 12: Multiple objects via subquery
SELECT name, type_desc FROM sys.objects
WHERE object_id IN (
    SELECT object_id FROM sys.objects WHERE name IN ('babel_6814_t1', 'babel_6814_t2', 'babel_6814_proc1')
)
ORDER BY name;
GO

-- Test 13: Different object types all resolve correctly
SELECT name, type, type_desc FROM sys.objects
WHERE name LIKE 'babel_6814%'
ORDER BY name;
GO

-- Test 14: sys.indexes with index_id filter
SELECT i.index_id FROM sys.indexes i
WHERE i.object_id = (SELECT object_id FROM sys.tables WHERE name = 'babel_6814_t1')
AND i.index_id > 0
ORDER BY i.index_id;
GO

-- Test 15: Correlated count - ensures all indexes found per table
SELECT t.name,
    (SELECT COUNT(*) FROM sys.indexes i WHERE i.object_id = t.object_id AND i.index_id > 0) as idx_count
FROM sys.tables t
WHERE t.name IN ('babel_6814_t1', 'babel_6814_t2')
ORDER BY t.name;
GO

-- Verifying Index Scans being Used
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false);
GO

SET babelfish_showplan_all ON;
GO

-- Test 16: Point lookup pattern - hook rewrites (oid)::int4 = 56 to oid = (56)::oid
-- Look for: Index Scan using pg_type_oid_index, Index Cond: (oid = (56)::oid)
SELECT name FROM sys.types WHERE user_type_id = 56;
GO

-- Test 17: Reversed operand pattern - hook handles value = (oid)::int4
-- Look for: Index Scan using pg_type_oid_index, Index Cond: (oid = (56)::oid)
SELECT name FROM sys.types WHERE 56 = user_type_id;
GO

SET babelfish_showplan_all OFF;
GO

