--varchar
SELECT * FROM collation_tests_vu_prepare_english_collation_varchar ORDER BY name;
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_varchar WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_varchar WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_varchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_varchar WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_varchar WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_varchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_varchar WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_varchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

--inner join
SELECT * FROM [INNER JOIN SAME CP] WHERE same_name = 'new DelHI';
GO

--computed column
SELECT substr FROM collation_tests_vu_prepare_english_collation_varchar_computed_columns;
GO

SELECT substr FROM collation_tests_vu_prepare_english_collation_varchar_computed_columns WHERE substr='NEw d';
GO

SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr';
GO



--nvarchar
SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar ORDER BY name;
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nvarchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

--char
SELECT * FROM collation_tests_vu_prepare_english_collation_char ORDER BY name;
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_char WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_char WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_char WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_char WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_char WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_char WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_char WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_char WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

--nchar
SELECT * FROM collation_tests_vu_prepare_english_collation_nchar ORDER BY name;
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_nchar WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nchar WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nchar WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nchar WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_nchar WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_nchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

--text
SELECT * FROM collation_tests_vu_prepare_english_collation_text ORDER BY name;
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_text WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_text WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_text WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_text WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_text WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_text WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_text WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_text WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO


--test for primary key
INSERT INTO collation_tests_vu_prepare_english_collation_primary_key VALUES ('new Delhi');
GO
INSERT INTO collation_tests_vu_prepare_english_collation_primary_key VALUES ('neW DElhi');
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_primary_key ORDER BY name;
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_primary_key WHERE name LIKE 'NE%h%';
GO

SELECT * FROM collation_tests_vu_prepare_english_collation_primary_key WHERE name = 'NeW deLHi';
GO
SELECT * FROM collation_tests_vu_prepare_english_collation_primary_key WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO