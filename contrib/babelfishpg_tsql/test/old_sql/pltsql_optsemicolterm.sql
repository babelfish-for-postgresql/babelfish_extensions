--
-- PLTSQL -- Optional semicolon line termination
--

CREATE FUNCTION test_declare_termination() RETURNS void AS $$
DECLARE @a int;
DECLARE @b int = (23 + 45)
DECLARE @c decimal(10,2)
BEGIN
    PRINT @b
END
$$ LANGUAGE pltsql;

SELECT test_declare_termination();

CREATE FUNCTION test_if_termination() RETURNS void AS $$
BEGIN
    IF true
        PRINT 'true';
    IF true
    BEGIN
        PRINT 'true'
    END
END
$$ LANGUAGE pltsql;

SELECT test_if_termination();

CREATE FUNCTION test_assign_termination() RETURNS void AS $$
DECLARE @a int
BEGIN
    SET @a = 25; SET @a = (-@a - 11)
    SET @a = -@a / 2
    PRINT @a
END
$$ LANGUAGE pltsql;

SELECT test_assign_termination();

CREATE FUNCTION test_perform_termination() RETURNS void AS $$
BEGIN
    PERFORM setting FROM pg_settings WHERE name = 'nonexistent';
    PERFORM setting FROM pg_settings WHERE name = 'nonexistent'
END
$$ LANGUAGE pltsql;

SELECT test_perform_termination();

CREATE FUNCTION test_getdiag_termination() RETURNS void AS $$
DECLARE @perform_rowcount int
BEGIN
    PERFORM setting FROM pg_settings WHERE name = 'nonexistent'
    GET DIAGNOSTICS @perform_rowcount = ROW_COUNT;
    PRINT @perform_rowcount
    PERFORM setting FROM pg_settings WHERE name = 'search_path'
    GET DIAGNOSTICS @perform_rowcount = ROW_COUNT
    PRINT @perform_rowcount
END
$$ LANGUAGE pltsql;

SELECT test_getdiag_termination();

CREATE FUNCTION test_close_termination() RETURNS void AS $$
    DECLARE @c1 CURSOR FOR SELECT name FROM pg_settings
BEGIN
    OPEN @c1;
    CLOSE @c1
END
$$ LANGUAGE pltsql;

SELECT test_close_termination();

CREATE FUNCTION test_move_termination() RETURNS void AS $$
    DECLARE @c1 CURSOR FOR SELECT name FROM pg_settings
BEGIN
    OPEN @c1;
    MOVE @c1;
    MOVE @c1
    MOVE FORWARD 1 FROM @c1;
    MOVE FORWARD 2 FROM @c1
    MOVE RELATIVE -1 FROM @c1
    MOVE LAST FROM @c1
    CLOSE @c1
END
$$ LANGUAGE pltsql;

SELECT test_move_termination();

CREATE FUNCTION test_while_termination() RETURNS void AS $$
    DECLARE @a int = 0
BEGIN
    WHILE @a < 2
    BEGIN
        PRINT @a
        SET @a = @a + 1
    END

    WHILE @a < 5
        SET @a = @a + 1

    PRINT @a
END
$$ LANGUAGE pltsql;

SELECT test_while_termination();

CREATE TEMPORARY TABLE test AS SELECT 1 a;

CREATE FUNCTION test_select_after_optsemicol_stmt() RETURNS void AS $$
DECLARE @a int, c1 CURSOR FOR SELECT a FROM test t1, test t2
BEGIN
    SET @a = 12
    SELECT a + 2 INTO @a FROM test WHERE
            a = (SELECT 1) LIMIT 1;
    print @a
end
$$ language pltsql;

SELECT test_select_after_optsemicol_stmt();