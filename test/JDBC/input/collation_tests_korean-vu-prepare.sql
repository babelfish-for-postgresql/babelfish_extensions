--varchar
CREATE TABLE collation_tests_korean_vu_prepare_varchar (name varchar(20) COLLATE korean_wansung_ci_as);
GO

INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('여기');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('그곳에');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('장소');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('학교');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('가게');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('일');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('화장실');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('도시');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('나라');
INSERT INTO collation_tests_korean_vu_prepare_varchar VALUES ('기차역');
GO


--inner join
CREATE TABLE collation_tests_korean_vu_prepare_varchar_innerjoin (name_same_cp varchar(20) COLLATE korean_wansung_ci_as);
GO

INSERT INTO collation_tests_korean_vu_prepare_varchar_innerjoin VALUES ('여기');
INSERT INTO collation_tests_korean_vu_prepare_varchar_innerjoin VALUES ('장소');
INSERT INTO collation_tests_korean_vu_prepare_varchar_innerjoin VALUES ('가게');
INSERT INTO collation_tests_korean_vu_prepare_varchar_innerjoin VALUES ('화장실');
INSERT INTO collation_tests_korean_vu_prepare_varchar_innerjoin VALUES ('나라');
INSERT INTO collation_tests_korean_vu_prepare_varchar_innerjoin VALUES ('기차역');
GO

CREATE VIEW [INNER JOIN SAME CP KOREAN] AS
SELECT collation_tests_korean_vu_prepare_varchar.name AS name, collation_tests_korean_vu_prepare_varchar_innerjoin.name_same_cp AS same_name
FROM collation_tests_korean_vu_prepare_varchar
INNER JOIN collation_tests_korean_vu_prepare_varchar_innerjoin ON collation_tests_korean_vu_prepare_varchar.name = collation_tests_korean_vu_prepare_varchar_innerjoin.name_same_cp;
GO

--computed column
-- 1st column is for the actual string
-- 2nd column is for the substring
CREATE TABLE collation_tests_korean_vu_prepare_varchar_computed_columns(name_same varchar(20) COLLATE korean_wansung_ci_as, 
substr AS SUBSTRING (name_same, 1, 1));
GO

INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('여기');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('그곳에');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('장소');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('학교');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('가게');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('일');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('화장실');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('도시');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('나라');
INSERT INTO collation_tests_korean_vu_prepare_varchar_computed_columns VALUES ('기차역');
GO


--nvarchar
CREATE TABLE collation_tests_korean_vu_prepare_nvarchar (name nvarchar(20) COLLATE korean_wansung_ci_as);
GO

INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('여기');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('그곳에');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('장소');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('학교');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('가게');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('일');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('화장실');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('도시');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('나라');
INSERT INTO collation_tests_korean_vu_prepare_nvarchar VALUES ('기차역');
GO

--char
CREATE TABLE collation_tests_korean_vu_prepare_char (name char(20) COLLATE korean_wansung_ci_as);
GO

INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('여기');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('그곳에');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('장소');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('학교');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('가게');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('일');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('화장실');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('도시');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('나라');
INSERT INTO collation_tests_korean_vu_prepare_char VALUES ('기차역');
GO

--nchar
CREATE TABLE collation_tests_korean_vu_prepare_nchar (name nchar(20) COLLATE korean_wansung_ci_as);
GO

INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('여기');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('그곳에');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('장소');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('학교');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('가게');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('일');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('화장실');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('도시');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('나라');
INSERT INTO collation_tests_korean_vu_prepare_nchar VALUES ('기차역');
GO


--text
CREATE TABLE collation_tests_korean_vu_prepare_text (name text COLLATE korean_wansung_ci_as);
GO

INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('여기');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('그곳에');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('장소');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('학교');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('가게');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('일');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('화장실');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('도시');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('나라');
INSERT INTO collation_tests_korean_vu_prepare_text VALUES ('기차역');
GO

--primary key
CREATE TABLE collation_tests_korean_vu_prepare_primary(name varchar(20) COLLATE korean_wansung_ci_as NOT NULL PRIMARY KEY);
GO


--Truncation error
CREATE TABLE collation_tests_korean_vu_prepare_truncation(name varchar(3) COLLATE korean_wansung_ci_as);
GO