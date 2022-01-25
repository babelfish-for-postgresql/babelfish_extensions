CREATE TABLE babel_cursor_t1 (i INT, d double precision, c varchar(10), u uniqueidentifier, v sql_variant);
INSERT INTO babel_cursor_t1 VALUES (1, 1.1, 'a', '1E984725-C51C-4BF4-9960-E1C80E27ABA0', 1);
INSERT INTO babel_cursor_t1 VALUES (2, 22.22, 'bb', '2E984725-C51C-4BF4-9960-E1C80E27ABA0', 22.22);
INSERT INTO babel_cursor_t1 VALUES (3, 333.333, 'cccc', '3E984725-C51C-4BF4-9960-E1C80E27ABA0', 'cccc');
INSERT INTO babel_cursor_t1 VALUES (4, 4444.4444, 'dddddd', '4E984725-C51C-4BF4-9960-E1C80E27ABA0', cast('4E984725-C51C-4BF4-9960-E1C80E27ABA0' as uniqueidentifier));
INSERT INTO babel_cursor_t1 VALUES (NULL, NULL, NULL, NULL, NULL);
GO

-- simple happy case
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, 'select i, d, c, u from babel_cursor_t1', 2, 8193;
-- NEXT 1
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
-- NEXT 1
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
-- NEXT 1
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
-- PREV 1
EXEC sp_cursorfetch @cursor_handle, 4, 0, 1;
-- FIRST 2
EXEC sp_cursorfetch @cursor_handle, 1, 0, 2;
-- LAST 3
EXEC sp_cursorfetch @cursor_handle, 8, 0, 3;
-- ABSOLUTE 2 2
EXEC sp_cursorfetch @cursor_handle, 16, 2, 2;
EXEC sp_cursorclose @cursor_handle;
GO

-- sp_cursor auto-close
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, 'select i, d, c, u from babel_cursor_t1', 16400, 8193;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 100;
DECLARE @num_opened_cursor int;
SELECT @num_opened_cursor = count(*) FROM pg_catalog.pg_cursors where statement not like '%num_opened_cursor%';
PRINT 'num_opened_cursor: ' + cast(@num_opened_cursor as varchar(10));
GO

-- sp_cursor auto-close (no fast-forward)
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, 'select i, d, c, u from babel_cursor_t1', 16384, 8193;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 100;
DECLARE @num_opened_cursor int;
SELECT @num_opened_cursor = count(*) FROM pg_catalog.pg_cursors where statement not like '%num_opened_cursor%';
PRINT 'num_opened_cursor: ' + cast(@num_opened_cursor as varchar(10));
GO

-- sp_cursor auto-close (BABEL-1812)
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, 'select i, d, c, u from babel_cursor_t1', 16388, 8193;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 100;
DECLARE @num_opened_cursor int;
SELECT @num_opened_cursor = count(*) FROM pg_catalog.pg_cursors where statement not like '%num_opened_cursor%';
PRINT 'num_opened_cursor: ' + cast(@num_opened_cursor as varchar(10));
GO


-- sp_cursoroption and sp_cursor (not meaningful without TDS implemenation)
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, 'select i, d, c, u from babel_cursor_t1', 2, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 2;
-- TEXTPTR_ONLY 2
EXEC sp_cursoroption @cursor_handle, 1, 2;
EXEC sp_cursor @cursor_handle, 40, 1, '';
-- TEXTPTR_ONLY 4
EXEC sp_cursoroption @cursor_handle, 1, 4;
EXEC sp_cursor @cursor_handle, 40, 1, '';
-- TEXTPTR_ONLY 0
EXEC sp_cursoroption @cursor_handle, 1, 0;
EXEC sp_cursor @cursor_handle, 40, 1, '';
-- TEXTDATA 3
EXEC sp_cursoroption @cursor_handle, 3, 3;
EXEC sp_cursor @cursor_handle, 40, 1, '';
-- TEXTDATA 0
EXEC sp_cursoroption @cursor_handle, 3, 0;
EXEC sp_cursor @cursor_handle, 40, 1, '';
EXEC sp_cursorclose @cursor_handle;
GO

-- cursor prep/exec test
DECLARE @stmt_handle int;
DECLARE @cursor_handle int;
DECLARE @cursor_handle2 int;
EXEC sp_cursorprepare @stmt_handle OUTPUT, N'', 'select i, d, c, u from babel_cursor_t1', 0, 2, 1;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle OUTPUT, 2, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorclose @cursor_handle;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle2 OUTPUT, 2, 1;
EXEC sp_cursorfetch @cursor_handle2, 2, 0, 4;
EXEC sp_cursorclose @cursor_handle2;
EXEC sp_cursorunprepare @stmt_handle;
GO

-- cursor prepexec test
DECLARE @stmt_handle int;
DECLARE @cursor_handle int;
DECLARE @cursor_handle2 int;
EXEC sp_cursorprepexec @stmt_handle OUTPUT, @cursor_handle OUTPUT, N'', 'select i+100 from babel_cursor_t1', 16400, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorclose @cursor_handle;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle2 OUTPUT, 2, 1;
EXEC sp_cursorfetch @cursor_handle2, 2, 0, 4;
EXEC sp_cursorclose @cursor_handle2;
EXEC sp_cursorunprepare @stmt_handle;
GO

-- parameterized query
-- sp_cursoropen
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 2, 8193, 20, N'@ii int, @cc varchar(10)', 1, 'd%';
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorclose @cursor_handle;
GO

-- sp_cursorprepare + sp_cursorexecute
DECLARE @stmt_handle int;
DECLARE @cursor_handle int;
DECLARE @cursor_handle2 int;
EXEC sp_cursorprepare @stmt_handle OUTPUT, N'@ii int,@cc varchar(10)', N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 0, 2, 8193;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle OUTPUT, 2, 8193, 20, 1, 'd%';
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorclose @cursor_handle;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle2 OUTPUT, 2, 8193, 20, 2, 'c%';
EXEC sp_cursorfetch @cursor_handle2, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle2, 2, 0, 1;
EXEC sp_cursorclose @cursor_handle2;
EXEC sp_cursorunprepare @stmt_handle;
GO

-- sp_cursorprepexec
DECLARE @stmt_handle int;
DECLARE @cursor_handle int;
DECLARE @cursor_handle2 int;
EXEC sp_cursorprepexec @stmt_handle OUTPUT, @cursor_handle OUTPUT, N'@ii int,@cc varchar(10)', N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 2, 8193, 20, 1, 'd%';
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorclose @cursor_handle;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle2 OUTPUT, 2, 8193, 20, 2, 'c%';
EXEC sp_cursorfetch @cursor_handle2, 2, 0, 4;
EXEC sp_cursorclose @cursor_handle2;
EXEC sp_cursorunprepare @stmt_handle;
GO


-- passing parameter using variables
DECLARE @ii int = 1;
DECLARE @cc varchar(10) = 'd%';
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 2, 8193, 20, N'@ii int, @cc varchar(10)', @ii, @cc;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorclose @cursor_handle;
GO


-- NULL parameter
DECLARE @cursor_handle int;
	EXEC sp_cursoropen @cursor_handle OUTPUT, N'select i, d, c, u from babel_cursor_t1 where i > (case when @ii is null then 1 else 1000 end)', 2, 8193, 20, N'@ii int', NULL;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorfetch @cursor_handle, 2, 0, 1;
EXEC sp_cursorclose @cursor_handle;
GO


-- valid error: the # of parameter mismatches
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 2, 8193, 20, N'@ii int, @cc varchar(10)', 1;
GO

DECLARE @stmt_handle int;
DECLARE @cursor_handle int;
EXEC sp_cursorprepare @stmt_handle OUTPUT, N'@ii int,@cc varchar(10)', N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 0, 2, 8193;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle OUTPUT, 2, 8193, 20, 1;
EXEC sp_cursorunprepare @stmt_handle
GO


-- unsupported feature: named parameter
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 2, 8193, 20, N'@ii int, @cc varchar(10)', @ii=1, @cc='c%';
GO

DECLARE @stmt_handle int;
DECLARE @cursor_handle int;
EXEC sp_cursorprepare @stmt_handle OUTPUT, N'@ii int,@cc varchar(10)', N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 0, 2, 8193;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle OUTPUT, 2, 8193, 20, @ii=1, @cc='c%';
EXEC sp_cursorunprepare @stmt_handle
GO

-- unsupported feature: output parameter
DECLARE @ii int;
DECLARE @cursor_handle int;
EXEC sp_cursoropen @cursor_handle OUTPUT, N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 2, 8193, 20, N'@ii int OUTPUT, @cc varchar(10)', @ii, 'c%';
GO

DECLARE @ii int;
DECLARE @stmt_handle int;
DECLARE @cursor_handle int;
EXEC sp_cursorprepare @stmt_handle OUTPUT, N'@ii int OUTPUT, @cc varchar(10)', N'select i, d, c, u from babel_cursor_t1 where i > @ii and c not like @cc', 0, 2, 8193;
EXEC sp_cursorexecute @stmt_handle, @cursor_handle OUTPUT, 2, 8193, 20, @ii, 'c%';
EXEC sp_cursorunprepare @stmt_handle
GO


-- BABEL-1812
CREATE TABLE t1812(id int primary key, a int, b int);
GO
declare @p1 int
set @p1=1
declare @p2 int
set @p2=0
declare @p5 int
set @p5=16388
declare @p6 int
set @p6=8193
declare @p7 int
set @p7=0
exec sp_cursorprepexec @p1 output,@p2 output,NULL,N'SELECT [id],[a],[b]  FROM [dbo].[t1812]',@p5 output,@p6 output,@p7 output
select @p1, @p2, @p5, @p6, @p7;
exec sp_cursorclose @p2;
exec sp_cursorunprepare @p1;
go
