-- Test view v1 (style 0)
SELECT * FROM BABEL_BINARY_vu_prepare_v1
GO
DROP VIEW BABEL_BINARY_vu_prepare_v1
GO

-- Test procedure p1 (style 0)
EXEC BABEL_BINARY_vu_prepare_p1
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p1
GO

-- Test function f1 (style 0)
SELECT dbo.BABEL_BINARY_vu_prepare_f1()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f1
GO

-- Test view v2 (style 1)
SELECT * FROM BABEL_BINARY_vu_prepare_v2
GO
DROP VIEW BABEL_BINARY_vu_prepare_v2
GO

-- Test procedure p2 (style 1)
EXEC BABEL_BINARY_vu_prepare_p2
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p2
GO

-- Test function f2 (style 1)
SELECT dbo.BABEL_BINARY_vu_prepare_f2()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f2
GO

-- Test view v3 (style 2)
SELECT * FROM BABEL_BINARY_vu_prepare_v3
GO
DROP VIEW BABEL_BINARY_vu_prepare_v3
GO

-- Test procedure p3 (style 2)
EXEC BABEL_BINARY_vu_prepare_p3
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p3
GO

-- Test function f3 (style 2)
SELECT dbo.BABEL_BINARY_vu_prepare_f3()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f3
GO

-- Test view v4 (VARBINARY)
SELECT * FROM BABEL_BINARY_vu_prepare_v4
GO
DROP VIEW BABEL_BINARY_vu_prepare_v4
GO

-- Test procedure p4 (VARBINARY)
EXEC BABEL_BINARY_vu_prepare_p4
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p4
GO

-- Test function f4 (VARBINARY)
SELECT dbo.BABEL_BINARY_vu_prepare_f4()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f4
GO

-- Test procedure p5 (invalid style - should cause an error)
EXEC BABEL_BINARY_vu_prepare_p5
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p5
GO

-- Test function f5 (NULL input)
SELECT dbo.BABEL_BINARY_vu_prepare_f5()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f5
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v5
GO
DROP VIEW BABEL_BINARY_vu_prepare_v5
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v6
GO
DROP VIEW BABEL_BINARY_vu_prepare_v6
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v7
GO
DROP VIEW BABEL_BINARY_vu_prepare_v7
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v8_try
GO
DROP VIEW BABEL_BINARY_vu_prepare_v8_try
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v9_try
GO
DROP VIEW BABEL_BINARY_vu_prepare_v9_try
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v10_try
GO
DROP VIEW BABEL_BINARY_vu_prepare_v10_try
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v11
GO
DROP VIEW BABEL_BINARY_vu_prepare_v11
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v12
GO
DROP VIEW BABEL_BINARY_vu_prepare_v12
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v13
GO
DROP VIEW BABEL_BINARY_vu_prepare_v13
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v14_try
GO
DROP VIEW BABEL_BINARY_vu_prepare_v14_try
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v15_try
GO
DROP VIEW BABEL_BINARY_vu_prepare_v15_try
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v16_try
GO
DROP VIEW BABEL_BINARY_vu_prepare_v16_try
GO

EXEC BABEL_BINARY_vu_prepare_p6
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p6
GO

EXEC BABEL_BINARY_vu_prepare_p7
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p7
GO

EXEC BABEL_BINARY_vu_prepare_p8
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p8
GO

EXEC BABEL_BINARY_vu_prepare_p9
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p9
GO

EXEC BABEL_BINARY_vu_prepare_p10
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p10
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v17
GO
DROP VIEW BABEL_BINARY_vu_prepare_v17
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v18
GO
DROP VIEW BABEL_BINARY_vu_prepare_v18
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v19
GO
DROP VIEW BABEL_BINARY_vu_prepare_v19
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v20
GO
DROP VIEW BABEL_BINARY_vu_prepare_v20
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v21
GO
DROP VIEW BABEL_BINARY_vu_prepare_v21
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v22
GO
DROP VIEW BABEL_BINARY_vu_prepare_v22
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v23
GO
DROP VIEW BABEL_BINARY_vu_prepare_v23
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v24
GO
DROP VIEW BABEL_BINARY_vu_prepare_v24
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v26
GO
DROP VIEW BABEL_BINARY_vu_prepare_v26
GO

EXEC BABEL_BINARY_vu_prepare_p11
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p11
GO

SELECT dbo.BABEL_BINARY_vu_prepare_f7()
DROP FUNCTION BABEL_BINARY_vu_prepare_f7
GO

SELECT dbo.BABEL_BINARY_vu_prepare_f8()
DROP FUNCTION BABEL_BINARY_vu_prepare_f8
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v27
GO
DROP VIEW BABEL_BINARY_vu_prepare_v27
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v28
GO
DROP VIEW BABEL_BINARY_vu_prepare_v28
GO

SELECT dbo.BABEL_BINARY_vu_prepare_f9()
DROP FUNCTION BABEL_BINARY_vu_prepare_f9
GO

SELECT dbo.BABEL_BINARY_vu_prepare_f10()
DROP FUNCTION BABEL_BINARY_vu_prepare_f10
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v29
GO
DROP VIEW BABEL_BINARY_vu_prepare_v29
GO

SELECT * FROM BABEL_BINARY_vu_prepare_v30
GO
DROP VIEW BABEL_BINARY_vu_prepare_v30
GO

SELECT * FROM BABEL_BINARY_test_table_compcol
GO
DROP TABLE BABEL_BINARY_test_table_compcol
GO

SELECT * FROM BABEL_BINARY_test_table_compcol1
GO
DROP TABLE BABEL_BINARY_test_table_compcol1
GO

SELECT * FROM BABEL_BINARY_test_table_compcol2
GO
DROP TABLE BABEL_BINARY_test_table_compcol2
GO

SELECT * FROM BABEL_BINARY_test_table_compcol3
GO
DROP TABLE BABEL_BINARY_test_table_compcol3
GO

-- Additional test cases
-- 1. Testing style 0 (default, ASCII conversion):

-- even length string
SELECT CONVERT(BINARY(5), '0904D00034', 0)
Go

-- odd length string
SELECT CONVERT(BINARY(10), '0904D000341', 0)
Go

-- default style selected as 0
SELECT CONVERT(BINARY(5), '0904D00034')
Go

-- string with prefix '0x' and even length
SELECT CONVERT(BINARY(10), '0x0904D00034', 0)
Go

-- string with prefix '0x' and odd length
SELECT CONVERT(BINARY(10), '0x0904D000341', 0)
Go

SELECT CONVERT(BINARY(5), 'Hello', 0)
Go

-- padding
SELECT CONVERT(BINARY(20), 'Hello', 0)
Go

-- string with blank spaces
SELECT CONVERT(BINARY(10), 'Hello World', 0)
Go

-- special characters 
SELECT CONVERT(BINARY(15), '0904D000341!@', 0)
Go

-- empty string
SELECT CONVERT(BINARY(5), '', 0)
Go


-- 2. Testing style 1 (hexadecimal conversion with '0x' prefix):


-- even length string
SELECT CONVERT(BINARY(5), '0x0904D00034', 1);
Go

-- odd length string (should cause an error)
SELECT CONVERT(BINARY(10), '0x0904D000341', 1)
Go

-- string without '0x' prefix (should cause an error)
SELECT CONVERT(BINARY(10), '0904D00034', 1)
Go

-- string with '0x' prefix and odd length (should cause an error)
SELECT CONVERT(BINARY(10), '0x0904D000341', 1)
Go

-- non-hexadecimal string (should cause an error)
SELECT CONVERT(BINARY(5), 'Hello', 1)
Go

-- hexadecimal with padding
SELECT CONVERT(BINARY(20), '0x48656C6C6F', 1)
Go

-- special characters in hexadecimal (should cause an error)
SELECT CONVERT(BINARY(15), '0x0904D000341213440', 1)
Go

-- non-hexadecimal characters after '0x' (should cause an error)
SELECT CONVERT(BINARY(16), '0x0904D000341!@', 1)
Go

-- odd number of hexadecimal digits (should cause an error)
SELECT CONVERT(BINARY(5), '0x0904D0003', 1)
Go

-- empty string (should cause an error)
SELECT CONVERT(BINARY(5), '', 1)
Go


-- 3. Testing style 2 (hexadecimal conversion without '0x' prefix):


-- even length string
SELECT CONVERT(BINARY(5), '0904D00034', 2)
Go

-- odd length string (should cause an error)
SELECT CONVERT(BINARY(10), '0904D000341', 2)
Go

-- string with '0x' prefix (should cause an error)
SELECT CONVERT(BINARY(10), '0x0904D00034', 2)
Go

-- hexadecimal with padding
SELECT CONVERT(BINARY(20), '48656C6C6F', 2)
Go

-- non-hexadecimal characters (should cause an error)
SELECT CONVERT(BINARY(16), '0904D000341!@', 2)
Go

-- empty string
SELECT CONVERT(BINARY(5), '', 2)
Go

-- maximum length input (8000 bytes = 16000 hex digits)
SELECT CONVERT(BINARY(8000), REPLICATE('0', 16000), 2)
Go


-- Testing null styles and empty strings

-- Style 0 (default, ASCII conversion)

-- Null input
SELECT CONVERT(BINARY(5), NULL, 0)
Go

-- Empty string
SELECT CONVERT(BINARY(5), '', 0)
Go

-- Null style
SELECT CONVERT(BINARY(5), '0904D00034', NULL)
Go

-- Empty string with null style
SELECT CONVERT(BINARY(5), '', NULL)
Go

-- Style 1 (hexadecimal conversion with '0x' prefix)

-- Null input
SELECT CONVERT(BINARY(5), NULL, 1)
Go

-- Empty string (should cause an error)
SELECT CONVERT(BINARY(5), '', 1)
Go

-- Null style with '0x' prefix 
SELECT CONVERT(BINARY(5), '0x0904D00034', NULL)
Go

-- Style 2 (hexadecimal conversion without '0x' prefix)

-- Null input
SELECT CONVERT(BINARY(5), NULL, 2)
Go

-- Empty string
SELECT CONVERT(BINARY(5), '', 2)
Go

-- Additional edge cases

-- Null input with null style
SELECT CONVERT(BINARY(5), NULL, NULL)
Go

-- Empty string with large BINARY size
SELECT CONVERT(BINARY(8000), '', 0)
Go

-- Null input with large BINARY size
SELECT CONVERT(BINARY(8000), NULL, 0)
Go

-- Space-only string
SELECT CONVERT(BINARY(5), '     ', 0)
Go

SELECT CONVERT(BINARY(5), '     ', 1)
Go

SELECT CONVERT(BINARY(5), '     ', 2)
Go

-- Invalid style
SELECT CONVERT(BINARY(10), '0904D00034', 3);
Go

-- Length greater than maximum allowed length (8000)
SELECT CONVERT(BINARY(8001), '0904D00034', 2)
Go

-- Minimum length (1 byte) for BINARY
SELECT CONVERT(BINARY(1), 'A', 0);
Go

-- Minimum length (1 byte) for VARBINARY
SELECT CONVERT(VARBINARY(1), 'A', 0);
Go

-- Negative length for BINARY
SELECT CONVERT(BINARY(-5), '0904D00034', 0);
Go

-- Zero length for BINARY
SELECT CONVERT(BINARY(0), '0904D00034', 0);
Go

-- Varbinary

-- 1. Testing style 0 (default, ASCII conversion):

-- even length string
SELECT CONVERT(VARBINARY(10), '0904D00034', 0);
Go

-- odd length string
SELECT CONVERT(VARBINARY(10), '0904D000341', 0);
Go

-- default style (should be equivalent to style 0)
SELECT CONVERT(VARBINARY(10), '0904D00034');
Go

-- string with prefix '0x' and even length
SELECT CONVERT(VARBINARY(10), '0x0904D00034', 0);
Go

-- string with blank spaces
SELECT CONVERT(VARBINARY(15), 'Hello World', 0);
Go

-- special characters 
SELECT CONVERT(VARBINARY(15), '0904D000341!@', 0);
Go

-- empty string
SELECT CONVERT(VARBINARY(5), '', 0);
Go

-- 2. Testing style 1 (hexadecimal conversion with '0x' prefix):

-- even length string
SELECT CONVERT(VARBINARY(10), '0x0904D00034', 1);
Go

-- odd length string (should cause an error)
SELECT CONVERT(VARBINARY(10), '0x0904D000341', 1);
Go

-- string without '0x' prefix (should cause an error)
SELECT CONVERT(VARBINARY(10), '0904D00034', 1);
Go

-- non-hexadecimal string (should cause an error)
SELECT CONVERT(VARBINARY(10), '0xHello', 1);
Go

-- 3. Testing style 2 (hexadecimal conversion without '0x' prefix):

-- even length string
SELECT CONVERT(VARBINARY(10), '0904D00034', 2);
Go

-- odd length string (should cause an error)
SELECT CONVERT(VARBINARY(10), '0904D000341', 2);
Go

-- string with '0x' prefix (should cause an error)
SELECT CONVERT(VARBINARY(10), '0x0904D00034', 2);
Go

-- non-hexadecimal characters (should cause an error)
SELECT CONVERT(VARBINARY(16), '0904D000341!@', 2);
Go

-- empty string
SELECT CONVERT(VARBINARY(5), '', 2);
Go

-- 4. Testing with larger sizes and edge cases:

-- maximum length input (8000 bytes = 16000 hex digits)
SELECT CONVERT(VARBINARY(8000), REPLICATE('0', 16000), 2);
Go

-- NULL input
SELECT CONVERT(VARBINARY(10), NULL, 0);
Go

SELECT CONVERT(VARBINARY(10), NULL, 1);
Go

SELECT CONVERT(VARBINARY(10), NULL, 2);
Go

-- NULL style
SELECT CONVERT(VARBINARY(10), '0904D00034', NULL);
Go

-- Invalid style
SELECT CONVERT(VARBINARY(10), '0904D00034', 3);
Go

-- Length greater than maximum allowed length (8000)
SELECT CONVERT(VARBINARY(8001), '0904D00034', 2)
Go
