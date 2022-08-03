--varchar
SELECT * FROM collation_tests_polish_vu_prepare_varchar ORDER BY name;
GO

SELECT * FROM collation_tests_polish_vu_prepare_varchar WHERE name LIKE '%un%';
GO

SELECT * FROM collation_tests_polish_vu_prepare_varchar WHERE name='sekunda';
GO
SELECT * FROM collation_tests_polish_vu_prepare_varchar WHERE name='sekunda' COLLATE polish_cs_as;
GO

--inner join
SELECT * FROM [INNER JOIN SAME CP POLISH] WHERE same_name = 'wczoraj';
GO

--computed column
SELECT substr_polish FROM collation_tests_polish_vu_prepare_varchar_computed_columns;
GO

SELECT substr_polish FROM collation_tests_polish_vu_prepare_varchar_computed_columns WHERE substr_polish='dzi';
GO

SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr_polish';
GO

--nvarchar
SELECT * FROM collation_tests_polish_vu_prepare_nvarchar ORDER BY name;
GO

SELECT * FROM collation_tests_polish_vu_prepare_nvarchar WHERE name LIKE '%un%';
GO

SELECT * FROM collation_tests_polish_vu_prepare_nvarchar WHERE name='sekunda';
GO
SELECT * FROM collation_tests_polish_vu_prepare_nvarchar WHERE name='sekunda' COLLATE polish_cs_as;
GO


--char
SELECT * FROM collation_tests_polish_vu_prepare_char ORDER BY name;
GO

SELECT * FROM collation_tests_polish_vu_prepare_char WHERE name LIKE '%un%';
GO

SELECT * FROM collation_tests_polish_vu_prepare_char WHERE name='sekunda';
GO
SELECT * FROM collation_tests_polish_vu_prepare_char WHERE name='sekunda' COLLATE polish_cs_as;
GO

--nchar
SELECT * FROM collation_tests_polish_vu_prepare_nchar ORDER BY name;
GO

SELECT * FROM collation_tests_polish_vu_prepare_nchar WHERE name LIKE '%un%';
GO

SELECT * FROM collation_tests_polish_vu_prepare_nchar WHERE name='sekunda';
GO
SELECT * FROM collation_tests_polish_vu_prepare_nchar WHERE name='sekunda' COLLATE polish_cs_as;
GO

--text
SELECT * FROM collation_tests_polish_vu_prepare_text ORDER BY name;
GO

SELECT * FROM collation_tests_polish_vu_prepare_text WHERE name LIKE '%un%';
GO

SELECT * FROM collation_tests_polish_vu_prepare_text WHERE name='sekunda';
GO
SELECT * FROM collation_tests_polish_vu_prepare_text WHERE name='sekunda' COLLATE polish_cs_as;
GO

--primary key
INSERT INTO collation_tests_polish_vu_prepare_primary VALUES ('tydzień');
INSERT INTO collation_tests_polish_vu_prepare_primary VALUES ('tydzień');
GO

SELECT * FROM collation_tests_polish_vu_prepare_primary ORDER BY name;
GO

SELECT * FROM collation_tests_polish_vu_prepare_primary WHERE name LIKE '%dz%';
GO

SELECT * FROM collation_tests_polish_vu_prepare_primary WHERE name = 'tydzień';
GO
SELECT * FROM collation_tests_polish_vu_prepare_primary WHERE name='tydzień' COLLATE polish_cs_as;
GO