-- BABEL-662
CREATE TABLE babel_662_table (x INT, y FLOAT, z VARCHAR(10));
go

CREATE PROC babel_662_proc_1 AS SELECT 'hi'
go

CREATE PROC babel_662_proc_2 @p VARCHAR(50) AS SELECT @p
go

CREATE PROC babel_662_proc_3
(
	@a INT,
	@b FLOAT,
	@c VARCHAR(10)
)
AS INSERT INTO babel_662_table VALUES (@a, @b, @c);
go

babel_662_proc_1
go

babel_662_proc_2 'hello'
go

babel_662_proc_2 'hello again'
go

babel_662_proc_3 1, 1.1, 'one';
go

babel_662_proc_3 @a = 2, @b = 2.2, @c = 'two';
go

babel_662_proc_3 3, @b = 3.3, @c = 'three';
go

babel_662_proc_3 4, @b = 4.4, 'four';  -- invalid
go

SELECT * FROM babel_662_table;
go

-- Invalid syntax
begin babel_662_proc_2 end
go

babel_662_proc_2
go

-- BABEL-1995
ABC
go

-- BABEL-2052
us emaster
go

-- BABEL-2067
seelect 1;
go

-- Test stored procedure
sp_executesql N'SELECT ''hello world'''
go

DROP TABLE babel_662_table
DROP PROC babel_662_proc_1
DROP PROC babel_662_proc_2
DROP PROC babel_662_proc_3
go
