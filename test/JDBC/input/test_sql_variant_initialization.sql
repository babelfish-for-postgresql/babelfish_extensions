----------------------------------------------------
-- 1. Direct initialization with varchar
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = ('Hello World');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 2. Query initialization with varchar
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT 'Hello World');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 3. Direct initialization with unicode (nvarchar)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (N'Hello World😀');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 4. Query initialization with unicode (nvarchar)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT N'Hello World😀');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 5. Direct initialization with numeric string
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = ('12345');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 6. Query initialization with numeric string
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT '12345');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 7. Direct initialization with empty string
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = ('');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 8. Query initialization with empty string
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT '');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 9. Direct initialization with explicit cast
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST('Explicit Cast' AS VARCHAR(50)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 10. Query initialization with explicit cast
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST('Explicit Cast' AS VARCHAR(50)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 11. Direct initialization with numeric conversion
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(123.45 AS VARCHAR(20)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 12. Query initialization with numeric conversion
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(123.45 AS VARCHAR(20)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 13. Direct initialization with CONCAT
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = ('Prefix-' + 'Value' + '-Suffix');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 14. Query initialization with CONCAT
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT 'Prefix-' + 'Value' + '-Suffix');
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 15. Direct initialization with NULL
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (NULL);
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 16. Query initialization with NULL
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT NULL);
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 17. Direct initialization with char (fixed length)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST('Test' AS CHAR(10)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 18. Query initialization with char (fixed length)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST('Test' AS CHAR(10)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 19. Direct initialization with nchar (unicode fixed length)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(N'Test' AS NCHAR(10)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 20. Query initialization with nchar (unicode fixed length)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(N'Test' AS NCHAR(10)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 21. Direct initialization with char padding (trailing spaces)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST('A' AS CHAR(5)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 22. Query initialization with char padding (trailing spaces)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST('A' AS CHAR(5)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 23. Direct initialization with nchar padding (unicode trailing spaces)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(N'İ' AS NCHAR(5)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 24. Query initialization with nchar padding (unicode trailing spaces)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(N'İ' AS NCHAR(5)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 25. Direct initialization with max length char
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST('X' AS CHAR(8000)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 26. Query initialization with max length char
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST('X' AS CHAR(8000)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 27. Direct initialization with max length nchar
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(N'Y' AS NCHAR(4000)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 28. Query initialization with max length nchar
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(N'Y' AS NCHAR(4000)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 29. Direct initialization with char(1) minimum size
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST('Z' AS CHAR(1)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 30. Query initialization with char(1) minimum size
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST('Z' AS CHAR(1)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 31. Direct initialization with nchar(1) minimum size
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(N'Ş' AS NCHAR(1)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 32. Query initialization with nchar(1) minimum size
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(N'Ş' AS NCHAR(1)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 33. Direct initialization with char containing spaces
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST('A B C' AS CHAR(10)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 34. Query initialization with char containing spaces
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST('A B C' AS CHAR(10)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 35. Direct initialization with nchar containing unicode spaces
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(N'A B C' AS NCHAR(10)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 36. Query initialization with nchar containing unicode spaces
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(N'A B C' AS NCHAR(10)));
SELECT @result_sql_variant AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 37. Direct initialization with binary string from 'binary_string_test'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (0x62696E6172795F737472696E675F74657374);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 38. Query initialization with binary string from 'binary_string_test'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT 0x62696E6172795F737472696E675F74657374);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 39. Direct initialization with short binary from 'b' (1 byte)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (0x62);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 40. Query initialization with short binary from 'b' (1 byte)
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT 0x62);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 41. Direct initialization with empty binary
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (0x);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 42. Query initialization with empty binary
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT 0x);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 43. Direct initialization with CAST to BINARY from 'test'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(0x74657374 AS BINARY(10)));
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 44. Query initialization with CAST to BINARY from 'test'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(0x74657374 AS BINARY(10)));
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 45. Direct initialization with CAST to VARBINARY from 'binary'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(0x62696E617279 AS VARBINARY(20)));
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 46. Query initialization with CAST to VARBINARY from 'binary'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(0x62696E617279 AS VARBINARY(20)));
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 47. Direct initialization with BINARY padding from 'str'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(0x737472 AS BINARY(10)));
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 48. Query initialization with BINARY padding from 'str'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(0x737472 AS BINARY(10)));
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 49. Direct initialization with max length BINARY from 'x'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (CAST(0x78 AS BINARY(8000)));
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 50. Query initialization with max length BINARY from 'x'
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT CAST(0x78 AS BINARY(8000)));
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 51. Direct initialization with 'string' binary pattern
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (0x737472696E67);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 52. Query initialization with 'string' binary pattern
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT 0x737472696E67);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 53. Direct initialization with 'test_data' zeros ending
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (0x746573745F6461746100);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 54. Query initialization with 'test_data' zeros ending
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT 0x746573745F6461746100);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 55. Direct initialization with 'BINARY_TEST' in hex
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (0x42494E4152595F54455354);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO

----------------------------------------------------
-- 56. Query initialization with 'BINARY_TEST' in hex
----------------------------------------------------
DECLARE @result_sql_variant sql_variant;
SET @result_sql_variant = (SELECT 0x42494E4152595F54455354);
SELECT CAST(@result_sql_variant AS VARBINARY(MAX)) AS Result,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'BaseType') AS BaseType,
       SQL_VARIANT_PROPERTY(@result_sql_variant, 'MaxLength') AS MaxLength;
GO