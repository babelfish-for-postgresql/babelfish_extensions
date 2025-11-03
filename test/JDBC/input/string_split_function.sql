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
-- 11. Check return type with nvarchar input
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;

SET @result_sql_variant = (
    SELECT TOP 1 value
    FROM STRING_SPLIT(N'A,B,C', N',')
);

SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
-- Expected in SQL Server: BaseType = nvarchar, MaxLength = input length
-- Babelfish: Likely varchar
GO

----------------------------------------------------
-- 12. Check behavior with empty separator (Invalid)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', '');
-- Expected: ERROR (Separator length must be 1)
GO

----------------------------------------------------
-- 13. Split numeric string
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('1|2|3', '|');
-- Expected: 1 | 2 | 3
GO

----------------------------------------------------
-- 14. Test ordering guarantee (SQL Server doesn't guarantee)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('b,a,c', ',')
ORDER BY value ASC;
-- Expected: a | b | c (after ORDER BY)
GO

----------------------------------------------------
-- 15. Test with trailing delimiters
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,', ',');
-- Expected: a | b | (empty)
GO

----------------------------------------------------
-- 16. Mixed ASCII + Unicode with explicit nvarchar cast
----------------------------------------------------
SELECT CAST(value as nvarchar)
FROM STRING_SPLIT(N'Hello,世界,😊', N',');
-- Expected: Hello | 世界 | 😊
GO

----------------------------------------------------
-- 17. Input as char(10)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(CAST('X|Y|Z' AS char(10)), '|');
-- Expected: X | Y | Z (with padding stripped)
GO

----------------------------------------------------
-- 18. Input as nchar(10)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(CAST(N'Ω|Φ|Ψ' AS nchar(10)), N'|');
-- Expected: Ω | Φ | Ψ (with padding stripped)
GO

----------------------------------------------------
-- 19. Separator as NULL (Invalid)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', NULL);
-- Expected: ERROR (Invalid separator)
GO

----------------------------------------------------
-- 20. Separator with multiple spaces (Invalid)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a  b  c', '  ');
-- Expected: ERROR (Separator length must be 1)
GO

----------------------------------------------------
-- 21. Very large input string (varchar(max))
----------------------------------------------------
SELECT COUNT(*)
FROM STRING_SPLIT(REPLICATE('a,', 10000), ',');
-- Expected: 10001 rows (last one empty)
GO

----------------------------------------------------
-- 22. Return type check with varchar input
----------------------------------------------------
DECLARE @r sql_variant;
SET @r = (SELECT TOP 1 value FROM STRING_SPLIT('a,b,c', ','));
SELECT @r AS Result,
       SQL_VARIANT_PROPERTY(@r, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@r, 'MaxLength') AS MaxLength;
-- Expected: BaseType = varchar, MaxLength = input length
GO

----------------------------------------------------
-- 23. Separator is a Unicode emoji (valid if single character)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'a😊b😊c', N'😊');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 24. VARCHAR-VARCHAR input (Expect varchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', ',');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 25. VARCHAR-NVARCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a,b,c', cast(',' as NVARCHAR));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 26. NVARCHAR-NVARCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'a,b,c', N',');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 27. NVARCHAR-VARCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(N'a,b,c', ',');
-- Expected: a | b | c
GO

----------------------------------------------------
-- 28. CHAR-CHAR input (Expect varchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast('a' as CHAR), cast(',' as CHAR(1)));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 29. CHAR-NVARCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT('a', cast(',' as NVARCHAR));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 30. CHAR-NCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast('a,b,c' as CHAR), cast(',' as NCHAR(1)));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 31. NCHAR-CHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast('a,b,c' as NCHAR), cast(',' as CHAR(1)));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 32. NVARCHAR-CHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast(N'a,b,c' as NVARCHAR), cast(',' as CHAR(1)));
-- Expected: a | b | c
GO

----------------------------------------------------
-- 33. VARCHAR-NCHAR input (Expect nvarchar)
----------------------------------------------------
SELECT value
FROM STRING_SPLIT(cast('a,b,c' as VARCHAR), cast(',' as NCHAR(1)));
-- Expected: a | b | c
GO
