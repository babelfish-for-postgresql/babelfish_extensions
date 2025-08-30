/*
===========================================
BABEL-5809: ASCII Function Testing - Verify
===========================================
*/

-- 1. Basic ASCII Character Tests
SELECT ASCII('A') AS Test1_CapitalA_Expect65;
SELECT ASCII('a') AS Test2_LowercaseA_Expect97;
SELECT ASCII('Z') AS Test3_CapitalZ_Expect90;
SELECT ASCII('z') AS Test4_LowercaseZ_Expect122;
SELECT ASCII('0') AS Test5_Zero_Expect48;
SELECT ASCII('9') AS Test6_Nine_Expect57;
GO

-- 2. Special Character Tests
SELECT ASCII(' ') AS Test7_Space_Expect32;
SELECT ASCII('!') AS Test8_ExclamMark_Expect33;
SELECT ASCII('@') AS Test9_AtSign_Expect64;
SELECT ASCII('#') AS Test10_Hash_Expect35;
SELECT ASCII('$') AS Test11_Dollar_Expect36;
SELECT ASCII('%') AS Test12_Percent_Expect37;
GO

-- 3. Control Character Tests
SELECT ASCII(CHAR(0)) AS Test13_NUL_ExpectNull;
SELECT ASCII(CHAR(1)) AS Test14_SOH_Expect1;
SELECT ASCII(CHAR(9)) AS Test15_Tab_Expect9;
SELECT ASCII(CHAR(10)) AS Test16_LF_Expect10;
SELECT ASCII(CHAR(13)) AS Test17_CR_Expect13;
SELECT ASCII(CHAR(27)) AS Test18_ESC_Expect27;
SELECT ASCII(CHAR(31)) AS Test19_US_Expect31;
GO

-- 4. NULL and Empty String Tests
SELECT 
    ASCII(NULL) AS Test20_Null_ExpectNull,
    ASCII('') AS Test21_Empty_ExpectNull,
    ASCII('  ') AS Test22_TwoSpaces_Expect32,
    ASCII(CAST(NULL AS VARCHAR)) AS Test23_NullVarchar_ExpectNull,
    ASCII(CAST(NULL AS NVARCHAR)) AS Test24_NullNVarchar_ExpectNull;
GO

-- 5. Multiple Character String Tests
SELECT 
    ASCII('ABC') AS Test25_ABC_Expect65,
    ASCII('123') AS Test26_123_Expect49,
    ASCII('!@#') AS Test27_SpecialChars_Expect33,
    ASCII('   ABC') AS Test28_SpacedString_Expect32,
    ASCII(CHAR(13) + 'ABC') AS Test29_CRString_Expect13;
GO

SELECT * FROM babel_5809_t1 ORDER BY ID;
GO

-- 6. Unicode Character Tests
SELECT * FROM babel_5809_t2;
GO

-- 7. Binary and Hex Tests
-- Direct hex values
SELECT 
    ASCII(0x00) AS Test30_Hex00_Expect0,
    ASCII(0x41) AS Test31_Hex41_Expect65,
    ASCII(0x61) AS Test32_Hex61_Expect97,
    ASCII(0xFF) AS Test33_HexFF_Expect255;
GO

-- Binary table tests
SELECT * FROM babel_5809_v2_binary;
GO

SELECT * FROM babel_5809_t4_convert ORDER BY ID;
GO

-- 8. Range Tests
-- Standard ASCII Range (0-127)
SELECT ASCII(CHAR(0)) AS Test34_Char0_ExpectNull;
SELECT ASCII(CHAR(127)) AS Test35_Char127_Expect127;

-- Extended ASCII Range (128-255)
SELECT ASCII(CHAR(128)) AS Test36_Char128_ExpectNull;
SELECT ASCII(CHAR(255)) AS Test37_Char255_Expect255;

-- Out of Range Tests
SELECT ASCII(CHAR(256)) AS Test38_Char256_ExpectNull;
SELECT ASCII(CHAR(65535)) AS Test39_CharMax_ExpectNull;
GO

-- 9. Data Type Tests
-- Test all data types from t1
SELECT * FROM babel_5809_v1_datatypes;
GO

-- Test type conversions
SELECT 
    ASCII(CAST(65 AS CHAR(1))) AS Test40_IntToChar_Expect54,
    ASCII(CAST(97.0 AS VARCHAR)) AS Test41_FloatToVarchar_Expect57,
    ASCII(CAST('A' AS NCHAR)) AS Test42_CharToNChar_Expect65;
GO

-- 10. Edge Cases Tests
-- Test edge cases from t5_edge
SELECT * FROM babel_5809_t5_edge;
GO

-- Test boundary conditions
SELECT 
    ASCII(CHAR(31)) AS Test43_LastControl_Expect31,
    ASCII(CHAR(32)) AS Test44_FirstPrintable_Expect32,
    ASCII(CHAR(126)) AS Test45_LastPrintable_Expect126,
    ASCII(CHAR(127)) AS Test46_DEL_Expect127;
GO

-- 11. Numeric Tests
-- Test numeric conversions
SELECT * FROM babel_5809_t6_numeric;
GO

-- Test scientific notation
SELECT 
    ASCII('1E+10') AS Test47_ScientificPos_Expect49,
    ASCII('1E-10') AS Test48_ScientificNeg_Expect49,
    ASCII('2.5E+5') AS Test49_ScientificDecimal_Expect50;
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
SELECT dbo.babel_5809_fn_ascii_category('A') AS Test50_Category_Uppercase;
SELECT dbo.babel_5809_fn_ascii_category('1') AS Test51_Category_Digit;
SELECT dbo.babel_5809_fn_ascii_category(' ') AS Test52_Category_Special;
SELECT dbo.babel_5809_fn_ascii_category(CHAR(0)) AS Test53_Category_Control;
SELECT dbo.babel_5809_fn_ascii_category(CHAR(255)) AS Test54_Category_Extended;
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
EXEC babel_5809_ascii_sp_validateascii 'A', 65;  -- Should pass
EXEC babel_5809_ascii_sp_validateascii 'A', 97;  -- Should fail
EXEC babel_5809_ascii_sp_validateascii '1', 49;  -- Should pass
EXEC babel_5809_ascii_sp_validateascii ' ', 32;  -- Should pass
GO

-- 15. Computed Column Tests
SELECT * FROM babel_5809_computed_ascii ORDER BY ASCIIValue;
GO

-- 16. Constraint Tests
BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES ('X');
    PRINT 'Test55_ValidInsert_Pass: Standard ASCII character accepted';
END TRY
BEGIN CATCH
    PRINT 'Test55_ValidInsert_Fail: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test control character constraint
BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES (CHAR(31));
    PRINT 'Test56_ControlChar_Fail: Control character was accepted';
END TRY
BEGIN CATCH
    PRINT 'Test56_ControlChar_Pass: Control character correctly rejected';
END CATCH;
GO

-- Test extended ASCII constraint
BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES (CHAR(128));
    PRINT 'Test57_ExtendedASCII_Fail: Extended ASCII character was accepted';
END TRY
BEGIN CATCH
    PRINT 'Test57_ExtendedASCII_Pass: Extended ASCII character correctly rejected';
END CATCH;
GO

-- Test NULL constraint
BEGIN TRY
    INSERT INTO babel_5809_constrained_ascii (InputChar) VALUES (NULL);
    PRINT 'Test58_NullChar_Fail: NULL was accepted';
END TRY
BEGIN CATCH
    PRINT 'Test58_NullChar_Pass: NULL correctly rejected';
END CATCH;
GO

SELECT * FROM babel_5809_constrained_ascii ORDER BY ID;
GO
