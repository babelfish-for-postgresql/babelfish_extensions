CREATE DATABASE db_babel_3192;
go

USE db_babel_3192;
go

-- T-SQL table-type
CREATE TYPE babel_3192_type AS TABLE (a int, b int);
go

-- Procedure with table-type as a parameter
CREATE PROCEDURE babel_3192_proc @a INT, @b babel_3192_type READONLY
AS SELECT * FROM @b;
go

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

CREATE TABLE babel_3192_table (a int, b int);
go

INSERT INTO babel_3192_table(a,b) VALUES(1,1), (2,2);
go

-- MS-TVF
CREATE FUNCTION babel_3192_mstvf(@a int)
RETURNS @tab table(a int, b int) AS
BEGIN
	INSERT INTO @tab SELECT * FROM babel_3192_table WHERE a = @a;
	RETURN;
END;
go

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
