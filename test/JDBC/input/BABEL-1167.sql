CREATE TABLE babel_1167_table (a INT);
go

INSERT INTO babel_1167_table VALUES (111), (222)
go

CREATE PROCEDURE babel_1167_proc AS
IF 1=1
	UPDATE babel_1167_table SET a = 0
ELSE
	UPDATE babel_1167_table SET a = 1
go

EXEC babel_1167_proc
go

SELECT * FROM babel_1167_table
go

DROP PROC babel_1167_proc
go

DROP TABLE babel_1167_table
go
