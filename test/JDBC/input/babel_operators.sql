-- test adding with varbinary
SELECT (123 + 0x42);
SELECT (0x42 + 123);
GO

-- test subtracting with varbinary
SELECT (123 - 0x42);
SELECT (0x42 - 123);
GO

-- test multiplication with varbinary
SELECT (123 * CAST(123 AS varbinary(4)));
SELECT (CAST(123 AS varbinary(4)) * 123);
GO

-- test division with varbinary
SELECT (12345 / CAST(12 AS varbinary(4)));
SELECT (CAST(12345 AS varbinary(4)) / 12);
GO

-- test & operator with varbinary
SELECT (CAST(123 AS varbinary(1)) & 21);
SELECT (CAST(123 AS varbinary(2)) & 321);
SELECT (CAST(12345 AS varbinary(4)) & 54321);
GO

SELECT (CAST(9876543210 AS BIGINT) & CAST(1234567890 AS varbinary(8)));
SELECT (543210 & CAST(12345 AS varbinary(4)));
SELECT (CAST(321 AS smallint) & CAST(123 AS varbinary(2)));
SELECT (CAST(12 AS tinyint) & CAST(21 AS varbinary(1)));
GO

-- test | operator with varbinary
SELECT (CAST(123 AS varbinary(1)) | 21);
SELECT (CAST(123 AS varbinary(2)) | 321);
SELECT (CAST(12345 AS varbinary(4)) | 54321);
GO

SELECT (CAST(9876543210 AS BIGINT) | CAST(1234567890 AS varbinary(8)));
SELECT (543210 | CAST(12345 AS varbinary(4)));
SELECT (CAST(321 AS smallint) | CAST(123 AS varbinary(2)));
SELECT (CAST(12 AS tinyint) | CAST(21 AS varbinary(1)));
GO

-- test ^ operator with varbinary
SELECT (17 ^ 5);
GO

SELECT (CAST(123 AS varbinary(1)) ^ 21);
SELECT (CAST(123 AS varbinary(2)) ^ 321);
SELECT (CAST(12345 AS varbinary(4)) ^ 54321);
GO

SELECT (CAST(9876543210 AS BIGINT) ^ CAST(1234567890 AS varbinary(8)));
SELECT (543210 ^ CAST(12345 AS varbinary(4)));
SELECT (CAST(321 AS smallint) ^ CAST(123 AS varbinary(2)));
SELECT (CAST(12 AS tinyint) ^ CAST(21 AS varbinary(1)));
GO
