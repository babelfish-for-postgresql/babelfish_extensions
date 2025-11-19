-- test REPLICATE function
SELECT REPLICATE(' abc ', 3)
GO

SELECT REPLICATE(N'abc', 3)
GO

SELECT REPLICATE(' abc ', 0)
GO

-- test null condition
SELECT REPLICATE('abc', -3)
GO

SELECT REPLICATE(null, 1)
GO

-- test LEN and DATALENGTH functions
SELECT LEN(N'123')
GO

SELECT LEN(N'123   ')
GO

SELECT LEN(N'   123   ')
GO

SELECT LEN(CAST('123' as char(25)))
GO

SELECT LEN('abc')
GO

SELECT LEN('abc' + 'def')
GO

SELECT LEN('tamaño')
GO

SELECT DATALENGTH(N'123')
GO

SELECT DATALENGTH(N'123   ')
GO

SELECT DATALENGTH(N'   123   ')
GO

SELECT DATALENGTH(CAST('123' as char(25)))
GO

SELECT DATALENGTH('ab' + 'def')
GO

SELECT DATALENGTH('哈哈12345')
GO

-- additional tests for DATALENGTH (more types, nullvalues)
SELECT datalength(a), datalength(b),datalength(c),datalength(d),datalength(e),
       datalength(f),datalength(g),datalength(h),datalength(i) FROM babel_function_string_vu_prepare_1
GO

SELECT datalength(a), datalength(b),datalength(c),datalength(d),datalength(e), datalength(f),datalength(g),datalength(h),datalength(i) FROM babel_function_string_vu_prepare_2
GO

SELECT datalength(a), datalength(b),datalength(c),datalength(d),datalength(e), datalength(f),datalength(g),datalength(h) FROM babel_function_string_vu_prepare_3
GO

-- test quotename function
SELECT quotename('hardrada', ']')
GO

SELECT quotename('gershwin', '<')
GO

SELECT quotename('faulkner', '>')
GO

SELECT quotename('edgerton', '(')
GO

SELECT quotename('denali', ')')
GO

SELECT quotename('charisma', '{')
GO

SELECT quotename('banana', '}')
GO

SELECT quotename('aardvark', '`')
GO

SELECT quotename('128 characters exactly----------------------------------------------------------------------------------------------------------')
GO

SELECT
quotename(']]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]')
GO

SELECT
quotename('""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""')
GO

SELECT quotename('''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''')
GO

SELECT quotename('')
GO

-- regtype error expected pending BABEL-883
SELECT pg_typeof(quotename('a'))
GO

SELECT quotename(CAST('abc' as varchar))
GO

SELECT quotename(CAST('abc' as sys.nvarchar))
GO

SELECT quotename(CAST('abc' as text))
GO

SELECT quotename('invalid char', 'F')
GO

SELECT quotename('too long char', 'aa')
GO

SELECT quotename('129 characters exactly-----------------------------------------------------------------------------------------------------------')
GO

SELECT quotename('default should be bracket')
GO

SELECT quotename('abc [] def')
GO

SELECT quotename(NULL)
GO

SELECT quotename(NULL, NULL)
GO

SELECT quotename('hey', NULL)
GO

SELECT quotename(NULL, '[')
GO

SELECT QUOTENAME('Hello ) there', ')')
GO

SELECT QUOTENAME('Hello )" there', ')')
GO

SELECT QUOTENAME('Hello < there', '<')
GO

SELECT QUOTENAME('Hello > there', '>')
GO

SELECT QUOTENAME('Hello } there', '}')
GO

SELECT QUOTENAME('Hello ` there', '`')
GO

SELECT QUOTENAME('[KEY]', '"')
GO

SELECT QUOTENAME('"KEY"', '[')
GO

SELECT QUOTENAME('"KEY"', '')
GO

-- test quotename with multibyte characters
SELECT quotename('こんにちは')
GO

SELECT quotename('测试中文', '"')
GO

SELECT quotename('café')
GO

SELECT quotename('Москва', '}{')
GO

SELECT quotename('Émojis🚀🌟')
GO

SELECT quotename('Mixed英文中文')
GO

-- test quotename with multibyte characters and different quote chars
SELECT quotename('こんにちは', '"')
GO

SELECT quotename('测试中文', '''')
GO

SELECT quotename('café', '>')
GO

SELECT quotename('Москва', '}')
GO

SELECT quotename('العربية', '`')
GO

-- test different size delimeter
SELECT quotename('こん"にちは', '["')
GO

SELECT quotename('test''中文', '[%&69]')
GO

SELECT quotename('café]test', '''')
GO

SELECT quotename('Москва}test', '}{^$[]}')
GO

SELECT quotename('Москва}test', 'Ğ🚀🌟')
GO

-- test unicode function

SELECT unicode(null)
GO

SELECT unicode('Åkergatan 24')
GO

SELECT nchar(unicode('Åkergatan 24'))
GO

SELECT unicode(cast('Āmazon' AS nvarchar))
GO

SELECT unicode(CAST('Āmazon' as nvarchar))
GO

SELECT unicode(cast('Ƃ' as nchar))
GO

SELECT unicode(CAST('Ƃ' as nchar))
GO

SELECT STRING_SPLIT('Lorem ipsum dolor sit amet.', ' ')
GO

SELECT STRING_SPLIT('clothing,road,,touring,bike', ',')
GO

SELECT STRING_SPLIT('||||||||', '|')
GO

SELECT STRING_SPLIT(NULL, ' ')
GO

-- test invalid separator
SELECT STRING_SPLIT('asdf', '')
GO

SELECT STRING_SPLIT('asdf', NULL)
GO

SELECT STRING_SPLIT(NULL, NULL)
GO

SELECT STRING_SPLIT(CAST('nvarchar nvarchar nvarchar' as nvarchar), CAST(' ' as nvarchar))
GO

SELECT STRING_SPLIT(CAST('varchar varchar varchar' as varchar), CAST(' ' as varchar))
GO

SELECT STRING_SPLIT('char char char', ' ')
GO

SELECT STRING_SPLIT('a,b,c,d', ',')
GO

SELECT STRING_SPLIT('mississippi island lives in igloo', 'i')
GO

SELECT STRING_SPLIT(CAST('asdf' as nchar(4)), ' ')
GO

SELECT STRING_SPLIT(CAST('asdf' as char(4)), ' ')
GO

-- test invalid separator
SELECT STRING_SPLIT('Lorem ipsum', 'too many chars')
GO

SELECT value FROM STRING_SPLIT('Lorem ipsum dolor sit amet.', ' ')
GO

SELECT mycol FROM STRING_SPLIT('Lorem ipsum dolor sit amet.', ' ')
GO

-- STRING_ESCAPE tests

SELECT STRING_ESCAPE('foo', 'notjson')
GO

SELECT STRING_ESCAPE('foo', '')
GO

SELECT STRING_ESCAPE('foo', NULL)
GO

SELECT STRING_ESCAPE(NULL, '')
GO

SELECT STRING_ESCAPE(NULL, NULL)
GO

SELECT STRING_ESCAPE(NULL, 'json')
GO

SELECT STRING_ESCAPE('	', 'json')
GO

SELECT STRING_ESCAPE('"', 'json')
GO

SELECT STRING_ESCAPE('\', 'json')
GO

SELECT STRING_ESCAPE('/', 'json')
GO

SELECT STRING_ESCAPE(chr(1), 'json')
GO

SELECT STRING_ESCAPE(chr(2), 'json')
GO

SELECT STRING_ESCAPE(chr(8), 'json')
GO

SELECT STRING_ESCAPE(chr(9), 'json')
GO

SELECT STRING_ESCAPE('
', 'json')
GO

SELECT STRING_ESCAPE(chr(10), 'json')
GO

SELECT STRING_ESCAPE(chr(11), 'json')
GO

SELECT STRING_ESCAPE(chr(12), 'json')
GO

SELECT STRING_ESCAPE(chr(13), 'json')
GO

SELECT STRING_ESCAPE(chr(31), 'json')
GO

SELECT STRING_ESCAPE('lorem ipsum dolor amet	
consectetur adipiscing elit', 'json')
GO

----------------------------------------------------
-- 1. Basic split with comma separator
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', ',');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 2. Empty substrings with consecutive delimiters
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,,b', ',');
-- Expected: a | (empty) | b
GO

----------------------------------------------------
-- 3. NULL input string
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(NULL, ',');
-- Expected: Empty result set
GO

----------------------------------------------------
-- 4. Space as separator
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('apple banana cherry', ' ');
-- Expected: apple | banana | cherry
GO

----------------------------------------------------
-- 5. Separator is more than 1 character (Invalid)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a--b--c', '--');
-- Expected: ERROR (Invalid separator length)
GO

----------------------------------------------------
-- 6. Unicode input with nvarchar
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'α,β,γ', N',');
-- Expected: α | β | γ
GO

----------------------------------------------------
-- 7. Mixed ASCII + Unicode
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'Hello,世界,😊', N',');
-- Expected: Hello | 世界 | 😊
GO

----------------------------------------------------
-- 8. Separator as space in Unicode string
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'one two 三', N' ');
-- Expected: one | two | 三
GO

----------------------------------------------------
-- 9. enable_ordinal = 1 (SQL Server feature)
----------------------------------------------------
SELECT value, ordinal
FROM STRING_SPLIT('x|y|z', '|', 1);
-- Expected (SQL Server 2022+): value | ordinal
-- x | 1
-- y | 2
-- z | 3
-- Babelfish: Should FAIL (function not supported)
GO

----------------------------------------------------
-- 10. enable_ordinal = 0 (Ignored in SQL Server)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('x|y|z', '|', 0);
-- Expected: x | y | z
-- Babelfish: FAIL (function signature mismatch)
GO

----------------------------------------------------
-- 11. Check behavior with empty separator (Invalid)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', '');
-- Expected: ERROR (Separator length must be 1)
GO

----------------------------------------------------
-- 12. Split numeric string
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('1|2|3', '|');
-- Expected: 1 | 2 | 3
GO

----------------------------------------------------
-- 13. Test ordering guarantee (SQL Server doesn't guarantee)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('b,a,c', ',')
ORDER BY value ASC;
-- Expected: a | b | c (after ORDER BY)
GO

----------------------------------------------------
-- 14. Test with trailing delimiters
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,', ',');
-- Expected: a | b | (empty)
GO

----------------------------------------------------
-- 15. Mixed ASCII + Unicode with explicit nvarchar cast
----------------------------------------------------
SELECT CAST(value as nvarchar)
FROM STRING_SPLIT(N'Hello,世界,😊', N',');
-- Expected: Hello | 世界 | 😊
GO

----------------------------------------------------
-- 16. Input as char(10)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(CAST('X|Y|Z' AS char(10)), '|');
-- Expected: X | Y | Z (with padding stripped)
GO

----------------------------------------------------
-- 17. Input as nchar(10)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(CAST(N'Ω|Φ|Ψ' AS nchar(10)), N'|');
-- Expected: Ω | Φ | Ψ (with padding stripped)
GO

----------------------------------------------------
-- 18. Separator as NULL (Invalid)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', NULL);
-- Expected: ERROR (Invalid separator)
GO

----------------------------------------------------
-- 19. Separator with multiple spaces (Invalid)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a  b  c', '  ');
-- Expected: ERROR (Separator length must be 1)
GO

----------------------------------------------------
-- 20. Very large input string (varchar(max))
----------------------------------------------------
SELECT COUNT(*)
FROM STRING_SPLIT(REPLICATE('a,', 10000), ',');
-- Expected: 10001 rows (last one empty)
GO

----------------------------------------------------
-- 21. Separator is a Unicode emoji (valid if single character)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'a😊b😊c', N'😊');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 22. VARCHAR-VARCHAR input (Expect varchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', ',');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 23. VARCHAR-NVARCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', cast(',' as NVARCHAR));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 24. NVARCHAR-NVARCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'a,b,c', N',');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 25. NVARCHAR-VARCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'a,b,c', ',');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 26. CHAR-CHAR input (Expect varchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast('a' as CHAR), cast(',' as CHAR(1)));
-- Expected: a
GO

----------------------------------------------------
-- 27. CHAR-NVARCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a', cast(',' as NVARCHAR));
-- Expected: a
GO

----------------------------------------------------
-- 28. CHAR-NCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast('a,b,c' as CHAR), cast(',' as NCHAR(1)));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 29. NCHAR-CHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast('a,b,c' as NCHAR), cast(',' as CHAR(1)));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 30. NVARCHAR-CHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast(N'a,b,c' as NVARCHAR), cast(',' as CHAR(1)));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 31. VARCHAR-NCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast('a,b,c' as VARCHAR), cast(',' as NCHAR(1)));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 32. Arbitrary input: INT (Expect error)
----------------------------------------------------
SELECT value FROM STRING_SPLIT(123, ',');
-- Expected: ERROR(Argument data type integer is invalid for argument 1 of string_split function.)
GO

----------------------------------------------------
-- 33. Arbitrary input: DECIMAL (Expect error)
----------------------------------------------------
SELECT value FROM STRING_SPLIT(123.45, ',');
-- Expected: ERROR(Argument data type numeric is invalid for argument 1 of string_split function.)
GO

----------------------------------------------------
-- 34. Arbitrary input: DATETIME (Expect error)
----------------------------------------------------
SELECT value FROM STRING_SPLIT(CAST('20231005' AS DATETIME), ',');
-- Expected: ERROR(Argument data type datetime is invalid for argument 1 of string_split function.)
GO

----------------------------------------------------
-- 35. Arbitrary input: VARBINARY (Expect error)
----------------------------------------------------
SELECT value FROM STRING_SPLIT(0x48656C6C6F, ',');
-- Expected: ERROR(Argument data type varbinary is invalid for argument 1 of string_split function.)
GO

