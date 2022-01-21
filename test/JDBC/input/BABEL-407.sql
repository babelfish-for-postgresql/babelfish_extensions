USE master
go

CREATE FUNCTION babel_407_func (@a INT) 
RETURNS TABLE AS
RETURN (SELECT @a + 1 AS col);
go

CREATE VIEW babel_407_view AS
SELECT * FROM babel_407_func(123)
go

SELECT * FROM babel_407_view
go

DROP VIEW babel_407_view
go

DROP FUNCTION babel_407_func
go
