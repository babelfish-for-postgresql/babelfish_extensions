--
-- PLTSQL -- IF Statement
--

CREATE FUNCTION if_with_block() RETURNS void AS $$
BEGIN
    IF true
        BEGIN
            PRINT 'true'
            PRINT 'true'
        END
END
$$ LANGUAGE pltsql;

SELECT if_with_block();

CREATE FUNCTION if_else() RETURNS void AS $$
DECLARE @a int
BEGIN
    SET @a = 1
    IF 2 > @a
        UPDATE pg_settings SET setting = 'notupdated' WHERE name = 'nonexistent';
    ELSE
        SET @a = NULL
END
$$ LANGUAGE pltsql;

SELECT if_else();

CREATE FUNCTION if_else_with_blocks() RETURNS void AS $$
DECLARE @a int
BEGIN
    SET @a = 1
    IF 2 < @a
        BEGIN
            UPDATE pg_settings SET setting = 'notupdated' WHERE name = 'nonexistent';
        END
    ELSE
        BEGIN
            PRINT '2 > @a'
            SET @a = NULL
        END
END
$$ LANGUAGE pltsql;

SELECT if_else_with_blocks();

CREATE FUNCTION if_else_with_nesting() RETURNS void AS $$
DECLARE @a int
BEGIN
    SET @a = 0
    IF 2 > @a
        IF @a = 1
            PRINT '@a = 1'
        ELSE
            PRINT '@a < 1'
    ELSE
        BEGIN
            SET @a = NULL
            PRINT @a
        END
END
$$ LANGUAGE pltsql;

SELECT if_else_with_nesting();
