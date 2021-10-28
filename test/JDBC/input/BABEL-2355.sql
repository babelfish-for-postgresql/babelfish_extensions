-- All following procedures should report error.
-- Before the fix for BABEL-2355, all these 
-- procedures lead to crash.

CREATE PROC babel_2355_proc1 AS
DECLARE @a DECIMAL(38, 39)
go

CREATE PROC babel_2355_proc2 AS
DECLARE @a INTA
go

DROP PROC babel_2355_proc1
DROP PROC babel_2355_proc2
go
