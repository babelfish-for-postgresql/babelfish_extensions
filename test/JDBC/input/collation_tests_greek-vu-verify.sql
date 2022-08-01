--varchar
SELECT * FROM collation_tests_greek_vu_prepare_varchar ORDER BY name;
GO

SELECT * FROM collation_tests_greek_vu_prepare_varchar WHERE name LIKE '%υχ%';
GO

SELECT * FROM collation_tests_greek_vu_prepare_varchar WHERE name='ευτυχία';
GO
SELECT * FROM collation_tests_greek_vu_prepare_varchar WHERE name='ευτυχία' COLLATE greek_cs_as;
GO

--inner join
SELECT * FROM [INNER JOIN SAME CP GREEK] WHERE same_name = 'ψυχή';
GO

--computed column
SELECT substr_greek FROM collation_tests_greek_vu_prepare_varchar_computed_columns;
GO

SELECT substr_greek FROM collation_tests_greek_vu_prepare_varchar_computed_columns WHERE substr_greek='αγά';
GO

SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr_greek';
GO

--nvarchar
SELECT * FROM collation_tests_greek_vu_prepare_nvarchar ORDER BY name;
GO

SELECT * FROM collation_tests_greek_vu_prepare_nvarchar WHERE name LIKE '%υχ%';
GO

SELECT * FROM collation_tests_greek_vu_prepare_nvarchar WHERE name='ευτυχία';
GO
SELECT * FROM collation_tests_greek_vu_prepare_nvarchar WHERE name='ευτυχία' COLLATE greek_cs_as;
GO


--char
SELECT * FROM collation_tests_greek_vu_prepare_char ORDER BY name;
GO

SELECT * FROM collation_tests_greek_vu_prepare_char WHERE name LIKE '%υχ%';
GO

SELECT * FROM collation_tests_greek_vu_prepare_char WHERE name='ευτυχία';
GO
SELECT * FROM collation_tests_greek_vu_prepare_char WHERE name='ευτυχία' COLLATE greek_cs_as;
GO

--nchar
SELECT * FROM collation_tests_greek_vu_prepare_nchar ORDER BY name;
GO

SELECT * FROM collation_tests_greek_vu_prepare_nchar WHERE name LIKE '%υχ%';
GO

SELECT * FROM collation_tests_greek_vu_prepare_nchar WHERE name='ευτυχία';
GO
SELECT * FROM collation_tests_greek_vu_prepare_nchar WHERE name='ευτυχία' COLLATE greek_cs_as;
GO

--text
SELECT * FROM collation_tests_greek_vu_prepare_text ORDER BY name;
GO

SELECT * FROM collation_tests_greek_vu_prepare_text WHERE name LIKE '%υχ%';
GO

SELECT * FROM collation_tests_greek_vu_prepare_text WHERE name='ευτυχία';
GO
SELECT * FROM collation_tests_greek_vu_prepare_text WHERE name='ευτυχία' COLLATE greek_cs_as;
GO

--primary key
INSERT INTO collation_tests_greek_vu_prepare_primary VALUES ('ελπίδα');
INSERT INTO collation_tests_greek_vu_prepare_primary VALUES ('ελπίδα');
GO

SELECT * FROM collation_tests_greek_vu_prepare_primary ORDER BY name;
GO

SELECT * FROM collation_tests_greek_vu_prepare_primary WHERE name LIKE '%πί%';
GO

SELECT * FROM collation_tests_greek_vu_prepare_primary WHERE name = 'ελπίδα';
GO
SELECT * FROM collation_tests_greek_vu_prepare_primary WHERE name='ελπίδα' COLLATE greek_cs_as;
GO