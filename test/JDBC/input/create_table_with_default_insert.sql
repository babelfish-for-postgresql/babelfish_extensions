IF OBJECT_ID('test_unicode_defaults') IS NOT NULL DROP TABLE test_unicode_defaults;
GO
 
CREATE TABLE test_unicode_defaults
(
    id              INT IDENTITY PRIMARY KEY,
    col_char        CHAR(10) DEFAULT 'a😄ğğş',
    col_nchar       NCHAR(10) DEFAULT N'a😄ğğş',
    col_varchar     VARCHAR(10) DEFAULT 'a😄ğğş',
    col_nvarchar    NVARCHAR(10) DEFAULT N'a😄ğğş'
);
GO

INSERT INTO test_unicode_defaults DEFAULT VALUES;
GO

SELECT * FROM test_unicode_defaults;

INSERT INTO test_unicode_defaults VALUES ('a😄ğğş',N'a😄ğğş','a😄ğğş',N'a😄ğğş');
GO

SELECT * FROM test_unicode_defaults;
GO

INSERT INTO test_unicode_defaults VALUES ('000',N'000','000',N'000');
GO

SELECT * FROM test_unicode_defaults;
GO

UPDATE test_unicode_defaults
SET col_nchar = CAST(N'a😄ğğş' AS NVARCHAR(10))
WHERE id = 3;
GO

UPDATE test_unicode_defaults
SET col_nvarchar = CAST(N'a😄ğğş' AS NVARCHAR(10))
WHERE id = 3;
GO

UPDATE test_unicode_defaults
SET col_char = CAST(N'a😄ğğş' AS VARCHAR(10))
WHERE id = 3;
GO

UPDATE test_unicode_defaults
SET col_varchar = CAST(N'a😄ğğş' AS VARCHAR(10))
WHERE id = 3;
GO

SELECT * FROM test_unicode_defaults;
GO

INSERT INTO test_unicode_defaults DEFAULT VALUES;
GO

SELECT * FROM test_unicode_defaults;
GO

IF OBJECT_ID('test_unicode_defaults') IS NOT NULL DROP TABLE test_unicode_defaults;
GO