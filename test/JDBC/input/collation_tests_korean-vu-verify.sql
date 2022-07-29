--varchar
SELECT * FROM collation_tests_korean_vu_prepare_varchar ORDER BY name;
GO

SELECT * FROM collation_tests_korean_vu_prepare_varchar WHERE name LIKE '%장%';
GO

SELECT * FROM collation_tests_korean_vu_prepare_varchar WHERE name='화장실';
GO
SELECT * FROM collation_tests_korean_vu_prepare_varchar WHERE name='화장실' COLLATE korean_wansung_cs_as;
GO

--inner join
SELECT * FROM [INNER JOIN SAME CP KOREAN] WHERE same_name = '가게';
GO

--computed column
SELECT substr FROM collation_tests_korean_vu_prepare_varchar_computed_columns;
GO

SELECT substr FROM collation_tests_korean_vu_prepare_varchar_computed_columns WHERE substr='화';
GO

SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr';
GO

--nvarchar
SELECT * FROM collation_tests_korean_vu_prepare_nvarchar ORDER BY name;
GO

SELECT * FROM collation_tests_korean_vu_prepare_nvarchar WHERE name LIKE '%장%';
GO

SELECT * FROM collation_tests_korean_vu_prepare_nvarchar WHERE name='화장실';
GO
SELECT * FROM collation_tests_korean_vu_prepare_nvarchar WHERE name='화장실' COLLATE korean_wansung_cs_as;
GO


--char
SELECT * FROM collation_tests_korean_vu_prepare_char ORDER BY name;
GO

SELECT * FROM collation_tests_korean_vu_prepare_char WHERE name LIKE '%장%';
GO

SELECT * FROM collation_tests_korean_vu_prepare_char WHERE name='화장실';
GO
SELECT * FROM collation_tests_korean_vu_prepare_char WHERE name='화장실' COLLATE korean_wansung_cs_as;
GO

--nchar
SELECT * FROM collation_tests_korean_vu_prepare_nchar ORDER BY name;
GO

SELECT * FROM collation_tests_korean_vu_prepare_nchar WHERE name LIKE '%장%';
GO

SELECT * FROM collation_tests_korean_vu_prepare_nchar WHERE name='화장실';
GO
SELECT * FROM collation_tests_korean_vu_prepare_nchar WHERE name='화장실' COLLATE korean_wansung_cs_as;
GO

--text
SELECT * FROM collation_tests_korean_vu_prepare_text ORDER BY name;
GO

SELECT * FROM collation_tests_korean_vu_prepare_text WHERE name LIKE '%장%';
GO

SELECT * FROM collation_tests_korean_vu_prepare_text WHERE name='화장실';
GO
SELECT * FROM collation_tests_korean_vu_prepare_text WHERE name='화장실' COLLATE korean_wansung_cs_as;
GO

--primary key
INSERT INTO collation_tests_korean_vu_prepare_primary VALUES ('여기');
INSERT INTO collation_tests_korean_vu_prepare_primary VALUES ('여기');
GO

SELECT * FROM collation_tests_korean_vu_prepare_primary ORDER BY name;
GO

SELECT * FROM collation_tests_korean_vu_prepare_primary WHERE name LIKE '%여%';
GO

SELECT * FROM collation_tests_korean_vu_prepare_primary WHERE name = '여기';
GO
SELECT * FROM collation_tests_korean_vu_prepare_primary WHERE name='여기' COLLATE korean_wansung_cs_as;
GO

--truncation error
INSERT INTO collation_tests_korean_vu_prepare_truncation VALUES('가게');
GO