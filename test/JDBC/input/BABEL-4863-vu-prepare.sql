create table babel_4863_t1 (a int)
GO
INSERT INTO babel_4863_t1 VALUES(1)
GO

create function babel_4863_func()
	returns table as return 
	(
		select 'value' = '1'
	)
go

create function babel_4863_func1()
returns table as return 
(
    SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END[this is a $.^ test], 
    CASE WHEN 1=1  THEN 1 ELSE 0 END'this is a $.^ test1', 
    CASE WHEN 1=1  THEN 1 ELSE 0 END"this is a $.^ test2"
)
GO

CREATE PROCEDURE babel_4863_proc @a INT
AS BEGIN 
DECLARE @v1 int = CASE WHEN @a=1  THEN 1 ELSE 0 END;
DECLARE @v2 int = CASE WHEN @a=1  THEN 1 ELSE 0 END;
DECLARE @v3 int = CASE WHEN @a=1  THEN 1 ELSE 0 END;
SELECT @v1[this is a $.^ test], @v2'this is a $.^ test1', @v3"this is a $.^ test2";
END;
GO

CREATE VIEW babel_4863_view AS 
SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END[this is a $.^ test], 
    CASE WHEN 1=1  THEN 1 ELSE 0 END'this is a $.^ test1', 
    CASE WHEN 1=1  THEN 1 ELSE 0 END"this is a $.^ test2";
GO
