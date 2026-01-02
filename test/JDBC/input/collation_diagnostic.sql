-- Collation diagnostic test
CREATE TABLE collation_test (id INT, test_value NCHAR(50));
GO

INSERT INTO collation_test VALUES 
(1, N'Apple'),
(2, N'Zebra'), 
(3, N'日本語'),
(4, N'中文');
GO

-- Check current collation settings
SELECT SERVERPROPERTY('Collation') AS ServerCollation;
GO

-- Test ordering behavior
SELECT test_value FROM collation_test ORDER BY test_value;
GO

-- Test MIN/MAX behavior
SELECT MIN(test_value) AS min_val, MAX(test_value) AS max_val FROM collation_test;
GO

-- Check individual comparisons
SELECT 
    CASE WHEN N'日本語' > N'Zebra' THEN 'Japanese > Zebra' ELSE 'Zebra > Japanese' END AS comparison1,
    CASE WHEN N'中文' > N'Zebra' THEN 'Chinese > Zebra' ELSE 'Zebra > Chinese' END AS comparison2;
GO

DROP TABLE collation_test;
GO