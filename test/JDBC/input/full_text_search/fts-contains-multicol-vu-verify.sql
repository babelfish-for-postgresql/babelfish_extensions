-- Basic Multiple Column Tests
SELECT sys.replace_special_chars_fts('one`two', 'three@four', 'five#six');
SELECT sys.replace_special_chars_fts('one@two', 'three#four', 'five$six', 'seven&eight');
GO

-- Mixed Single and Multiple Column Tests
SELECT sys.replace_special_chars_fts('"one @ @ @ @ two"');
SELECT sys.replace_special_chars_fts('"one @ @ @ @ two"', 'three ^ four', 'five & six');
GO

-- Quoted String Multiple Column Tests
SELECT sys.replace_special_chars_fts('"one @ two"', '"three $ four"', '"five # six"');
SELECT sys.replace_special_chars_fts('"one   @ two    ^ three"', '"four % five"', '"six & seven"');
GO

-- Multiple Spaces Multiple Column Tests
SELECT sys.replace_special_chars_fts('one     two', 'three    four', 'five   six');
SELECT sys.replace_special_chars_fts('   one   two   ', '   three   four   ', '   five   six   ');
GO

-- Apostrophe Multiple Column Tests
SELECT sys.replace_special_chars_fts('Arts '' opening', 'Bob''s place', 'Smith''s store');
SELECT sys.replace_special_chars_fts('Don''t', 'Won''t', 'Can''t', 'Shouldn''t');
GO


-- Mixed Special Characters Multiple Column Tests
SELECT sys.replace_special_chars_fts('one@two#three', 'four$five^six', 'seven&eight*nine');
SELECT sys.replace_special_chars_fts('"one@@two"', '"three##four"', '"five$$six"');
GO

-- Empty and NULL Multiple Column Tests
SELECT sys.replace_special_chars_fts('', NULL, 'three');
SELECT sys.replace_special_chars_fts(NULL, '', NULL);
-- SELECT sys.babelfish_fts_rewrite('', NULL, 'three');
GO

-- Unicode Character Multiple Column Tests
SELECT sys.replace_special_chars_fts('café@résumé', 'über#müller', 'señor$españa');
SELECT sys.replace_special_chars_fts('"café@résumé"', '"über#müller"', '"señor$españa"');
GO

-- Mixed Content Type Tests
SELECT sys.replace_special_chars_fts('normal text', '"quoted text"', 'special@text');
SELECT sys.replace_special_chars_fts('UPPER CASE', 'lower case', 'Mixed@Case');
GO

-- Large Number of Columns Test
SELECT sys.replace_special_chars_fts(
    'column1@test',
    'column2#test',
    'column3$test',
    'column4%test',
    'column5^test',
    'column6&test',
    'column7*test',
    'column8(test'
);
GO

-- Complex Multiple Column Tests
SELECT sys.replace_special_chars_fts(
    '"Complex @ Test"',
    'Simple # Test',
    '"Mixed @ # $ Test"',
    'Normal Text'
);
GO

-- Special Characters Combination Tests
SELECT sys.replace_special_chars_fts(
    'one@two#three',
    '"four$five^six"',
    'seven & eight',
    '"nine @ ten"'
);
GO

-- Edge Cases with Multiple Columns
SELECT sys.replace_special_chars_fts('""""', '@@@', '###', '$$$');
SELECT sys.replace_special_chars_fts('    ', '"   "', '  @  ', ' # ');
-- SELECT sys.babelfish_fts_rewrite('""""', '@@@', '###', '$$$');
GO

-- Mixed Length Tests
SELECT sys.replace_special_chars_fts(
    'short',
    'medium length text',
    'very long text with special @ characters and spaces',
    '"quoted short"'
);
GO

-- Nested Quotes Tests
SELECT sys.replace_special_chars_fts(
    '"outer "inner" quote"',
    '"another "inner" test"',
    'no quotes here'
);
GO

-- Special Character Position Tests
SELECT sys.replace_special_chars_fts(
    '@start',
    'middle@middle',
    'end@',
    '"@quoted@"'
);
GO


-- Verify the results
SELECT TOP 50 * FROM test_tb ORDER BY id;

-- Check total count
SELECT COUNT(*) as total_records FROM test_tb;

-- Check pattern repetition (first 24 rows vs next 24 rows)
SELECT 'First 24 rows' as Pattern, * FROM (
    SELECT TOP 24 * FROM test_tb ORDER BY id
) t1
UNION ALL
SELECT 'Next 24 rows' as Pattern, * FROM (
    SELECT TOP 24 * FROM (
        SELECT TOP 48 * FROM test_tb ORDER BY id
    ) t ORDER BY id DESC
) t2;
GO
