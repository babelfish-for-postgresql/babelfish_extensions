USE db_babel_3192;
go

-- T-SQL table-type
DECLARE @tablevar babel_3192_type;
INSERT INTO @tablevar(a,b) VALUES(1,1);
INSERT INTO @tablevar(a,b) VALUES(2,2);
EXEC babel_3192_proc 1, @tablevar;
go

-- The underlying template table should have a dependency on table-type
SELECT COUNT(*) AS has_dependency FROM pg_catalog.pg_depend
WHERE objid = CAST('babel_3192_type' AS pg_catalog.regclass)  -- will get converted to pg_class oid
AND refobjid = CAST('babel_3192_type' AS pg_catalog.regtype); -- will get converted to pg_type oid
go

-- MS-TVF
SELECT * FROM babel_3192_mstvf(1);
go

-- MS-TVF's return table-type should have a dependency on MS-TVF
SELECT COUNT(*) AS has_dependency FROM pg_catalog.pg_depend
WHERE objid = CAST('@tab_babel_3192_mstvf' AS pg_catalog.regtype)   -- will get converted to pg_type oid
AND refobjid = CAST('babel_3192_mstvf' AS pg_catalog.regproc);      -- will get converted to pg_proc oid
go

-- The underlying template table should have a dependency on table-type
SELECT COUNT(*) AS has_dependency FROM pg_catalog.pg_depend
WHERE objid = CAST('@tab_babel_3192_mstvf' AS pg_catalog.regclass)  -- will get converted to pg_class oid
AND refobjid = CAST('@tab_babel_3192_mstvf' AS pg_catalog.regtype); -- will get converted to pg_type oid
go

USE master;
go
