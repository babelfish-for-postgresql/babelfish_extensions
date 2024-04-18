create function babel_4863_func()
	returns table as return 
	(
		select '1' as val
	)
go

create function babel_4863_func1()
returns table as return 
(
    SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END
)
GO

CREATE PROCEDURE babel_4863_proc @a INT
AS BEGIN 
DECLARE @v1 int = CASE WHEN @a=1  THEN 1 ELSE 0 END;
DECLARE @v2 int = CASE WHEN @a=1  THEN 1 ELSE 0 END;
DECLARE @v3 int = CASE WHEN @a=1  THEN 1 ELSE 0 END;
SELECT @v1, @v2, @v3;
END;
GO

CREATE VIEW babel_4863_view AS 
SELECT CASE WHEN 1=1  THEN 1 ELSE 0 END;
GO
