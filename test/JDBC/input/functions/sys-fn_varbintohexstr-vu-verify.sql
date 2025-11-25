SELECT sys.fn_varbintohexstr(NULL);
GO

SELECT sys.fn_varbintohexstr(CAST('' AS varbinary));
GO

SELECT sys.fn_varbintohexstr(CAST(0x AS varbinary));
GO

SELECT sys.fn_varbintohexstr(0x00);
GO

SELECT sys.fn_varbintohexstr(0xFF);
GO

SELECT sys.fn_varbintohexstr(0x0000000000);
GO

SELECT sys.fn_varbintohexstr(0xFFFFFFFFFF);
GO

SELECT sys.fn_varbintohexstr(0xAbCdEf);
GO

SELECT sys.fn_varbintohexstr(CAST(0x42 AS binary(1)));
GO

SELECT sys.fn_varbintohexstr(CAST(0x42 AS varbinary(1)));
GO

SELECT sys.fn_varbintohexstr(0x0123456789ABCDEF);
GO

SELECT sys.fn_varbintohexstr(CAST(0x123456 AS binary(10)));
GO

SELECT sys.fn_varbintohexstr(CAST(0x123456 AS varbinary(10)));
GO

SELECT sys.fn_varbintohexstr(CAST('Hello' AS varbinary));
GO

SELECT sys.fn_varbintohexstr(CAST(N'A' AS varbinary));
GO

SELECT sys.fn_varbintohexstr(0x000102);
GO

SELECT sys.fn_varbintohexstr(0x010200);
GO

SELECT sys.fn_varbintohexstr(CAST(0x48656c6c6faefaef as binary(16)));
GO

SELECT sys.fn_varbintohexstr(CAST(0x01 AS varbinary(max)));
GO

SELECT sys.fn_varbintohexstr(0xDEADBEEF);
GO

SELECT sys.fn_varbintohexstr(CAST(0xAB AS binary(5)));
GO

-- Test UDT
DECLARE @udt_var babel_6216_udt;
SET @udt_var = 0x48656c6c6f;
SELECT sys.fn_varbintohexstr(@udt_var);
GO

-- Test VIEW
SELECT * FROM fn_varbintohexstr_vu_prepare_view;
GO

-- Test PROCEDURE
EXEC fn_varbintohexstr_vu_prepare_proc;
GO

-- Test FUNCTION
SELECT dbo.fn_varbintohexstr_vu_prepare_func();
GO

-- Test TABLE with fn_varbintohexstr on each column
SELECT sys.fn_varbintohexstr(col1) FROM BABEL_6216_t1;
GO

-- FIX ME: need to have implicit cast to varbinary
SELECT sys.fn_varbintohexstr(col2) FROM BABEL_6216_t1;
GO

SELECT sys.fn_varbintohexstr(col3) FROM BABEL_6216_t1;
GO

SELECT sys.fn_varbintohexstr(col4) FROM BABEL_6216_t1;
GO

SELECT sys.fn_varbintohexstr(col5) FROM BABEL_6216_t1;
GO

SELECT sys.fn_varbintohexstr(col6) FROM BABEL_6216_t1;
GO

SELECT sys.fn_varbintohexstr(col7) FROM BABEL_6216_t1;
GO

SELECT sys.fn_varbintohexstr(col8) FROM BABEL_6216_t1;
GO
