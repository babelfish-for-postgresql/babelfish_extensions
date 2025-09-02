-- 1. Basic ASCII Character Tests
SELECT ASCII('A') AS CapitalA_Expect65;
SELECT ASCII('a') AS LowercaseA_Expect97;
SELECT ASCII('Z') AS CapitalZ_Expect90;
SELECT ASCII('z') AS LowercaseZ_Expect122;
SELECT ASCII('0') AS Zero_Expect48;
SELECT ASCII('9') AS Nine_Expect57;
GO

-- 2. Special Character Tests
SELECT ASCII(' ') AS Space_Expect32;
SELECT ASCII('!') AS ExclamMark_Expect33;
SELECT ASCII('@') AS AtSign_Expect64;
SELECT ASCII('#') AS Hash_Expect35;
SELECT ASCII('$') AS Dollar_Expect36;
SELECT ASCII('%') AS Percent_Expect37;
GO

-- 3. Control Character Tests
SELECT ASCII(CHAR(0)) AS NUL_ExpectNull;
SELECT ASCII(CHAR(1)) AS SOH_Expect1;
SELECT ASCII(CHAR(9)) AS Tab_Expect9;
SELECT ASCII(CHAR(10)) AS LF_Expect10;
SELECT ASCII(CHAR(13)) AS CR_Expect13;
SELECT ASCII(CHAR(27)) AS ESC_Expect27;
SELECT ASCII(CHAR(31)) AS US_Expect31;
GO

-- 4. NULL and Empty String Tests
SELECT 
    ASCII(NULL) AS Null_ExpectNull,
    ASCII('') AS Empty_ExpectNull,
    ASCII('  ') AS TwoSpaces_Expect32,
    ASCII(CAST(NULL AS VARCHAR)) AS NullVarchar_ExpectNull,
    ASCII(CAST(NULL AS NVARCHAR)) AS NullNVarchar_ExpectNull;
GO

-- 5. Multiple Character String Tests
SELECT 
    ASCII('ABC') AS "ABC_Expect65",
    ASCII('123') AS "123_Expect49",
    ASCII('!@#') AS "SpecialChars_Expect33",
    ASCII('   ABC') AS "SpacedString_Expect32",
    ASCII(CHAR(13) || 'ABC') AS "CRString_Expect13"; 
GO

SELECT * FROM babel_5809_t1 ORDER BY ID;
GO

-- 6. Unicode Character Tests
SELECT * FROM babel_5809_t2;
GO

-- 7. Binary and Hex Tests
-- Direct hex values
SELECT 
    ASCII(0x00) AS Hex00_Expect0,
    ASCII(0x41) AS Hex41_Expect65,
    ASCII(0x61) AS Hex61_Expect97,
    ASCII(0xFF) AS HexFF_Expect255;
GO

-- Binary table tests
SELECT * FROM babel_5809_v2_binary;
GO

SELECT * FROM babel_5809_t4_convert ORDER BY ID;
GO

-- 8. Range Tests
-- Standard ASCII Range (0-127)
SELECT ASCII(CHAR(0)) AS Char0_ExpectNull;
SELECT ASCII(CHAR(127)) AS Char127_Expe
-- Extended ASCII Range (128-255)
SELECT ASCII(CHAR(128)) AS Char128_Expect128;
SELECT ASCII(CHAR(255)) AS Char255_Expect255;

-- Out of Range Tests
SELECT ASCII(CHAR(256)) AS Char256_ExpectNull;
SELECT ASCII(CHAR(65535)) AS CharMax_ExpectNull;
GO

-- 9. Data Type Tests
-- Test all data types from t1
SELECT * FROM babel_5809_v1_datatypes;
GO

-- Test type conversions
SELECT 
    ASCII(CAST(65 AS CHAR(1))) AS IntToChar_Expect54,
    ASCII(CAST(97.0 AS VARCHAR)) AS FloatToVarchar_Expect57,
    ASCII(CAST('A' AS NCHAR)) AS CharToNChar_Expect65;
GO

-- 10. Edge Cases Tests
-- Test edge cases from t5_edge
SELECT * FROM babel_5809_t5_edge;
GO

-- Test boundary conditions
SELECT 
    ASCII(CHAR(31)) AS LastControl_Expect31,
    ASCII(CHAR(32)) AS FirstPrintable_Expect32,
    ASCII(CHAR(126)) AS LastPrintable_Expect126,
    ASCII(CHAR(127)) AS DEL_Expect127;
GO

-- 11. Numeric Tests
-- Test numeric conversions
SELECT * FROM babel_5809_t6_numeric;
GO

-- Test scientific notation
SELECT 
    ASCII('1E+10') AS ScientificPos_Expect49,
    ASCII('1E-10') AS ScientificNeg_Expect49,
    ASCII('2.5E+5') AS ScientificDecimal_Expect50;
GO

-- 12. Invalid Input Tests
SELECT * FROM babel_5809_t7_edge;
GO

-- 13. Function Tests
-- Test standard ASCII
SELECT * FROM babel_5809_fn_validate_ascii_range('A');
SELECT * FROM babel_5809_fn_validate_ascii_range('1');
SELECT * FROM babel_5809_fn_validate_ascii_range(' ');
GO

-- Test control characters
SELECT * FROM babel_5809_fn_validate_ascii_range(CHAR(1));
SELECT * FROM babel_5809_fn_validate_ascii_range(CHAR(31));
GO

-- Test extended ASCII
SELECT * FROM babel_5809_fn_validate_ascii_range(CHAR(128));
SELECT * FROM babel_5809_fn_validate_ascii_range(CHAR(255));
GO

-- Test different categories
SELECT dbo.babel_5809_fn_ascii_category('A') AS Category_Uppercase;
SELECT dbo.babel_5809_fn_ascii_category('1') AS Category_Digit;
SELECT dbo.babel_5809_fn_ascii_category(' ') AS Category_Special;
SELECT dbo.babel_5809_fn_ascii_category(CHAR(0)) AS Category_Control;
SELECT dbo.babel_5809_fn_ascii_category(CHAR(255)) AS Category_Extended;
GO

-- 14. Stored Procedure Tests
-- Test with various string types
EXEC babel_5809_sp_validate_string 'Hello123!@#';
EXEC babel_5809_sp_validate_string 'UPPER lower 123 !@#';
EXEC babel_5809_sp_validate_string 'Tab	Newline';
GO

-- Test different character types
EXEC babel_5809_ascii_sp_analyzestring 'ABC';
EXEC babel_5809_ascii_sp_analyzestring '123';
EXEC babel_5809_ascii_sp_analyzestring '!@#';
EXEC babel_5809_ascii_sp_analyzestring '';
EXEC babel_5809_ascii_sp_analyzestring NULL;
GO

-- Test expected matches and mismatches
EXEC babel_5809_ascii_sp_validateascii 'A', 65;  
EXEC babel_5809_ascii_sp_validateascii 'A', 97; -- should give as fail result  
EXEC babel_5809_ascii_sp_validateascii '1', 49;  
EXEC babel_5809_ascii_sp_validateascii ' ', 32;  
GO

-- 15. Computed Column Tests
SELECT * FROM babel_5809_computed_ascii ORDER BY ASCIIValue;
GO

-- 16. Constraint Tests
BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES ('X');
    PRINT 'ValidInsert_Pass: Standard ASCII character accepted';
END TRY
BEGIN CATCH
    PRINT 'ValidInsert_Fail: ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES ('A'), ('z'), ('#');
    INSERT INTO babel_5809_ascii_constrained_t6 (InputString) VALUES ('Test'), ('ABC');
    SELECT 'Valid inserts succeeded' AS Status;
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- Invalid inserts
BEGIN TRY
    -- Try to insert a digit
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES ('5');
END TRY
BEGIN CATCH
    SELECT 'Digit constraint' AS TestCase,
           ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

BEGIN TRY
    -- Try to insert lowercase first character
    INSERT INTO babel_5809_ascii_constrained_t6 (InputString) VALUES ('test');
END TRY
BEGIN CATCH
    SELECT 'Uppercase constraint' AS TestCase,
           ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- Test control character constraint
BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES (CHAR(31));
    PRINT 'ControlChar_Fail: Control character was accepted';
END TRY
BEGIN CATCH
    PRINT 'ControlChar_Pass: Control character correctly rejected';
END CATCH;
GO

-- Test extended ASCII constraint
BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES (CHAR(128));
    PRINT 'ExtendedASCII_Fail: Extended ASCII character was accepted';
END TRY
BEGIN CATCH
    PRINT 'ExtendedASCII_Pass: Extended ASCII character correctly rejected';
END CATCH;
GO

-- Test NULL constraint
BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES (NULL);
    PRINT 'NullChar_Fail: NULL was accepted';
END TRY
BEGIN CATCH
    PRINT 'NullChar_Pass: NULL correctly rejected';
END CATCH;
GO

SELECT * FROM babel_5809_constrained_ascii ORDER BY ID;
GO
