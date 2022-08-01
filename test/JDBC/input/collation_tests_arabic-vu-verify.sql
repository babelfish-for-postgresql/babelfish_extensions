--varchar
SELECT * FROM collation_tests_arabic_vu_prepare_varchar ORDER BY name;
GO

SELECT * FROM collation_tests_arabic_vu_prepare_varchar WHERE name LIKE '%ب%';
GO

SELECT * FROM collation_tests_arabic_vu_prepare_varchar WHERE name='سعودي';
GO
SELECT * FROM collation_tests_arabic_vu_prepare_varchar WHERE name='سعودي' COLLATE arabic_cs_as;
GO

--inner join
SELECT * FROM [INNER JOIN SAME CP ARABIC] WHERE same_name = 'كلب';
GO

--computed column
SELECT substr_arabic FROM collation_tests_arabic_vu_prepare_varchar_computed_columns;
GO

SELECT substr_arabic FROM collation_tests_arabic_vu_prepare_varchar_computed_columns WHERE substr_arabic='مرح';
GO

SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr_arabic';
GO

--nvarchar
SELECT * FROM collation_tests_arabic_vu_prepare_nvarchar ORDER BY name;
GO

SELECT * FROM collation_tests_arabic_vu_prepare_nvarchar WHERE name LIKE '%ب%';
GO

SELECT * FROM collation_tests_arabic_vu_prepare_nvarchar WHERE name='سعودي';
GO
SELECT * FROM collation_tests_arabic_vu_prepare_nvarchar WHERE name='سعودي' COLLATE arabic_cs_as;
GO


--char
SELECT * FROM collation_tests_arabic_vu_prepare_char ORDER BY name;
GO

SELECT * FROM collation_tests_arabic_vu_prepare_char WHERE name LIKE '%ب%';
GO

SELECT * FROM collation_tests_arabic_vu_prepare_char WHERE name='سعودي';
GO
SELECT * FROM collation_tests_arabic_vu_prepare_char WHERE name='سعودي' COLLATE arabic_cs_as;
GO

--nchar
SELECT * FROM collation_tests_arabic_vu_prepare_nchar ORDER BY name;
GO

SELECT * FROM collation_tests_arabic_vu_prepare_nchar WHERE name LIKE '%ب%';
GO

SELECT * FROM collation_tests_arabic_vu_prepare_nchar WHERE name='سعودي';
GO
SELECT * FROM collation_tests_arabic_vu_prepare_nchar WHERE name='سعودي' COLLATE arabic_cs_as;
GO

--text
SELECT * FROM collation_tests_arabic_vu_prepare_text ORDER BY name;
GO

SELECT * FROM collation_tests_arabic_vu_prepare_text WHERE name LIKE '%ب%';
GO

SELECT * FROM collation_tests_arabic_vu_prepare_text WHERE name='سعودي';
GO
SELECT * FROM collation_tests_arabic_vu_prepare_text WHERE name='سعودي' COLLATE arabic_cs_as;
GO

--primary key
INSERT INTO collation_tests_arabic_vu_prepare_primary VALUES ('مرحبا');
INSERT INTO collation_tests_arabic_vu_prepare_primary VALUES ('مرحبا');
GO

SELECT * FROM collation_tests_arabic_vu_prepare_primary ORDER BY name;
GO

SELECT * FROM collation_tests_arabic_vu_prepare_primary WHERE name LIKE '%م%';
GO

SELECT * FROM collation_tests_arabic_vu_prepare_primary WHERE name = 'مرحبا';
GO
SELECT * FROM collation_tests_arabic_vu_prepare_primary WHERE name='مرحبا' COLLATE arabic_cs_as;
GO