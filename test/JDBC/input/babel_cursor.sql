CREATE TABLE babel_cursor_t1 (i INT, d numeric(8, 4), c varchar(10), u uniqueidentifier, v sql_variant);
INSERT INTO babel_cursor_t1 VALUES (1, 1.1, 'a', '1E984725-C51C-4BF4-9960-E1C80E27ABA0', 1);
INSERT INTO babel_cursor_t1 VALUES (2, 22.22, 'bb', '2E984725-C51C-4BF4-9960-E1C80E27ABA0', 22.22);
INSERT INTO babel_cursor_t1 VALUES (3, 333.333, 'cccc', '3E984725-C51C-4BF4-9960-E1C80E27ABA0', 'cccc');
INSERT INTO babel_cursor_t1 VALUES (4, 4444.4444, 'dddddd', '4E984725-C51C-4BF4-9960-E1C80E27ABA0', CAST('4E984725-C51C-4BF4-9960-E1C80E27ABA0' AS uniqueidentifier));
INSERT INTO babel_cursor_t1 VALUES (NULL, NULL, NULL, NULL, NULL);
GO

CREATE PROCEDURE babel_fetch_cursor_helper_int_proc(@cur CURSOR, @num_fetch int)
AS
BEGIN
	DECLARE @var_i int;
	DECLARE @cnt int = 0;

	WHILE @cnt < @num_fetch
	  BEGIN
		FETCH FROM @cur INTO @var_i
		SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10))
		IF @@FETCH_STATUS <> 0
		BREAK
		SELECT '@var_i: ' + CAST(@var_i AS VARCHAR(100))
		IF (@var_i IS NULL)
		SELECT '@var_i is null: ' + CAST((case when @var_i is null then 'true' else 'false' end) AS VARCHAR(100))
		SET @cnt = @cnt + 1
	  END
END;
GO

CREATE PROCEDURE babel_fetch_cursor_helper_char_proc(@cur CURSOR, @num_fetch int)
AS
BEGIN
	DECLARE @var_c varchar(100);
	DECLARE @cnt int = 0;

	WHILE @cnt < @num_fetch
	BEGIN
		FETCH FROM @cur INTO @var_c
		SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10))
		IF @@FETCH_STATUS <> 0
			BREAK
		SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100))
		IF (@var_c IS NULL)
			SELECT '@var_c is null: ' + CAST((case when @var_c is null then 'true' else 'false' end) AS VARCHAR(100))
		SET @cnt = @cnt + 1
	END
END;
GO

CREATE PROCEDURE babel_cursor_proc
AS
BEGIN
	DECLARE @var_a int;
	DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	OPEN cur_a;

	EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	CLOSE cur_a;
END;
GO

EXEC babel_cursor_proc;
GO

CREATE PROCEDURE babel_cursor_no_semi_proc
AS
BEGIN
	DECLARE @var_a int
	DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i
	OPEN cur_a

	EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	CLOSE cur_a
END;
GO

EXEC babel_cursor_no_semi_proc;
GO

-- no cursor cur_a (in OPEN)
CREATE PROCEDURE babel_invalid_cursor_proc_1
AS
BEGIN
	DECLARE @var_a int;
	OPEN cur_a;
END;
GO

-- no cursor cur_b (in CLOSE)
CREATE PROCEDURE babel_invalid_cursor_proc_2
AS
BEGIN
	DECLARE @var_a int;
	DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	OPEN cur_a;
	FETCH NEXT FROM cur_a INTO @var_a;

	EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	CLOSE cur_b;
END;
GO

-- OPEN with non-cursor var
CREATE PROCEDURE babel_invalid_cursor_proc_3
AS
BEGIN
	DECLARE @var_a int;
	DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	OPEN @var_a;
END;
GO

-- CLOSE with non-cursor var
CREATE PROCEDURE babel_invalid_cursor_proc_4
AS
BEGIN
	DECLARE @var_a int;
	DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	OPEN cur_a;
	FETCH NEXT FROM cur_a INTO @var_a;

	EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	CLOSE @var_a;
END;
GO

-- global cursor is not supported yet (OPEN)
CREATE PROCEDURE babel_cursor_global_open_proc
AS
BEGIN
	DECLARE @var_a int;
	DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	OPEN GLOBAL cur_a;
	FETCH NEXT FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	CLOSE cur_a;
END;
GO

-- global cursor is not supported yet (CLOSE)
CREATE PROCEDURE babel_cursor_global_close_proc
AS
BEGIN
	DECLARE @var_a int;
	DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	OPEN cur_a;
	FETCH NEXT FROM cur_a INTO @var_a;

	EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	CLOSE GLOBAL cur_a;
END;
GO


-- double precision datatype
CREATE PROCEDURE babel_cursor_double_precision_proc
AS
BEGIN
	  DECLARE @var_a double precision;
	  DECLARE cur_a CURSOR FOR SELECT d FROM babel_cursor_t1 ORDER BY d;
	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a is null: ' + CAST((case when @var_a is null then 'true' else 'false' end) AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  CLOSE cur_a;
END;
GO

EXEC babel_cursor_double_precision_proc;
GO

-- varchar datatype
CREATE PROCEDURE babel_cursor_varchar_proc
AS
BEGIN
	  DECLARE @var_a varchar(100);
	  DECLARE cur_a CURSOR FOR SELECT c FROM babel_cursor_t1 ORDER BY c;
	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a is null: ' + CAST((case when @var_a is null then 'true' else 'false' end) AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  CLOSE cur_a;
END;
GO

EXEC babel_cursor_varchar_proc;
GO

-- uniqueidentifier datatype
CREATE PROCEDURE babel_cursor_uniqueidentifier_proc
AS
BEGIN
	  DECLARE @var_a uniqueidentifier;
	  DECLARE cur_a CURSOR FOR SELECT u FROM babel_cursor_t1 ORDER BY u;
	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a is null: ' + CAST((case when @var_a is null then 'true' else 'false' end) AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  CLOSE cur_a;
END;
GO

EXEC babel_cursor_uniqueidentifier_proc;
GO

-- sql_variant datatype
CREATE PROCEDURE babel_cursor_sql_variant_proc
AS
BEGIN
	  DECLARE @var_a sql_variant;
	  DECLARE cur_a CURSOR FOR SELECT v FROM babel_cursor_t1 ORDER BY v;
	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT 'base type of @var_a: ' + CAST(sql_variant_property(@var_a, 'basetype') AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT 'base type of @var_a: ' + CAST(sql_variant_property(@var_a, 'basetype') AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT 'base type of @var_a: ' + CAST(sql_variant_property(@var_a, 'basetype') AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT 'base type of @var_a: ' + CAST(sql_variant_property(@var_a, 'basetype') AS VARCHAR(100));
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT 'base type of @var_a: ' + CAST(sql_variant_property(@var_a, 'basetype') AS VARCHAR(100));
	  CLOSE cur_a;
END;
GO

EXEC babel_cursor_sql_variant_proc;
GO


-- multi-columns with sql expression
CREATE PROCEDURE babel_cursor_multi_columns_proc
AS
BEGIN
	  DECLARE @var_i int;
	  DECLARE @var_d double precision;
	  DECLARE @var_c varchar(100);
	  DECLARE @var_u uniqueidentifier;
	  DECLARE @var_v sql_variant;
	  DECLARE cur_a CURSOR FOR SELECT i+100, d+0.1, c+'_postfix', u, v FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;

	  FETCH NEXT FROM cur_a INTO @var_i, @var_d, @var_c, @var_u, @var_v;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_i: ' + CAST(@var_i AS VARCHAR(100));
	  SELECT '@var_d: ' + CAST(@var_d AS VARCHAR(100));
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));
	  SELECT '@var_u: ' + CAST(@var_u AS VARCHAR(100));
	  SELECT 'base type of @var_v: ' + CAST(sql_variant_property(@var_v, 'basetype') AS VARCHAR(100));

	  FETCH NEXT FROM cur_a INTO @var_i, @var_d, @var_c, @var_u, @var_v;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_i: ' + CAST(@var_i AS VARCHAR(100));
	  SELECT '@var_d: ' + CAST(@var_d AS VARCHAR(100));
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));
	  SELECT '@var_u: ' + CAST(@var_u AS VARCHAR(100));
	  SELECT 'base type of @var_v: ' + CAST(sql_variant_property(@var_v, 'basetype') AS VARCHAR(100));

	  FETCH NEXT FROM cur_a INTO @var_i, @var_d, @var_c, @var_u, @var_v;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_i: ' + CAST(@var_i AS VARCHAR(100));
	  SELECT '@var_d: ' + CAST(@var_d AS VARCHAR(100));
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));
	  SELECT '@var_u: ' + CAST(@var_u AS VARCHAR(100));
	  SELECT 'base type of @var_v: ' + CAST(sql_variant_property(@var_v, 'basetype') AS VARCHAR(100));

	  FETCH NEXT FROM cur_a INTO @var_i, @var_d, @var_c, @var_u, @var_v;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_i: ' + CAST(@var_i AS VARCHAR(100));
	  SELECT '@var_d: ' + CAST(@var_d AS VARCHAR(100));
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));
	  SELECT '@var_u: ' + CAST(@var_u AS VARCHAR(100));
	  SELECT 'base type of @var_v: ' + CAST(sql_variant_property(@var_v, 'basetype') AS VARCHAR(100));

	  FETCH NEXT FROM cur_a INTO @var_i, @var_d, @var_c, @var_u, @var_v;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_i: ' + CAST(@var_i AS VARCHAR(100));
	  SELECT '@var_d: ' + CAST(@var_d AS VARCHAR(100));
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));
	  SELECT '@var_u: ' + CAST(@var_u AS VARCHAR(100));
	  SELECT 'base type of @var_v: ' + CAST(sql_variant_property(@var_v, 'basetype') AS VARCHAR(100));

	  CLOSE cur_a;
END;
GO

EXEC babel_cursor_multi_columns_proc;
GO

-- T-SQL extended DECLARE CURSOR sytax

CREATE PROCEDURE babel_global_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR GLOBAL FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
END;
GO

CREATE PROCEDURE babel_local_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	  CLOSE cur_a;
END;
GO

EXEC babel_local_cursor_proc;
GO

CREATE PROCEDURE babel_forward_only_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FORWARD_ONLY FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 3;

	  -- error
	  FETCH PRIOR FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  CLOSE cur_a;
END;
GO

EXEC babel_forward_only_cursor_proc;
GO

CREATE PROCEDURE babel_scroll_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR SCROLL FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 3;

	  FETCH PRIOR FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	  CLOSE cur_a;
END;
GO

EXEC babel_scroll_cursor_proc;
GO

CREATE PROCEDURE babel_static_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR STATIC FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	  CLOSE cur_a;
END;
GO

EXEC babel_static_cursor_proc;
GO

CREATE PROCEDURE babel_keyset_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR KEYSET FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	  CLOSE cur_a;
END;
GO

--EXEC babel_keyset_cursor_proc;
--GO

CREATE PROCEDURE babel_dynamic_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR DYNAMIC FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	  CLOSE cur_a;
END;
GO

--EXEC babel_dynamic_cursor_proc;
--GO

CREATE PROCEDURE babel_fast_forward_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FAST_FORWARD FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	  CLOSE cur_a;
END;
GO

EXEC babel_fast_forward_cursor_proc;
GO

CREATE PROCEDURE babel_read_only_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR READ_ONLY FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	-- TODO: currently READ_ONLY is ignored. read-only cursor is updatable.
	-- UPDATE babel_cursor_t1 SET i = i+1 WHERE CURRENT OF cur_a;
	  CLOSE cur_a;
END;
GO

EXEC babel_read_only_cursor_proc;
GO

CREATE PROCEDURE babel_scroll_locks_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR SCROLL_LOCKS FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	  CLOSE cur_a;
END;
GO

--EXEC babel_scroll_locks_cursor_proc;
--GO

CREATE PROCEDURE babel_optimistic_cursor_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR OPTIMISTIC FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	  CLOSE cur_a;
END;
GO

--EXEC babel_optimistic_cursor_proc;
--GO

-- fetch options
CREATE PROCEDURE babel_cursor_fetch_options_proc
AS
BEGIN
	DECLARE @var_a int;
	DECLARE cur_a CURSOR SCROLL FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	OPEN cur_a;
	-- row 1
	FETCH FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a is null: ' + CAST((case when @var_a is null then 'true' else 'false' end) AS VARCHAR(100));
	-- row 2
	FETCH NEXT FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	-- row 3
	FETCH NEXT FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	-- row 2
	FETCH PRIOR FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	-- row 5
	FETCH LAST FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	-- row 1
	FETCH FIRST FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a is null: ' + CAST((case when @var_a is null then 'true' else 'false' end) AS VARCHAR(100));
	-- row 3
	FETCH ABSOLUTE 3 FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	-- row 4
	FETCH ABSOLUTE -2 FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	-- row 1
	FETCH RELATIVE -3 FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a is null: ' + CAST((case when @var_a is null then 'true' else 'false' end) AS VARCHAR(100));
	-- row 3
	FETCH RELATIVE 2 FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));

	-- row 3
	DECLARE @var_offset int;
	SET @var_offset = 3;
	FETCH ABSOLUTE @var_offset FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
	-- row 2
	SET @var_offset = -1;
	FETCH RELATIVE @var_offset FROM cur_a INTO @var_a;
	SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));

	CLOSE cur_a;
END;
GO

EXEC babel_cursor_fetch_options_proc
GO

-- unsual @@fetch_status (-1 can be shown only now)
CREATE PROCEDURE babel_cursor_fetch_failure_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;

	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5;

	  SET @var_a = 1;
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
	  CLOSE cur_a;
END;
GO

EXEC babel_cursor_fetch_failure_proc;
GO

CREATE PROCEDURE babel_cursor_fetch_unopened_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@@fetch_status: ' + CAST(@@fetch_status AS VARCHAR(10));
END;
GO

EXEC babel_cursor_fetch_unopened_proc;
GO

CREATE PROCEDURE babel_cursor_deallocate_assign_proc
AS
BEGIN
	  DECLARE @var_i int;
	  DECLARE @var_c varchar(10)
	  DECLARE @cur_a CURSOR;

	  SET @cur_a = CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN @cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc @cur_a, 5;

	  DEALLOCATE @cur_a;

	  -- set another cursor for the same curvar
	  SET @cur_a = CURSOR FOR SELECT c FROM babel_cursor_t1 ORDER BY i;
	  OPEN @cur_a;

	  EXEC babel_fetch_cursor_helper_char_proc @cur_a, 5;

	  CLOSE @cur_a;
END;
GO

EXEC babel_cursor_deallocate_assign_proc
GO

CREATE PROCEDURE babel_cursor_deallocate_assign_change_cursor_type_proc
AS
BEGIN
	  DECLARE @var_i int;
	  DECLARE @var_c varchar(10)
	  DECLARE @cur_a CURSOR;

	  SET @cur_a = CURSOR FAST_FORWARD FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN @cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc @cur_a, 5;

	  DEALLOCATE @cur_a;

	  -- set another cursor for the same curvar
	  SET @cur_a = CURSOR SCROLL FOR SELECT c FROM babel_cursor_t1 ORDER BY c;
	  OPEN @cur_a;

	  EXEC babel_fetch_cursor_helper_char_proc @cur_a, 5;

	  CLOSE @cur_a;
END;
GO

EXEC babel_cursor_deallocate_assign_change_cursor_type_proc
GO

CREATE PROCEDURE babel_cursor_double_set_proc
AS
BEGIN
	  DECLARE @var_i int;
	  DECLARE @var_c varchar(10)
	  DECLARE @cur_a CURSOR;

	  SET @cur_a = CURSOR FAST_FORWARD FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  OPEN @cur_a;

	  EXEC babel_fetch_cursor_helper_int_proc @cur_a, 1;

	  -- set another cursor for the same curvar without deallocate
	  SET @cur_a = CURSOR SCROLL FOR SELECT c FROM babel_cursor_t1 ORDER BY c;
	  OPEN @cur_a;

	  EXEC babel_fetch_cursor_helper_char_proc @cur_a, 1;

	  CLOSE @cur_a;
END;
GO

EXEC babel_cursor_double_set_proc
GO

CREATE PROCEDURE babel_cursor_double_set_without_open_proc
AS
BEGIN
	  DECLARE @var_i int;
	  DECLARE @var_c varchar(10)
	  DECLARE @cur_a CURSOR;

	  SET @cur_a = CURSOR FAST_FORWARD FOR SELECT i FROM babel_cursor_t1;

	  -- set another cursor for the same curvar without deallocate
	  SET @cur_a = CURSOR SCROLL FOR SELECT c FROM babel_cursor_t1;
	  OPEN @cur_a;

	  EXEC babel_fetch_cursor_helper_char_proc @cur_a, 1;

	  CLOSE @cur_a;
END;
GO

EXEC babel_cursor_double_set_without_open_proc
GO

CREATE PROCEDURE babel_cursor_deallocate_uninitialized_proc
AS
BEGIN
	  DECLARE @cur_a CURSOR;
	  DEALLOCATE @cur_a;
END;
GO

EXEC babel_cursor_deallocate_uninitialized_proc
GO

CREATE PROCEDURE babel_cursor_double_deallocate_proc
AS
BEGIN
	  DECLARE @var_i int;
	  DECLARE @cur_a CURSOR;

	  SET @cur_a = CURSOR FAST_FORWARD FOR SELECT i FROM babel_cursor_t1;
	  OPEN @cur_a;
	  FETCH NEXT FROM @cur_a INTO @var_i;

	  EXEC babel_fetch_cursor_helper_int_proc @cur_a, 1;

	  DEALLOCATE @cur_a;
	  DEALLOCATE @cur_a;
END;
GO

EXEC babel_cursor_double_deallocate_proc
GO


CREATE PROCEDURE babel_cursor_switch_cursors_proc
AS
BEGIN
	  DECLARE @var_i int;
	  DECLARE @var_c varchar(10);
	  DECLARE cur_i CURSOR FOR SELECT i FROM babel_cursor_t1;
	  DECLARE cur_c CURSOR FOR SELECT c FROM babel_cursor_t1;
	  DECLARE @refcur CURSOR;

	  OPEN cur_i;
	  OPEN cur_c;

	  -- using cur_a
	  set @refcur = cur_i;
	  FETCH NEXT FROM @refcur INTO @var_i;
	  SELECT '@var_i: ' + CAST(@var_i AS VARCHAR(100));

	  -- switching to cur_c
	  set @refcur = cur_c;
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  -- switching back to cur_a
	  set @refcur = cur_i;
	  FETCH NEXT FROM @refcur INTO @var_i;
	  SELECT '@var_i: ' + CAST(@var_i AS VARCHAR(100));

	  -- switching back to cur_c
	  set @refcur = cur_c;
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  CLOSE cur_i;
	  CLOSE cur_c;
END;
GO

EXEC babel_cursor_switch_cursors_proc;
GO

-- test will keep exchaning two cursor variables
-- and verify their context is kept correctly
CREATE PROCEDURE babel_cursor_switch_cursors_proc_2
AS
BEGIN
	  DECLARE @var_c varchar(10);
	  DECLARE @refcur CURSOR; -- primary cursor
	  DECLARE @refcur2 CURSOR; -- secondary cursor (not called)
	  DECLARE @refcur_temp CURSOR; -- temp variable for swap

	  SET @refcur = CURSOR FOR SELECT i FROM babel_cursor_t1;
	  SET @refcur2 = CURSOR FOR SELECT c FROM babel_cursor_t1;

	  OPEN @refcur;
	  OPEN @refcur2;

	  -- SELECT i
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  -- swap
	  SET @refcur_temp = @refcur;
	  SET @refcur = @refcur2;
	  SET @refcur2 = @refcur_temp;

	  -- SELECT c
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  -- swap
	  SET @refcur_temp = @refcur;
	  SET @refcur = @refcur2;
	  SET @refcur2 = @refcur_temp;

	  -- SELECT i
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  -- swap
	  SET @refcur_temp = @refcur;
	  SET @refcur = @refcur2;
	  SET @refcur2 = @refcur_temp;

	  -- SELECT c
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));
END;
GO

EXEC babel_cursor_switch_cursors_proc_2;
GO


-- test will keep exchaning two cursor variables
-- and verify their context is kept correctly
CREATE PROCEDURE babel_cursor_switch_cursors_proc_3
AS
BEGIN
	  DECLARE @var_c varchar(10);
	  DECLARE @refcur CURSOR; -- primary cursor
	  DECLARE @refcur2 CURSOR; -- secondary cursor (not called)
	  DECLARE @refcur_temp CURSOR; -- temp variable for swap

	  SET @refcur = CURSOR FOR SELECT i FROM babel_cursor_t1;
	  OPEN @refcur;

	  -- swap
	  SET @refcur_temp = @refcur;
	  SET @refcur = @refcur2;
	  SET @refcur2 = @refcur_temp;

	  SET @refcur = CURSOR FOR SELECT c FROM babel_cursor_t1;
	  OPEN @refcur;

	  -- SELECT c
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  -- swap
	  SET @refcur_temp = @refcur;
	  SET @refcur = @refcur2;
	  SET @refcur2 = @refcur_temp;

	  -- SELECT i
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  -- swap
	  SET @refcur_temp = @refcur;
	  SET @refcur = @refcur2;
	  SET @refcur2 = @refcur_temp;

	  -- SELECT c
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  -- swap
	  SET @refcur_temp = @refcur;
	  SET @refcur = @refcur2;
	  SET @refcur2 = @refcur_temp;

	  -- SELECT i
	  FETCH NEXT FROM @refcur INTO @var_c;
	  SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));

	  CLOSE @refcur;
	  CLOSE @refcur2;
END;
GO

EXEC babel_cursor_switch_cursors_proc_3;
GO


-- CURSOR_STATUS
CREATE PROCEDURE babel_cursor_status_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i
	  SELECT 'cursor_status (after decl): ' + cast(cursor_status('local','cur_a') as varchar(10));

	  OPEN cur_a
	  SELECT 'cursor_status (after open): ' + cast(cursor_status('local','cur_a') as varchar(10));

	  FETCH FROM cur_a INTO @var_a;
	  SELECT 'cursor_status (after fetch): ' + cast(cursor_status('local','cur_a') as varchar(10));

	  WHILE @@FETCH_STATUS = 0
	  BEGIN
			SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
			FETCH FROM cur_a INTO @var_a;
	  END

	  -- cursor_source is 'variable'. should not be shown
	  SELECT 'cursor_status (variable - should not be shown): ' + cast(cursor_status('variable','cur_a') as varchar(10));

	  CLOSE cur_a
	  SELECT 'cursor_status (after close): ' + cast(cursor_status('local','cur_a') as varchar(10));

	  DEALLOCATE cur_a
	  SELECT 'cursor_status (after deallocate): ' + cast(cursor_status('local','cur_a') as varchar(10));
END;
GO

EXEC babel_cursor_status_proc;
GO


CREATE PROCEDURE babel_nested_cursor_status_proc_level_2
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i
	  SELECT 'cursor_status lv2 (after decl): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  OPEN cur_a
	  SELECT 'cursor_status lv2 (after open): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  FETCH FROM cur_a INTO @var_a;
	  SELECT 'cursor_status lv2 (after fetch): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  CLOSE cur_a
	  SELECT 'cursor_status lv2 (after close): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  DEALLOCATE cur_a
	  SELECT 'cursor_status lv2 (after deallocate): ' + cast(cursor_status('local','cur_a') as varchar(10));
END
GO

CREATE PROCEDURE babel_nested_cursor_status_proc_level_1
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i
	  SELECT 'cursor_status lv1 (after decl): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  OPEN cur_a
	  SELECT 'cursor_status lv1 (after open): ' + cast(cursor_status('local','cur_a') as varchar(10));

	  EXEC babel_nested_cursor_status_proc_level_2
	  -- result should not be affected
	  SELECT 'cursor_status lv1 (after exec nested procedure): ' + cast(cursor_status('local','cur_a') as varchar(10));

	  FETCH FROM cur_a INTO @var_a;
	  SELECT 'cursor_status lv1 (after fetch): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  CLOSE cur_a
	  SELECT 'cursor_status lv1 (after close): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  DEALLOCATE cur_a
	  SELECT 'cursor_status lv1 (after deallocate): ' + cast(cursor_status('local','cur_a') as varchar(10));
END
GO

CREATE PROCEDURE babel_nested_cursor_status_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i
	  SELECT 'cursor_status lv0 (after decl): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  EXEC babel_nested_cursor_status_proc_level_1
	  -- result should not be affected
	  SELECT 'cursor_status lv0 (after exec nested procedure): ' + cast(cursor_status('local','cur_a') as varchar(10));

	  OPEN cur_a
	  SELECT 'cursor_status lv0 (after open): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  FETCH FROM cur_a INTO @var_a;
	  SELECT 'cursor_status lv0 (after fetch): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  CLOSE cur_a
	  SELECT 'cursor_status lv0 (after close): ' + cast(cursor_status('local','cur_a') as varchar(10));
	  DEALLOCATE cur_a
	  SELECT 'cursor_status lv0 (after deallocate): ' + cast(cursor_status('local','cur_a') as varchar(10));
END;
GO

EXEC babel_nested_cursor_status_proc;
GO

CREATE PROCEDURE babel_cursor_var_status_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE @cur_a CURSOR;
	  SELECT 'cursor_status (after decl): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  SET @cur_a = CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i
	  SELECT 'cursor_status (after set): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  OPEN @cur_a
	  SELECT 'cursor_status (after open): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  FETCH FROM @cur_a INTO @var_a;
	  SELECT 'cursor_status (after fetch): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  WHILE @@FETCH_STATUS = 0
	  BEGIN
		SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
		FETCH FROM @cur_a INTO @var_a;
	  END

	  -- cursor source is 'local'. should not be shown.
	  SELECT 'cursor_status (local - should not be shown): ' + cast(cursor_status('local','@cur_a') as varchar(10));

	  CLOSE @cur_a
	  SELECT 'cursor_status (after close): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  DEALLOCATE @cur_a
	  SELECT 'cursor_status (after deallocate): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  -- assign new cursor
	  DECLARE @var_c varchar(100)
	  SET @cur_a = CURSOR FOR SELECT c FROM babel_cursor_t1 ORDER BY c
	  SELECT 'cursor_status (after set): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  OPEN @cur_a
	  SELECT 'cursor_status (after open): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  FETCH FROM @cur_a INTO @var_c;
	  SELECT 'cursor_status (after fetch): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  WHILE @@FETCH_STATUS = 0
	  BEGIN
		SELECT '@var_c: ' + CAST(@var_c AS VARCHAR(100));
		FETCH FROM @cur_a INTO @var_c;
	  END

	  CLOSE @cur_a
	  SELECT 'cursor_status (after close): ' + cast(cursor_status('variable','@cur_a') as varchar(10));

	  DEALLOCATE @cur_a
	  SELECT 'cursor_status (after deallocate): ' + cast(cursor_status('variable','@cur_a') as varchar(10));
END;
GO

EXEC babel_cursor_var_status_proc;
GO

CREATE PROCEDURE babel_cursor_status_non_literal_param_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i

	  DECLARE @cur_source varchar(10) = 'local';
	  DECLARE @cur_name varchar(10) = 'cur_a';

	  OPEN cur_a
	  SELECT 'cursor_status (after open): ' + cast(cursor_status(@cur_source,'c'+'u'+'r'+'_'+'a') as varchar(10));

	  CLOSE cur_a
	  SELECT 'cursor_status (after close): ' + cast(cursor_status(substring(('local2'),1,5),@cur_name) as varchar(10));
END;
GO

EXEC babel_cursor_status_non_literal_param_proc;
GO


-- auto close
CREATE PROCEDURE babel_cursor_auto_close_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1;

	  OPEN cur_a;
	  FETCH NEXT FROM cur_a INTO @var_a;
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
END;
GO

CREATE PROCEDURE babel_cursor_auto_close_exec_proc
AS
BEGIN
	  DECLARE @cursor_cnt int;

	  -- should be empty before execution
	  SELECT @cursor_cnt = count(*) FROM pg_catalog.pg_cursors WHERE statement like '%babel_cursor_t1%' and statement not like '%pg_cursors%';
	  SELECT '@cursor_cnt (before proc execution): ' + CAST(@cursor_cnt AS VARCHAR(100));

	  EXEC babel_cursor_auto_close_proc;
	  -- should be empty because cursor is closed automatically
	  SELECT @cursor_cnt = count(*) FROM pg_catalog.pg_cursors WHERE statement like '%babel_cursor_t1%' and statement not like '%pg_cursors%';
	  SELECT '@cursor_cnt (after proc execution): ' + CAST(@cursor_cnt AS VARCHAR(100));
END;
GO

EXEC babel_cursor_auto_close_exec_proc;
GO


CREATE PROCEDURE babel_cursor_var_auto_close_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE @cur_a CURSOR;
	  SET @cur_a = CURSOR FOR SELECT i FROM babel_cursor_t1;

	  OPEN @cur_a;
	  FETCH NEXT FROM @cur_a INTO @var_a;
	  SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
END;
GO

CREATE PROCEDURE babel_cursor_var_auto_close_exec_proc
AS
BEGIN
	  DECLARE @cursor_cnt int;

	  -- should be empty before execution
	  SELECT @cursor_cnt = count(*) FROM pg_catalog.pg_cursors WHERE statement like '%babel_cursor_t1%' and statement not like '%pg_cursors%';
	  SELECT '@cursor_cnt (before proc execution): ' + CAST(@cursor_cnt AS VARCHAR(100));

	  EXEC babel_cursor_var_auto_close_proc;
	  -- should be empty because cursor is closed automatically
	  SELECT @cursor_cnt = count(*) FROM pg_catalog.pg_cursors WHERE statement like '%babel_cursor_t1%' and statement not like '%pg_cursors%';
	  SELECT '@cursor_cnt (after proc execution): ' + CAST(@cursor_cnt AS VARCHAR(100));
END;
GO

EXEC babel_cursor_var_auto_close_exec_proc;
GO

CREATE PROCEDURE babel_cursor_redecl_proc
AS
BEGIN
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
	  CLOSE cur_a
	  DEALLOCATE cur_a

	  -- redeclare with different definition
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i+100 from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
	  CLOSE cur_a
	  DEALLOCATE cur_a
END;
GO

EXEC babel_cursor_redecl_proc
GO


CREATE PROCEDURE babel_cursor_redecl_not_deallocd_proc_1
AS
BEGIN
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
	  CLOSE cur_a

	  -- redeclare with different definition
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i+100 from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
	  CLOSE cur_a
END;
GO

EXEC babel_cursor_redecl_not_deallocd_proc_1
GO

CREATE PROCEDURE babel_cursor_redecl_not_deallocd_proc_2
AS
BEGIN
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i from babel_cursor_t1
	  OPEN cur_a

	  -- redeclare with different definition
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i+100 from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
END;
GO

EXEC babel_cursor_redecl_not_deallocd_proc_2
GO

CREATE PROCEDURE babel_cursor_redecl_not_deallocd_proc_3
AS
BEGIN
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i from babel_cursor_t1
	  -- redeclare with different definition
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i+100 from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
END;
GO

EXEC babel_cursor_redecl_not_deallocd_proc_3
GO

CREATE PROCEDURE babel_cursor_redecl_goto_proc
AS
BEGIN
	  GOTO label1
	label2:
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i+100 from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
	  GOTO label3
	label1:
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
	  DEALLOCATE cur_a
	  GOTO label2
	label3:
END
GO

EXEC babel_cursor_redecl_goto_proc
GO

CREATE PROCEDURE babel_cursor_redecl_goto_proc_2
AS
BEGIN
	  GOTO label1
	label2:
	  -- error is expected here because cur_a in label1 is not dealloc'd
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i+100 from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
	  DEALLOCATE cur_a
	  GOTO label3
	label1:
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i from babel_cursor_t1
	  OPEN cur_a
	  EXEC babel_fetch_cursor_helper_int_proc cur_a, 5
	  GOTO label2
	label3:
END
GO

EXEC babel_cursor_redecl_goto_proc_2
GO

CREATE PROCEDURE babel_print_sp_cursor_list(@cur CURSOR)
AS
BEGIN
	  DECLARE @refname VARCHAR(200);
	  DECLARE @curname VARCHAR(200);
	  DECLARE @scope INT;
	  DECLARE @status INT;
	  DECLARE @model INT;
	  DECLARE @concurrency INT;
	  DECLARE @scrollable INT;
	  DECLARE @open_status INT;
	  DECLARE @cursor_rows DECIMAL(10,0);
	  DECLARE @fetch_status INT;
	  DECLARE @column_count INT;
	  DECLARE @row_count DECIMAL(10,0);
	  DECLARE @last_operation INT;

	  FETCH FROM @cur INTO @refname, @curname, @scope, @status, @model, @concurrency, @scrollable, @open_status, @cursor_rows, @fetch_status, @column_count, @row_count, @last_operation;
	  WHILE @@FETCH_STATUS = 0
	  BEGIN
		SELECT '(sp_cursor_list out) @refname: ' + @refname + ', @curname: ' + @curname + ', @scope: ' + cast(@scope as VARCHAR(10)) + ', @model: ' + cast(@model as varchar(10)) + ', @concurrency: ' + cast(@concurrency as varchar(10)) + ', @scrollable: ' + cast(@scrollable as varchar(10)) + ', @open_status: ' + cast(@open_status as varchar(10)) + ', @cursor_rows: ' + cast(@cursor_rows as varchar(10)) + ', @fetch_status: ' + cast(@fetch_status as varchar(10)) + ', @column_count: ' + cast(@column_count as varchar(10)) + ', @row_count: ' + cast(@row_count as varchar(10)) + ', @last_operation ' + cast(@last_operation as varchar(10));
		FETCH FROM @cur INTO @refname, @curname, @scope, @status, @model, @concurrency, @scrollable, @open_status, @cursor_rows, @fetch_status, @column_count, @row_count, @last_operation;
	  END

	  CLOSE @cur;
	  DEALLOCATE @cur;
END
GO


CREATE PROCEDURE babel_sp_cursor_list_proc
AS
BEGIN
	  DECLARE @report_cur CURSOR;
	  DECLARE @var_a int;

	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  DECLARE cur_b CURSOR FOR SELECT i+1 FROM babel_cursor_t1 ORDER BY i;

	  DECLARE @refcur_b CURSOR;
	  DECLARE @refcur_c CURSOR;

	  SELECT '== AFTER DECLARE ==';
	  EXEC sp_cursor_list @report_cur OUT, 1;
	  EXEC babel_print_sp_cursor_list @report_cur;

	  SET @refcur_b = cur_b;
	  SET @refcur_c = CURSOR FOR SELECT i+2 FROM babel_cursor_t1 ORDER BY i;

	  SELECT '== AFTER SET ==';
	  EXEC sp_cursor_list @report_cur OUT, 1;
	  EXEC babel_print_sp_cursor_list @report_cur;

	  OPEN cur_a;
	  OPEN @refcur_b;
	  OPEN @refcur_c;

	  SELECT '== AFTER OPEN ==';
	  EXEC sp_cursor_list @report_cur OUT, 1;
	  EXEC babel_print_sp_cursor_list @report_cur;

	  FETCH NEXT FROM cur_a INTO @var_a;
	  FETCH NEXT FROM @refcur_b INTO @var_a;
	  FETCH NEXT FROM @refcur_c INTO @var_a;

	  SELECT '== AFTER FETCH ==';
	  EXEC sp_cursor_list @report_cur OUT, 1;
	  EXEC babel_print_sp_cursor_list @report_cur;

	  CLOSE cur_a;
	  CLOSE @refcur_b;
	  CLOSE @refcur_c;

	  SELECT '== AFTER CLOSE ==';
	  EXEC sp_cursor_list @report_cur OUT, 1;
	  EXEC babel_print_sp_cursor_list @report_cur;

	  DEALLOCATE cur_a;
	  DEALLOCATE @refcur_b;
	  DEALLOCATE @refcur_c;

	  SELECT '== AFTER DEALLOCATE ==';
	  EXEC sp_cursor_list @report_cur OUT, 1;
	  EXEC babel_print_sp_cursor_list @report_cur;
END;
GO

EXEC babel_sp_cursor_list_proc;
GO

CREATE PROCEDURE babel_sp_cursor_list_nested_proc_2
AS
BEGIN
	  DECLARE @report_cur CURSOR;
	  DECLARE cur_a CURSOR FOR SELECT * FROM babel_cursor_t1 ORDER BY c;
	  OPEN cur_a;

	  SELECT '== in the nested proc ==';
	  EXEC sp_cursor_list @report_cur OUT, 3;
	  EXEC babel_print_sp_cursor_list @report_cur;

END;
GO

CREATE PROCEDURE babel_sp_cursor_list_nested_proc
AS
BEGIN
	  DECLARE @report_cur CURSOR;
	  DECLARE @var_a INT;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  DECLARE @refcur_a CURSOR;

	  SET @refcur_a = cur_a;

	  OPEN cur_a;
	  FETCH NEXT FROM @refcur_a INTO @var_a;

	  SELECT '== before calling nested proc ==';
	  EXEC sp_cursor_list @report_cur OUT, 3;
	  EXEC babel_print_sp_cursor_list @report_cur;

	  EXEC babel_sp_cursor_list_nested_proc_2;

	  SELECT '== after calling nested proc ==';
	  EXEC sp_cursor_list @report_cur OUT, 3;
	  EXEC babel_print_sp_cursor_list @report_cur;
END;
GO

EXEC babel_sp_cursor_list_nested_proc;
GO

CREATE PROCEDURE babel_sp_describe_cursor_proc
AS
BEGIN
	  DECLARE @report_cur CURSOR;
	  DECLARE @var_a int;

	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i;
	  DECLARE cur_b CURSOR FOR SELECT i+1 FROM babel_cursor_t1 ORDER BY i;

	  DECLARE @refcur_b CURSOR;
	  DECLARE @refcur_c CURSOR;

	  SELECT '== AFTER DECLARE ==';
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_a';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;

	  SET @refcur_b = cur_b;
	  SET @refcur_c = CURSOR FOR SELECT i+2 FROM babel_cursor_t1 ORDER BY i;

	  SELECT '== AFTER SET ==';
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_a';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_c';
	  EXEC babel_print_sp_cursor_list @report_cur;

	  OPEN cur_a;
	  OPEN @refcur_b;
	  OPEN @refcur_c;

	  SELECT '== AFTER OPEN ==';
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_a';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_c';
	  EXEC babel_print_sp_cursor_list @report_cur;

	  FETCH NEXT FROM cur_a INTO @var_a;
	  FETCH NEXT FROM @refcur_b INTO @var_a;
	  FETCH NEXT FROM @refcur_c INTO @var_a;

	  SELECT '== AFTER FETCH ==';
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_a';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_c';
	  EXEC babel_print_sp_cursor_list @report_cur;

	  SELECT '== BEGIN (call with invalid argument) =='
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', 'cur_a';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'local', '@refcur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'local', '@refcur_not_exsits';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_not_exsits';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  SELECT '== END (call with invalid argument) =='

	  CLOSE cur_a;
	  CLOSE @refcur_b;
	  CLOSE @refcur_c;

	  SELECT '== AFTER CLOSE ==';
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_a';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_c';
	  EXEC babel_print_sp_cursor_list @report_cur;

	  DEALLOCATE cur_a;
	  DEALLOCATE @refcur_b;
	  DEALLOCATE @refcur_c;

	  SELECT '== AFTER DEALLOCATE ==';
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_a';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'local', 'cur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_b';
	  EXEC babel_print_sp_cursor_list @report_cur;
	  EXEC sp_describe_cursor @report_cur OUT, 'variable', '@refcur_c';
	  EXEC babel_print_sp_cursor_list @report_cur;

END;
GO

EXEC babel_sp_describe_cursor_proc;
GO

CREATE PROCEDURE babel_same_cursor_name_proc(@opt int)
AS
BEGIN
	  DECLARE @report_cur CURSOR;
	  IF @opt = 1
	  BEGIN
		DECLARE @var_a int;
		DECLARE cur_a CURSOR LOCAL FOR SELECT i from babel_cursor_t1;
		OPEN cur_a;
		FETCH NEXT from cur_a INTO @var_a;
		SELECT '@var_a: ' + cast(@var_a as varchar(10));
	  END
	  ELSE IF @opt = 2
	  BEGIN
		DECLARE @var_b varchar(10);
		DECLARE cur_a CURSOR LOCAL FOR SELECT c from babel_cursor_t1;
		OPEN cur_a;
		FETCH NEXT from cur_a INTO @var_b;
		SELECT '@var_b: ' + @var_b;
	  END
	  ELSE
		SELECT 'not valid option'
END;
GO

EXEC babel_same_cursor_name_proc 1;
GO

EXEC babel_same_cursor_name_proc 2;
GO

CREATE PROCEDURE babel_cursor_rows_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR LOCAL FOR SELECT i from babel_cursor_t1;
	  DECLARE cur_b CURSOR LOCAL FOR SELECT i from babel_cursor_t1 where i = 1;

	  SELECT '@@cursor_rows (after decl): ' + cast(@@cursor_rows as varchar(10));

	  -- from now on, @@cursor_rows should depend on cur_a
	  OPEN cur_a;
	  SELECT '@@cursor_rows (after open a): ' + cast(@@cursor_rows as varchar(10));
	  FETCH NEXT from cur_a INTO @var_a;
	  SELECT '@var_a: ' + cast(@var_a as varchar(10));
	  SELECT '@@cursor_rows (after fetch 1): ' + cast(@@cursor_rows as varchar(10));

	  -- from now on, @@cursor_rows should depend on cur_b
	  OPEN cur_b;
	  SELECT '@@cursor_rows (after open b): ' + cast(@@cursor_rows as varchar(10));

	  FETCH NEXT from cur_a INTO @var_a;
	  SELECT '@var_a: ' + cast(@var_a as varchar(10));
	  SELECT '@@cursor_rows (after fetch 2): ' + cast(@@cursor_rows as varchar(10));

	  CLOSE cur_a;
	  SELECT '@@cursor_rows (after close a): ' + cast(@@cursor_rows as varchar(10));

	  CLOSE cur_b;
	  SELECT '@@cursor_rows (after close b): ' + cast(@@cursor_rows as varchar(10));

	  DEALLOCATE cur_a;
	  SELECT '@@cursor_rows (after deallocate): ' + cast(@@cursor_rows as varchar(10));
END;
GO

EXEC babel_cursor_rows_proc;
GO

CREATE PROCEDURE babel_sp_cursor_proc(@opttype INT, @rownum INT, @tablename text) AS
BEGIN
	  DECLARE @cursor_handle int;
	  SET @cursor_handle = sys.babelfish_pltsql_get_last_cursor_handle();
	  EXEC sp_cursor @cursor_handle, @opttype, @rownum, @tablename;
END;
GO

CREATE PROCEDURE babel_sp_cursor_open_proc(@stmt TEXT, @scrollopt INT, @ccopt INT) AS
BEGIN
	  DECLARE @cursor_handle int;
	  EXEC sp_cursoropen @cursor_handle OUTPUT, @stmt, @scrollopt, @ccopt;
END;
GO

CREATE PROCEDURE babel_sp_cursor_prepare_proc(@stmt TEXT, @options INT, @scrollopt INT, @ccopt INT) AS
BEGIN
	  DECLARE @stmt_handle int;
	  EXEC sp_cursorprepare @stmt_handle OUTPUT, N'', @stmt, @options, @scrollopt, @ccopt;
	  IF (@stmt_handle <> sys.babelfish_pltsql_get_last_stmt_handle())
		SELECT '@stmt_handle is wrong';
END;
GO

CREATE PROCEDURE babel_sp_cursor_execute_proc AS
BEGIN
	  DECLARE @stmt_handle INT;
	  DECLARE @cursor_handle INT;
	  SET @stmt_handle = sys.babelfish_pltsql_get_last_stmt_handle();

	  EXEC sp_cursorexecute @stmt_handle, @cursor_handle OUTPUT;
END;
GO

CREATE PROCEDURE babel_sp_cursor_prepexec_proc(@stmt TEXT, @options INT, @scrollopt INT, @ccopt INT) AS
BEGIN
	  DECLARE @stmt_handle INT;
	  DECLARE @cursor_handle INT;

	  EXEC sp_cursorprepexec @stmt_handle OUTPUT, @cursor_handle OUTPUT, N'', @stmt, @options, @scrollopt, @ccopt;
END;
GO

CREATE PROCEDURE babel_sp_cursor_unprepare_proc AS
BEGIN
	  DECLARE @stmt_handle INT;
	  SET @stmt_handle = sys.babelfish_pltsql_get_last_stmt_handle();
	  EXEC sp_cursorunprepare @stmt_handle;
END;
GO

CREATE PROCEDURE babel_sp_cursor_fetch_proc(@fetchtype INT, @rownum INT, @nrows INT) AS
BEGIN
	  DECLARE @cursor_handle int;
	  SET @cursor_handle = sys.babelfish_pltsql_get_last_cursor_handle();
	  EXEC sp_cursorfetch @cursor_handle, @fetchtype, @rownum, @nrows;
END;
GO

CREATE PROCEDURE babel_sp_cursor_option_proc(@code INT, @value INT) AS
BEGIN
	  DECLARE @cursor_handle int;
	  SET @cursor_handle = sys.babelfish_pltsql_get_last_cursor_handle();
	  EXEC sp_cursoroption @cursor_handle, @code, @value;
END;
GO

CREATE PROCEDURE babel_sp_cursor_close_proc AS
BEGIN
	  DECLARE @cursor_handle int;
	  SET @cursor_handle = sys.babelfish_pltsql_get_last_cursor_handle();
	  EXEC sp_cursorclose @cursor_handle;
END;
GO

CREATE PROCEDURE babel_assert_no_open_cursor_proc AS
BEGIN
	  DECLARE @num_opened_cursor int;
	  SELECT @num_opened_cursor = count(*) FROM pg_catalog.pg_cursors where statement not like '%@num_opened_cursor%';
	  IF @num_opened_cursor = 0
		SELECT 'no open cursor (expected)';
	  ELSE
		SELECT 'there is an opened cursor (this message should not be shown)';
END;
GO


-- START of sp_cursor testing

EXEC babel_sp_cursor_open_proc 'select * from babel_cursor_t1', 2, 1;
GO

-- NEXT 1
EXEC babel_sp_cursor_fetch_proc 2, 0, 1;
GO

-- NEXT 1
EXEC babel_sp_cursor_fetch_proc 2, 0, 1;
GO

-- NEXT 1
EXEC babel_sp_cursor_fetch_proc 2, 0, 1;
GO

-- PREV 1
EXEC babel_sp_cursor_fetch_proc 4, 0, 1;
GO

-- FIRST 2
EXEC babel_sp_cursor_fetch_proc 1, 0, 2;
GO

-- LAST 3
EXEC babel_sp_cursor_fetch_proc 8, 0, 3;
GO

-- ABSOLUTE 2 2
EXEC babel_sp_cursor_fetch_proc 16, 2, 2;
GO

EXEC babel_sp_cursor_close_proc;
GO

EXEC babel_assert_no_open_cursor_proc;
GO


-- START of sp_cursor auto-close

EXEC babel_sp_cursor_open_proc 'select * from babel_cursor_t1', 16400, 1;
GO

EXEC babel_sp_cursor_fetch_proc 2, 0, 100;
GO

EXEC babel_assert_no_open_cursor_proc;
GO


-- START of sp_cursoroption and sp_cursor

EXEC babel_sp_cursor_open_proc 'select * from babel_cursor_t1', 2, 1;
GO

-- NEXT 2
EXEC babel_sp_cursor_fetch_proc 2, 0, 2;
GO

-- TEXTPTR_ONLY 2 (not meaningful without TDS implemenation)
EXEC babel_sp_cursor_option_proc 1, 2;
SELECT sys.babelfish_pltsql_cursor_show_textptr_only_column_indexes(sys.babelfish_pltsql_get_last_cursor_handle());
GO

EXEC babel_sp_cursor_proc 40, 1, '';
GO

-- TEXTPTR_ONLY 2 (not meaningful without TDS implemenation)
EXEC babel_sp_cursor_option_proc 1, 4;
SELECT sys.babelfish_pltsql_cursor_show_textptr_only_column_indexes(sys.babelfish_pltsql_get_last_cursor_handle());
GO

EXEC babel_sp_cursor_proc 40, 1, '';
GO

-- TEXTPTR_ONLY 0 (not meaningful without TDS implemenation)
EXEC babel_sp_cursor_option_proc 1, 0;
SELECT sys.babelfish_pltsql_cursor_show_textptr_only_column_indexes(sys.babelfish_pltsql_get_last_cursor_handle());
GO

EXEC babel_sp_cursor_proc 40, 1, '';
GO

-- TEXTDATA 3 (not meaningful without TDS implemenation)
EXEC babel_sp_cursor_option_proc 3, 3;
SELECT sys.babelfish_pltsql_cursor_show_textptr_only_column_indexes(sys.babelfish_pltsql_get_last_cursor_handle());
GO

EXEC babel_sp_cursor_proc 40, 1, '';
GO

-- TEXTDATA 0 (not meaningful without TDS implemenation)
EXEC babel_sp_cursor_option_proc 3, 0;
SELECT sys.babelfish_pltsql_cursor_show_textptr_only_column_indexes(sys.babelfish_pltsql_get_last_cursor_handle());
GO

EXEC babel_sp_cursor_proc 40, 1, '';
GO

EXEC babel_sp_cursor_close_proc;
GO

EXEC babel_assert_no_open_cursor_proc;
GO


-- start of cursor prep/exec test

EXEC babel_sp_cursor_prepare_proc 'select * from babel_cursor_t1', 0, 2, 1;
GO

EXEC babel_sp_cursor_execute_proc;
GO
EXEC babel_sp_cursor_fetch_proc 2, 0, 1;
GO
EXEC babel_sp_cursor_close_proc;
GO

EXEC babel_sp_cursor_execute_proc;
GO
EXEC babel_sp_cursor_fetch_proc 2, 0, 4;
GO
EXEC babel_sp_cursor_close_proc;
GO

EXEC babel_sp_cursor_unprepare_proc;
GO

EXEC babel_assert_no_open_cursor_proc;
GO


EXEC babel_sp_cursor_prepexec_proc 'select i+100 from babel_cursor_t1', 0, 16400, 1;
GO
EXEC babel_sp_cursor_fetch_proc 2, 0, 1;
GO
EXEC babel_sp_cursor_close_proc;
GO

EXEC babel_sp_cursor_execute_proc;
GO
EXEC babel_sp_cursor_fetch_proc 2, 0, 6;
GO

EXEC babel_sp_cursor_unprepare_proc;
GO

EXEC babel_assert_no_open_cursor_proc;
GO


-- test with long varchar to check TOASTed value and memory management works
-- fine
CREATE TABLE babel_cursor_long_varchar(i INT, v varchar(max));
INSERT INTO babel_cursor_long_varchar values (1, repeat('this is the first record. ', 300));
INSERT INTO babel_cursor_long_varchar values (2, repeat('this is the second record. ', 300));
GO

SELECT char_length(v) from babel_cursor_long_varchar;
GO

EXEC babel_sp_cursor_open_proc 'select i, v from babel_cursor_long_varchar', 2, 1;
GO

-- NEXT 2
EXEC babel_sp_cursor_fetch_proc 2, 0, 2;
GO

-- TEXTPTR_ONLY 2 (not meaningful without TDS implemenation)
EXEC babel_sp_cursor_option_proc 1, 2;
SELECT sys.babelfish_pltsql_cursor_show_textptr_only_column_indexes(sys.babelfish_pltsql_get_last_cursor_handle());
GO

EXEC babel_sp_cursor_proc 40, 1, '';
GO

EXEC babel_sp_cursor_close_proc
GO

CREATE PROCEDURE babel_311_cusor_fetch_in_while_proc
AS
BEGIN
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i
	  OPEN cur_a

	  FETCH FROM cur_a INTO @var_a;
	  WHILE @@FETCH_STATUS = 0
	  BEGIN
		SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
		FETCH FROM cur_a INTO @var_a;
	  END
END;
GO

EXEC babel_311_cusor_fetch_in_while_proc;
GO

CREATE PROCEDURE babel_311_cusor_fetch_in_if_proc
AS
BEGIN
	  DECLARE @cnt int;
	  DECLARE @var_a int;
	  DECLARE cur_a CURSOR FOR SELECT i FROM babel_cursor_t1 ORDER BY i
	  OPEN cur_a

	  SET @cnt = 0

	  WHILE @cnt < 10
	  BEGIN
		FETCH FROM cur_a INTO @var_a;
		IF @@FETCH_STATUS <> 0
			BREAK;
		SELECT '@var_a: ' + CAST(@var_a AS VARCHAR(100));
		SET @cnt = @cnt + 1
	  END
END;
GO

EXEC babel_311_cusor_fetch_in_if_proc;
GO

-- BABEL-833
CREATE TABLE babel_833_table (a int);
GO

CREATE PROCEDURE babel_833_proc
AS
  DECLARE ExpiredSessionCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
  FOR SELECT * from sysobjects
GO

-- BABEL-881
CREATE PROCEDURE babel_881_proc AS
  DECLARE cur CURSOR FOR SELECT * FROM sysobjects
  DECLARE @v int
  DEALLOCATE cur;
GO


CREATE PROCEDURE babel_943_proc
AS
BEGIN
	  declare @v int
	  CREATE TABLE #t(n INT)
	  insert into #t values (1)
	  insert into #t values (2)
	  insert into #t values (3)

	  DECLARE TranLockCursor CURSOR FOR (select n from #t)
	  OPEN TranLockCursor
	  select '@@fetch_status before fetch=  '+convert(varchar,@@fetch_status)
	  while @@fetch_status = 0
	  begin
		fetch TranLockCursor into @v
		select 'fetched='+convert(varchar,@v)
	  end
	  CLOSE TranLockCursor
END
GO

EXEC babel_943_proc
GO

DROP PROCEDURE babel_cursor_proc;
DROP PROCEDURE babel_cursor_no_semi_proc;
DROP PROCEDURE babel_cursor_double_precision_proc;
DROP PROCEDURE babel_cursor_varchar_proc;
DROP PROCEDURE babel_cursor_uniqueidentifier_proc;
DROP PROCEDURE babel_cursor_sql_variant_proc;
DROP PROCEDURE babel_cursor_multi_columns_proc;
DROP PROCEDURE babel_local_cursor_proc;
DROP PROCEDURE babel_forward_only_cursor_proc;
DROP PROCEDURE babel_scroll_cursor_proc;
DROP PROCEDURE babel_static_cursor_proc;
DROP PROCEDURE babel_fast_forward_cursor_proc;
DROP PROCEDURE babel_read_only_cursor_proc;
DROP PROCEDURE babel_cursor_fetch_options_proc;
DROP PROCEDURE babel_cursor_fetch_failure_proc;
DROP PROCEDURE babel_cursor_fetch_unopened_proc;
DROP PROCEDURE babel_cursor_deallocate_assign_proc;
DROP PROCEDURE babel_cursor_deallocate_assign_change_cursor_type_proc;
DROP PROCEDURE babel_cursor_double_set_proc;
DROP PROCEDURE babel_cursor_double_set_without_open_proc;
DROP PROCEDURE babel_cursor_deallocate_uninitialized_proc;
DROP PROCEDURE babel_cursor_double_deallocate_proc;
DROP PROCEDURE babel_cursor_switch_cursors_proc;
DROP PROCEDURE babel_cursor_switch_cursors_proc_2;
DROP PROCEDURE babel_cursor_switch_cursors_proc_3;
DROP PROCEDURE babel_cursor_status_proc;
DROP PROCEDURE babel_nested_cursor_status_proc_level_2;
DROP PROCEDURE babel_nested_cursor_status_proc_level_1;
DROP PROCEDURE babel_nested_cursor_status_proc;
DROP PROCEDURE babel_cursor_var_status_proc;
DROP PROCEDURE babel_cursor_status_non_literal_param_proc;
DROP PROCEDURE babel_cursor_auto_close_proc;
DROP PROCEDURE babel_cursor_auto_close_exec_proc;
DROP PROCEDURE babel_cursor_var_auto_close_proc;
DROP PROCEDURE babel_cursor_var_auto_close_exec_proc;
DROP PROCEDURE babel_cursor_redecl_proc;
DROP PROCEDURE babel_cursor_redecl_not_deallocd_proc_1;
DROP PROCEDURE babel_cursor_redecl_not_deallocd_proc_2;
DROP PROCEDURE babel_cursor_redecl_not_deallocd_proc_3;
DROP PROCEDURE babel_cursor_redecl_goto_proc;
DROP PROCEDURE babel_cursor_redecl_goto_proc_2;
DROP PROCEDURE babel_fetch_cursor_helper_int_proc;
DROP PROCEDURE babel_fetch_cursor_helper_char_proc;
DROP PROCEDURE babel_sp_cursor_list_proc;
DROP PROCEDURE babel_sp_cursor_list_nested_proc_2;
DROP PROCEDURE babel_sp_cursor_list_nested_proc;
DROP PROCEDURE babel_sp_describe_cursor_proc;
DROP PROCEDURE babel_print_sp_cursor_list;
DROP PROCEDURE babel_same_cursor_name_proc;
DROP PROCEDURE babel_cursor_rows_proc;
DROP PROCEDURE babel_sp_cursor_proc;
DROP PROCEDURE babel_sp_cursor_open_proc;
DROP PROCEDURE babel_sp_cursor_prepare_proc;
DROP PROCEDURE babel_sp_cursor_execute_proc;
DROP PROCEDURE babel_sp_cursor_prepexec_proc;
DROP PROCEDURE babel_sp_cursor_unprepare_proc;
DROP PROCEDURE babel_sp_cursor_fetch_proc;
DROP PROCEDURE babel_sp_cursor_option_proc;
DROP PROCEDURE babel_sp_cursor_close_proc;
DROP PROCEDURE babel_assert_no_open_cursor_proc;
DROP TABLE babel_cursor_long_varchar;
DROP PROCEDURE babel_311_cusor_fetch_in_while_proc;
DROP PROCEDURE babel_311_cusor_fetch_in_if_proc;
DROP TABLE babel_cursor_t1;
DROP PROCEDURE babel_833_proc;
DROP TABLE babel_833_table;
drop PROCEDURE babel_881_proc;
DROP PROCEDURE babel_943_proc;
GO
