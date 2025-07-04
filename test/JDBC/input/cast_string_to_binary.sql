IF OBJECT_ID('string_to_varbinary_test', 'U') IS NOT NULL DROP TABLE string_to_varbinary_test;
go
 
CREATE TABLE string_to_varbinary_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    c CHAR(13),
    n NCHAR(13),
    v VARCHAR(13),
    nv NVARCHAR(13)
);
go
 
-- Insert diverse and edge case strings
INSERT INTO string_to_varbinary_test (c, n, v, nv) VALUES
('Hello, World!', N'Hello, World!', 'Hello, World!', N'Hello, World!'),
('abc', N'abc', 'abc', N'abc'),
('1234567890123', N'1234567890123', '1234567890123', N'1234567890123'),
('é', N'é', 'é', N'é'),
('', N'', '', N''),                  -- Empty
(' ', N' ', ' ', N' '),              -- Space
('😀', N'😀', '😀', N'😀'),         -- Emoji
('中文', N'中文', '中文', N'中文'),  -- Chinese characters
('ÿ', N'ÿ', 'ÿ', N'ÿ'),              -- Latin-1 extended
('A', N'A', 'A', N'A'),
('Z', N'Z', 'Z', N'Z'),
('a', N'a', 'a', N'a'),
('z', N'z', 'z', N'z'),
('...', N'...', '...', N'...'),
('DEADBEEF', N'DEADBEEF', 'DEADBEEF', N'DEADBEEF'),
('CAFEBABE', N'CAFEBABE', 'CAFEBABE', N'CAFEBABE'),
('𝄞', N'𝄞', '𝄞', N'𝄞'),             -- Musical symbol (surrogate pair)
(REPLICATE('A',13), REPLICATE(N'A',13), REPLICATE('A',13), REPLICATE(N'A',13)),
(REPLICATE(' ',13), REPLICATE(N' ',13), REPLICATE(' ',13), REPLICATE(N' ',13)),
('0123456789', N'0123456789', '0123456789', N'0123456789'),
('...', N'...', '...', N'...'),
('𝕬𝕭𝕮', N'𝕬𝕭𝕮', '𝕬𝕭𝕮', N'𝕬𝕭𝕮'), -- Gothic math bold
('foo\nbar', N'foo'+NCHAR(10)+'bar', 'foo\nbar', N'foo'+NCHAR(10)+'bar'), -- With newline
('tab'+CHAR(9)+'end', N'tab'+NCHAR(9)+'end', 'tab'+CHAR(9)+'end', N'tab'+NCHAR(9)+'end') -- With tab
-- (CHAR(0), NCHAR(0), CHAR(0), NCHAR(0)), -- Null character, COMMENTED OUT: Babelfish does not permit null chars
-- ('TEST\0', N'TEST'+NCHAR(0), 'TEST\0', N'TEST'+NCHAR(0)), -- Null in middle, COMMENTED OUT: Babelfish does not permit null chars
;
go
 
-- 1. SHOW: CAST to VARBINARY
------------------------------------- TEST 1
SELECT id, c, CAST(c AS VARBINARY(50)) AS cast_c_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 2
SELECT id, n, CAST(n AS VARBINARY(50)) AS cast_n_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 3
SELECT id, v, CAST(v AS VARBINARY(50)) AS cast_v_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 4
SELECT id, nv, CAST(nv AS VARBINARY(50)) AS cast_nv_to_varbinary FROM string_to_varbinary_test;
go
 
-- 2. SHOW: CONVERT to VARBINARY
------------------------------------- TEST 5
SELECT id, c, CONVERT(VARBINARY(50), c) AS conv_c_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 6
SELECT id, n, CONVERT(VARBINARY(50), n) AS conv_n_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 7
SELECT id, v, CONVERT(VARBINARY(50), v) AS conv_v_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 8
SELECT id, nv, CONVERT(VARBINARY(50), nv) AS conv_nv_to_varbinary FROM string_to_varbinary_test;
go
 
-- 3. SHOW: TRY_CAST to VARBINARY
------------------------------------- TEST 9
SELECT id, c, TRY_CAST(c AS VARBINARY(50)) AS try_cast_c_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 10
SELECT id, n, TRY_CAST(n AS VARBINARY(50)) AS try_cast_n_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 11
SELECT id, v, TRY_CAST(v AS VARBINARY(50)) AS try_cast_v_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 12
SELECT id, nv, TRY_CAST(nv AS VARBINARY(50)) AS try_cast_nv_to_varbinary FROM string_to_varbinary_test;
go
 
-- 4. SHOW: TRY_CONVERT to VARBINARY
------------------------------------- TEST 13
SELECT id, c, TRY_CONVERT(VARBINARY(50), c) AS try_conv_c_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 14
SELECT id, n, TRY_CONVERT(VARBINARY(50), n) AS try_conv_n_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 15
SELECT id, v, TRY_CONVERT(VARBINARY(50), v) AS try_conv_v_to_varbinary FROM string_to_varbinary_test;
go
------------------------------------- TEST 16
SELECT id, nv, TRY_CONVERT(VARBINARY(50), nv) AS try_conv_nv_to_varbinary FROM string_to_varbinary_test;
go
 
-- =======================================
-- BINARY CONVERSIONS
-- =======================================
 
-- 5. SHOW: CAST to BINARY
------------------------------------- TEST 17
SELECT id, c, CAST(c AS BINARY(16)) AS cast_c_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 18
SELECT id, n, CAST(n AS BINARY(32)) AS cast_n_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 19
SELECT id, v, CAST(v AS BINARY(16)) AS cast_v_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 20
SELECT id, nv, CAST(nv AS BINARY(32)) AS cast_nv_to_binary FROM string_to_varbinary_test;
go
 
-- 6. SHOW: CONVERT to BINARY
------------------------------------- TEST 21
SELECT id, c, CONVERT(BINARY(16), c) AS conv_c_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 22
SELECT id, n, CONVERT(BINARY(32), n) AS conv_n_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 23
SELECT id, v, CONVERT(BINARY(16), v) AS conv_v_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 24
SELECT id, nv, CONVERT(BINARY(32), nv) AS conv_nv_to_binary FROM string_to_varbinary_test;
go
 
-- 7. SHOW: TRY_CAST to BINARY 
------------------------------------- TEST 25
SELECT id, c, TRY_CAST(c AS BINARY(16)) AS try_cast_c_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 26
SELECT id, n, TRY_CAST(n AS BINARY(32)) AS try_cast_n_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 27
SELECT id, v, TRY_CAST(v AS BINARY(16)) AS try_cast_v_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 28
SELECT id, nv, TRY_CAST(nv AS BINARY(32)) AS try_cast_nv_to_binary FROM string_to_varbinary_test;
go
 
-- 8. SHOW: TRY_CONVERT to BINARY 
------------------------------------- TEST 29
SELECT id, c, TRY_CONVERT(BINARY(16), c) AS try_conv_c_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 30
SELECT id, n, TRY_CONVERT(BINARY(32), n) AS try_conv_n_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 31
SELECT id, v, TRY_CONVERT(BINARY(16), v) AS try_conv_v_to_binary FROM string_to_varbinary_test;
go
------------------------------------- TEST 32
SELECT id, nv, TRY_CONVERT(BINARY(32), nv) AS try_conv_nv_to_binary FROM string_to_varbinary_test;
go
 
-- CLEANUP
IF OBJECT_ID('string_to_varbinary_test', 'U') IS NOT NULL DROP TABLE string_to_varbinary_test;
go