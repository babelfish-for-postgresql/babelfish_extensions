-- function
CREATE FUNCTION babel_3166_func(@a numeric, @b varchar, @c varchar(max), @d varchar(8), @e binary(6))
RETURNS varbinary(8) AS BEGIN RETURN @e END;
go

-- Look at the probin for typmod information
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_3166_func';
go

SELECT babel_3166_func(1.2, 'abc', 'abcd', 'abcdefgh', 0x12bcfe);
go

-- procedure
CREATE PROCEDURE babel_3166_proc @a numeric, @b varchar, @c varchar(max), @d varchar(8), @e binary(6)
AS SELECT @e;
go

-- Look at the probin for typmod information
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_3166_proc';
go

EXEC babel_3166_proc 1.2, 'abc', 'abcd', 'abcdefgh', 0x12bcfe;
go