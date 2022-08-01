--varchar
SELECT * FROM collation_tests_chinese_vu_prepare_varchar ORDER BY name;
GO

SELECT * FROM collation_tests_chinese_vu_prepare_varchar WHERE name LIKE '%的%';
GO

SELECT * FROM collation_tests_chinese_vu_prepare_varchar WHERE name='是的。';
GO
SELECT * FROM collation_tests_chinese_vu_prepare_varchar WHERE name='是的。' COLLATE chinese_prc_cs_as;
GO

--inner join
SELECT * FROM [INNER JOIN SAME CP CHINESE] WHERE same_name = '微笑';
GO

--computed column
SELECT substr_chinese FROM collation_tests_chinese_vu_prepare_varchar_computed_columns;
GO

SELECT substr_chinese FROM collation_tests_chinese_vu_prepare_varchar_computed_columns WHERE substr_chinese='微';
GO

SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr_chinese';
GO

--nvarchar
SELECT * FROM collation_tests_chinese_vu_prepare_nvarchar ORDER BY name;
GO

SELECT * FROM collation_tests_chinese_vu_prepare_nvarchar WHERE name LIKE '%的%';
GO

SELECT * FROM collation_tests_chinese_vu_prepare_nvarchar WHERE name='是的。';
GO
SELECT * FROM collation_tests_chinese_vu_prepare_nvarchar WHERE name='是的。' COLLATE chinese_prc_cs_as;
GO


--char
SELECT * FROM collation_tests_chinese_vu_prepare_char ORDER BY name;
GO

SELECT * FROM collation_tests_chinese_vu_prepare_char WHERE name LIKE '%的%';
GO

SELECT * FROM collation_tests_chinese_vu_prepare_char WHERE name='是的。';
GO
SELECT * FROM collation_tests_chinese_vu_prepare_char WHERE name='是的。' COLLATE chinese_prc_cs_as;
GO

--nchar
SELECT * FROM collation_tests_chinese_vu_prepare_nchar ORDER BY name;
GO

SELECT * FROM collation_tests_chinese_vu_prepare_nchar WHERE name LIKE '%的%';
GO

SELECT * FROM collation_tests_chinese_vu_prepare_nchar WHERE name='是的。';
GO
SELECT * FROM collation_tests_chinese_vu_prepare_nchar WHERE name='是的。' COLLATE chinese_prc_cs_as;
GO

--text
SELECT * FROM collation_tests_chinese_vu_prepare_text ORDER BY name;
GO

SELECT * FROM collation_tests_chinese_vu_prepare_text WHERE name LIKE '%的%';
GO

SELECT * FROM collation_tests_chinese_vu_prepare_text WHERE name='是的。';
GO
SELECT * FROM collation_tests_chinese_vu_prepare_text WHERE name='是的。' COLLATE chinese_prc_cs_as;
GO

--primary key
INSERT INTO collation_tests_chinese_vu_prepare_primary VALUES ('爱');
INSERT INTO collation_tests_chinese_vu_prepare_primary VALUES ('爱');
GO

SELECT * FROM collation_tests_chinese_vu_prepare_primary ORDER BY name;
GO

SELECT * FROM collation_tests_chinese_vu_prepare_primary WHERE name LIKE '%是%';
GO

SELECT * FROM collation_tests_chinese_vu_prepare_primary WHERE name = '爱';
GO
SELECT * FROM collation_tests_chinese_vu_prepare_primary WHERE name='爱' COLLATE chinese_prc_cs_as;
GO

--truncation error
INSERT INTO collation_tests_chinese_vu_prepare_truncation VALUES('微笑');
GO