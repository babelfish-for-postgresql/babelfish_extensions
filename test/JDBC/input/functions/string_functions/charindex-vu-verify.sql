----------------------------------------- Test var[char], Nchar[char] ---------------------------------------------------
/*
* Test 1: Basic Test Case + Negative start location
*/
-- Basic syntax: CHARINDEX(substring, string [, start_location])
SELECT CHARINDEX('abc', 'xxabcxx');  -- Returns 3
GO
SELECT CHARINDEX('abc', 'xxabcxx', 1);  -- Returns 3
GO
SELECT CHARINDEX('abc', 'xxabcxx', 4);  -- Returns 0
GO
SELECT CHARINDEX('abc', 'xxabcxx', -100000000);  -- Returns 3
GO
SELECT CHARINDEX('abc', 'xxabcxx', 10000000);  -- Returns 0
GO

/*
 * Test 2: Empty input
 */
SELECT CHARINDEX('Hello World', ''); -- return 0
go
SELECT CHARINDEX('', ''); -- return 0
go
SELECT CHARINDEX(' ', ' '); -- return 1
go
SELECT CHARINDEX('         ', '    ', 3); -- return 1
go

/*
 * Test 3: Case Sensitive (depends on collation)
 */
SELECT CHARINDEX('ABC', 'xxabcxx');  -- Returns 0 or 3 depending on collation
GO
SELECT CHARINDEX('abc', 'xxABCxx');  -- Returns 0 or 3 depending on collation
GO

/*
 * Test 4: Force Case Sensitive
 */
SELECT CHARINDEX('ABC', 'xxabcxx' COLLATE Latin1_General_CS_AS);  -- Returns 0
GO

/*
 * Test 5: Different Collation
 */
 
-- Same explicit collation for both
SELECT CHARINDEX('ABC' COLLATE Latin1_General_CI_AS, 'xxabcxx' COLLATE Latin1_General_CI_AS); -- return 3 
GO
-- Only first argument with collation
SELECT CHARINDEX('ABC' COLLATE Latin1_General_CS_AS, 'xxabcxxABC');  -- retunrn 8
GO

/*
 * Test 6: NULL TEST
 */
SELECT CHARINDEX(NULL, 'test');  -- Returns NULL
GO
SELECT CHARINDEX('test', NULL);  -- Returns NULL
GO
SELECT CHARINDEX(NULL, NULL);    -- Returns NULL
GO
SELECT CHARINDEX('test','test', NULL);    -- Returns NULL
GO
SELECT CHARINDEX(NULL, NULL, NULL);    -- Returns NULL
GO

/*
 * Test 7: First Occurences Test
 */
SELECT CHARINDEX('a', 'aaa');  -- Returns 1
GO
SELECT CHARINDEX('a', 'aaa', 2);  -- Returns 2
GO

/*
 * Test 8: Special Character
 */
SELECT CHARINDEX(' ', 'Hello World');  -- Returns 6
GO
SELECT CHARINDEX('.', 'www.test.com');  -- Returns 4
GO
SELECT CHARINDEX('\', 'C:\temp');      -- Returns 3
GO
SELECT CHARINDEX('''', 'It''s mine');  -- Returns 3
GO
SELECT CHARINDEX('%', 'It%s mine');  -- Returns 3
GO
SELECT CHARINDEX(']', 'It[s mi]ne');  -- Returns 8
GO
SELECT CHARINDEX('[]', 'It[s mi][]ne');  -- Returns 9
GO
SELECT CHARINDEX('_______', 'It_____ne');  -- Returns 0
GO
SELECT CHARINDEX('?', 'It?s mi]ne',2 );  -- Returns 3
GO
SELECT CHARINDEX('//', 'It[s "/"/mi//ne');  -- Returns 9
GO
SELECT CHARINDEX('^', 'It[s "/"^/mi//ne');  -- Returns 9
GO


/*
 * Test 9: Test Space
 */
SELECT CHARINDEX(' ', ' abc');
GO

/*
 * Test 10: Test Expression
 */
DECLARE @SearchStr varchar(100) = 'World'
DECLARE @Text varchar(100) = 'Hello World'
SELECT CHARINDEX(@SearchStr, @Text)  -- Returns 7
GO

/*
 * Test 11: Test Concatication
 */
SELECT CHARINDEX('World', 'Hello ' + 'World')  -- Returns 7
GO

/*
 * Test 12: Test Different Types
 */
-- varchar
SELECT CHARINDEX('World', col1) FROM charindex_tests.TestChar  -- Returns 7
GO

-- nvarchar (Unicode)
SELECT CHARINDEX(N'World', col1) FROM charindex_tests.TestNChar  -- Returns 7
GO

-- char
SELECT CHARINDEX('World', col1) FROM charindex_tests.TestFixedChar  -- Returns 7
GO

-- Nchar
SELECT CHARINDEX(N'World', col1) FROM charindex_tests.TestFixedNChar  -- Returns 7
GO

/*
 * Test 13: With Functions
 */
SELECT CHARINDEX(LEFT('World!', 5), 'Hello World')  -- Returns 7
GO

/*
 * Test 14: Empty String
 */
SELECT CHARINDEX('', 'abc');  -- Returns 0
GO
SELECT CHARINDEX('abc', '');  -- Returns 0
GO
SELECT CHARINDEX('', '');     -- Returns 0
GO

/*
 * Test 15: Long String
 */
DECLARE @LongText varchar(max) = REPLICATE('x', 10000) + 'target' + REPLICATE('x', 10000)
SELECT CHARINDEX('target', @LongText)  -- Returns 10001
GO

/*
 * Test 16: test in condition
 */
SELECT CASE 
    WHEN CHARINDEX('World', 'Hello World') > 0 THEN 'Found'
    ELSE 'Not Found'
END
GO

/*
 * Test 17: Unicode Emojis
 */
SELECT CHARINDEX(N'😊', N'Hello 😊 World');  -- Smiling face
GO
SELECT CHARINDEX(N'👍', N'Good job 👍');     -- Thumbs up
GO
SELECT CHARINDEX(N'❤️', N'I ❤️ SQL');        -- Heart
GO

/*
 * Test 18: Unicode Character
 */
SELECT CHARINDEX(N'你', N'Hello你好World');       -- Returns 4
GO
SELECT CHARINDEX(N'好', N'Hello你好World');     -- Returns 6
GO
SELECT CHARINDEX('Hello', N'Hello你好World');   -- Returns 1
GO
SELECT CHARINDEX(N'号', N'1号2号3号');   -- Returrn 2
GO

/*
 * Test 19: Test Different Collation with different inputs
 *  19.1.  Chinese Collation
 *  19.2.  Japanese Collation
 *  19.3.  Latin Collation
 */

-- Test 19.1 chinese collation 
SELECT id,
    CHARINDEX('中', char_col) as char_pos,
    CHARINDEX('中', varchar_col) as varchar_pos,
    CHARINDEX(N'中', nchar_col) as nchar_pos,
    CHARINDEX(N'中', nvarchar_col) as nvarchar_pos
FROM charindex_tests.chinese_variants;
GO

--  Case sensitivity tests (ABC vs abc)
SELECT id,
    CHARINDEX('ABC', char_col) as char_upper,
    CHARINDEX('abc', char_col) as char_lower,
    CHARINDEX('ABC', varchar_col) as varchar_upper,
    CHARINDEX('abc', varchar_col) as varchar_lower
FROM charindex_tests.chinese_variants
WHERE id = 2;
GO

--  single same characters test
SELECT id,
    CHARINDEX('中国', char_col) as char_multi,
    CHARINDEX('中国', varchar_col) as varchar_multi,
    CHARINDEX(N'中国', nchar_col) as nchar_multi,
    CHARINDEX(N'中国', nvarchar_col) as nvarchar_multi
FROM charindex_tests.chinese_variants
WHERE id = 1;
GO

-- Mixed character search
SELECT id,
    CHARINDEX('ABC中', char_col) as char_mixed,
    CHARINDEX('ABC中', varchar_col) as varchar_mixed,
    CHARINDEX(N'ABC中', nchar_col) as nchar_mixed,
    CHARINDEX(N'ABC中', nvarchar_col) as nvarchar_mixed
FROM charindex_tests.chinese_variants
WHERE id = 2;
GO

-- 19.2 Japanese collation test
SELECT id,
    CHARINDEX('こんに', char_col) as hiragana_multi_char,
    CHARINDEX('テスト', varchar_col) as katakana_multi_varchar,
    CHARINDEX(N'日本語', nchar_col) as kanji_multi_nchar,
    CHARINDEX(N'テストA', nvarchar_col) as mixed_multi_nvarchar
FROM charindex_tests.japanese_variants;
GO


SELECT id,
    -- Compare hiragana は with katakana ハ
    CHARINDEX('は', char_col) as hiragana_char,
    CHARINDEX('ハ', varchar_col) as katakana_varchar,
    CHARINDEX(N'は', nchar_col) as hiragana_nchar,
    CHARINDEX(N'ハ', nvarchar_col) as katakana_nvarchar
FROM charindex_tests.japanese_variants;
GO

--- test binary collation
SELECT id,
    -- Test with existing columns
    CHARINDEX(N'テスト', nvarchar_col) as nvarchar_match,
    CHARINDEX(N'テスト', char_col) as char_match
FROM charindex_tests.japanese_variants
WHERE id = 2;
GO

-- 19.3 Case sensitivity tests
SELECT 
    CHARINDEX('test', Content_CI) as CaseInsensitive,
    CHARINDEX('test', Content_CS) as CaseSensitive
FROM charindex_tests.UnicodeTest;
GO


------------------------------------- Test VAR[BINARY] arguments ----------------------------------------
/*
 * Test 1: Basic Test
 */
Declare @BinaryVar binary = CAST('B' AS BINARY);
SELECT 
    ID,
    CHARINDEX(CAST('B' AS BINARY), FixedBinary) AS Fixed_Pos1,
    CHARINDEX(@BinaryVar, FixedBinary) AS Fixed_Pos2,
    CHARINDEX(CAST('B' AS VARBINARY), VarBinary) AS Var_Pos
FROM charindex_tests.BinaryTypes;
GO
SELECT CHARINDEX( CAST('TEST' AS BINARY(10)), CAST('TEST' AS BINARY(20)) ) as Binary_Search, 
       CHARINDEX( CAST('TEST' AS VARBINARY(10)), CAST('TEST CASE' AS VARBINARY(10)) ) as VarBinary_Search;
GO

/*
 * Test 2: NULL Test
 */
SELECT CHARINDEX(NULL, FixedBinary) as Fixed_Null FROM charindex_tests.NullTests;
GO
SELECT CHARINDEX(NULL, VarBinary) as Var_Null FROM charindex_tests.NullTests;
GO

/*
 * Test 3: Empty Test
 */
SELECT 
    CHARINDEX(CAST('' AS BINARY), FixedBinary) as Fixed_Empty,
    CHARINDEX(CAST('' AS VARBINARY), VarBinary) as Var_Empty,
    CHARINDEX(CAST('ABC' AS BINARY), CAST('' AS BINARY)) as Fixed_Empty1
FROM charindex_tests.NullTests;
GO

/*
 * Test 4: Complex Cases
 */
SELECT 
    CHARINDEX(0x435C, Fixed1, 2) as Pattern_With_Null_Fixed,
    CHARINDEX(0x46, Var1, 2) as Pattern_With_Null_Var,
    CHARINDEX( CAST('DEF' AS BINARY(3)), Fixed2 ) as Padded_Search_Fixed,
    CHARINDEX( Var1,Fixed1) as Complex_Pattern_Match from charindex_tests.ComplexBinary;
GO

/*
 * Test 5: Pattern longer than search string
 */
SELECT CHARINDEX( CAST('HelloWorldLongerPattern' AS VARBINARY(MAX)), VarbinaryData ) AS LongPatternSearch FROM charindex_tests.SpecialBinary;
GO

/*
 * Test 6: Nested Charindex Test
 */
SELECT CHARINDEX(
    CAST('World' AS VARBINARY(MAX)),
    SUBSTRING(
        VarbinaryData,
        CHARINDEX(CAST('123' AS VARBINARY(MAX)), VarbinaryData),
        50
    )
) AS NestedSearch
FROM charindex_tests.SpecialBinary;
GO

/*
 * Test 7: Special Chars
 */
SELECT CHARINDEX( CAST('©' AS VARBINARY(MAX)), VarbinaryData) AS SpecialCharSearch FROM charindex_tests.SpecialBinary;
GO

/*
 * Test 8: Test UDTs
 */
declare @a charindex_tests.varbinary_udt = 0x65
declare @b charindex_tests.varbinary_udt = 0x707172656667
select charindex(@a, @b)
go

declare @a charindex_tests.binary_udt = 0x65
declare @b charindex_tests.binary_udt = 0x707172656667
select charindex(@a, @b)
go

/*
 * Test 8: Test var[binary] with varchar
 */
declare @a varchar = 'abc'
declare @b varbinary(100) = 0x616263
select charindex(@b, @a)    -- throw error
GO

declare @a varchar = 'abc'
declare @b binary(3) = 0x616263
select charindex(@b, @a)   -- throw error
GO

----------------------------------------- Mixed Type testing -------------------------------------------

/*
 *  Test 1:  Charindex(var[char], Any)
 *  Return : Right Arg should explicitly converted to var[char] and give O/P
 */
SELECT CHARINDEX('123', 123456) AS FindInInt;  -- int
GO
select CHARINDEX('45', 123.45) AS FindInDecimal;  -- decimal
GO
select CHARINDEX('03', 02-03-2025) AS FindInDecimal; -- date
GO
SELECT CHARINDEX('100', $100.50) as FindInMoney; -- money
GO
SELECT CHARINDEX('1', CAST(1 AS BIT)) AS FindInBit;  -- Bit
GO
SELECT CHARINDEX('E', 1.23E+5) AS FindScientificNotation -- scientific notation
GO
SELECT CHARINDEX('1', DATEPART(month, '2025-01-15')) AS FindInDatePart; --datepart result
GO
SELECT CHARINDEX('b', 0x616263) AS FindInBinary -- Binary
GO

/*
 *  Test 2:  Charindex(var[binary], Any)
 *  Return : Right Arg should explicitly converted to var[binary] and give O/P
 */
SELECT CHARINDEX(0x31, 49) AS FindInInt;  -- int to varbinary
GO

/*
*  All below statement currently throw  eerror as no cast function is available for varbinary
*  Hence need to handle this in future
*/
SELECT CHARINDEX(0x020200012D000000, 0.45) AS FindInDecimal;  -- decimal to varbinary
GO
SELECT CHARINDEX(0x55, $100.50) AS FindInMoney;  -- money to varbinary
GO
SELECT CHARINDEX(0x01, CAST(1 AS BIT)) AS FindInBit;  -- bit to varbinary
GO
SELECT CHARINDEX(0x45, 1.23E+5) AS FindScientificNotation;  -- scientific notation to varbinary
GO
SELECT CHARINDEX(0x31, DATEPART(month, '2025-01-15')) AS FindInDatePart;  -- datepart result to varbinary
GO
SELECT CHARINDEX(0x62, 'abc') AS FindInString;  -- string to varbinary
GO

/*
 *  Test 3:  Charindex(Any, Any)
 *  In Charindex(expressionToFind, expressionToSearch), expressionToFind could only be var[char], var[binary]
 *  For other type expressionToFind, it should throw error
 */

------------------------------------------------------------------------------------
--- NOTE: This is not problematic for now.
---       All below statemnt should throw error.Hence need to handle this in future
-------------------------------------------------------------------------------------
Select charindex(123, 43123);
GO
Select charindex(123, '43123', 2);
GO
SELECT CHARINDEX($50, $100.50)
GO

--------------------------------------- Dependent objects like function, triggers, views , etc for MVU --------------------------

-- 2. Check view
SELECT * FROM charindex_tests.text_view;
GO

SELECT * FROM charindex_tests.text_view1;
GO

-- 3. Test function
SELECT * FROM charindex_tests.find_text(N'テスト');
GO

-- 4. Test trigger
BEGIN TRY
    INSERT INTO charindex_tests.text_base(id, content) VALUES (4, N'testABC');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE();
END CATCH
GO

-- 5. Test function for var[binary]
SELECT * FROM charindex_tests.find_binary;
GO
SELECT * FROM charindex_tests.find_binary1;
GO
SELECT * FROM charindex_tests.find_varbinary;
GO
SELECT * FROM charindex_tests.find_varbinary1;
GO