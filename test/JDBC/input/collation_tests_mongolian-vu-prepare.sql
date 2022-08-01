--varchar
CREATE TABLE collation_tests_mongolian_vu_prepare_varchar (name varchar(20) COLLATE mongolian_ci_as);
GO

INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('гл');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('орой');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('Баяртай');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('хоол');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('хувцас');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('зэг');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('цнх');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('эгч');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('эмч');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar VALUES ('сургууль');
GO


--inner join
CREATE TABLE collation_tests_mongolian_vu_prepare_varchar_innerjoin (name_same_cp varchar(20) COLLATE mongolian_ci_as);
GO

INSERT INTO collation_tests_mongolian_vu_prepare_varchar_innerjoin VALUES ('гл');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_innerjoin VALUES ('Баяртай');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_innerjoin VALUES ('хувцас');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_innerjoin VALUES ('цнх');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_innerjoin VALUES ('эмч');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_innerjoin VALUES ('сургууль');
GO

CREATE VIEW [INNER JOIN SAME CP MONGOLIAN] AS
SELECT collation_tests_mongolian_vu_prepare_varchar.name AS name, collation_tests_mongolian_vu_prepare_varchar_innerjoin.name_same_cp AS same_name
FROM collation_tests_mongolian_vu_prepare_varchar
INNER JOIN collation_tests_mongolian_vu_prepare_varchar_innerjoin ON collation_tests_mongolian_vu_prepare_varchar.name = collation_tests_mongolian_vu_prepare_varchar_innerjoin.name_same_cp;
GO

--computed column
-- 1st column is for the actual string
-- 2nd column is for the substring
CREATE TABLE collation_tests_mongolian_vu_prepare_varchar_computed_columns(name_same varchar(20) COLLATE mongolian_ci_as, 
substr_mongolian AS SUBSTRING (name_same, 1, 3));
GO

INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('гл');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('орой');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('Баяртай');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('хоол');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('хувцас');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('зэг');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('цнх');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('эгч');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('эмч');
INSERT INTO collation_tests_mongolian_vu_prepare_varchar_computed_columns VALUES ('сургууль');
GO


--nvarchar
CREATE TABLE collation_tests_mongolian_vu_prepare_nvarchar (name nvarchar(20) COLLATE mongolian_ci_as);
GO

INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('гл');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('орой');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('Баяртай');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('хоол');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('хувцас');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('зэг');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('цнх');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('эгч');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('эмч');
INSERT INTO collation_tests_mongolian_vu_prepare_nvarchar VALUES ('сургууль');
GO

--char
CREATE TABLE collation_tests_mongolian_vu_prepare_char (name char(20) COLLATE mongolian_ci_as);
GO

INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('гл');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('орой');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('Баяртай');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('хоол');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('хувцас');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('зэг');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('цнх');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('эгч');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('эмч');
INSERT INTO collation_tests_mongolian_vu_prepare_char VALUES ('сургууль');
GO

--nchar
CREATE TABLE collation_tests_mongolian_vu_prepare_nchar (name nchar(20) COLLATE mongolian_ci_as);
GO

INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('гл');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('орой');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('Баяртай');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('хоол');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('хувцас');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('зэг');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('цнх');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('эгч');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('эмч');
INSERT INTO collation_tests_mongolian_vu_prepare_nchar VALUES ('сургууль');
GO


--text
CREATE TABLE collation_tests_mongolian_vu_prepare_text (name text COLLATE mongolian_ci_as);
GO

INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('гл');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('орой');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('Баяртай');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('хоол');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('хувцас');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('зэг');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('цнх');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('эгч');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('эмч');
INSERT INTO collation_tests_mongolian_vu_prepare_text VALUES ('сургууль');
GO

--primary key
CREATE TABLE collation_tests_mongolian_vu_prepare_primary(name varchar(20) COLLATE mongolian_ci_as NOT NULL PRIMARY KEY);
GO
