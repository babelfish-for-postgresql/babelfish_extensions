-- UTF-8 TABLE
 
IF OBJECT_ID('varbinary_crash_test_utf8', 'U') IS NOT NULL DROP TABLE varbinary_crash_test_utf8;
go
 
CREATE TABLE varbinary_crash_test_utf8 (
    id INT IDENTITY(1,1) PRIMARY KEY,
    vb VARBINARY(50)
);
go
 
INSERT INTO varbinary_crash_test_utf8 (vb) VALUES
(0x48656C6C6F2C20576F726C6421), -- "Hello, World!" (ASCII/UTF-8)
(0x616263),                     -- "abc"
(0x7A62),                       -- "zb"
(0xE4B8ADE59BBD),               -- "中文" (UTF-8)
(0xDEADBEEF),                   -- Hex pattern
(0xF09F9880),                   -- 😀 emoji (UTF-8)
(0x20202020),                   -- Four spaces
(0x31323334),                   -- "1234"
(0x41424344),                   -- "ABCD"
(0xEFBFBD),                     -- Unicode replacement char (UTF-8)
(0x41),                         -- "A"
(0x42),                         -- "B"
(0x43),                         -- "C"
(0x5A),                         -- "Z"
(0x61),                         -- "a"
(0x62),                         -- "b"
(0x63),                         -- "c"
(0x2E2E2E),                     -- "..."
(0x7F7F7F),                     -- ASCII DEL characters
(0xCAFEBABE),                   -- Hex pattern
(0xBEEF),                       -- Hex pattern
(0xABCD),                       -- Hex pattern
(0x123456),                     -- Hex pattern
(0xABCDEF),                     -- Hex pattern
(0x303132),                     -- "012"
(0x313233),                     -- "123"
(0x343536),                     -- "456"
(0x373839),                     -- "789"
(0x414243),                     -- "ABC"
(0x61626364),                   -- "abcd"
(0x414243444546),               -- "ABCDEF"
(0x616263646566),               -- "abcdef"
(0x3132333435),                 -- "12345"
(0x010203040506),               -- Incrementing bytes, no forbidden bytes
(0xF7),                         -- Valid single byte > 0x7F (not forbidden)
(0xF0F0F0F0),                   -- Hex pattern
(CAST('' AS VARBINARY(50)))     -- Empty
;
go
 
-- UTF-16LE TABLE
 
IF OBJECT_ID('varbinary_crash_test_utf16le', 'U') IS NOT NULL DROP TABLE varbinary_crash_test_utf16le;
go
 
CREATE TABLE varbinary_crash_test_utf16le (
    id INT IDENTITY(1,1) PRIMARY KEY,
    vb VARBINARY(50)
);
go
 
INSERT INTO varbinary_crash_test_utf16le (vb) VALUES
(0x480065006C006C006F002C00200057006F0072006C00640021), -- "Hello, World!" (UTF-16LE)
(0x610062006300),                                       -- "abc" (UTF-16LE)
(0xE900),                                               -- "é" (U+00E9, UTF-16LE)
(0x7A006200),                                           -- "z""b" (UTF-16LE)
(0x2D4E8765),                                           -- "中文" (UTF-16LE)
(0x34D81EDD),                                           -- 𝄞 (musical symbol G clef, surrogate pair, UTF-16LE)
(0x2000200020002000),                                   -- Four spaces (UTF-16LE)
(0x3100320033003400),                                   -- "1234" (UTF-16LE)
(0x4100420043004400),                                   -- "ABCD" (UTF-16LE)
(0xFDFF),                                               -- Replacement character (U+FFFD, UTF-16LE)
(0x3DD800DE),                                           -- 😀 emoji (UTF-16LE, surrogate pair)
(0x4100),                                               -- "A" (UTF-16LE)
(0x4200),                                               -- "B" (UTF-16LE)
(0x4300),                                               -- "C" (UTF-16LE)
(0x5A00),                                               -- "Z" (UTF-16LE)
(0x6100),                                               -- "a" (UTF-16LE)
(0x6200),                                               -- "b" (UTF-16LE)
(0x6300),                                               -- "c" (UTF-16LE)
(0x2E002E002E00),                                       -- "..." (UTF-16LE)
(0x010203040506),                                       -- Incrementing bytes, no forbidden bytes
(0xF0F0F0F0),                                           -- Hex pattern
(CAST('' AS VARBINARY(50)))                             -- Empty
;
go
 
----------------------
-- CONVERSION TESTS --
----------------------
 
-- UTF-8 table to string types
 
-- VARCHAR
------------------------------------- TEST 1
SELECT id, vb, CAST(vb AS VARCHAR(13)) AS cast_varchar FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 2
SELECT id, vb, CONVERT(VARCHAR(13), vb) AS conv_varchar FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 3
SELECT id, vb, TRY_CAST(vb AS VARCHAR(13)) AS try_cast_varchar FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 4
SELECT id, vb, TRY_CONVERT(VARCHAR(13), vb) AS try_conv_varchar FROM varbinary_crash_test_utf8;
go
 
-- NVARCHAR
------------------------------------- TEST 5
SELECT id, vb, CAST(vb AS NVARCHAR(13)) AS cast_nvarchar FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 6
SELECT id, vb, CONVERT(NVARCHAR(13), vb) AS conv_nvarchar FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 7
SELECT id, vb, TRY_CAST(vb AS NVARCHAR(13)) AS try_cast_nvarchar FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 8
SELECT id, vb, TRY_CONVERT(NVARCHAR(13), vb) AS try_conv_nvarchar FROM varbinary_crash_test_utf8;
go
 
-- CHAR
------------------------------------- TEST 9
SELECT id, vb, CAST(vb AS CHAR(13)) AS cast_char FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 10
SELECT id, vb, CONVERT(CHAR(13), vb) AS conv_char FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 11
SELECT id, vb, TRY_CAST(vb AS CHAR(13)) AS try_cast_char FROM varbinary_crash_test_utf8; -- fails
go
------------------------------------- TEST 12
SELECT id, vb, TRY_CONVERT(CHAR(13), vb) AS try_conv_char FROM varbinary_crash_test_utf8;
go
 
-- NCHAR
------------------------------------- TEST 13
SELECT id, vb, CAST(vb AS NCHAR(13)) AS cast_nchar FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 14
SELECT id, vb, CONVERT(NCHAR(13), vb) AS conv_nchar FROM varbinary_crash_test_utf8;
go
------------------------------------- TEST 15
SELECT id, vb, TRY_CAST(vb AS NCHAR(13)) AS try_cast_nchar FROM varbinary_crash_test_utf8; --fails
go
------------------------------------- TEST 16
SELECT id, vb, TRY_CONVERT(NCHAR(13), vb) AS try_conv_nchar FROM varbinary_crash_test_utf8;
go
 
-- UTF-16LE table to string types
 
-- VARCHAR
------------------------------------- TEST 17
SELECT id, vb, CAST(vb AS VARCHAR(13)) AS cast_varchar FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 18
SELECT id, vb, CONVERT(VARCHAR(13), vb) AS conv_varchar FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 19
SELECT id, vb, TRY_CAST(vb AS VARCHAR(13)) AS try_cast_varchar FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 20
SELECT id, vb, TRY_CONVERT(VARCHAR(13), vb) AS try_conv_varchar FROM varbinary_crash_test_utf16le;
go
 
-- NVARCHAR
------------------------------------- TEST 21
SELECT id, vb, CAST(vb AS NVARCHAR(13)) AS cast_nvarchar FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 22
SELECT id, vb, CONVERT(NVARCHAR(13), vb) AS conv_nvarchar FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 23
SELECT id, vb, TRY_CAST(vb AS NVARCHAR(13)) AS try_cast_nvarchar FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 24
SELECT id, vb, TRY_CONVERT(NVARCHAR(13), vb) AS try_conv_nvarchar FROM varbinary_crash_test_utf16le;
go
 
-- CHAR
------------------------------------- TEST 25
SELECT id, vb, CAST(vb AS CHAR(13)) AS cast_char FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 26
SELECT id, vb, CONVERT(CHAR(13), vb) AS conv_char FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 27
SELECT id, vb, TRY_CAST(vb AS CHAR(13)) AS try_cast_char FROM varbinary_crash_test_utf16le; --fails
go
------------------------------------- TEST 28
SELECT id, vb, TRY_CONVERT(CHAR(13), vb) AS try_conv_char FROM varbinary_crash_test_utf16le;
go
 
-- NCHAR
------------------------------------- TEST 29
SELECT id, vb, CAST(vb AS NCHAR(13)) AS cast_nchar FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 30
SELECT id, vb, CONVERT(NCHAR(13), vb) AS conv_nchar FROM varbinary_crash_test_utf16le;
go
------------------------------------- TEST 31
SELECT id, vb, TRY_CAST(vb AS NCHAR(13)) AS try_cast_nchar FROM varbinary_crash_test_utf16le; --fails
go
------------------------------------- TEST 32
SELECT id, vb, TRY_CONVERT(NCHAR(13), vb) AS try_conv_nchar FROM varbinary_crash_test_utf16le;
go


------------------------------------- TEST 33
-- Test the problematic case that was causing errors
-- What happens during conversion
SELECT CAST(0xE4B8ADE59BBD AS CHAR(6)) AS result;
SELECT LENGTH(CAST(0xE4B8ADE59BBD AS CHAR(6))) AS character_count;
SELECT DATALENGTH(CAST(0xE4B8ADE59BBD AS CHAR(6))) AS byte_count;
GO

-- Show how this differs from VARCHAR
SELECT CAST(0xE4B8ADE59BBD AS VARCHAR(6)) AS varchar_result;
SELECT LENGTH(CAST(0xE4B8ADE59BBD AS VARCHAR(6))) AS varchar_char_count;
SELECT DATALENGTH(CAST(0xE4B8ADE59BBD AS VARCHAR(6))) AS varchar_byte_count;
GO


-- Edge Case 2: Single byte characters (no expansion)
SELECT CAST(0x616263 AS CHAR(5)) AS ascii_result;  -- "abc" -> "abc  "
SELECT LENGTH(CAST(0x616263 AS CHAR(5))) AS ascii_length;
GO


-- Edge Case 4: Empty input
SELECT CAST(0x AS CHAR(3)) AS empty_result;
SELECT LENGTH(CAST(0x AS CHAR(3))) AS empty_length;
SELECT '"|' || CAST(0x AS CHAR(3)) || '|"' AS empty_visualized;
GO

-- Performance test with large inputs
-- Create a binary string with many characters
DECLARE @large_binary VARBINARY(MAX);
SET @large_binary = 0xE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBD; -- 20 Chinese chars
SELECT CAST(@large_binary AS CHAR(10)) AS large_truncated_result;
SELECT LENGTH(CAST(@large_binary AS CHAR(10))) AS large_truncated_length;
GO

-- CLEANUP
IF OBJECT_ID('varbinary_crash_test_utf8', 'U') IS NOT NULL DROP TABLE varbinary_crash_test_utf8;
go
IF OBJECT_ID('varbinary_crash_test_utf16le', 'U') IS NOT NULL DROP TABLE varbinary_crash_test_utf16le;
go
