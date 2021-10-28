CREATE TABLE babel_1577_table (col# int, #col int, co##l int, col$$ int, co_#$#$l int, col_# int)
go

INSERT INTO babel_1577_table VALUES (1, 2, 3, 4, 5, 6);
go

CREATE PROC babel_1577_proc AS
SELECT 
	col# AS a,
	#col AS b,
	co##l AS c,
	col$$ AS d,
	co_#$#$l AS e,
	col_# AS f
FROM babel_1577_table
go

EXEC babel_1577_proc
go

DROP PROC babel_1577_proc
go

DROP TABLE babel_1577_table
go
