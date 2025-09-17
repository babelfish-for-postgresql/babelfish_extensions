-- Table for testing binary, varbinary, char, varchar combinations
CREATE TABLE ascii_function_binary_test (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    BinaryCol BINARY(10),
    BinaryASCII INT,
    VarbinaryCol VARBINARY(50),
    VarbinaryASCII INT,
    CharCol CHAR(10),
    CharASCII INT,
    VarcharCol VARCHAR(50),
    VarcharASCII INT,
    Description VARCHAR(100),
    TestResult VARCHAR(10)
);
-- Insert test data 
INSERT INTO ascii_function_binary_test 
(BinaryCol, VarbinaryCol, CharCol, VarcharCol, Description) VALUES
(0x41, 0x41, 'A', 'A', 'Letter A'),
(0x65, 0x65, 'e', 'e', 'Letter A'),
(0x61, 0x61, 'a', 'a', 'Letter a'),
(0x20, 0x20, ' ', ' ', 'Space'),
(0x42, 0x42, 'B', 'B', 'Letter B'),
(0x31, 0x31, '1', '1', 'Number 1'),
(0x21, 0x21, '!', '!', 'Exclamation'),
(0x414243, 0x414243, 'ABC', 'ABC', 'Multiple chars'),
(0x20414243, 0x20414243, ' ABC', ' ABC', 'Space and chars');
GO

-- Table for empty string testing
CREATE TABLE ascii_function_empty_test (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharCol CHAR(10),
    CharASCII INT,
    VarcharCol VARCHAR(50),
    VarcharASCII INT,
    IsNull BIT,
    Description VARCHAR(100)
);
GO

-- Insert test data for empty strings
INSERT INTO ascii_function_empty_test 
(CharCol, VarcharCol, Description) VALUES
('', '', 'Empty string'),
(' ', ' ', 'Single space'),
('  ', '  ', 'Two spaces'),
(' A', ' A', 'Space then char'),
('A ', 'A ', 'Char then space');
GO

-- Table for CHAR(n) testing
CREATE TABLE ascii_function_char_range (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CharValue INT,
    Description VARCHAR(100)
);
GO

-- Insert test data for CHAR range
INSERT INTO ascii_function_char_range 
(CharValue, Description)
SELECT generate_series, 'CHAR(' + CAST(generate_series AS VARCHAR(3)) + ')'
FROM generate_series(1, 255);
GO

-- Table for CAST/CONVERT testing
CREATE TABLE ascii_function_conversion_test (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    InputValue VARCHAR(50),
    DataType VARCHAR(20),
    Description VARCHAR(100)
);
GO

-- Insert test data 
INSERT INTO ascii_function_conversion_test 
(InputValue, DataType, Description) VALUES
('65', 'INT', 'Number to CHAR'),
('97.0', 'FLOAT', 'Float to VARCHAR'),
('A', 'CHAR', 'CHAR to NCHAR'),
('123', 'VARCHAR', 'VARCHAR to CHAR'),
('ABC', 'NVARCHAR', 'NVARCHAR to VARCHAR');
GO

-- Table for negative number testing
CREATE TABLE ascii_function_negative_test (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    NegativeNum VARCHAR(20),
    Description VARCHAR(100)
);
GO

-- Insert test data for negative numbers
INSERT INTO ascii_function_negative_test 
(NegativeNum, Description) VALUES
('-1', 'Negative one'),
('-123', 'Negative three digits'),
('-0.123', 'Negative decimal'),
('-1E+10', 'Negative scientific'),
('-9999999', 'Large negative');
GO

-- Table for testing datetime and money types
CREATE TABLE ascii_function_special_types (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MoneyValue MONEY,
    SmallMoneyValue SMALLMONEY,
    Description VARCHAR(100)
);
GO

-- Insert test data for special types
INSERT INTO ascii_function_special_types 
( MoneyValue, SmallMoneyValue, Description) 
VALUES
( 123.45, 123.45, 'Basic values'),
( -123.45, -123.45, 'Negative money'),
( 214748.3647, 214748.3647, 'Max values'),
( 0.00, 0.00, 'zero money');
GO

-- Table for testing NULL with different types
CREATE TABLE ascii_function_null_types (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    NullChar CHAR(10),
    NullVarchar VARCHAR(50),
    NullNchar NCHAR(10),
    NullNvarchar NVARCHAR(50),
    NullBinary BINARY(10),
    NullVarbinary VARBINARY(50),
    NullMoney MONEY,
    Description VARCHAR(100)
);
GO

-- Insert test data for NULL types
INSERT INTO ascii_function_null_types 
(Description) VALUES
('All NULL values');

INSERT INTO ascii_function_null_types 
(NullChar, NullVarchar, NullNchar, NullNvarchar, NullBinary, NullVarbinary, NullMoney, Description)
VALUES
('', '', N'', N'', 0x00, 0x00, NULL, 'Empty/zero values');
GO

-- Functions tests
CREATE FUNCTION ascii_function_analyze_pattern
(
    @InputString VARCHAR(100)
)
RETURNS @Result TABLE
(
    ASCIIValue INT,
    Character CHAR(1),
    Position INT
)
AS
BEGIN
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@InputString);
    
    WHILE @i <= @len
    BEGIN
        INSERT INTO @Result
        SELECT 
            ASCII(SUBSTRING(@InputString, @i, 1)),
            SUBSTRING(@InputString, @i, 1),
            @i;
            
        SET @i = @i + 1;
    END;
    
    RETURN;
END;
GO

CREATE FUNCTION ascii_function_compare_types
(
    @Char CHAR(10),
    @Varchar VARCHAR(50),
    @Binary BINARY(10),
    @Varbinary VARBINARY(50)
)
RETURNS @Result TABLE
(
    DataType VARCHAR(20),
    ASCIIValue INT,
    Matches BIT
)
AS
BEGIN
    DECLARE @BaseValue INT = ASCII(@Char);
    
    INSERT @Result VALUES
    ('CHAR', ASCII(@Char), 1),
    ('VARCHAR', ASCII(@Varchar), CASE WHEN ASCII(@Varchar) = @BaseValue THEN 1 ELSE 0 END),
    ('BINARY', ASCII(@Binary), CASE WHEN ASCII(@Binary) = @BaseValue THEN 1 ELSE 0 END),
    ('VARBINARY', ASCII(@Varbinary), CASE WHEN ASCII(@Varbinary) = @BaseValue THEN 1 ELSE 0 END);
    
    RETURN;
END;
GO

-- Procedures tests
CREATE PROCEDURE ascii_function_analyze_string
    @InputString VARCHAR(MAX)
AS
BEGIN
    DECLARE @Position INT = 1;
    DECLARE @Length INT = LEN(@InputString);
    
    -- Create temporary table to store results
    CREATE TABLE #StringAnalysis
    (
        Position INT,
        Character CHAR(1),
        ASCIIValue INT,
        CharacterType VARCHAR(10)
    );
    WHILE @Position <= @Length
    BEGIN
        INSERT INTO #StringAnalysis
        SELECT 
            @Position,
            SUBSTRING(@InputString, @Position, 1),
            ASCII(SUBSTRING(@InputString, @Position, 1)),
            CASE 
                WHEN ASCII(SUBSTRING(@InputString, @Position, 1)) BETWEEN 65 AND 90 THEN 'Uppercase'
                WHEN ASCII(SUBSTRING(@InputString, @Position, 1)) BETWEEN 97 AND 122 THEN 'Lowercase'
                WHEN ASCII(SUBSTRING(@InputString, @Position, 1)) BETWEEN 48 AND 57 THEN 'Digit'
                ELSE 'Special'
            END;
            
        SET @Position = @Position + 1;
    END;
    SELECT * FROM #StringAnalysis ORDER BY Position;
    DROP TABLE #StringAnalysis;
END;
GO

CREATE PROCEDURE ascii_function_validate_conversion
    @Value VARCHAR(50),
    @TargetType VARCHAR(20)
AS
BEGIN
    DECLARE @Result INT;
    
    SET @Result = CASE @TargetType
        WHEN 'CHAR' THEN ASCII(CAST(@Value AS CHAR(10)))
        WHEN 'VARCHAR' THEN ASCII(CAST(@Value AS VARCHAR(50)))
        WHEN 'NCHAR' THEN ASCII(CAST(@Value AS NCHAR(10)))
        WHEN 'NVARCHAR' THEN ASCII(CAST(@Value AS NVARCHAR(50)))
        WHEN 'BINARY' THEN ASCII(CAST(@Value AS BINARY(10)))
        WHEN 'VARBINARY' THEN ASCII(CAST(@Value AS VARBINARY(50)))
    END;
    
    SELECT 
        @Value AS InputValue,
        @TargetType AS ConvertedTo,
        @Result AS ASCIIResult;
END;
GO

-- Views tests
CREATE VIEW ascii_function_v_empty_analysis AS
SELECT 
    ID,
    CASE WHEN ASCII(CharCol) IS NULL THEN 'NULL' 
         ELSE CAST(ASCII(CharCol) AS VARCHAR) END AS CharASCII,
    CASE WHEN ASCII(VarcharCol) IS NULL THEN 'NULL' 
         ELSE CAST(ASCII(VarcharCol) AS VARCHAR) END AS VarcharASCII,
    LEN(CharCol) AS CharLength,
    LEN(VarcharCol) AS VarcharLength,
    Description
FROM ascii_function_empty_test;
GO

-- different data types
CREATE TABLE ascii_function_image(a IMAGE);
GO

INSERT INTO ascii_function_image 
VALUES(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS image));
GO

CREATE TABLE ascii_function_text(a TEXT, b NTEXT);
GO

INSERT INTO ascii_function_text 
VALUES (N'abc🙂defghi🙂🙂', N'abc🙂defghi🙂🙂');
GO

CREATE TABLE ascii_function_test_image (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    a VARBINARY(MAX)
);
GO

INSERT INTO ascii_function_test_image (a) VALUES 
(0x41424344), -- 'ABCD'
(0x61626364), -- 'abcd'
(0x31323334), -- '1234'
(0x21402324); -- '!@#$'
GO

CREATE TABLE ascii_function_test_text (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    a TEXT,
    b NTEXT
);
GO

INSERT INTO ascii_function_test_text (a, b) VALUES 
('ABCD', N'ABCD'),
('abcd', N'abcd'),
('1234', N'1234'),
('!@#$', N'!@#$'),
('    ', N'    '),
('', N'');
GO

-- Create User Defined Types
-- String UDTs
CREATE TYPE dbo.ascii_function_charUDT FROM char(10);
GO
CREATE TYPE dbo.ascii_function_varcharUDT FROM varchar(50);
GO
CREATE TYPE dbo.ascii_function_ncharUDT FROM nchar(10);
GO
CREATE TYPE dbo.ascii_function_nvarcharUDT FROM nvarchar(50);
GO
CREATE TYPE dbo.ascii_function_textUDT FROM text;
GO
CREATE TYPE dbo.ascii_function_ntextUDT FROM ntext;
GO

-- Binary UDTs
CREATE TYPE dbo.ascii_function_binaryUDT FROM binary(10);
GO
CREATE TYPE dbo.ascii_function_varbinaryUDT FROM varbinary(50);
GO
CREATE TYPE dbo.ascii_function_imageUDT FROM image;
GO

-- Numeric UDTs
CREATE TYPE dbo.ascii_function_bigintUDT FROM bigint;
GO
CREATE TYPE dbo.ascii_function_intUDT FROM int;
GO
CREATE TYPE dbo.ascii_function_smallintUDT FROM smallint;
GO
CREATE TYPE dbo.ascii_function_tinyintUDT FROM tinyint;
GO
CREATE TYPE dbo.ascii_function_decimalUDT FROM decimal(18,2);
GO
CREATE TYPE dbo.ascii_function_numericUDT FROM numeric(18,2);
GO
CREATE TYPE dbo.ascii_function_floatUDT FROM float;
GO
CREATE TYPE dbo.ascii_function_realUDT FROM real;
GO

--- DateTime UDTs
CREATE TYPE dbo.ascii_function_datetimeUDT FROM datetime;
GO
CREATE TYPE dbo.ascii_function_smalldatetimeUDT FROM smalldatetime;
GO
CREATE TYPE dbo.ascii_function_dateUDT FROM date;
GO
CREATE TYPE dbo.ascii_function_timeUDT FROM time;
GO
CREATE TYPE dbo.ascii_function_datetime2UDT FROM datetime2;
GO
CREATE TYPE dbo.ascii_function_datetimeoffsetUDT FROM datetimeoffset;
GO

-- Money UDTs
CREATE TYPE dbo.ascii_function_moneyUDT FROM money;
GO
CREATE TYPE dbo.ascii_function_smallmoneyUDT FROM smallmoney;
GO

-- Create test tables
CREATE TABLE ascii_function_UDT_test (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    char_col dbo.ascii_function_charUDT,
    varchar_col dbo.ascii_function_varcharUDT,
    nchar_col dbo.ascii_function_ncharUDT,
    nvarchar_col dbo.ascii_function_nvarcharUDT,
    text_col dbo.ascii_function_textUDT,
    ntext_col dbo.ascii_function_ntextUDT,
    binary_col dbo.ascii_function_binaryUDT,
    varbinary_col dbo.ascii_function_varbinaryUDT,
    bigint_col dbo.ascii_function_bigintUDT,
    int_col dbo.ascii_function_intUDT,
    smallint_col dbo.ascii_function_smallintUDT,
    tinyint_col dbo.ascii_function_tinyintUDT,
    decimal_col dbo.ascii_function_decimalUDT,
    numeric_col dbo.ascii_function_numericUDT,
    float_col dbo.ascii_function_floatUDT,
    real_col dbo.ascii_function_realUDT,
    datetime_col dbo.ascii_function_datetimeUDT,
    smalldatetime_col dbo.ascii_function_smalldatetimeUDT,
    date_col dbo.ascii_function_dateUDT,
    time_col dbo.ascii_function_timeUDT,
    datetime2_col dbo.ascii_function_datetime2UDT,
    datetimeoffset_col dbo.ascii_function_datetimeoffsetUDT,
    money_col dbo.ascii_function_moneyUDT,
    smallmoney_col dbo.ascii_function_smallmoneyUDT
);
GO

-- Insert test data
INSERT INTO ascii_function_UDT_test (
    char_col, varchar_col, nchar_col, nvarchar_col,
    text_col, ntext_col, binary_col, varbinary_col,
    bigint_col, int_col, smallint_col,
    tinyint_col, decimal_col, numeric_col, float_col,
    real_col, datetime_col, smalldatetime_col, date_col,
    time_col, datetime2_col, datetimeoffset_col,
    money_col, smallmoney_col
)
VALUES (
    'ABC', 'ABC', N'ABC', N'ABC',
    'ABC', N'ABC', 0x414243, 0x414243,
    123456, 12345, 1234,
    123, 123.45, 123.45, 123.45,
    123.45, '2023-01-01', '2023-01-01', '2023-01-01',
    '12:34:56', '2023-01-01 12:34:56', '2023-01-01 12:34:56 +00:00',
    123.45, 123.45
),
(
    '', '', N'', N'',
    '', N'', 0x, 0x,
    0, 0, 0,
    0, 0.00, 0.00, 0.00,
    0.00, NULL, NULL, NULL,
    NULL, NULL, NULL,
    0.00, 0.00
);
GO

-- dependent test for ascii(text)
CREATE PROCEDURE ascii_function_text_validator
    @InputText TEXT,
    @ExpectedASCII INT
AS
BEGIN
    IF ASCII(CAST(@InputText AS TEXT)) = @ExpectedASCII
        SELECT 'Pass' AS Result;
    ELSE
        SELECT 'Fail' AS Result;
END;
GO
