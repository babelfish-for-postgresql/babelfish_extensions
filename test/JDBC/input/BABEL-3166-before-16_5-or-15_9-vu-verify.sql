-- Look at function's probin for typmod information
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_3166_func';
go

SELECT babel_3166_func(1.2, 'abc', 'abcd', 'abcdefgh', 0x12bcfe);
go

DROP FUNCTION babel_3166_func;

-- Look at procedures's probin for typmod information
SELECT proname, probin FROM pg_proc WHERE proname = 'babel_3166_proc';
go

EXEC babel_3166_proc 1.2, 'abc', 'abcd', 'abcdefgh', 0x12bcfe;
go

DROP PROCEDURE babel_3166_proc;
go
