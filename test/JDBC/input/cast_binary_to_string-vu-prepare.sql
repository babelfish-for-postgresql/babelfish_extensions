CREATE SCHEMA test_bin_str_conversion;
GO

-- UTF-8 TABLE
CREATE TABLE test_bin_str_conversion.varbinary_crash_test_utf8 (
    id INT IDENTITY(1,1) PRIMARY KEY,
    b BINARY(20),
    vb VARBINARY(20)
);
go

INSERT INTO test_bin_str_conversion.varbinary_crash_test_utf8 (b, vb) VALUES
(0x48656C6C6F2C20576F726C6421, 0x48656C6C6F2C20576F726C6421), -- "Hello, World!" (ASCII/UTF-8)
(0x616263, 0x616263),                     -- "abc"
(0x7A62, 0x7A62),                         -- "zb"
(0xE4B8ADE59BBD, 0xE4B8ADE59BBD),         -- "中文" (UTF-8)
(0xDEADBEEF, 0xDEADBEEF),                 -- Hex pattern
(0xF09F9880, 0xF09F9880),                 -- 😀 emoji (UTF-8)
(0x20202020, 0x20202020),                 -- Four spaces
(0x31323334, 0x31323334),                 -- "1234"
(0x41424344, 0x41424344),                 -- "ABCD"
(0xEFBFBD, 0xEFBFBD),                     -- Unicode replacement char (UTF-8)
(0x41, 0x41),                             -- "A"
(0x42, 0x42),                             -- "B"
(0x43, 0x43),                             -- "C"
(0x5A, 0x5A),                             -- "Z"
(0x61, 0x61),                             -- "a"
(0x62, 0x62),                             -- "b"
(0x63, 0x63),                             -- "c"
(0x2E2E2E, 0x2E2E2E),                     -- "..."
(0x7F7F7F, 0x7F7F7F),                     -- ASCII DEL characters
(0xCAFEBABE, 0xCAFEBABE),                 -- Hex pattern
(0xBEEF, 0xBEEF),                         -- Hex pattern
(0xABCD, 0xABCD),                         -- Hex pattern
(0x123456, 0x123456),                     -- Hex pattern
(0xABCDEF, 0xABCDEF),                     -- Hex pattern
(0x303132, 0x303132),                     -- "012"
(0x313233, 0x313233),                     -- "123"
(0x343536, 0x343536),                     -- "456"
(0x373839, 0x373839),                     -- "789"
(0x414243, 0x414243),                     -- "ABC"
(0x61626364, 0x61626364),                 -- "abcd"
(0x414243444546, 0x414243444546),         -- "ABCDEF"
(0x616263646566, 0x616263646566),         -- "abcdef"
(0x3132333435, 0x3132333435),             -- "12345"
(0x010203040506, 0x010203040506),         -- Incrementing bytes
(0xF7, 0xF7),                             -- Valid single byte > 0x7F
(0xF0F0F0F0, 0xF0F0F0F0),                 -- Hex pattern
(CAST('' AS VARBINARY(20)), CAST('' AS VARBINARY(20))) -- Empty
;
go

-- UTF-16LE TABLE
CREATE TABLE test_bin_str_conversion.varbinary_crash_test_utf16le (
    id INT IDENTITY(1,1) PRIMARY KEY,
    b BINARY(50),
    vb VARBINARY(50)
);
go

INSERT INTO test_bin_str_conversion.varbinary_crash_test_utf16le (b, vb) VALUES
(0x480065006C006C006F002C00200057006F0072006C00640021, 0x480065006C006C006F002C00200057006F0072006C00640021), -- "Hello, World!" (UTF-16LE)
(0x610062006300, 0x610062006300),                                       -- "abc" (UTF-16LE)
(0xE900, 0xE900),                                                       -- "é" (U+00E9, UTF-16LE)
(0x7A006200, 0x7A006200),                                               -- "zb" (UTF-16LE)
(0x2D4E8765, 0x2D4E8765),                                               -- "中文" (UTF-16LE)
(0x34D81EDD, 0x34D81EDD),                                               -- 𝄞 (G clef, surrogate pair)
(0x2000200020002000, 0x2000200020002000),                               -- Four spaces
(0x3100320033003400, 0x3100320033003400),                               -- "1234"
(0x4100420043004400, 0x4100420043004400),                               -- "ABCD"
(0xFDFF, 0xFDFF),                                                       -- Replacement char (U+FFFD)
(0x3DD800DE, 0x3DD800DE),                                               -- 😀 emoji (UTF-16LE surrogate pair)
(0x4100, 0x4100),                                                       -- "A"
(0x4200, 0x4200),                                                       -- "B"
(0x4300, 0x4300),                                                       -- "C"
(0x5A00, 0x5A00),                                                       -- "Z"
(0x6100, 0x6100),                                                       -- "a"
(0x6200, 0x6200),                                                       -- "b"
(0x6300, 0x6300),                                                       -- "c"
(0x2E002E002E00, 0x2E002E002E00),                                       -- "..."
(0x010203040506, 0x010203040506),                                       -- Incrementing bytes
(0xF0F0F0F0, 0xF0F0F0F0),                                               -- Hex pattern
(CAST('' AS VARBINARY(50)), CAST('' AS VARBINARY(50)))                  -- Empty
;
go

----------------------
-- CONVERSION TESTS --
----------------------

-- CAST
CREATE VIEW test_bin_str_conversion.v_utf8_cast
AS
	SELECT id,
		vb,
        CAST(b AS CHAR(13)) AS b_char13,
		CAST(b AS VARCHAR(13)) AS b_varchar13,
		CAST(vb AS CHAR(13)) AS vb_char13,
		CAST(vb AS VARCHAR(13)) AS vb_varchar13
	FROM test_bin_str_conversion.varbinary_crash_test_utf8;
GO

CREATE PROCEDURE test_bin_str_conversion.p_utf16_cast
AS
BEGIN
	SELECT id,
		vb,
        CAST(b AS NCHAR(13)) AS b_nchar13,
		CAST(b AS NVARCHAR(13)) AS b_nvarchar13,
		CAST(vb AS NCHAR(13)) AS vb_nchar13,
		CAST(vb AS NVARCHAR(13)) AS vb_nvarchar13
	FROM test_bin_str_conversion.varbinary_crash_test_utf16le;
END
GO

-- TRY_CAST
CREATE VIEW test_bin_str_conversion.v_utf8_try_cast
AS
	SELECT id,
		vb,
		TRY_CAST(b AS CHAR(13)) AS b_char13,
		TRY_CAST(b AS VARCHAR(13)) AS b_varchar13,
        TRY_CAST(vb AS CHAR(13)) AS vb_char13,
		TRY_CAST(vb AS VARCHAR(13)) AS vb_varchar13
	FROM test_bin_str_conversion.varbinary_crash_test_utf8;
GO

CREATE PROCEDURE test_bin_str_conversion.p_utf16_try_cast
AS
BEGIN
	SELECT id,
		vb,
        TRY_CAST(b AS NCHAR(13)) AS b_nchar13,
		TRY_CAST(b AS NVARCHAR(13)) AS b_nvarchar13,
		TRY_CAST(vb AS NCHAR(13)) AS vb_nchar13,
		TRY_CAST(vb AS NVARCHAR(13)) AS vb_nvarchar13
	FROM test_bin_str_conversion.varbinary_crash_test_utf16le;
END
GO

-- CONVERT
CREATE VIEW test_bin_str_conversion.v_utf8_convert
AS
SELECT
    id,
    vb,
    CONVERT(CHAR(13), b)     AS b_char13,
    CONVERT(VARCHAR(13), b)  AS b_varchar13,
    CONVERT(CHAR(13), vb)     AS vb_char13,
    CONVERT(VARCHAR(13), vb)  AS vb_varchar13
FROM test_bin_str_conversion.varbinary_crash_test_utf8;
GO

CREATE PROCEDURE test_bin_str_conversion.p_utf16_convert
AS
BEGIN
    SELECT
        id,
        vb,
        CONVERT(NCHAR(13), b)    AS b_nchar13,
        CONVERT(NVARCHAR(13), b) AS b_nvarchar13,
        CONVERT(NCHAR(13), vb)    AS vb_nchar13,
        CONVERT(NVARCHAR(13), vb) AS vb_nvarchar13
    FROM test_bin_str_conversion.varbinary_crash_test_utf16le;
END
GO

-- TRY_CONVERT
CREATE VIEW test_bin_str_conversion.v_utf8_try_convert
AS
SELECT
    id,
    vb,
    TRY_CONVERT(CHAR(13), b)     AS b_char13,
    TRY_CONVERT(VARCHAR(13), b)  AS b_varchar13,
    TRY_CONVERT(CHAR(13), vb)     AS vb_char13,
    TRY_CONVERT(VARCHAR(13), vb)  AS vb_varchar13
FROM test_bin_str_conversion.varbinary_crash_test_utf8;
GO

CREATE PROCEDURE test_bin_str_conversion.p_utf16_try_convert
AS
BEGIN
    SELECT
        id,
        vb,
        TRY_CONVERT(NCHAR(13), b)    AS b_nchar13,
        TRY_CONVERT(NVARCHAR(13), b) AS b_nvarchar13,
        TRY_CONVERT(NCHAR(13), vb)    AS vb_nchar13,
        TRY_CONVERT(NVARCHAR(13), vb) AS vb_nvarchar13
    FROM test_bin_str_conversion.varbinary_crash_test_utf16le;
END
GO

CREATE FUNCTION test_bin_str_conversion.f_case_char6()
RETURNS @Result TABLE
(
    result          CHAR(6)      NULL,
    character_count INT          NULL,
    byte_count      INT          NULL
)
AS
BEGIN
	DECLARE @vb VARBINARY(6) = 0xE4B8ADE59BBD;

	INSERT INTO @Result(result, character_count, byte_count)
    SELECT
        CAST(@vb AS CHAR(6)),
        LEN(CAST(@vb AS CHAR(6))),
        DATALENGTH(CAST(@vb AS CHAR(6)));
	RETURN;
END
GO

CREATE FUNCTION test_bin_str_conversion.f_case_varchar6()
RETURNS @Result TABLE
(
    result          VARCHAR(6)      NULL,
    character_count INT          NULL,
    byte_count      INT          NULL
)
AS
BEGIN
	DECLARE @vb VARBINARY(6) = 0xE4B8ADE59BBD;

	INSERT INTO @Result(result, character_count, byte_count)
    SELECT
        CAST(@vb AS VARCHAR(6)),
        LEN(CAST(@vb AS VARCHAR(6))),
        DATALENGTH(CAST(@vb AS VARCHAR(6)));
	RETURN;
END
GO

IF OBJECT_ID('test_bin_str_conversion.f_edge_truncation_char2', 'TF') IS NOT NULL
    DROP FUNCTION test_bin_str_conversion.f_edge_truncation_char2;
GO

CREATE FUNCTION test_bin_str_conversion.f_edge_truncation_char2()
RETURNS @Result TABLE
(
    result          CHAR(2) NULL,
    character_count INT     NULL
)
AS
BEGIN
    DECLARE @vb VARBINARY(12) = 0xE4B8ADE59BBDE4B8ADE59BBD;

    INSERT INTO @Result(result, character_count)
    SELECT
        CAST(@vb AS CHAR(2)),
        LEN(CAST(@vb AS CHAR(2)));

    RETURN;
END;
GO

IF OBJECT_ID('test_bin_str_conversion.f_edge_ascii_char5', 'TF') IS NOT NULL
    DROP FUNCTION test_bin_str_conversion.f_edge_ascii_char5;
GO

CREATE FUNCTION test_bin_str_conversion.f_edge_ascii_char5()
RETURNS @Result TABLE
(
    result          CHAR(5) NULL,
    character_count INT     NULL
)
AS
BEGIN
    DECLARE @vb VARBINARY(5) = 0x616263;

    INSERT INTO @Result(result, character_count)
    SELECT
        CAST(@vb AS CHAR(5)),
        LEN(CAST(@vb AS CHAR(5)));

    RETURN;
END;
GO

CREATE FUNCTION test_bin_str_conversion.f_edge_mixed_char5()
RETURNS @Result TABLE
(
    result          CHAR(5) NULL,
    character_count INT     NULL
)
AS
BEGIN
    DECLARE @vb VARBINARY(6) = 0x61E4B8AD62;  -- "a中b"

    INSERT INTO @Result(result, character_count)
    SELECT
        CAST(@vb AS CHAR(5)),
        LEN(CAST(@vb AS CHAR(5)));

    RETURN;
END;
GO

CREATE FUNCTION test_bin_str_conversion.f_edge_empty_char3()
RETURNS @Result TABLE
(
    result           CHAR(3) NULL,
    character_count  INT     NULL,
    visualized_value NVARCHAR(20) NULL
)
AS
BEGIN
    DECLARE @vb VARBINARY(1) = 0x; -- empty binary literal

    INSERT INTO @Result(result, character_count, visualized_value)
    SELECT
        CAST(@vb AS CHAR(3)),
        LEN(CAST(@vb AS CHAR(3))),
        '"' + '|' + CAST(@vb AS CHAR(3)) + '|"' ;

    RETURN;
END;
GO

CREATE FUNCTION test_bin_str_conversion.f_perf_large_char10()
RETURNS @Result TABLE
(
    result          CHAR(10) NULL,
    character_count INT      NULL
)
AS
BEGIN
    DECLARE @vb VARBINARY(MAX) =
        0xE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBDE4B8ADE59BBD;

    INSERT INTO @Result(result, character_count)
    SELECT
        CAST(@vb AS CHAR(10)),
        LEN(CAST(@vb AS CHAR(10)));

    RETURN;
END;
GO
