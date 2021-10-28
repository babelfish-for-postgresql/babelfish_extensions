--
-- PLTSQL -- PRINT Statement
--

CREATE FUNCTION print_with_semicolon() RETURNS void AS $$
BEGIN
    PRINT 'PRINT with a semicolon.';
END
$$ LANGUAGE pltsql;

SELECT print_with_semicolon();

CREATE FUNCTION print_without_semicolon() RETURNS void AS $$
BEGIN
    PRINT 'PRINT without a semicolon.'
END
$$ LANGUAGE pltsql;

SELECT print_without_semicolon();

CREATE FUNCTION multiple_prints_with_mixed_termination() RETURNS void AS $$
BEGIN
    PRINT 'First PRINT without a semicolon.'
    PRINT 'Second PRINT without a semicolon.'
    PRINT 'Third PRINT with a semicolon.';
END
$$ LANGUAGE pltsql;

SELECT multiple_prints_with_mixed_termination();

CREATE FUNCTION multiple_prints_same_line() RETURNS void AS $$
BEGIN
    PRINT 'First PRINT';PRINT 'Second PRINT'
    PRINT 'Third PRINT'; PRINT 'Fourth PRINT'
    PRINT 'Fifth PRINT' PRINT 'Sixth PRINT'
END
$$ LANGUAGE pltsql;

SELECT multiple_prints_same_line();

CREATE FUNCTION error_print_noarg() RETURNS void AS $$
BEGIN
    PRINT
END
$$ LANGUAGE pltsql;

CREATE FUNCTION error_print_noarg_semicolon() RETURNS void AS $$
BEGIN
    PRINT;
END
$$ LANGUAGE pltsql;

CREATE FUNCTION error_print_multipleargs() RETURNS void AS $$
BEGIN
    PRINT 'first' 'second'
END
$$ LANGUAGE pltsql;

CREATE FUNCTION error_print_multipleargs_comma() RETURNS void AS $$
BEGIN
    PRINT 'first','second'
END
$$ LANGUAGE pltsql;
