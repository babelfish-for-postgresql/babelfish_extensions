--varchar
SELECT * FROM collation_tests_mongolian_vu_prepare_varchar ORDER BY name;
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_varchar WHERE name LIKE '%л%';
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_varchar WHERE name='цнх';
GO
SELECT * FROM collation_tests_mongolian_vu_prepare_varchar WHERE name='цнх' COLLATE mongolian_cs_as;
GO

--inner join
SELECT * FROM [INNER JOIN SAME CP MONGOLIAN] WHERE same_name = 'хувцас';
GO

--computed column
SELECT substr_mongolian FROM collation_tests_mongolian_vu_prepare_varchar_computed_columns;
GO

SELECT substr_mongolian FROM collation_tests_mongolian_vu_prepare_varchar_computed_columns WHERE substr_mongolian='хув';
GO

SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr_mongolian';
GO

--nvarchar
SELECT * FROM collation_tests_mongolian_vu_prepare_nvarchar ORDER BY name;
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_nvarchar WHERE name LIKE '%л%';
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_nvarchar WHERE name='цнх';
GO
SELECT * FROM collation_tests_mongolian_vu_prepare_nvarchar WHERE name='цнх' COLLATE mongolian_cs_as;
GO


--char
SELECT * FROM collation_tests_mongolian_vu_prepare_char ORDER BY name;
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_char WHERE name LIKE '%л%';
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_char WHERE name='цнх';
GO
SELECT * FROM collation_tests_mongolian_vu_prepare_char WHERE name='цнх' COLLATE mongolian_cs_as;
GO

--nchar
SELECT * FROM collation_tests_mongolian_vu_prepare_nchar ORDER BY name;
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_nchar WHERE name LIKE '%л%';
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_nchar WHERE name='цнх';
GO
SELECT * FROM collation_tests_mongolian_vu_prepare_nchar WHERE name='цнх' COLLATE mongolian_cs_as;
GO

--text
SELECT * FROM collation_tests_mongolian_vu_prepare_text ORDER BY name;
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_text WHERE name LIKE '%л%';
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_text WHERE name='цнх';
GO
SELECT * FROM collation_tests_mongolian_vu_prepare_text WHERE name='цнх' COLLATE mongolian_cs_as;
GO

--primary key
INSERT INTO collation_tests_mongolian_vu_prepare_primary VALUES ('гл');
INSERT INTO collation_tests_mongolian_vu_prepare_primary VALUES ('гл');
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_primary ORDER BY name;
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_primary WHERE name LIKE '%г%';
GO

SELECT * FROM collation_tests_mongolian_vu_prepare_primary WHERE name = 'гл';
GO
SELECT * FROM collation_tests_mongolian_vu_prepare_primary WHERE name='гл' COLLATE mongolian_cs_as;
GO