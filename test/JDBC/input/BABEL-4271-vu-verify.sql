-- Test to check ESCAPE null case (ESCAPE null means no ESCAPE char used)
select 1 where 'ABCD' LIKE 'AB[C]D' ESCAPE '';
go
select 1 where 'cbc' LIKE '[c-a]bc' ESCAPE '';
go
select 1 where 'abc' LIKE '[0-a]bc' ESCAPE '';
go
select 1 where 'abc' LIKE '[abc]bc' ESCAPE '';
go
select 1 where 'abc' LIKE '[a-c]bc' ESCAPE '';
go
select 1 where 'bbc' LIKE '[a-c]bc' ESCAPE '';
go
select a, b from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE babel_4271_vu_prepare_t1.b ESCAPE '';
go
SELECT a, '' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE '' ESCAPE '';
go
SELECT a, 'abc' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE '' ESCAPE '';
go
SELECT '', '' from babel_4271_vu_prepare_t1 where '' LIKE babel_4271_vu_prepare_t1.b ESCAPE '';
go
SELECT 'xy', b from babel_4271_vu_prepare_t1 where 'cbc' LIKE babel_4271_vu_prepare_t1.a ESCAPE '';
go
SELECT a, b from babel_4271_vu_prepare_t1 where '' LIKE '' ESCAPE '';
go
-- Test to check ESCAPE null case (ESCAPE null means no ESCAPE char used)
select 1 where 'ABCD' LIKE 'AB[C]D' ESCAPE null;
go
select 1 where 'cbc' LIKE '[c-a]bc' ESCAPE null;
go
select 1 where 'abc' LIKE '[0-a]bc' ESCAPE null;
go
select 1 where 'abc' LIKE '[abc]bc' ESCAPE null;
go
select 1 where 'abc' LIKE '[a-c]bc' ESCAPE null;
go
select 1 where 'bbc' LIKE '[a-c]bc' ESCAPE null;
go
select a, b from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE babel_4271_vu_prepare_t1.b ESCAPE null;
go
SELECT a, 'abc' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE 'abc' ESCAPE null;
go
SELECT a, '' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE babel_4271_vu_prepare_t1.b ESCAPE null;
go
SELECT a, '' from babel_4271_vu_prepare_t1 where babel_4271_vu_prepare_t1.a LIKE '' ESCAPE null;
go
SELECT 'xy', b from babel_4271_vu_prepare_t1 where 'cbc' LIKE babel_4271_vu_prepare_t1.a ESCAPE null;
go
SELECT '', '' from babel_4271_vu_prepare_t1 where '' LIKE babel_4271_vu_prepare_t1.b ESCAPE null;
go
SELECT a, b from babel_4271_vu_prepare_t1 where '' LIKE '' ESCAPE null;
go

-- BABEL-6180
-- =============================================================================
-- TEST SECTION 1: Escaped Brackets with Different Escape Characters
-- =============================================================================

--- '=== TEST 1: Escaped Brackets with Backslash ==='

-- Test 1.1: Exact bracket patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '\[300\]' ESCAPE '\' ORDER BY id;
GO

-- Test 1.2: Infix bracket patterns (the main fix)
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\[300\]%' ESCAPE '\' ORDER BY id;
GO

-- Test 1.3: Prefix bracket patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '\[300\]%' ESCAPE '\' ORDER BY id;
GO

-- Test 1.4: Suffix bracket patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\[300\]' ESCAPE '\' ORDER BY id;
GO

--- '=== TEST 2: Escaped Brackets with Exclamation Mark ===' as test_section;

-- Test 2.1: Exact bracket patterns with !
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '![300!]' ESCAPE '!' ORDER BY id;
GO

-- Test 2.2: Infix bracket patterns with !
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%![300!]%' ESCAPE '!' ORDER BY id;
GO

-- Test 2.3: Mixed bracket patterns with !
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '![abc!]%' ESCAPE '!' ORDER BY id;
GO

--- '=== TEST 3: Escaped Brackets with Hash Mark ===' as test_section;

-- Test 3.1: Various bracket patterns with #
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%#[300#]%' ESCAPE '#' ORDER BY id;
GO

-- =============================================================================
-- TEST SECTION 2: Escaped Underscores with Different Escape Characters
-- =============================================================================

---  '=== TEST 4: Escaped Underscores ==='

-- Test 4.1: Exact underscore patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '\_test\_' ESCAPE '\' ORDER BY id;
GO

-- Test 4.2: Infix underscore patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\_test\_%' ESCAPE '\' ORDER BY id;
GO

-- Test 4.3: Mixed underscore and wildcard patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE 'prefix\_test\_%' ESCAPE '\' ORDER BY id;
GO

-- Test 4.4: Underscore with different escape character
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%!_test!_%' ESCAPE '!' ORDER BY id;
GO

-- =============================================================================
-- TEST SECTION 3: Escaped Percent Signs
-- =============================================================================

--- '=== TEST 5: Escaped Percent Signs ==='

-- Test 5.1: Exact percent patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '100\%' ESCAPE '\' ORDER BY id;
GO

-- Test 5.2: Infix percent patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\%%' ESCAPE '\' ORDER BY id;
GO

-- Test 5.3: Percent with different escape character
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%!%%' ESCAPE '!' ORDER BY id;
GO

-- =============================================================================
-- TEST SECTION 4: Mixed Escaped and Unescaped Wildcards
-- =============================================================================

--- '=== TEST 6: Mixed Escaped and Unescaped Wildcards ==='

-- Test 6.1: Escaped brackets with unescaped wildcards
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\[%\]%' ESCAPE '\' ORDER BY id;
GO

-- Test 6.2: Escaped underscores with unescaped percent
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\_level\_%' ESCAPE '\' ORDER BY id;
GO

-- Test 6.3: Complex mixed pattern
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '_\[%\]_' ESCAPE '\' ORDER BY id;
GO

-- =============================================================================
-- TEST SECTION 5: Different Escape Characters
-- =============================================================================

--- '=== TEST 7: Various Escape Characters ==='

-- Test 7.1: At symbol as escape
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%@[300@]%' ESCAPE '@' ORDER BY id;
GO

-- Test 7.2: Hash as escape
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%#[300#]%' ESCAPE '#' ORDER BY id;
GO

-- Test 7.3: Pipe as escape
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%|[300|]%' ESCAPE '|' ORDER BY id;
GO

-- =============================================================================
-- TEST SECTION 6: Edge Cases and Error Conditions
-- =============================================================================

--- '=== TEST 8: Edge Cases ==='

-- Test 8.1: Empty pattern
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '' ORDER BY id;
GO

-- Test 8.2: Single character patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '\[' ESCAPE '\' ORDER BY id;
GO

-- Test 8.3: Multiple consecutive escapes
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\[\]%' ESCAPE '\' ORDER BY id;
GO

-- =============================================================================
-- TEST SECTION 7: Bracket Wildcard Behavior (Unescaped)
-- =============================================================================

--- '=== TEST 9: Bracket Wildcards (Unescaped) ==='

-- Test 9.1: Character class matching
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%[0-9]%' ORDER BY id;
GO

-- Test 9.2: Character class matching [a-z]
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%[a-z]%' ORDER BY id;
GO

-- Test 9.3: Specific character set
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%[abc]%' ORDER BY id;
GO

-- =============================================================================
-- TEST SECTION 8: Performance and Regression Tests
-- =============================================================================

--- '=== TEST 10: Regression Tests ===' as test_section;

-- Test 10.1: Ensure normal wildcards still work
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%test%' ORDER BY id;
GO

-- Test 10.2: Ensure normal underscore wildcard still works
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '_test_' ORDER BY id;
GO

-- Test 10.3: Complex pattern without escape
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%[0-9]%' ORDER BY id;
GO

-- =============================================================================
-- TEST SECTION 9: TSQL Compatibility Tests
-- =============================================================================

--- '=== TEST 11: TSQL Compatibility ===' as test_section;

-- Test 11.1: Typical TSQL escape patterns
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\[%\]%' ESCAPE '\' ORDER BY id;
GO

-- Test 11.2: TSQL underscore escape
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\_test\_%' ESCAPE '\' ORDER BY id;
GO

-- Test 11.3: TSQL percent escape
SELECT id, test_data FROM like_escape_test WHERE test_data LIKE '%\%%' ESCAPE '\' ORDER BY id;
GO

SELECT * FROM
(
SELECT string_agg('[' + CAST(BranchNumber as varchar(50)) + ']', ',') as BranchesOfAccounts
FROM like_escape_test_2
GROUP BY Id
) a
WHERE BranchesOfAccounts LIKE '%\[300\]%' ESCAPE '\';
GO
